# Etapa 1: Compilar el binario
FROM rust:1.81 as builder

WORKDIR /app
COPY . .

RUN cargo build --release --example server

# Etapa 2: Imagen de producción
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app

# Copiar el binario compilado
COPY --from=builder /app/target/release/examples/server /app/server

# Copiar certificados si quieres hacer test local
# COPY cert.pem key.pem .

EXPOSE 4433/udp
EXPOSE 8080/tcp

CMD ["./server"]
