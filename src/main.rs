use futures_util::{FutureExt, SinkExt as _, stream::StreamExt as _};
use http::header::SEC_WEBSOCKET_PROTOCOL;
use log::{debug, error, info, warn};
use tokio::{
    net::{TcpListener, TcpStream},
    sync::{Semaphore, SemaphorePermit, TryAcquireError},
    task::JoinSet,
};
use tokio_tungstenite::tungstenite::{
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
    let intr_handler = tokio::spawn(tokio::signal::ctrl_c());

    info!("Listening for connections");
    loop {
        if intr_handler.is_finished() {
            eprint!("\r"); // clear the ^C in the terminal
            info!("Gracefully quitting");
            intr_handler.await??;
            tasks.abort_all();
            return Ok(());
        }

        if let Some(Ok((raw_stream, addr))) = socket.accept().now_or_never() {
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

    while let Some(message) = rx.next().await {
        let message = message?;
        use tokio_tungstenite::tungstenite::Message;
        match message {
            Message::Text(text) => {
                debug!("Received: {text}");
                tx.send(Message::Text("Hello from Rust!".into())).await?;
                debug!("Sent message");
            }
            Message::Close(_) => break,
            Message::Frame(_) => unreachable!(),
            _ => warn!("Unexpected message: {message}"),
        }
    }

    info!("Connection gracefully terminated");
    Ok(())
}
