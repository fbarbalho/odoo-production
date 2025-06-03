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
