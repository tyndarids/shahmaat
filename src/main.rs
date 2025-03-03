#![warn(clippy::use_self)]

mod board;
mod board_pos;
mod piece;
mod protocol;

use board::BoardState;
use futures_util::{SinkExt as _, stream::StreamExt as _};
use http::header::SEC_WEBSOCKET_PROTOCOL;
use log::{error, info, warn};
use protocol::{ClientMessage, ServerMessage};
use tokio::{
    net::{TcpListener, TcpStream},
    select,
    sync::{Semaphore, SemaphorePermit, TryAcquireError},
    task::JoinSet,
};
use tokio_tungstenite::tungstenite::{
    self,
    handshake::client::Request,
    http::{HeaderValue, Response},
};

const PROTOCOL_VERSION: &str = "shahmaat_protocol_0.1.0";
static SEMAPHORE: Semaphore = Semaphore::const_new(1);

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
                info!("Gracefully quitting");
                tasks.abort_all();
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

    let board = BoardState::default();
    info!("\n{}", board);

    while let Some(message) = rx.next().await {
        let message = message?;
        match message {
            tungstenite::Message::Text(text) => {
                let Ok(message) = serde_json::from_str::<ClientMessage>(text.as_ref()) else {
                    tx.send(tungstenite::Message::Text(
                        serde_json::to_string(&ServerMessage::Error(
                            "Could not decode message".to_owned(),
                        ))?
                        .into(),
                    ))
                    .await?;
                    continue;
                };
                match &message {
                    ClientMessage::Picked { pos } => {
                        if let Some(piece) = board[*pos] {
                            todo!();
                        }
                    }
                    ClientMessage::Placed { pos } => todo!(),
                    ClientMessage::Error(err) => error!("{:?}", message),
                }
            }
            tungstenite::Message::Close(_) => break,
            tungstenite::Message::Frame(_) => unreachable!(),
            _ => warn!("Unexpected message: {message}"),
        }
    }

    info!("Connection gracefully terminated");
    Ok(())
}
