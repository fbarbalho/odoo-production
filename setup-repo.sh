#!/bin/bash

# Script para criar estrutura completa do repositório Odoo
# Execute no GitHub Codespace: bash setup-repo.sh

set -e

echo "🚀 Criando estrutura completa do repositório Odoo..."

# Criar estrutura de diretórios
echo "📁 Criando diretórios..."
mkdir -p .github/workflows
mkdir -p config
mkdir -p addons
mkdir -p scripts

# Criar .gitignore
echo "📝 Criando .gitignore..."
cat > .gitignore << 'GITIGNORE_EOF'
# Arquivos sensíveis
.env
*.env

# Dados e logs
backups/
logs/
*.log

# Cache Python
__pycache__/
*.pyc
*.pyo
.cache/

# OS específicos
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Temporary files
*.tmp
*.temp
GITIGNORE_EOF

# Criar .env.example
echo "🔧 Criando .env.example..."
cat > .env.example << 'ENV_EOF'
# PostgreSQL password - ALTERE PARA UMA SENHA SEGURA
POSTGRES_PASSWORD=mude_esta_senha_por_favor
ENV_EOF

# Criar docker-compose.yml
echo "🐳 Criando docker-compose.yml..."
cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.1'

services:

  web:
    image: odoo:18.0
    container_name: odoo_web
    restart: unless-stopped
    depends_on:
      - db
    ports:
      - "8069:8069"
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - odoo-web-data:/var/lib/odoo
      - ./config:/etc/odoo
      - ./addons:/mnt/extra-addons
    command: --
    networks:
      - odoo_network

  db:
    image: postgres:15
    container_name: odoo_postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_USER=odoo
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - odoo-db-data:/var/lib/postgresql/data/pgdata
    networks:
      - odoo_network

volumes:
  odoo-web-data:
  odoo-db-data:

networks:
  odoo_network:
    driver: bridge
COMPOSE_EOF

# Criar configuração Odoo
echo "⚙️ Criando config/odoo.conf..."
cat > config/odoo.conf << 'ODOO_CONF_EOF'
[options]
# Diretórios
addons_path = /mnt/extra-addons
data_dir = /var/lib/odoo

# Banco de dados
; admin_passwd = admin_password_aqui
db_maxconn = 64
db_name = False
db_template = template1
dbfilter = .*

# Performance otimizada para Hetzner CX22 (2 vCPUs, 4GB RAM)
limit_memory_hard = 2147483648
limit_memory_soft = 1610612736
limit_request = 8192
limit_time_cpu = 60
limit_time_real = 120
max_cron_threads = 2
workers = 2

# Logs
log_handler = [':INFO']
log_level = info
logfile = None

# Web
xmlrpc = True
xmlrpc_interface = 
xmlrpc_port = 8069
longpolling_port = 8072

# Email
email_from = False
smtp_password = False
smtp_port = 25
smtp_server = localhost
smtp_ssl = False
smtp_user = False

# Outras configurações
csv_internal_sep = ,
debug_mode = False
list_db = True
log_db = False
osv_memory_age_limit = 1.0
osv_memory_count_limit = False
xmlrpcs = True
xmlrpcs_interface = 
xmlrpcs_port = 8071
ODOO_CONF_EOF

# Criar GitHub Actions workflow
echo "⚡ Criando .github/workflows/deploy.yml..."
cat > .github/workflows/deploy.yml << 'WORKFLOW_EOF'
name: Deploy Odoo to Hetzner

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Deploy to Hetzner VPS
      uses: appleboy/ssh-action@v1.0.0
      with:
        host: ${{ secrets.HOST }}
        username: ${{ secrets.USERNAME }}
        key: ${{ secrets.SSH_KEY }}
        port: 22
        script: |
          cd /opt/odoo
          
          # Backup antes do deploy
          echo "🗄️ Fazendo backup..."
          if [ -f "./backup.sh" ]; then
            ./backup.sh
          fi
          
          # Verificar se é primeira execução
          if [ ! -d ".git" ]; then
            echo "📥 Primeira execução - inicializando Git..."
            git init
            git remote add origin https://github.com/fbarbalho/odoo-production.git
          fi
          
          # Atualizar código
          echo "📥 Atualizando código..."
          git fetch origin main
          git reset --hard origin/main
          
          # Verificar se .env existe
          if [ ! -f ".env" ]; then
            echo "⚠️ Arquivo .env não encontrado! Copiando exemplo..."
            cp .env.example .env
            echo "🔧 ATENÇÃO: Edite o arquivo .env com sua senha!"
          fi
          
          # Tornar scripts executáveis
          chmod +x *.sh
          
          # Verificar se precisa rebuild
          if git diff HEAD~1 HEAD --name-only 2>/dev/null | grep -q -E "(docker-compose\.yml|Dockerfile)"; then
            echo "🔧 Rebuild necessário..."
            docker-compose down
            docker-compose up -d --build
          else
            echo "🔄 Restart simples..."
            docker-compose up -d
          fi
          
          # Aguardar containers
          echo "⏳ Aguardando containers inicializarem..."
          sleep 45
          
          # Verificar se está funcionando
          if docker-compose ps | grep -q "Up"; then
            echo "✅ Deploy concluído com sucesso!"
            echo "🌐 Odoo disponível em: http://$(curl -s ifconfig.me):8069"
          else
            echo "❌ Erro no deploy - verificando logs..."
            docker-compose logs --tail=20
            exit 1
          fi
