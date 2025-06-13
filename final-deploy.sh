#!/bin/bash

# Script para deploy final com domínio
# Execute no GitHub Codespace: ./final-deploy.sh

set -e

echo "🚀 Deploy Final: erp.grupogcr.com.br"
echo "=========================================="
echo ""

# Verificar se estamos no repositório
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Execute na raiz do repositório odoo-production!"
    exit 1
fi

# Verificar addons
if [ ! -d "addons" ] || [ -z "$(ls -A addons)" ]; then
    echo "❌ Addons não encontrados!"
    exit 1
fi

# Contar addons
addon_count=$(ls -1 addons/ | grep -v -E "(\.gitkeep|ADDONS_INFO\.md)" | wc -l)

echo "📊 Status atual:"
echo "   📦 $addon_count addons configurados"
echo "   📱 WhatsApp widget incluído"
echo "   🌐 Domínio: erp.grupogcr.com.br"
echo ""

# Verificar arquivos essenciais
echo "📋 Verificando arquivos..."
files_ok=true
for file in "addons/web_responsive" "addons/whatsapp_widget" "setup-domain.sh"; do
    if [ -e "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file FALTANDO!"
        files_ok=false
    fi
done

if [ "$files_ok" = false ]; then
    echo "❌ Alguns arquivos estão faltando!"
    exit 1
fi

echo ""
echo "🎯 O que será deployado:"
echo "   • Odoo 18.0 com $addon_count addons"
echo "   • Configuração SSL para erp.grupogcr.com.br"
echo "   • WhatsApp widget responsivo"
echo "   • Backup automático configurado"
echo "   • Nginx proxy reverso"
echo ""

read -p "Fazer commit e deploy agora? (y/n): " do_deploy

if [ "$do_deploy" = "y" ] || [ "$do_deploy" = "Y" ]; then
    echo ""
    echo "📤 Fazendo commit..."
    
    # Adicionar arquivos novos ao git
    git add setup-domain.sh final-deploy.sh
    
    # Commit com mensagem descritiva
    git commit -m "🚀 Deploy final: Configuração domínio erp.grupogcr.com.br

🌐 Configurações adicionadas:
- Nginx proxy reverso
- SSL/TLS com Let's Encrypt
- Configuração Cloudflare ready
- Script setup-domain.sh

📦 Addons já configurados:
- $addon_count addons instalados
- WhatsApp widget customizado
- Interface web responsiva

🔧 Deploy para: Hetzner CX22 + Cloudflare"
    
    echo "✅ Commit realizado!"
    
    # Push para main
    echo "📡 Fazendo push para GitHub..."
    git push origin main
    
    echo ""
    echo "🎉 Deploy iniciado!"
    echo ""
    echo "📊 Acompanhe o deploy:"
    echo "   🔗 https://github.com/fbarbalho/odoo-production/actions"
    echo ""
    echo "🔧 Próximos passos:"
    echo ""
    echo "1️⃣ Configurar DNS Cloudflare:"
    echo "   • erp.grupogcr.com.br → IP_DA_VPS"
    echo "   • Proxy: DESABILITADO (nuvem cinza) durante setup"
    echo ""
    echo "2️⃣ Aguardar deploy GitHub Actions concluir"
    echo ""
    echo "3️⃣ Configurar domínio na VPS:"
    echo "   ssh root@IP_VPS"
    echo "   cd /opt/odoo"
    echo "   ./setup-domain.sh"
    echo ""
    echo "4️⃣ Habilitar Cloudflare proxy:"
    echo "   • Nuvem cinza → laranja após SSL configurado"
    echo ""
    echo "✅ Acesso final: https://erp.grupogcr.com.br"
    
else
    echo ""
    echo "⏸️ Deploy cancelado."
    echo ""
    echo "Para fazer deploy depois:"
    echo "   ./final-deploy.sh"
fi

echo ""
echo "✅ Script concluído!"