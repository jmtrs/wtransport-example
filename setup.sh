#!/bin/bash

echo "Clonando repositorio..."
git clone https://github.com/jmtrs/wtransport-example.git
cd wtransport-example || { echo "No se pudo entrar al directorio"; exit 1; }

echo "Creando carpetas de certbot..."
mkdir -p certbot/conf certbot/www
chmod -R 755 certbot

echo "Construyendo y levantando contenedores con Docker Compose..."
docker compose up -d --build

echo "Hecho. Revisa Portainer o ejecuta 'docker ps' para verificar que esté corriendo."
