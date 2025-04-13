#!/bin/bash

set -e

REPO_URL="https://github.com/jmtrs/wtransport-example.git"
CLONE_DIR="wtransport-example"
DOMAIN="wtransport.jmtrs.uk"

echo "Clonando el repositorio si no existe..."
if [ ! -d "$CLONE_DIR" ]; then
  git clone --recursive "$REPO_URL"
fi

cd "$CLONE_DIR" || { echo "No se pudo acceder al directorio $CLONE_DIR"; exit 1; }

echo "Preparando carpetas para Certbot..."
mkdir -p certbot/conf certbot/www
chmod -R 755 certbot

echo "Solicitando certificado con Certbot..."
docker run --rm -it \
  -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
  -v "$(pwd)/certbot/www:/var/www/certbot" \
  -p 80:80 \
  certbot/certbot certonly \
  --webroot \
  -w /var/www/certbot \
  -d "$DOMAIN" \
  --register-unsafely-without-email \
  --agree-tos

echo "Construyendo el backend..."
docker compose build --no-cache

echo "Levantando contenedores..."
docker compose down || true
docker compose up -d

echo "Listo. Usa 'docker logs -f webtransport' para ver si está funcionando."
