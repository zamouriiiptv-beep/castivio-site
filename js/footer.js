/* footer.js — Prime IPTV Unified Footer v15 */
(function () {
  'use strict';

  const footer = document.querySelector('footer');
  if (!footer) return;

  const lang = document.documentElement.lang || 'ar';

  /* ── Translations ── */
  const i18n = {
    ar: {
      links   : 'روابط مهمة',
      links2  : 'روابط إضافية',
      home    : 'الصفحة الرئيسية',
      pricing : 'خطط الأسعار',
      faq     : 'الأسئلة الشائعة',
      whyUs   : 'لماذا تختار IPTV؟',
      payment : 'طرق الدفع',
      reviews : 'آراء عملائنا',
      contactLink: 'تواصل معنا',
      contact : 'تواصل معنا',
      waText  : 'WhatsApp – دعم 24/7',
      waAria  : 'دعم واتساب 24 ساعة',
      privacy : 'سياسة الخصوصية', privacyHref: '/privacy-policy/',
      terms   : 'شروط الاستخدام',  termsHref : '/terms-of-service/',
      copy    : '© جميع حقوق الطبع والنشر محفوظة – Prime IPTV',
      base    : '/',
    },
    en: {
      links   : 'Important Links',
      links2  : 'Additional Links',
      home    : 'Home Page',
      pricing : 'Subscription Plans',
      faq     : 'FAQ',
      whyUs   : 'Why Choose IPTV?',
      payment : 'Payment Methods',
      reviews : 'Customer Reviews',
      contactLink: 'Contact Us',
      contact : 'Contact Us',
      waText  : 'WhatsApp – Support 24/7',
      waAria  : 'WhatsApp Support 24/7',
      privacy : 'Privacy Policy',     privacyHref: '/en/privacy-policy/',
      terms   : 'Terms of Service',   termsHref  : '/en/terms-of-service/',
      copy    : '© All Rights Reserved – Prime IPTV',
      base    : '/en/',
    },
    fr: {
      links   : 'Liens importants',
      links2  : 'Liens supplémentaires',
      home    : "Page d'accueil",
      pricing : "Plans d'abonnement",
      faq     : 'FAQ',
      whyUs   : 'Pourquoi choisir IPTV ?',
      payment : 'Moyens de paiement',
      reviews : 'Avis clients',
      contactLink: 'Contactez-nous',
      contact : 'Contactez-nous',
      waText  : 'WhatsApp – Support 24/7',
      waAria  : 'Support WhatsApp 24/7',
      privacy : 'Politique de confidentialité', privacyHref: '/fr/privacy-policy/',
      terms   : "Conditions d'utilisation",     termsHref  : '/fr/terms-of-service/',
      copy    : '© Tous droits réservés – Prime IPTV',
      base    : '/fr/',
    },
    es: {
      links   : 'Enlaces importantes',
      links2  : 'Enlaces adicionales',
      home    : 'Inicio',
      pricing : 'Planes de suscripción',
      faq     : 'Preguntas frecuentes',
      whyUs   : '¿Por qué elegir IPTV?',
      payment : 'Métodos de pago',
      reviews : 'Opiniones de clientes',
      contactLink: 'Contáctanos',
      contact : 'Contáctanos',
      waText  : 'WhatsApp – Soporte 24/7',
      waAria  : 'Soporte WhatsApp 24/7',
      privacy : 'Política de privacidad', privacyHref: '/es/privacy-policy/',
      terms   : 'Términos de servicio',   termsHref  : '/es/terms-of-service/',
      copy    : '© Todos los derechos reservados – Prime IPTV',
      base    : '/es/',
    },
    de: {
      links   : 'Wichtige Links',
      links2  : 'Weitere Links',
      home    : 'Startseite',
      pricing : 'Abonnement-Pakete',
      faq     : 'FAQ',
      whyUs   : 'Warum IPTV wählen?',
      payment : 'Zahlungsmethoden',
      reviews : 'Kundenbewertungen',
      contactLink: 'Kontakt',
      contact : 'Kontakt',
      waText  : 'WhatsApp – Support 24/7',
      waAria  : 'WhatsApp Support 24/7',
      privacy : 'Datenschutzerklärung', privacyHref: '/privacy-policy/',
      terms   : 'Nutzungsbedingungen',  termsHref  : '/terms-of-service/',
      copy    : '© Alle Rechte vorbehalten – Prime IPTV',
      base    : '/de/',
    },
    it: {
      links   : 'Link importanti',
      links2  : 'Link aggiuntivi',
      home    : 'Pagina principale',
      pricing : 'Piani di abbonamento',
      faq     : 'Domande frequenti',
      whyUs   : 'Perché scegliere IPTV?',
      payment : 'Metodi di pagamento',
      reviews : 'Recensioni clienti',
      contactLink: 'Contattaci',
      contact : 'Contattaci',
      waText  : 'WhatsApp – Supporto 24/7',
      waAria  : 'Supporto WhatsApp 24/7',
      privacy : 'Privacy Policy',      privacyHref: '/privacy-policy/',
      terms   : 'Termini di servizio', termsHref  : '/terms-of-service/',
      copy    : '© Tutti i diritti riservati – Prime IPTV',
      base    : '/it/',
    },
    nl: {
      links   : 'Belangrijke links',
      links2  : 'Extra links',
      home    : 'Startpagina',
      pricing : 'Abonnementsplannen',
      faq     : 'Veelgestelde vragen',
      whyUs   : 'Waarom IPTV kiezen?',
      payment : 'Betaalmethoden',
      reviews : 'Klantbeoordelingen',
      contactLink: 'Contact',
      contact : 'Contact',
      waText  : 'WhatsApp – Support 24/7',
      waAria  : 'WhatsApp Support 24/7',
      privacy : 'Privacybeleid',       privacyHref: '/privacy-policy/',
      terms   : 'Servicevoorwaarden',  termsHref  : '/terms-of-service/',
      copy    : '© Alle rechten voorbehouden – Prime IPTV',
      base    : '/nl/',
    },
    pt: {
      links   : 'Links importantes',
      links2  : 'Links adicionais',
      home    : 'Página inicial',
      pricing : 'Planos de assinatura',
      faq     : 'Perguntas frequentes',
      whyUs   : 'Por que escolher IPTV?',
      payment : 'Métodos de pagamento',
      reviews : 'Avaliações de clientes',
      contactLink: 'Contate-nos',
      contact : 'Contate-nos',
      waText  : 'WhatsApp – Suporte 24/7',
      waAria  : 'Suporte WhatsApp 24/7',
      privacy : 'Política de privacidade', privacyHref: '/privacy-policy/',
      terms   : 'Termos de serviço',       termsHref  : '/terms-of-service/',
      copy    : '© Todos os direitos reservados – Prime IPTV',
      base    : '/pt/',
    },
    tr: {
      links   : 'Önemli Bağlantılar',
      links2  : 'Ek Bağlantılar',
      home    : 'Ana Sayfa',
      pricing : 'Abonelik planları',
      faq     : 'Sık Sorulan Sorular',
      whyUs   : 'Neden IPTV seçilir?',
      payment : 'Ödeme Yöntemleri',
      reviews : 'Müşteri Yorumları',
      contactLink: 'İletişim',
      contact : 'İletişim',
      waText  : 'WhatsApp – Destek 24/7',
      waAria  : 'WhatsApp Destek 24/7',
      privacy : 'Gizlilik Politikası',  privacyHref: '/privacy-policy/',
      terms   : 'Kullanım Şartları',    termsHref  : '/terms-of-service/',
      copy    : '© Tüm hakları saklıdır – Prime IPTV',
      base    : '/tr/',
    },
  };

  const t = i18n[lang] || i18n['en'];

  /* ── Extract WhatsApp href from existing footer ── */
  const waEl  = footer.querySelector('a[href*="wa.me"]');
  const waHref = waEl ? waEl.getAttribute('href') : 'https://wa.me/212666686732';

  /* ── Nav links: 2-column grid on tablet/desktop, single col on mobile ── */
  var li = function(href, text, ext) {
    return '<li><a href="' + href + '" class="hover:text-white"' +
      (ext ? ' target="_blank" rel="noopener noreferrer"' : '') +
      '>' + text + '</a></li>';
  };
  var ulHTML =
    '<h4 class="ft-links-main-h4 font-semibold mb-4 text-lg">' + t.links + '</h4>' +
    '<div class="ft-links-grid">' +
      '<div class="ft-links-col">' +
        '<h4 class="ft-links-col-h4 font-semibold mb-4 text-lg">' + t.links + '</h4>' +
        '<ul class="space-y-3 text-gray-200">' +
          li(t.base + '#home',    t.home)    +
          li(t.base + '#pricing', t.pricing) +
          li(t.base + '#faq',     t.faq)     +
        '</ul>' +
      '</div>' +
      '<div class="ft-links-col">' +
        '<h4 class="ft-links-col-h4 font-semibold mb-4 text-lg">' + t.links2 + '</h4>' +
        '<ul class="space-y-3 text-gray-200">' +
          li(t.base + '#why-us',          t.whyUs)  +
          li(t.base + '#payment-methods', t.payment) +
          li(t.base + '#testimonials',    t.reviews) +
        '</ul>' +
      '</div>' +
    '</div>';

  /* ── Rebuild footer ── */
  footer.className = 'bg-gradient-to-r from-blue-600 via-purple-600 to-indigo-700 text-white py-12 relative';
  footer.style.marginTop = '0';

  footer.innerHTML =
    '<div class="footer-particles" aria-hidden="true">' +
      '<span class="particle p1"></span><span class="particle p2"></span>' +
      '<span class="particle p3"></span><span class="particle p4"></span>' +
      '<span class="particle p5"></span><span class="particle p6"></span>' +
      '<span class="particle p7"></span><span class="particle p8"></span>' +
    '</div>' +
    '<div class="container mx-auto px-4">' +
      '<div class="grid grid-cols-2 gap-4 md:gap-12">' +

        /* Content column */
        '<div class="flex flex-col gap-7">' +
          '<div class="flex items-center">' +
            '<img src="/images/logo.webp" alt="Prime IPTV" class="h-14 w-14 rounded-full mr-3 shadow-lg" loading="lazy" decoding="async">' +
            '<h3 class="text-2xl font-bold tracking-wide">Prime IPTV</h3>' +
          '</div>' +
          '<div>' + ulHTML + '</div>' +
          '<div>' +
            '<h4 class="font-semibold mb-4 text-lg">' + t.contact + '</h4>' +
            '<a href="' + waHref + '" target="_blank" rel="noopener noreferrer"' +
               ' class="inline-flex items-center bg-green-500 hover:bg-green-600 px-5 py-2 rounded-full shadow-lg transition-transform hover:scale-105"' +
               ' aria-label="' + t.waAria + '">' +
              '<i class="fab fa-whatsapp mr-2" aria-hidden="true"></i>' +
              t.waText +
            '</a>' +
          '</div>' +
        '</div>' +

        /* Logo column */
        '<div class="ft-player-logo-wrap">' +
          '<img src="/images/Prime-Player.webp" alt="Prime Player" class="footer-logo" loading="lazy" decoding="async" fetchpriority="high">' +
        '</div>' +

      '</div>' +

      /* Legal links */
      '<div class="flex justify-center gap-6 mt-10">' +
        '<a href="' + t.privacyHref + '" class="text-gray-300 hover:text-white text-sm transition">' + t.privacy + '</a>' +
        '<span class="text-gray-500">|</span>' +
        '<a href="' + t.termsHref + '" class="text-gray-300 hover:text-white text-sm transition">' + t.terms + '</a>' +
      '</div>' +

    '</div>';

  /* ── Copyright div OUTSIDE footer — insert once, remove all duplicates ── */
  /* 1. Remove any existing copyright divs already in the HTML */
  document.querySelectorAll('[data-ft-copy], .footer-bottom').forEach(function(el) {
    el.remove();
  });

  /* 2. Insert a fresh one after footer */
  var isLight = document.body.classList.contains('light-mode') || document.documentElement.classList.contains('light-mode');
  var copyDiv = document.createElement('div');
  copyDiv.dataset.ftCopy = '1';
  copyDiv.className = 'ft-copy-bar';
  if (isLight) {
    copyDiv.style.cssText = 'width:100%;background:rgba(212,207,234,.99);padding:22px 16px;text-align:center;border-top:1px solid rgba(91,22,163,.2);';
    copyDiv.innerHTML = '<p style="margin:0;color:#3b0764;font-size:14px;font-weight:500;letter-spacing:.5px;">' + t.copy + '</p>';
  } else {
    copyDiv.style.cssText = 'width:100%;background:#04010c;padding:22px 16px;text-align:center;border-top:1px solid rgba(168,85,247,.10);';
    copyDiv.innerHTML = '<p style="margin:0;color:#d8d2ff;font-size:14px;font-weight:500;letter-spacing:.5px;text-shadow:0 0 10px rgba(168,85,247,.18);">' + t.copy + '</p>';
  }
  footer.insertAdjacentElement('afterend', copyDiv);

  /* ── Seed rising particles ── */
  const pContainer = footer.querySelector('.footer-particles');
  for (var i = 0; i < 14; i++) {
    var p = document.createElement('span');
    p.className = 'ft-particle';
    var size = (2 + Math.random() * 2).toFixed(1) + 'px';
    p.style.cssText = 'left:' + (Math.random() * 100).toFixed(1) + '%;' +
      'width:' + size + ';height:' + size + ';' +
      'animation-duration:' + (10 + Math.random() * 14).toFixed(1) + 's;' +
      'animation-delay:' + (Math.random() * 8).toFixed(1) + 's;';
    pContainer.appendChild(p);
  }

})();
