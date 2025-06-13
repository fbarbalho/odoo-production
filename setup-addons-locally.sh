#!/bin/bash

# Script corrigido para baixar addons localmente
# Execute no GitHub Codespace: ./setup-addons-fixed.sh

set -e

echo "📦 Setup Local de Addons para Odoo 18.0 (CORRIGIDO)"
echo "=================================================="
echo ""

# Verificar se estamos no repositório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Execute este script na raiz do repositório odoo-production!"
    exit 1
fi

# Limpar e preparar diretórios
TEMP_DIR="temp_addons"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
mkdir -p "addons"

echo "📁 Preparando diretório addons..."

# Função para clonar repositório uma vez e copiar múltiplos addons
download_repo_addons() {
    local repo_url=$1
    local branch=$2
    local repo_display_name=$3
    shift 3
    local addons_list=("$@")
    
    echo ""
    echo "📥 Baixando repositório: $repo_display_name"
    echo "   URL: $repo_url"
    echo "   Branch: $branch"
    
    repo_name=$(basename "$repo_url" .git)
    local temp_repo_dir="$TEMP_DIR/$repo_name"
    
    # Clonar repositório
    if git clone --branch "$branch" --depth 1 "$repo_url" "$temp_repo_dir" 2>/dev/null; then
        echo "   ✅ Repositório clonado com sucesso!"
        
        # Copiar cada addon solicitado
        for addon_info in "${addons_list[@]}"; do
            # Formato: "addon_name:display_name"
            IFS=':' read -r addon_name display_name <<< "$addon_info"
            
            if [ -d "$temp_repo_dir/$addon_name" ]; then
                cp -r "$temp_repo_dir/$addon_name" "addons/"
                echo "   ✅ $addon_name ($display_name) copiado!"
                
                # Adicionar info ao arquivo
                echo "## $display_name" >> "addons/ADDONS_INFO.md"
                echo "- **Addon:** $addon_name" >> "addons/ADDONS_INFO.md"
                echo "- **Fonte:** $repo_url (branch: $branch)" >> "addons/ADDONS_INFO.md"
                echo "- **Repositório:** $repo_display_name" >> "addons/ADDONS_INFO.md"
                echo "" >> "addons/ADDONS_INFO.md"
            else
                echo "   ❌ Addon $addon_name não encontrado"
                echo "   📁 Addons disponíveis:"
                ls -1 "$temp_repo_dir" | grep -E "^[a-z]" | head -5 || echo "   Nenhum addon encontrado"
            fi
        done
    else
        echo "   ❌ Erro ao clonar $repo_url"
        echo "   ⚠️ Tentando com branch main..."
        
        if git clone --depth 1 "$repo_url" "$temp_repo_dir" 2>/dev/null; then
            echo "   ✅ Clonado com branch main!"
            # Repetir cópia dos addons
            for addon_info in "${addons_list[@]}"; do
                IFS=':' read -r addon_name display_name <<< "$addon_info"
                if [ -d "$temp_repo_dir/$addon_name" ]; then
                    cp -r "$temp_repo_dir/$addon_name" "addons/"
                    echo "   ✅ $addon_name ($display_name) copiado!"
                fi
            done
        else
            echo "   ❌ Falha total ao clonar repositório"
        fi
    fi
}

# Inicializar arquivo de informações
cat > "addons/ADDONS_INFO.md" << 'EOF'
# 📦 Addons Instalados no Odoo

Este diretório contém os addons externos instalados.

## 🔄 Como Atualizar

```bash
./setup-addons-fixed.sh
git add addons/
git commit -m "Atualizar addons"
git push origin main
```

## 📋 Addons Instalados:

EOF

echo "🔄 Baixando addons essenciais..."

# 1. REPOSITÓRIO OCA/WEB (múltiplos addons web)
download_repo_addons \
    "https://github.com/OCA/web.git" \
    "18.0" \
    "OCA Web Extensions" \
    "web_responsive:Interface Web Responsiva" \
    "web_timeline:Visualização Timeline" \
    "web_advanced_search:Busca Avançada"

# 2. REPOSITÓRIO OCA/SERVER-TOOLS (ferramentas servidor)
download_repo_addons \
    "https://github.com/OCA/server-tools.git" \
    "18.0" \
    "OCA Server Tools" \
    "auto_backup:Backup Automático Database" \
    "database_cleanup:Limpeza Database" \
    "base_technical_user:Usuário Técnico Base"

# 3. REPOSITÓRIO OCA/SOCIAL (marketing e comunicação)
download_repo_addons \
    "https://github.com/OCA/social.git" \
    "18.0" \
    "OCA Social & Marketing" \
    "mail_tracking:Rastreamento de Email"

# 4. REPOSITÓRIO OCA/WEBSITE (website e landing pages)
download_repo_addons \
    "https://github.com/OCA/website.git" \
    "18.0" \
    "OCA Website Extensions" \
    "website_snippet_anchor:Website Snippets Anchor"

echo ""
echo "📱 Criando addon customizado WhatsApp Widget..."

# Criar addon WhatsApp customizado
mkdir -p "addons/whatsapp_widget"

cat > "addons/whatsapp_widget/__manifest__.py" << 'EOF'
{
    'name': 'WhatsApp Widget',
    'version': '18.0.1.0.0',
    'summary': 'Botão flutuante WhatsApp no website',
    'description': '''
        Adiciona um botão flutuante do WhatsApp no website
        que permite aos visitantes iniciar uma conversa diretamente.
        
        Funcionalidades:
        - Botão flutuante responsivo
        - Mensagem pré-configurada
        - Fácil customização do número
        - Design moderno com hover effects
    ''',
    'author': 'Sua Empresa',
    'website': 'https://seusite.com',
    'category': 'Website',
    'depends': ['website'],
    'data': [
        'views/website_templates.xml',
    ],
    'assets': {
        'web.assets_frontend': [
            'whatsapp_widget/static/src/css/whatsapp_widget.css',
            'whatsapp_widget/static/src/js/whatsapp_widget.js',
        ],
    },
    'installable': True,
    'auto_install': False,
    'application': False,
    'license': 'LGPL-3',
}
EOF

