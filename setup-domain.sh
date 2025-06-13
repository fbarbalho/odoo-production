#!/bin/bash

# Script corrigido para configurar domínio erp.grupogcr.com.br
# Execute na VPS: ./setup-domain-fixed.sh

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

# Parar containers nginx existentes se houver
docker stop nginx 2>/dev/null || true
docker rm nginx 2>/dev/null || true

# Instalar Nginx e Certbot
echo "📦 Instalando Nginx e Certbot..."
apt update
apt install -y nginx certbot python3-certbot-nginx

# Parar Apache se existir
systemctl stop apache2 2>/dev/null || true
systemctl disable apache2 2>/dev/null || true

# Parar nginx para configuração limpa
systemctl stop nginx

# PASSO 1: Configurar Nginx SEM SSL primeiro (só HTTP)
echo "⚙️ Configurando Nginx para $DOMAIN (HTTP primeiro)..."
cat > /etc/nginx/sites-available/$DOMAIN << 'NGINX_HTTP'
upstream odoo {
    server 127.0.0.1:8069;
}

upstream odoochat {
    server 127.0.0.1:8072;
}

server {
    listen 80;
    server_name erp.grupogcr.com.br;
    
    # Allow Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Proxy to Odoo for now (antes do SSL)
    location / {
        proxy_pass http://odoo;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_redirect off;
        
        # Configurações para uploads
        client_max_body_size 200M;
        proxy_read_timeout 720s;
        proxy_connect_timeout 720s;
        proxy_send_timeout 720s;
    }
    
    # Longpolling
    location /longpolling {
        proxy_pass http://odoochat;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINX_HTTP

# Remover configuração padrão e habilitar nosso site
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Testar configuração nginx
echo "🔧 Testando configuração Nginx..."
nginx -t

# Iniciar nginx
systemctl start nginx
systemctl enable nginx

echo "✅ Nginx configurado e rodando (HTTP)!"

# Verificar se DNS está apontando
echo ""
echo "🔍 Verificando DNS..."
CURRENT_IP=$(curl -s ifconfig.me)
echo "IP deste servidor: $CURRENT_IP"

# Testar resolução DNS
DNS_IP=$(dig +short $DOMAIN | tail -1)
if [ "$DNS_IP" = "$CURRENT_IP" ]; then
    echo "✅ DNS configurado corretamente!"
    DNS_OK=true
else
    echo "⚠️ DNS não aponta para este servidor:"
    echo "   DNS resolve para: $DNS_IP"
    echo "   Este servidor: $CURRENT_IP"
    DNS_OK=false
fi

# Testar HTTP
echo ""
echo "🌐 Testando HTTP..."
if curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN | grep -q "200\|302\|303"; then
    echo "✅ HTTP funcionando!"
    HTTP_OK=true
else
    echo "❌ HTTP não está funcionando"
    HTTP_OK=false
fi

# PASSO 2: Configurar SSL
echo ""
echo "🔒 Configurando SSL com Let's Encrypt..."

if [ "$DNS_OK" = true ] && [ "$HTTP_OK" = true ]; then
    echo "📜 Obtendo certificado SSL..."
    
    # Obter certificado SSL
    if certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL --redirect; then
        echo "✅ SSL configurado com sucesso!"
        
        # Configurar renovação automática
        echo "🔄 Configurando renovação automática..."
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        
        SSL_OK=true
    else
        echo "❌ Erro ao configurar SSL"
        SSL_OK=false
    fi
else
    echo "⚠️ Pulando configuração SSL devido a problemas anteriores"
    SSL_OK=false
fi

# PASSO 3: Atualizar configuração Odoo para proxy
echo ""
echo "🔧 Atualizando configuração Odoo..."

# Verificar se configurações já existem
if ! grep -q "proxy_mode" /opt/odoo/config/odoo.conf; then
    echo "" >> /opt/odoo/config/odoo.conf
    echo "# Configurações para proxy reverso" >> /opt/odoo/config/odoo.conf
    echo "proxy_mode = True" >> /opt/odoo/config/odoo.conf
    echo "trusted_proxy_header = X-Forwarded-For" >> /opt/odoo/config/odoo.conf
    echo "✅ Configurações proxy adicionadas ao Odoo"
else
    echo "✅ Configurações proxy já existem no Odoo"
fi

# Reiniciar Odoo
echo "🔄 Reiniciando Odoo..."
cd /opt/odoo
docker-compose restart web

# Aguardar Odoo inicializar
echo "⏳ Aguardando Odoo inicializar..."
sleep 30

# PASSO 4: Verificações finais
echo ""
echo "🔍 Verificações finais..."

# Verificar se containers estão rodando
if docker-compose ps | grep -q "Up.*web"; then
    echo "✅ Odoo está rodando"
else
    echo "❌ Odoo não está rodando - verificar logs:"
    docker-compose logs web | tail -10
fi

# Verificar nginx
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx está rodando"
else
    echo "❌ Nginx não está rodando"
fi

echo ""
echo "================================="
echo "🎉 Configuração concluída!"
echo "================================="
echo ""

if [ "$SSL_OK" = true ]; then
    echo "🌐 Acesso:"
    echo "   HTTP:  http://$DOMAIN (redireciona para HTTPS)"
    echo "   HTTPS: https://$DOMAIN"
    echo ""
    echo "☁️ Cloudflare:"
    echo "   Agora você pode habilitar o proxy (nuvem laranja)"
else
    echo "🌐 Acesso:"
    echo "   HTTP:  http://$DOMAIN"
    echo ""
    echo "⚠️ SSL não configurado - verifique:"
    echo "   1. DNS: $DOMAIN → $CURRENT_IP"
    echo "   2. Firewall: portas 80 e 443 abertas"
    echo "   3. Execute novamente: ./setup-domain-fixed.sh"
fi

echo ""
echo "📊 Status:"
echo "   Nginx: $(systemctl is-active nginx)"
echo "   Odoo:  $(docker-compose ps | grep web | awk '{print $4}' || echo 'Verificar')"
echo ""
echo "🔧 Comandos úteis:"
echo "   Ver logs Nginx: tail -f /var/log/nginx/error.log"
echo "   Ver logs Odoo:  docker-compose logs -f web"
echo "   Testar SSL:     curl -I https://$DOMAIN"
echo "   Status geral:   ./monitor-resources.sh"