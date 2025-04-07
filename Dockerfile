FROM rust:1.81 as builder

WORKDIR /app
COPY . .
RUN cargo build --release --example server

FROM debian:bookworm-slim  # <-- ¡Aquí cambiamos Bullseye por Bookworm!
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/examples/server /app/server
COPY cert.pem key.pem . # en desarrollo, en producción ya tienes el volumen
EXPOSE 4433/udp
CMD ["./server"]
