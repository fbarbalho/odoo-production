#!/bin/bash

set -e

echo "⚡ Otimizando para Hetzner CX22..."

# Configurar swap
echo "💾 Configurando swap..."
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Configurações do sistema
echo "🔧 Otimizando sistema..."
cat >> /etc/sysctl.conf << 'SYSCTL_EOF'
vm.swappiness=10
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
vm.dirty_expire_centisecs = 1500
vm.dirty_writeback_centisecs = 500
SYSCTL_EOF

sysctl -p

# Configurar Docker
echo "🐳 Otimizando Docker..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'DOCKER_EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
DOCKER_EOF

systemctl restart docker

echo "✅ Otimizações aplicadas!"
echo "🚀 Execute: docker-compose up -d"
