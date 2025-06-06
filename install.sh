#!/bin/bash

set -e

### 0. Hapus file dan folder lama
echo "🧹 Menghapus file lama (jika ada)..."
rm -rf ~/cysic-verifier
rm -f ~/install.sh
rm -f ~/install.sh.*

### 1. Pastikan Docker terinstal
if ! command -v docker &> /dev/null; then
  echo "📦 Menginstal Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sudo usermod -aG docker $USER
  echo "✅ Docker terpasang. Logout/login ulang mungkin diperlukan."
else
  echo "✅ Docker sudah tersedia."
fi

### 2. Pastikan Docker Compose terinstal
if ! command -v docker-compose &> /dev/null; then
  echo "📦 Menginstal Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  echo "✅ Docker Compose terpasang."
else
  echo "✅ Docker Compose sudah tersedia."
fi

### 3. Siapkan direktori kerja
WORK_DIR=~/cysic-verifier
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

### 4. Minta wallet address
read -p "🔑 Masukkan alamat wallet (0x...): " WALLET

if [[ ! $WALLET =~ ^0x[a-fA-F0-9]{40}$ ]]; then
  echo "❌ Alamat wallet tidak valid."
  exit 1
fi

echo "REWARD_ADDRESS=$WALLET" > .env

### 5. Buat Dockerfile
cat <<'EOF' > Dockerfile
FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y curl git wget bash ca-certificates && \
    curl -L https://github.com/cysic-labs/cysic-phase3/releases/download/v1.0.0/setup_linux.sh -o /root/setup_linux.sh && \
    chmod +x /root/setup_linux.sh

WORKDIR /root

ARG REWARD_ADDRESS
ENV REWARD_ADDRESS=${REWARD_ADDRESS}

CMD bash /root/setup_linux.sh ${REWARD_ADDRESS} && cd /root/cysic-verifier && bash start.sh
EOF

### 6. Buat docker-compose.yml
cat <<'EOF' > docker-compose.yml
version: '3.8'

services:
  cysic:
    build:
      context: .
      args:
        REWARD_ADDRESS: ${REWARD_ADDRESS}
    container_name: cysic-verifier
    stdin_open: true
    tty: true
    volumes:
      - /root/.cysic/keys:/root/.cysic/keys     # Pakai folder yang benar
    restart: unless-stopped
    env_file:
      - .env
EOF

### 7. Stop container lama jika ada
if docker ps -a --format '{{.Names}}' | grep -q '^cysic-verifier$'; then
  echo "🧹 Menghapus container lama..."
  docker-compose down
fi

### 8. Build & run
echo "🔨 Membuild Docker image..."
docker-compose build

echo "🚀 Menjalankan container..."
docker-compose up -d

### 9. Tampilkan log
sleep 2
echo "📡 Menampilkan log (Ctrl+C untuk keluar):"
docker logs -f cysic-verifier

### 10. Hapus skrip ini sendiri
rm -- "$0"
