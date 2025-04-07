FROM rust:1.81 as builder
WORKDIR /app
COPY . .
RUN cargo build --release --example server

FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/examples/server /app/server
COPY cert.pem key.pem
EXPOSE 4433/udp
CMD ["./server"]