cat > "addons/whatsapp_widget/__init__.py" << 'EOF'
# WhatsApp Widget Module
EOF

mkdir -p "addons/whatsapp_widget/views"
cat > "addons/whatsapp_widget/views/website_templates.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <template id="whatsapp_widget" name="WhatsApp Widget" inherit_id="website.layout">
        <xpath expr="//body" position="inside">
            <div class="whatsapp-float" onclick="openWhatsApp()">
                <i class="fa fa-whatsapp"></i>
            </div>
        </xpath>
    </template>
</odoo>
EOF

mkdir -p "addons/whatsapp_widget/static/src/css"
cat > "addons/whatsapp_widget/static/src/css/whatsapp_widget.css" << 'EOF'
.whatsapp-float {
    position: fixed;
    width: 60px;
    height: 60px;
    bottom: 40px;
    right: 40px;
    background-color: #25d366;
    color: #FFF;
    border-radius: 50px;
    text-align: center;
    font-size: 30px;
    line-height: 60px;
    box-shadow: 2px 2px 3px #999;
    z-index: 1000;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
}

.whatsapp-float:hover {
    background-color: #128c7e;
    transform: scale(1.1);
    box-shadow: 4px 4px 8px #666;
}

.whatsapp-float i {
    font-size: 28px;
}

@media (max-width: 768px) {
    .whatsapp-float {
        width: 50px;
        height: 50px;
        font-size: 24px;
        bottom: 20px;
        right: 20px;
    }
    
    .whatsapp-float i {
        font-size: 22px;
    }
}

/* Animação de pulso */
@keyframes pulse {
    0% {
        transform: scale(1);
    }
    50% {
        transform: scale(1.05);
    }
    100% {
        transform: scale(1);
    }
}

.whatsapp-float {
    animation: pulse 2s infinite;
}

.whatsapp-float:hover {
    animation: none;
}
EOF

mkdir -p "addons/whatsapp_widget/static/src/js"
cat > "addons/whatsapp_widget/static/src/js/whatsapp_widget.js" << 'EOF'
function openWhatsApp() {
    // ===== CONFIGURE SEU NÚMERO AQUI =====
    // Formato: código país + DDD + número (sem espaços, hífens ou parênteses)
    // Exemplo Brasil: 5511999999999 (55 = Brasil, 11 = São Paulo, 999999999 = número)
    var phone = "5511999999999"; // ⚠️ ALTERE PARA SEU NÚMERO
    
    // Mensagem pré-configurada (pode personalizar)
    var message = "Olá! Vim através do seu site e gostaria de mais informações sobre seus produtos/serviços.";
    
    // Abrir WhatsApp
    var url = "https://wa.me/" + phone + "?text=" + encodeURIComponent(message);
    window.open(url, '_blank');
    
    // Analytics (opcional - descomente se usar Google Analytics)
    // gtag('event', 'click', {
    //     'event_category': 'WhatsApp',
    //     'event_label': 'Widget Click'
    // });
}

// Adicionar evento quando página carregar
document.addEventListener('DOMContentLoaded', function() {
    console.log('WhatsApp Widget carregado! Configure o número em whatsapp_widget.js');
});
EOF

echo "   ✅ WhatsApp Widget customizado criado!"

# Adicionar info do WhatsApp
cat >> "addons/ADDONS_INFO.md" << 'EOF'
## WhatsApp Widget (Customizado)
- **Addon:** whatsapp_widget
- **Fonte:** Addon customizado criado localmente
- **Funcionalidades:** 
  - Botão flutuante WhatsApp responsivo
  - Mensagem pré-configurada customizável
  - Design moderno com animações
  - Analytics tracking (opcional)

**⚠️ CONFIGURAÇÃO OBRIGATÓRIA:**
Edite o número do WhatsApp em: `addons/whatsapp_widget/static/src/js/whatsapp_widget.js`
Linha: `var phone = "5511999999999";` // Altere para seu número

EOF

# Limpar temp
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Download e configuração concluídos!"
echo ""
echo "📊 Resumo dos addons baixados:"
addon_count=$(ls -1 addons/ | grep -v ".gitkeep" | grep -v "ADDONS_INFO.md" | wc -l)
echo "   📦 Total: $addon_count addons"
echo ""
echo "📁 Addons instalados:"
ls -1 addons/ | grep -v ".gitkeep" | grep -v "ADDONS_INFO.md" | while read addon; do
    echo "   ✅ $addon"
done

echo ""
echo "🔧 IMPORTANTE - Configurar WhatsApp:"
echo "   📝 Edite: addons/whatsapp_widget/static/src/js/whatsapp_widget.js"
echo "   📞 Altere: var phone = \"5511999999999\"; // SEU NÚMERO AQUI"
echo ""
echo "📋 Próximos passos:"
echo "   1. Configurar número WhatsApp (obrigatório)"
echo "   2. git add addons/"
echo "   3. git commit -m \"Adicionar addons essenciais: web, backup, WhatsApp, marketing\""
echo "   4. git push origin main"
echo "   5. GitHub Actions fará deploy automático!"
echo ""
echo "📖 Ver detalhes completos:"
echo "   cat addons/ADDONS_INFO.md"