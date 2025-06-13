#!/bin/bash

# Script para configurar domínio erp.gcrconstrutora.com.br com SSL
# Execute na VPS: ./setup-domain.sh

set -e

DOMAIN="erp.grupogcr.com.br"
EMAIL="contato@grupogcr.com.br"

echo "🌐 Configurando domínio: $DOMAIN"
echo "==============================================="

# Verificar se estamos na VPS
if [ ! -f "/opt/odoo/docker-compose.yml" ]; then
    echo "❌ Este script deve ser executado na VPS com Odoo!"
    exit 1
fi

# Instalar Nginx e Certbot
echo "📦 Instalando Nginx e Certbot..."
apt update
apt install -y nginx certbot python3-certbot-nginx

# Parar Apache se existir
systemctl stop apache2 2>/dev/null || true
systemctl disable apache2 2>/dev/null || true

# Configurar Nginx
echo "⚙️ Configurando Nginx para $DOMAIN..."
cat > /etc/nginx/sites-available/$DOMAIN << 'NGINX_CONF'
upstream odoo {
    server 127.0.0.1:8069;
}

upstream odoochat {
    server 127.0.0.1:8072;
}

server {
    listen 80;
    server_name erp.grupogcr.com.br;
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name erp.grupogcr.com.br;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    client_max_body_size 200M;

    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;

    location /longpolling {
        proxy_pass http://odoochat;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_http_version 1.1;
    }

    location / {
        proxy_pass http://odoo;
        proxy_set_header Host $host;
        proxy_redirect off;
    }
}
NGINX_CONF

ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl restart nginx
systemctl enable nginx

echo "✅ Nginx configurado!"

# SSL
echo "🔒 Configurando SSL..."
echo "IP deste servidor: $(curl -s ifconfig.me)"
echo "Configure o DNS antes de continuar!"
read -p "DNS configurado? (y/n): " dns_ready

if [ "$dns_ready" = "y" ]; then
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
fi

# Atualizar Odoo config
echo "proxy_mode = True" >> /opt/odoo/config/odoo.conf
echo "trusted_proxy_header = X-Forwarded-For" >> /opt/odoo/config/odoo.conf

docker-compose restart web

echo "✅ Domínio configurado: https://$DOMAIN"