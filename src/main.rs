#![warn(clippy::use_self)]

mod board;
mod board_pos;
mod piece;
mod protocol;
mod valid_moves;

use board::BoardState;
use futures_util::{SinkExt as _, stream::StreamExt as _};
use http::header::SEC_WEBSOCKET_PROTOCOL;
use log::{debug, error, info, warn};
use protocol::ClientMessage;
use std::{mem::take, sync::Arc, time::Duration};
use tokio::{
    net::{TcpListener, TcpStream},
    select,
    sync::{OwnedSemaphorePermit, Semaphore, TryAcquireError},
    task::JoinSet,
    time::interval,
};
use tokio_tungstenite::tungstenite::{
    Bytes,
    handshake::client::Request,
    http::{HeaderValue, Response},
};

const PROTOCOL_VERSION: &str = "shahmaat_protocol_0.1.0";

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
    let semaphore = Arc::new(Semaphore::new(1));

    info!("Listening for connections");
    loop {
        select! {
            Some(task) = tasks.join_next() => if let Err(err) = task? {
                error!("Task errored out: {:?}", err);
            },
            Ok(()) = tokio::signal::ctrl_c() => {
                eprint!("\r"); // clear the ^C in the terminal
                info!("Shutting down {} tasks", tasks.len());
                tasks.shutdown().await;
                return Ok(());
            }
            Ok((raw_stream, addr)) = socket.accept() => {
                info!("Connection requested from {addr}");
                match Arc::clone(&semaphore).try_acquire_owned() {
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
    _permit: OwnedSemaphorePermit,
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

    let mut heartbeat_timer = interval(Duration::from_secs(10));
    let mut pings = 0;
    let mut pongs = 0;
    let mut board = BoardState::default();
    let mut picked_piece_pos = None;

    send!(tx, Start(board));

    loop {
        select! {
            _ = heartbeat_timer.tick() => {
                if pings != pongs {
                    error!("Client not responding to pings");
                    break;
                }
                tx.send(Message::Ping(Bytes::new())).await?;
                pings += 1;
            },

            Some(message) = rx.next() => {
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
                                if let Some(piece) = board[*pos] {
                                    debug!("Picked up {piece:?} at {pos:?}");
                                    picked_piece_pos = Some(*pos);
                                    send!(tx, ValidMoves(board.valid_moves(*pos)));
                                } else {
                                    send!(tx, Error("No piece at picked location"));
                                }
                            }

                            ClientMessage::Placed(pos) => {
                                if let Some(from) = picked_piece_pos {
                                    let valid_moves = board.valid_moves(from);
                                    if &from == pos || valid_moves.contains(pos) {
                                        debug!("Moving from {from:?} to {pos:?}");
                                        if let Some(piece) = take(&mut board[from]) {
                                            board[*pos] = Some(piece);
                                            send!(tx, Place(from, *pos));
                                        } else {
                                            send!(tx, Error("No piece found at picked location"));
                                        }
                                    } else {
                                        send!(tx, Error("Placing in an invalid location"));
                                    }
                                } else {
                                    send!(tx, Error("Trying to place without picking a piece"));
                                }
                            }

                            ClientMessage::Error(_) => error!("{:?}", message),
                        }
                        debug!("\n{board}");
                    }

                    Message::Close(_) => {
                        info!("Client disconnected");
                        break;
                    }

                    Message::Pong(_) => {
                        pongs += 1;
                        debug!("Heartbeat {pings} - {pongs}");
                    }
                    Message::Ping(_) => {
                        debug!("Client pinged, sending pong");
                        tx.send(Message::Pong(Bytes::new())).await?;
                    }

                    Message::Binary(_) => warn!("Unexpected binary message: {message:?}"),
                    Message::Frame(_) => unreachable!(),
                }
            }
        }
    }

    Ok(())
}
