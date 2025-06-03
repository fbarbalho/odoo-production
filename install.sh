#!/bin/bash

# Script de instalação Odoo 18.0 para Hetzner VPS
set -e

echo "🚀 Instalando Odoo 18.0 na Hetzner VPS..."

# Atualizar sistema
apt update && apt upgrade -y

# Instalar dependências
apt install -y curl wget git apt-transport-https ca-certificates software-properties-common

# Instalar Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y docker-ce docker-ce-cli containerd.io

systemctl start docker
systemctl enable docker

# Instalar Docker Compose
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Criar estrutura
mkdir -p /opt/odoo
cd /opt/odoo

# Clonar repositório
git clone https://github.com/fbarbalho/odoo-production.git .

# Configurar .env se não existir
if [ ! -f ".env" ]; then
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" > .env
    echo "💾 Senha PostgreSQL: ${POSTGRES_PASSWORD}"
fi

# Tornar scripts executáveis
chmod +x *.sh

# Configurar serviço systemd
cat > /etc/systemd/system/odoo.service << 'SERVICE_EOF'
[Unit]
Description=Odoo 18.0
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/odoo
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload
systemctl enable odoo.service

# Configurar backup automático
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/odoo/backup.sh >> /var/log/odoo-backup.log 2>&1") | crontab -

echo "✅ Instalação concluída!"
echo "🚀 Execute: ./optimize-hetzner.sh && docker-compose up -d"
echo "🌐 Acesso: http://$(curl -s ifconfig.me):8069"
