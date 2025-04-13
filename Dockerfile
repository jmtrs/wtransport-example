FROM rust:1.81 as builder
WORKDIR /app
COPY . .
RUN cargo build --release --example full
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/examples/full /app/server
EXPOSE 4433/udp
EXPOSE 8080/tcp
CMD ["./server"]
