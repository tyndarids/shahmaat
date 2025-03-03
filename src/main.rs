#![warn(clippy::use_self)]

mod board;
mod board_pos;
mod piece;
mod protocol;
mod valid_moves;

use board::BoardState;
use futures_util::{SinkExt as _, stream::StreamExt as _};
use http::header::SEC_WEBSOCKET_PROTOCOL;
use log::{error, info, warn};
use protocol::ClientMessage;
use std::mem::take;
use tokio::{
    net::{TcpListener, TcpStream},
    select,
    sync::{Semaphore, SemaphorePermit, TryAcquireError},
    task::JoinSet,
};
use tokio_tungstenite::tungstenite::{
    handshake::client::Request,
    http::{HeaderValue, Response},
};

const PROTOCOL_VERSION: &str = "shahmaat_protocol_0.1.0";
static SEMAPHORE: Semaphore = Semaphore::const_new(1);

macro_rules! send {
    ($tx:expr, $variant:expr) => {
        use protocol::ServerMessage::*;
        use tokio_tungstenite::tungstenite::Message;

        let message = $variant;

        if let Error(err) = &message {
            error!("Error: {err}");
        } else {
            info!("Sending {:?}", &message);
        }

        $tx.send(Message::Text(serde_json::to_string(&message)?.into()))
            .await?;
    };
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    env_logger::init();

    let socket = TcpListener::bind("localhost:8080").await?;
    let mut tasks = JoinSet::new();

    info!("Listening for connections");
    loop {
        select! {
            Ok(()) = tokio::signal::ctrl_c() => {
                eprint!("\r"); // clear the ^C in the terminal
                info!("Shutting down {} tasks", tasks.len());
                tasks.shutdown().await;
                return Ok(());
            }
            Ok((raw_stream, addr)) = socket.accept() => {
                info!("Connection requested from {addr}");
                match SEMAPHORE.try_acquire() {
                    Ok(permit) => {
                        tasks.spawn(handle_connection(permit, raw_stream));
                    }
                    Err(TryAcquireError::NoPermits) => {
                        error!("Server reached its maximum number of simultaneous connections")
                    }
                    Err(err) => error!("Error: {err}"),
                }

            }
        }
    }
}

async fn handle_connection(
    _permit: SemaphorePermit<'_>,
    raw_stream: TcpStream,
) -> anyhow::Result<()> {
    let stream = tokio_tungstenite::accept_hdr_async(
        raw_stream,
        |req: &'_ Request, mut resp: Response<_>| {
            let protocols = req.headers().get_all(http::header::SEC_WEBSOCKET_PROTOCOL);
            for protocol in protocols
                .iter()
                .map(HeaderValue::to_str)
                .map(Result::unwrap)
                .map(str::trim)
            {
                if protocol == PROTOCOL_VERSION {
                    resp.headers_mut()
                        .append(SEC_WEBSOCKET_PROTOCOL, protocol.try_into().unwrap());
                    return Ok(resp);
                }
            }
            warn!("Shahmaat protocol version mismatch");
            warn!(
                "Client protocols: {:?}",
                protocols.iter().collect::<Vec<_>>(),
            );
            warn!("Server protocols: {PROTOCOL_VERSION:?}");
            Ok(resp)
        },
    )
    .await?;
    let (mut tx, mut rx) = stream.split();

    let mut board = BoardState::default();
    let mut picked_piece_pos = None;
    info!("\n{}", board);
    send!(tx, Start(board));

    while let Some(message) = rx.next().await {
        let message = message?;
        match message {
            Message::Text(text) => {
                let Ok(message) = serde_json::from_str::<ClientMessage>(text.as_ref()) else {
                    send!(tx, Error("Could not decode message"));
                    error!("Received `{text}`");
                    continue;
                };
                match &message {
                    ClientMessage::Picked(pos) => {
                        picked_piece_pos = Some(*pos);
                        let valid_moves = board.valid_moves(*pos);
                        send!(tx, ValidMoves(valid_moves));
                    }

                    ClientMessage::Placed(pos) => {
                        if let Some(from) = picked_piece_pos {
                            let valid_moves = board.valid_moves(*pos);
                            if &from == pos || valid_moves.contains(pos) {
                                board[*pos] = take(&mut board[from]);
                                send!(tx, Place(*pos));
                            }
                        } else {
                            send!(tx, Error("Trying to place without picking a piece"));
                        }
                    }

                    ClientMessage::Error(_) => error!("{:?}", message),
                }
            }
            Message::Close(_) => {
                info!("Client disconnected");
                break;
            }
            Message::Frame(_) => unreachable!(),
            _ => warn!("Unexpected message: {message}"),
        }
    }

    Ok(())
}
