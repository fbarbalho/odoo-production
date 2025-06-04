#!/bin/bash

# Script para instalar addons essenciais solicitados
# Web Responsivo, Backup DB, Limpeza, WhatsApp, Landing Page, Marketing
# Execute: ./install-essential-addons.sh

set -e

ADDONS_DIR="/opt/odoo/addons"
TEMP_DIR="/tmp/odoo-addons-install"

echo "🚀 Instalando Addons Essenciais para Odoo 18.0"
echo "=============================================="
echo "📦 Addons a instalar:"
echo "   ✅ Web Responsivo (Interface mobile)"
echo "   ✅ Database Auto Backup"
echo "   ✅ Database Cleanup Tools" 
echo "   ✅ WhatsApp Integration"
echo "   ✅ Website Builder (Landing Pages)"
echo "   ✅ Marketing Automation"
echo "   ✅ Email Marketing"
echo ""

# Criar diretórios
mkdir -p "$ADDONS_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Função para clonar e copiar addon específico
install_specific_addon() {
    local repo_url=$1
    local branch=$2
    local addon_name=$3
    local display_name=$4
    
    echo "📥 Instalando: $display_name"
    
    repo_name=$(basename "$repo_url" .git)
    
    if [ -d "$repo_name" ]; then
        rm -rf "$repo_name"
    fi
    
    git clone --branch "$branch" --depth 1 "$repo_url" "$repo_name" 2>/dev/null || {
        echo "⚠️ Erro ao clonar $repo_url - tentando branch main..."
        git clone --depth 1 "$repo_url" "$repo_name" || {
            echo "❌ Falha ao clonar $display_name"
            return 1
        }
    }
    
    if [ -d "$repo_name/$addon_name" ]; then
        cp -r "$repo_name/$addon_name" "$ADDONS_DIR/"
        echo "   ✅ $display_name instalado!"
    else
        echo "   ⚠️ Addon $addon_name não encontrado em $repo_name"
        # Listar diretórios disponíveis para debug
        echo "   📁 Addons disponíveis:"
        ls -1 "$repo_name" | grep -E "(web_|website_|marketing_|whatsapp|backup|clean)" | head -5 || echo "   Nenhum addon relevante encontrado"
        return 1
    fi
}

# Função para instalar todos os addons de um repositório
install_all_addons() {
    local repo_url=$1
    local branch=$2
    local display_name=$3
    local filter_pattern=${4:-".*"}
    
    echo "📥 Instalando: $display_name"
    
    repo_name=$(basename "$repo_url" .git)
    
    if [ -d "$repo_name" ]; then
        rm -rf "$repo_name"
    fi
    
    git clone --branch "$branch" --depth 1 "$repo_url" "$repo_name" 2>/dev/null || {
        echo "⚠️ Erro ao clonar $repo_url - tentando branch main..."
        git clone --depth 1 "$repo_url" "$repo_name" || {
            echo "❌ Falha ao clonar $display_name"
            return 1
        }
    }
    
    found_addons=0
    for dir in "$repo_name"*/; do
        if [ -f "${dir}__manifest__.py" ] && [[ $(basename "$dir") =~ $filter_pattern ]]; then
            addon_dir_name=$(basename "$dir")
            cp -r "$dir" "$ADDONS_DIR/"
            echo "   ✅ $addon_dir_name instalado!"
            found_addons=$((found_addons + 1))
        fi
    done
    
    if [ $found_addons -eq 0 ]; then
        echo "   ⚠️ Nenhum addon encontrado com filtro: $filter_pattern"
    fi
}

echo "🔄 Iniciando instalação dos addons..."
echo ""

# 1. WEB RESPONSIVO (OCA)
echo "1️⃣ Instalando Web Responsivo..."
install_specific_addon "https://github.com/OCA/web.git" "18.0" "web_responsive" "Web Responsivo"

# 2. DATABASE AUTO BACKUP (OCA)
echo ""
echo "2️⃣ Instalando Database Auto Backup..."
install_specific_addon "https://github.com/OCA/server-tools.git" "18.0" "auto_backup" "Database Auto Backup"

# 3. DATABASE CLEANUP (OCA) 
echo ""
echo "3️⃣ Instalando Database Cleanup..."
install_specific_addon "https://github.com/OCA/server-tools.git" "18.0" "database_cleanup" "Database Cleanup"

# 4. WHATSAPP INTEGRATION (Cybrosys)
echo ""
echo "4️⃣ Instalando WhatsApp Integration..."
# Tentar várias fontes de addons WhatsApp
install_specific_addon "https://github.com/CybroOdoo/CybroAddons.git" "18.0" "whatsapp_mail_messaging" "WhatsApp Messaging" || \
install_specific_addon "https://github.com/itpp-labs/misc-addons.git" "18.0" "web_widget_url_advanced" "WhatsApp Alternative" || \
echo "   ⚠️ WhatsApp addon não encontrado - será necessário instalar manualmente"

# 5. WEBSITE BUILDER (Core Odoo - já incluído, mas vamos ativar módulos extras)
echo ""
echo "5️⃣ Instalando Website Builder Extensions..."
install_specific_addon "https://github.com/OCA/website.git" "18.0" "website_snippet_anchor" "Website Snippets" || \
echo "   ℹ️ Website Builder já incluído no Odoo core"

# 6. MARKETING AUTOMATION (OCA)
echo ""
echo "6️⃣ Instalando Marketing Tools..."
install_specific_addon "https://github.com/OCA/social.git" "18.0" "mail_tracking" "Email Tracking" || \
install_specific_addon "https://github.com/OCA/server-tools.git" "18.0" "mass_mailing_custom_unsubscribe" "Marketing Tools"

# 7. ADDONS EXTRAS ÚTEIS
echo ""
echo "7️⃣ Instalando Addons Extras..."

# Web Timeline
install_specific_addon "https://github.com/OCA/web.git" "18.0" "web_timeline" "Web Timeline"

# Advanced Search
install_specific_addon "https://github.com/OCA/web.git" "18.0" "web_advanced_search" "Advanced Search"

# Cleanup temp
cd /opt/odoo
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Instalação concluída!"
echo ""
echo "📦 Addons instalados em $ADDONS_DIR:"
ls -1 "$ADDONS_DIR" | grep -v ".gitkeep" | sort

echo ""
echo "🔄 Reiniciando Odoo para aplicar mudanças..."
docker-compose restart web

echo ""
echo "⏳ Aguardando Odoo inicializar (60 segundos)..."
sleep 60

echo ""
echo "✅ Processo concluído!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Acesse: http://$(curl -s ifconfig.me 2>/dev/null || echo 'SEU_IP'):8069"
echo "   2. Vá em: Apps → Update Apps List"
echo "   3. Procure e instale os addons:"
echo "      • Web Responsive (interface mobile)"
echo "      • Database Auto Backup (backup automático)"
echo "      • Database Cleanup (limpeza)"
echo "      • Website Builder (landing pages)" 
echo "      • Mass Mailing (email marketing)"
echo ""
echo "🔧 Para WhatsApp:"
echo "   • Procure 'WhatsApp' nas Apps"
echo "   • Ou instale manualmente de: apps.odoo.com"
echo ""
echo "📊 Ver logs: docker-compose logs -f web"
echo "🗄️ Backup: ./backup.sh"