#!/bin/bash

set -e

echo "🛠️  Memulai setup CYSIC Verifier otomatis..."

### 1. Install Docker jika belum terpasang
if ! command -v docker &> /dev/null; then
  echo "📦 Docker belum terpasang. Menginstal Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sudo usermod -aG docker $USER
  echo "✅ Docker terpasang. Silakan logout-login ulang agar grup Docker aktif."
else
  echo "✅ Docker sudah tersedia."
fi

### 2. Install Docker Compose jika belum ada
if ! command -v docker-compose &> /dev/null; then
  echo "📦 Docker Compose belum tersedia. Menginstal..."
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  echo "✅ Docker Compose berhasil diinstal."
else
  echo "✅ Docker Compose sudah tersedia."
fi

### 3. Siapkan direktori
INSTALL_DIR=~/cysic-verifier
mkdir -p "$INSTALL_DIR/data"
mkdir -p "$INSTALL_DIR/keys"    # <- direktori untuk simpan .key dari container
cd "$INSTALL_DIR"

### 4. Minta input wallet
echo ""
read -p "🔑 Masukkan alamat wallet (0x...): " WALLET

# Validasi alamat Ethereum sederhana
if [[ ! $WALLET =~ ^0x[a-fA-F0-9]{40}$ ]]; then
  echo "❌ Alamat wallet tidak valid. Pastikan dalam format Ethereum (0x...)"
  exit 1
fi

# Simpan ke file .env
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
      - ./data:/root/cysic-verifier
      - ./keys:/root/.cysic/keys       # <- Mount keys folder dari container ke host
    restart: unless-stopped
    env_file:
      - .env
EOF

### 7. Hentikan container lama jika ada
if docker ps -a --format '{{.Names}}' | grep -q '^cysic-verifier$'; then
  echo "🧹 Menghentikan dan menghapus container lama..."
  docker-compose down
fi

### 8. Build & run
echo ""
echo "🔨 Membuild Docker image..."
docker-compose build

echo "🚀 Menjalankan container..."
docker-compose up -d

### 9. Tampilkan log
echo ""
echo "📡 Menampilkan log dari verifier (Ctrl+C untuk keluar):"
sleep 2
docker logs -f cysic-verifier
