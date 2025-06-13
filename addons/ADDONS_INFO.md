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

## Interface Web Responsiva
- **Addon:** web_responsive
- **Fonte:** https://github.com/OCA/web.git (branch: 18.0)
- **Repositório:** OCA Web Extensions

## Visualização Timeline
- **Addon:** web_timeline
- **Fonte:** https://github.com/OCA/web.git (branch: 18.0)
- **Repositório:** OCA Web Extensions

## Backup Automático Database
- **Addon:** auto_backup
- **Fonte:** https://github.com/OCA/server-tools.git (branch: 18.0)
- **Repositório:** OCA Server Tools

## Limpeza Database
- **Addon:** database_cleanup
- **Fonte:** https://github.com/OCA/server-tools.git (branch: 18.0)
- **Repositório:** OCA Server Tools

## Usuário Técnico Base
- **Addon:** base_technical_user
- **Fonte:** https://github.com/OCA/server-tools.git (branch: 18.0)
- **Repositório:** OCA Server Tools

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

