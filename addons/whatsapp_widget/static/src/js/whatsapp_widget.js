function openWhatsApp() {
    // ===== CONFIGURE SEU NÚMERO AQUI =====
    // Formato: código país + DDD + número (sem espaços, hífens ou parênteses)
    // Exemplo Brasil: 5511999999999 (55 = Brasil, 11 = São Paulo, 999999999 = número)
    var phone = "5531984466426"; // ⚠️ ALTERE PARA SEU NÚMERO
    
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