WORKFLOW_EOF

# Criar script de instalação
echo "🛠️ Criando install.sh..."
cat > install.sh << 'INSTALL_EOF'
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
INSTALL_EOF

# Criar script de backup
echo "💾 Criando backup.sh..."
cat > backup.sh << 'BACKUP_EOF'
#!/bin/bash

set -e

BACKUP_DIR="/opt/odoo/backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "🗄️ Iniciando backup do Odoo..."

# Verificar containers
if ! docker ps | grep -q "odoo_postgres"; then
    echo "❌ PostgreSQL não está rodando!"
    exit 1
fi

mkdir -p $BACKUP_DIR

# Backup banco
echo "📊 Backup do banco..."
docker exec odoo_postgres pg_dump -U odoo postgres > $BACKUP_DIR/db_backup_$DATE.sql

# Backup arquivos
echo "📁 Backup dos arquivos..."
docker run --rm -v odoo_odoo-web-data:/source -v $BACKUP_DIR:/backup alpine tar czf /backup/filestore_backup_$DATE.tar.gz -C /source .

# Backup configurações
echo "⚙️ Backup das configurações..."
tar czf $BACKUP_DIR/config_backup_$DATE.tar.gz config/ addons/ 2>/dev/null || true

# Limpar backups antigos
find $BACKUP_DIR -name "*backup*.sql" -mtime +7 -delete 2>/dev/null || true
find $BACKUP_DIR -name "*backup*.tar.gz" -mtime +7 -delete 2>/dev/null || true

echo "✅ Backup concluído em: $BACKUP_DIR"
ls -lh $BACKUP_DIR/*$DATE* 2>/dev/null || true
BACKUP_EOF

# Criar script de otimização
echo "⚡ Criando optimize-hetzner.sh..."
cat > optimize-hetzner.sh << 'OPTIMIZE_EOF'
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
OPTIMIZE_EOF

# Criar script de monitoramento
echo "📊 Criando monitor-resources.sh..."
cat > monitor-resources.sh << 'MONITOR_EOF'
#!/bin/bash

echo "📊 Status CX22 - $(date)"
echo "========================"

echo "🔥 CPU:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' || echo "N/A"

echo "💾 Memory:"
free -h | grep Mem

echo "💿 Disk:"
df -h / | tail -1

echo "🐳 Containers:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "N/A"

echo "========================"
MONITOR_EOF

# Criar README
echo "📚 Criando README.md..."
cat > README.md << 'README_EOF'
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
README_EOF

# Criar arquivo para addons
touch addons/.gitkeep

# Tornar scripts executáveis
chmod +x *.sh

echo ""
echo "✅ Estrutura criada com sucesso!"
echo ""
echo "📁 Arquivos:"
echo "   ├── .github/workflows/deploy.yml"
echo "   ├── config/odoo.conf"
echo "   ├── docker-compose.yml"
echo "   ├── install.sh"
echo "   ├── backup.sh"
echo "   ├── optimize-hetzner.sh"
echo "   ├── monitor-resources.sh"
echo "   └── README.md"
echo ""
echo "🚀 Próximos passos:"
echo "   git add ."
echo "   git commit -m 'Estrutura inicial Odoo 18.0'"
echo "   git push origin main"
echo ""
echo "🌐 Install URL:"
echo "   https://raw.githubusercontent.com/fbarbalho/odoo-production/main/install.sh"