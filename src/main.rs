use futures_util::{SinkExt as _, stream::StreamExt as _};
use http::header::SEC_WEBSOCKET_PROTOCOL;
use tokio::net::TcpListener;
use tokio_tungstenite::tungstenite::{
    handshake::client::Request,
    http::{HeaderValue, Response},
};

const PROTOCOL_VERSION: &str = "shahmaat_protocol_0.1.0";

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let socket = TcpListener::bind("localhost:8080").await?;

    eprint!("Waiting for connection... ");
    while let Ok((raw_stream, addr)) = socket.accept().await {
        println!("Accepted connection from {addr}");

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
                eprintln!("Shahmaat protocol version mismatch");
                eprintln!(
                    "Client protocols: {:?}",
                    protocols.iter().collect::<Vec<_>>(),
                );
                eprintln!("Server protocols: {PROTOCOL_VERSION:?}");
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
                    println!("Received: {text}");
                    tx.send(Message::Text("Hello from Rust!".into())).await?;
                    println!("Sent message");
                }
                Message::Close(_) => break,
                Message::Frame(_) => unreachable!(),
                _ => eprintln!("Unexpected message: {message}"),
            }
        }

        eprint!("\nWaiting for connection... ");
    }

    Ok(())
}
