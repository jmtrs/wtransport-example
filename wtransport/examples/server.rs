use anyhow::{Context, Result};
use std::env;
use std::time::Duration;
use tokio::fs;
use tracing::{error, info};
use tracing_subscriber::{filter::LevelFilter, EnvFilter};
use wtransport::endpoint::IncomingSession;
use wtransport::{Endpoint, Identity, ServerConfig};

#[tokio::main]
async fn main() -> Result<()> {
    init_logging();

    let identity = match (env::var("CERT_PATH"), env::var("KEY_PATH")) {
        (Ok(cert_path), Ok(key_path)) => {
            info!("Loading certificate from files");
            Identity::load_pemfiles(cert_path, key_path)
                .await
                .context("Failed to load cert or key")?
        }
        _ => {
            info!("Generating self-signed certificate");
            Identity::self_signed(["localhost", "127.0.0.1", "::1"])
                .context("Failed to generate self-signed cert")?
        }
    };

    let config = ServerConfig::builder()
        .with_bind_default(4433)
        .with_identity(identity)
        .keep_alive_interval(Some(Duration::from_secs(3)))
        .build();

    let server = Endpoint::server(config)?;
    info!("Server ready!");

    for id in 0.. {
        let incoming_session = server.accept().await;
        tokio::spawn(handle_connection(incoming_session));
    }

    Ok(())
}

async fn handle_connection(incoming_session: IncomingSession) {
    let mut buffer = vec![0; 65536].into_boxed_slice();

    if let Ok(session_request) = incoming_session.await {
        let authority = session_request.authority().to_string();
        let path = session_request.path().to_string();

        if let Ok(connection) = session_request.accept().await {
            info!(
            "New session: Authority: '{}', Path: '{}'",
            authority,
            path
        );

            loop {
                tokio::select! {
                    stream = connection.accept_bi() => {
                        let mut stream = match stream {
                            Ok(s) => s,
                            Err(_) => continue,
                        };

                        if let Ok(Some(bytes_read)) = stream.1.read(&mut buffer).await {
                            if let Ok(data) = std::str::from_utf8(&buffer[..bytes_read]) {
                                info!("Received (bi) '{data}'");
                                let _ = stream.0.write_all(b"ACK").await;
                            }
                        }
                    }
                    stream = connection.accept_uni() => {
                        let mut stream = match stream {
                            Ok(s) => s,
                            Err(_) => continue,
                        };

                        if let Ok(Some(bytes_read)) = stream.read(&mut buffer).await {
                            if let Ok(data) = std::str::from_utf8(&buffer[..bytes_read]) {
                                info!("Received (uni) '{data}'");

                                if let Ok(opened) = connection.open_uni().await {
                                    if let Ok(mut writer) = opened.await {
                                        let _ = writer.write_all(b"ACK").await;
                                    }
                                }
                            }
                        }
                    }
                    dgram = connection.receive_datagram() => {
                        if let Ok(dgram) = dgram {
                            if let Ok(data) = std::str::from_utf8(&dgram) {
                                info!("Received (dgram) '{data}'");
                                let _ = connection.send_datagram(b"ACK");
                            }
                        }
                    }
                }
            }
        }
    }
}

fn init_logging() {
    let env_filter = EnvFilter::builder()
        .with_default_directive(LevelFilter::INFO.into())
        .from_env_lossy();

    tracing_subscriber::fmt()
        .with_target(true)
        .with_level(true)
        .with_env_filter(env_filter)
        .init();
}
