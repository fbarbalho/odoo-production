#!/bin/bash

# Helper para configurar GitHub Secrets
# Execute na VPS após instalação: ./setup-secrets.sh

set -e

echo "🔑 GitHub Secrets Configuration Helper"
echo "======================================"

if [ ! -f "/opt/odoo/.env" ]; then
    echo "❌ Execute este script na VPS após a instalação!"
    exit 1
fi

echo "📋 Coletando informações para GitHub Secrets..."

# HOST
HOST_IP=$(curl -s ifconfig.me 2>/dev/null || echo "OBTER_IP_MANUALMENTE")
echo "🌐 HOST: $HOST_IP"

# POSTGRES_PASSWORD
POSTGRES_PASSWORD=$(grep "POSTGRES_PASSWORD=" /opt/odoo/.env | cut -d'=' -f2 2>/dev/null || echo "SENHA_NAO_ENCONTRADA")
echo "🔒 POSTGRES_PASSWORD: $POSTGRES_PASSWORD"

echo ""
echo "🎯 CONFIGURAR NO GITHUB:"
echo "https://github.com/fbarbalho/odoo-production/settings/secrets/actions"
echo ""
echo "Secrets necessários:"
echo "- HOST: $HOST_IP"
echo "- USERNAME: root"
echo "- SSH_KEY: [conteúdo da chave privada SSH]"
echo "- POSTGRES_PASSWORD: $POSTGRES_PASSWORD"
