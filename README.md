# Odoo 18.0 Production - Hetzner Deploy

Deploy automatizado do Odoo 18.0 na Hetzner Cloud com GitHub Actions.

## 🚀 Instalação Rápida

### 1. Criar VPS Hetzner CX22
- 2 vCPUs, 4GB RAM, 40GB SSD
- Ubuntu 22.04
- Firewall: 22, 80, 443, 8069

### 2. Instalar na VPS
```bash
curl -sSL https://raw.githubusercontent.com/fbarbalho/odoo-production/main/install.sh | bash
cd /opt/odoo
./optimize-hetzner.sh
docker-compose up -d
```

### 3. Configurar GitHub Actions
Secrets necessários:
- `HOST`: IP da VPS
- `USERNAME`: root
- `SSH_KEY`: Chave privada SSH

## 🌐 Acesso
- Odoo: http://SEU_IP:8069
- Primeiro acesso: Criar database e admin

## 📊 Comandos
```bash
# Status
docker-compose ps
./monitor-resources.sh

# Logs
docker-compose logs -f

# Backup
./backup.sh

# Restart
docker-compose restart web
```

## 🔄 Deploy Automático
Push para `main` → GitHub Actions → Deploy automático

Custo: €3.98/mês (Hetzner CX22)
