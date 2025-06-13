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
