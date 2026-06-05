#!/usr/bin/env python3
import re, os

BASE = '/home/user/Prime-iptv'

ICONS = [
    'M5 16L3 5l5.5 4L12 4l3.5 5L21 5l-2 11H5zm0 3h14v2H5v-2z',
    'M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z',
    'M1 9l2 2c4.97-4.97 13.03-4.97 18 0l2-2C16.93 2.93 7.08 2.93 1 9zm8 8l3 3 3-3c-1.65-1.66-4.34-1.66-6 0zm-4-4l2 2c2.76-2.76 7.24-2.76 10 0l2-2C15.14 9.14 8.87 9.14 5 13z',
    'M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm-1.2 14.2L7.6 12l1.4-1.4 1.8 1.8 4.2-4.2 1.4 1.4-5.6 5.6z',
    'M8 5v14l11-7z',
    'M21 3H3c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h5v2h8v-2h5c1.1 0 1.99-.9 1.99-2L23 5c0-1.1-.9-2-2-2zm0 14H3V5h18v12z',
    'M4 6h16v2H4zm0 5h16v2H4zm0 5h16v2H4z',
    'M21 12.22C21 6.73 16.74 3 12 3c-4.69 0-9 3.65-9 9.28-.6.34-1 .98-1 1.72v2c0 1.1.9 2 2 2h1v-6.1c0-3.87 3.13-7 7-7s7 3.13 7 7V19h-8v2h8c1.1 0 2-.9 2-2v-1.22c.59-.31 1-.92 1-1.64v-2.3c0-.7-.41-1.31-1-1.62z',
    'M12 1L9 9H1l6.5 5-2.5 8L12 17l7 5-2.5-8L23 9h-8z',
    'M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zm6.93 6h-2.95c-.32-1.25-.78-2.45-1.38-3.56 1.84.63 3.37 1.9 4.33 3.56zM12 4.04c.83 1.2 1.48 2.53 1.91 3.96h-3.82c.43-1.43 1.08-2.76 1.91-3.96zM4.26 14C4.1 13.36 4 12.69 4 12s.1-1.36.26-2h3.38c-.08.66-.14 1.32-.14 2 0 .68.06 1.34.14 2H4.26zm.82 2h2.95c.32 1.25.78 2.45 1.38 3.56-1.84-.63-3.37-1.9-4.33-3.56zm2.95-8H5.08c.96-1.66 2.49-2.93 4.33-3.56C8.81 5.55 8.35 6.75 8.03 8zM12 19.96c-.83-1.2-1.48-2.53-1.91-3.96h3.82c-.43 1.43-1.08 2.76-1.91 3.96zM14.34 14H9.66c-.09-.66-.16-1.32-.16-2 0-.68.07-1.35.16-2h4.68c.09.65.16 1.32.16 2 0 .68-.07 1.34-.16 2zm.25 5.56c.6-1.11 1.06-2.31 1.38-3.56h2.95c-.96 1.66-2.49 2.93-4.33 3.56zM16.36 14c.08-.66.14-1.32.14-2 0-.68-.06-1.34-.14-2h3.38c.16.64.26 1.31.26 2s-.1 1.36-.26 2h-3.38z',
]

FEAT_SVGS = [
    '<svg viewBox="0 0 24 24"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm-1.2 14.2L7.6 12l1.4-1.4 1.8 1.8 4.2-4.2 1.4 1.4-5.6 5.6z"/></svg>',
    '<svg viewBox="0 0 24 24"><path d="M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 17l-6.2 4.3 2.4-7.4L2 9.4h7.6z"/></svg>',
    '<svg viewBox="0 0 24 24"><path d="M21 12.22C21 6.73 16.74 3 12 3c-4.69 0-9 3.65-9 9.28-.6.34-1 .98-1 1.72v2c0 1.1.9 2 2 2h1v-6.1c0-3.87 3.13-7 7-7s7 3.13 7 7V19h-8v2h8c1.1 0 2-.9 2-2v-1.22c.59-.31 1-.92 1-1.64v-2.3c0-.7-.41-1.31-1-1.62z"/></svg>',
    '<svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>',
]

TOGGLE_SVG = '<svg viewBox="0 0 24 24"><path d="M7.41 8.59L12 13.17l4.59-4.58L18 10l-6 6-6-6 1.41-1.41z"/></svg>'
WA_SVG = '<svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/><path d="M12.003 1.5C6.197 1.5 1.5 6.197 1.5 12.003c0 1.922.517 3.72 1.416 5.271L1.5 22.5l5.35-1.402A10.494 10.494 0 0 0 12.003 22.5c5.806 0 10.5-4.697 10.5-10.497C22.503 6.197 17.809 1.5 12.003 1.5zm0 19.183a8.66 8.66 0 0 1-4.41-1.207l-.316-.188-3.276.859.875-3.193-.206-.328a8.638 8.638 0 0 1-1.324-4.606c.002-4.781 3.892-8.67 8.675-8.67a8.62 8.62 0 0 1 6.131 2.541 8.61 8.61 0 0 1 2.538 6.135c-.002 4.782-3.892 8.671-8.673 8.671z"/></svg>'

STAT_SVGS = [
    '<svg viewBox="0 0 24 24"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>',
    '<svg viewBox="0 0 24 24"><path d="M7 2v11h3v9l7-12h-4l4-8z"/></svg>',
    '<svg viewBox="0 0 24 24"><path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/></svg>',
    '<svg viewBox="0 0 24 24"><path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/></svg>',
]

def build_features(feats):
    html = '\n          <div class="faq2-features">\n'
    for svg, label in zip(FEAT_SVGS, feats):
        html += f'            <div class="faq2-feat">{svg}<span>{label}</span></div>\n'
    html += '          </div>'
    return html

def build_item(idx, question, answer, feats=None):
    icon = ICONS[idx % len(ICONS)]
    feat_html = build_features(feats) if feats else ''
    return f'''
      <div class="faq2-item">
        <button class="faq2-btn" type="button" aria-expanded="false">
          <span class="faq2-icon-box" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="{icon}"/></svg></span>
          <span class="faq2-q-text">{question}</span>
          <span class="faq2-toggle" aria-hidden="true">{TOGGLE_SVG}</span>
        </button>
        <div class="faq2-answer">{answer}{feat_html}
        </div>
      </div>'''

def build_section(cfg):
    items_html = ''
    for i, (q, a, *rest) in enumerate(cfg['qa']):
        feats = rest[0] if rest else None
        items_html += build_item(i, q, a, feats)

    stats_html = ''
    for svg, title, sub in zip(STAT_SVGS, cfg['stats_titles'], cfg['stats_subs']):
        stats_html += f'''
      <div class="faq2-stat">
        <div class="faq2-stat-icon">{svg}</div>
        <span class="faq2-stat-title">{title}</span>
        <span class="faq2-stat-sub">{sub}</span>
      </div>'''

    return f'''<section id="faq" aria-label="FAQ">
  <div class="faq2-inner">

    <div class="faq2-head">
      <span class="faq2-badge"><i class="fas fa-circle-question" style="color:#f5c518;"></i><i class="fas fa-comments" style="color:#f5c518;"></i>FAQ</span>
      <h2 class="faq2-title">{cfg['title']}</h2>
      <p class="faq2-sub">{cfg['subtitle']}</p>
    </div>

    <div class="faq2-list">{items_html}

    </div>

    <div class="faq2-cta">
      <div class="faq2-cta-text">
        <p class="faq2-cta-title">{cfg['cta_title']}</p>
        <p class="faq2-cta-sub">{cfg['cta_sub']}</p>
      </div>
      <a href="https://wa.me/212666686732" target="_blank" rel="noopener noreferrer" class="faq2-cta-btn faq2-cta-wa">
        {WA_SVG}
        {cfg['cta_btn']}
      </a>
    </div>

    <div class="faq2-stats">{stats_html}
    </div>

  </div>
</section>'''

def update_file(rel_path, cfg):
    path = os.path.join(BASE, rel_path)
    with open(path, 'r', encoding='utf-8') as f:
        html = f.read()
    new_section = build_section(cfg)
    updated = re.sub(r'<section id="faq"[^>]*>.*?</section>', new_section, html, flags=re.DOTALL)
    if updated == html:
        print(f'  WARNING: no match in {rel_path}')
        return False
    with open(path, 'w', encoding='utf-8') as f:
        f.write(updated)
    print(f'  OK: {rel_path}')
    return True

# ─────────────────────────────────────────────
# PAGE DATA
# ─────────────────────────────────────────────

PAGES = {}

# ── EN MAIN ──────────────────────────────────
PAGES['en/index.html'] = {
    'title': 'Frequently Asked <span class="faq2-grad">Questions</span>',
    'subtitle': 'Quick and clear answers to the most common questions about IPTV',
    'cta_title': "Didn't find your answer?",
    'cta_sub': 'Our support team is available via WhatsApp',
    'cta_btn': 'Contact via WhatsApp',
    'stats_titles': ['Trusted', 'Stability', '24/7 Support', 'Guaranteed'],
    'stats_subs': ['Thousands of users', 'Crystal-clear quality', 'Always available', 'Satisfaction assured'],
    'qa': [
        ('What makes Prime IPTV the Best IPTV Provider available?',
         'The Best IPTV Provider stands out through 99%+ server uptime, 4K and 8K streaming quality, a global CDN infrastructure, and round-the-clock technical support. Prime IPTV meets every one of these benchmarks.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('How does an IPTV Subscription work technically?',
         'An IPTV Subscription delivers digital streams directly to your device over the internet using HLS or MPEG-TS protocols — no satellite dish or cable line required. After subscribing you receive login credentials and connect within minutes.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('What internet speed is needed for 4K IPTV?',
         'For stable 4K IPTV you need at least 25 Mbps. HD requires around 10 Mbps and FHD around 15 Mbps. Prime IPTV uses adaptive bitrate technology so quality adjusts automatically on slower connections.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Why choose Premium IPTV over a free service?',
         'Premium IPTV delivers dedicated server resources, zero buffering, daily content updates, and 24/7 technical assistance. Free services share overloaded servers, suffer constant interruptions, and provide no support whatsoever.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('How does IPTV Streaming reach my device?',
         'IPTV Streaming encodes digital content on our servers and transmits it to your device in real time via the internet. Our globally distributed infrastructure ensures the lowest possible latency regardless of your location.'),
        ('What is XTREAM IPTV and how is it different from M3U?',
         'XTREAM IPTV uses an API login (server URL + username + password) providing greater stability, built-in EPG, and advanced player features. M3U is a plain playlist link. Prime IPTV supports both formats for maximum device compatibility.'),
        ('What is the Best IPTV Service for multi-device households?',
         'The Best IPTV Service for families offers multi-connection plans, compatibility with Smart TV, Android, iOS, Firestick and PC simultaneously, and reliable uptime so every screen works without interruption.'),
        ('How many connections does an IPTV Pro plan include?',
         'IPTV Pro plans typically include between two and five simultaneous connections. Prime IPTV offers flexible plans so you can choose exactly how many devices need to stream at the same time.'),
        ('Can I use IPTV Online directly from a web browser?',
         'Yes — certain IPTV Online players run in a browser without any installation. However, dedicated apps like TiviMate or IPTV Smarters deliver a superior experience with full EPG, playback controls, and catch-up access.'),
        ('What is an IPTV Provider and what should I verify before subscribing?',
         'An IPTV Provider hosts and delivers digital streams over the internet. Before subscribing verify server uptime guarantees, supported resolutions, number of simultaneous connections, device compatibility, and the quality of customer support.'),
    ]
}

# ── FR MAIN ──────────────────────────────────
PAGES['fr/index.html'] = {
    'title': 'Questions <span class="faq2-grad">Fréquentes</span>',
    'subtitle': 'Réponses rapides aux questions les plus courantes sur l\'IPTV',
    'cta_title': 'Vous n\'avez pas trouvé votre réponse ?',
    'cta_sub': 'Notre équipe est disponible sur WhatsApp',
    'cta_btn': 'Contacter via WhatsApp',
    'stats_titles': ['Fiabilité', 'Stabilité', 'Support 24/7', 'Garanti'],
    'stats_subs': ['Des milliers d\'utilisateurs', 'Qualité irréprochable', 'Toujours disponible', 'Satisfaction assurée'],
    'qa': [
        ('Comment choisir le Meilleur IPTV pour ma connexion ?',
         'Le Meilleur IPTV combine un taux de disponibilité supérieur à 99 %, une qualité 4K, un support technique réactif et des tarifs compétitifs. Vérifiez toujours ces critères avant de souscrire un abonnement.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('Qu\'est-ce qu\'un Abonnement IPTV et comment fonctionne-t-il ?',
         'Un Abonnement IPTV vous donne accès à des flux numériques via internet grâce aux protocoles HLS ou MPEG-TS. Après inscription, vous recevez vos identifiants et configurez votre lecteur en quelques minutes.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('En quoi le Service IPTV Premium se distingue-t-il des offres gratuites ?',
         'Un Service IPTV Premium garantit des serveurs dédiés, aucune interruption de flux, des mises à jour quotidiennes du contenu et un support disponible en permanence. Les services gratuits souffrent de coupures fréquentes et n\'offrent aucune assistance.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('Quelle qualité d\'image propose l\'IPTV 4K de Prime IPTV ?',
         'L\'IPTV 4K offre une résolution de 3840×2160 pixels, soit quatre fois plus détaillée que la Full HD. Prime IPTV diffuse également en HD, FHD et 8K avec une technologie de compression avancée pour une image nette même à débit modéré.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Comment configurer XTREAM IPTV sur mon application ?',
         'Dans votre lecteur compatible (IPTV Smarters, TiviMate, etc.), sélectionnez l\'option XTREAM IPTV, puis saisissez l\'URL du serveur, votre nom d\'utilisateur et votre mot de passe. La liste est chargée automatiquement en quelques secondes.'),
        ('Qu\'est-ce qui fait d\'un Fournisseur IPTV un choix fiable ?',
         'Un Fournisseur IPTV fiable garantit un uptime supérieur à 99 %, propose des serveurs redondants, offre un support technique réactif et met à jour son infrastructure régulièrement. Vérifiez les avis clients avant de souscrire.'),
        ('Puis-je utiliser l\'IPTV Online sans télécharger d\'application ?',
         'Oui, certains lecteurs IPTV Online fonctionnent directement dans le navigateur. Cependant, une application dédiée comme IPTV Smarters ou TiviMate offre une expérience bien supérieure avec guide des programmes et lecture fluide.'),
        ('Comment fonctionne l\'IPTV Streaming techniquement ?',
         'L\'IPTV Streaming encode le contenu numérique sur nos serveurs et le transmet en temps réel à votre appareil via internet. Notre réseau de distribution mondial garantit la latence la plus faible possible pour une lecture sans interruption.'),
        ('L\'IPTV Pro inclut-il une fonctionnalité de rattrapage ?',
         'Oui, l\'IPTV Pro Prime IPTV inclut le catch-up qui vous permet de regarder les contenus manqués jusqu\'à 7 jours après leur diffusion, directement depuis votre lecteur compatible.'),
        ('Combien de connexions simultanées permet un Abonnement IPTV Pro ?',
         'Un Abonnement IPTV Pro inclut généralement entre deux et cinq connexions simultanées. Chez Prime IPTV vous choisissez le plan adapté au nombre d\'écrans que vous souhaitez utiliser en même temps.'),
    ]
}

# ── ES MAIN ──────────────────────────────────
PAGES['es/index.html'] = {
    'title': 'Preguntas <span class="faq2-grad">Frecuentes</span>',
    'subtitle': 'Respuestas claras a las preguntas más comunes sobre IPTV',
    'cta_title': '¿No encontró su respuesta?',
    'cta_sub': 'Nuestro equipo está disponible en WhatsApp',
    'cta_btn': 'Contactar por WhatsApp',
    'stats_titles': ['Confianza', 'Estabilidad', 'Soporte 24/7', 'Garantizado'],
    'stats_subs': ['Miles de usuarios', 'Calidad nítida', 'Siempre disponible', 'Satisfacción asegurada'],
    'qa': [
        ('¿Qué define al Mejor IPTV en términos de calidad y estabilidad?',
         'El Mejor IPTV ofrece una disponibilidad de servidores superior al 99 %, calidad de imagen en 4K y 8K, infraestructura CDN global y soporte técnico permanente. Prime IPTV cumple todos estos requisitos con miles de usuarios satisfechos.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Cuál es la diferencia entre un Servicio IPTV de pago y uno gratuito?',
         'El IPTV de Pago garantiza servidores dedicados, sin cortes, soporte técnico permanente y actualizaciones diarias de contenido. Los servicios gratuitos funcionan en servidores saturados con interrupciones constantes y sin ninguna asistencia.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Qué velocidad de internet necesito para IPTV 4K?',
         'Para disfrutar de IPTV 4K de forma estable necesita al menos 25 Mbps. La calidad HD requiere unos 10 Mbps y FHD unos 15 Mbps. Prime IPTV usa bitrate adaptativo para ajustar la calidad según su conexión.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('¿Cómo funciona el IPTV Streaming desde el punto de vista técnico?',
         'El IPTV Streaming codifica el contenido digital en nuestros servidores y lo transmite a su dispositivo en tiempo real mediante los protocolos HLS o MPEG-TS. Nuestra red distribuida garantiza la menor latencia posible.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Cómo elijo un buen Proveedor IPTV con servicio Premium?',
         'Un buen Proveedor IPTV Premium ofrece uptime garantizado por encima del 99 %, servidores redundantes, soporte 24/7 y planes flexibles. Revise siempre opiniones verificadas antes de contratar.'),
        ('¿Puedo acceder al IPTV Online desde el navegador?',
         'Sí, algunos reproductores IPTV Online funcionan directamente en el navegador. Sin embargo, aplicaciones dedicadas como IPTV Smarters o TiviMate ofrecen una experiencia muy superior con guía de programación y reproducción fluida.'),
        ('¿Qué dispositivos son compatibles con el IPTV HD de Prime IPTV?',
         'IPTV HD funciona en Smart TV Android, cajas Android, Firestick, iPhone, iPad, PC Windows y Mac. Prime IPTV es compatible con todos los principales sistemas operativos y no requiere hardware adicional.'),
        ('¿En qué consiste el IPTV Pro y qué lo diferencia del IPTV básico?',
         'IPTV Pro incluye mayor número de conexiones simultáneas, contenido en 4K y 8K, soporte prioritario, catch-up hasta 7 días y servidores de mayor capacidad. Es la opción ideal para usuarios que exigen la máxima calidad.'),
        ('¿Cuántos dispositivos se pueden conectar con un plan IPTV de Pago?',
         'Los planes IPTV de Pago de Prime IPTV permiten entre uno y cinco dispositivos simultáneos según el plan elegido. Puede personalizar su suscripción según las necesidades de su hogar.'),
        ('¿Qué protocolos de streaming usa un Proveedor IPTV profesional?',
         'Un Proveedor IPTV profesional usa principalmente HLS (HTTP Live Streaming) y MPEG-TS para la transmisión en vivo. Para la configuración, soporta tanto M3U como XTREAM IPTV API para compatibilidad total con todos los reproductores.'),
    ]
}

# ── PT MAIN ──────────────────────────────────
PAGES['pt/index.html'] = {
    'title': 'Perguntas <span class="faq2-grad">Frequentes</span>',
    'subtitle': 'Respostas rápidas às perguntas mais comuns sobre IPTV',
    'cta_title': 'Não encontrou a sua resposta?',
    'cta_sub': 'A nossa equipa está disponível no WhatsApp',
    'cta_btn': 'Contactar via WhatsApp',
    'stats_titles': ['Confiança', 'Estabilidade', 'Suporte 24/7', 'Garantido'],
    'stats_subs': ['Milhares de utilizadores', 'Qualidade cristalina', 'Sempre disponível', 'Satisfação assegurada'],
    'qa': [
        ('Como identificar o Melhor IPTV disponível no mercado?',
         'O Melhor IPTV combina disponibilidade de servidores acima de 99 %, qualidade 4K e 8K, suporte técnico permanente e preços justos. Verifique sempre estes critérios e leia avaliações reais antes de subscrever.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('O que um Serviço IPTV de qualidade deve oferecer?',
         'Um Serviço IPTV de qualidade deve garantir transmissão sem interrupções, qualidade de imagem adaptativa, compatibilidade com múltiplos dispositivos, suporte técnico 24/7 e planos flexíveis. Prime IPTV cumpre todos estes requisitos.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('Qual a diferença entre IPTV Pro e um plano básico?',
         'O IPTV Pro inclui mais conexões simultâneas, acesso a conteúdo em 4K e 8K, suporte prioritário, catch-up até 7 dias e servidores de maior capacidade. Os planos básicos são ideais para utilizadores individuais com necessidades simples.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('Como funciona o IPTV 4K e que ligação é necessária?',
         'O IPTV 4K transmite conteúdo a 3840×2160 pixels usando codificação H.265 avançada. Para uma experiência estável precisa de pelo menos 25 Mbps. Prime IPTV usa bitrate adaptativo para manter a qualidade em velocidades inferiores.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('O que são Streams IPTV e como são organizados?',
         'Streams IPTV são fluxos de dados digitais transmitidos em tempo real via internet. São organizados em listas M3U ou através da API XTREAM IPTV e agrupados por categorias para facilitar a navegação no seu leitor.'),
        ('Como configurar o IPTV Streaming no meu dispositivo?',
         'Após subscrever, recebe as credenciais de acesso. Instale um leitor compatível (IPTV Smarters, TiviMate ou GSE Player), introduza o URL do servidor ou os dados XTREAM IPTV e o conteúdo fica disponível imediatamente.'),
        ('É possível assistir IPTV Online sem instalar aplicações?',
         'Sim, alguns leitores IPTV Online funcionam diretamente no browser. No entanto, uma aplicação dedicada oferece uma experiência muito superior com guia eletrónico de programas, função catch-up e qualidade de reprodução otimizada.'),
        ('O que distingue um Fornecedor IPTV confiável dos demais?',
         'Um Fornecedor IPTV confiável garante uptime acima de 99 %, usa servidores redundantes em múltiplas localizações, oferece suporte 24/7 em tempo real e actualiza regularmente a sua infraestrutura para manter a estabilidade.'),
        ('O IPTV HD funciona bem em ligações de velocidade moderada?',
         'Sim, o IPTV HD funciona de forma estável com velocidades a partir de 10 Mbps. Prime IPTV usa tecnologia de compressão avançada que mantém a qualidade mesmo em ligações de velocidade moderada.'),
        ('Quantos dispositivos posso usar com um único plano IPTV Premium?',
         'Os planos IPTV Premium da Prime IPTV permitem entre dois e cinco dispositivos simultâneos conforme o plano escolhido. Pode personalizar a sua subscrição para cobrir todos os ecrãs da sua casa.'),
    ]
}

# ── DE MAIN ──────────────────────────────────
PAGES['de/index.html'] = {
    'title': 'Häufig gestellte <span class="faq2-grad">Fragen</span>',
    'subtitle': 'Schnelle und klare Antworten zu den häufigsten IPTV-Fragen',
    'cta_title': 'Keine Antwort gefunden?',
    'cta_sub': 'Unser Support-Team ist auf WhatsApp erreichbar',
    'cta_btn': 'Kontakt via WhatsApp',
    'stats_titles': ['Vertrauen', 'Stabilität', '24/7 Support', 'Garantiert'],
    'stats_subs': ['Tausende Nutzer', 'Kristallklare Qualität', 'Immer erreichbar', 'Zufriedenheit garantiert'],
    'qa': [
        ('Worauf sollte ich beim IPTV Kaufen bei einem IPTV Anbieter achten?',
         'Beim IPTV Kaufen sollten Sie auf garantierte Serververfügbarkeit über 99 %, 4K-Qualität, 24/7-Support, flexible Pakete und transparente Preise achten. Prime IPTV erfüllt alle diese Kriterien mit langjähriger Erfahrung.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Wie funktioniert IPTV Streaming technisch?',
         'IPTV Streaming kodiert digitale Inhalte auf unseren Servern und überträgt sie in Echtzeit über das Internet an Ihr Gerät mithilfe von HLS- oder MPEG-TS-Protokollen. Unser verteiltes Servernetzwerk sorgt für minimale Latenz.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Welche Internetgeschwindigkeit brauche ich für 4K IPTV?',
         'Für stabiles 4K IPTV benötigen Sie mindestens 25 Mbps. HD erfordert ca. 10 Mbps und Full HD ca. 15 Mbps. Prime IPTV nutzt adaptive Bitraten-Technologie, um die Qualität automatisch an Ihre Verbindung anzupassen.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Was bietet ein IPTV Service im Vergleich zu traditionellem Fernsehen?',
         'Ein IPTV Service liefert digitale Inhalte über das Internet statt über Satellit oder Kabel — ohne Mindestvertragslaufzeit, auf allen Geräten gleichzeitig und mit Qualitäten bis 8K. Kein Techniker-Besuch, keine teure Hardware.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Was ist XTREAM IPTV und wie unterscheidet es sich von M3U?',
         'XTREAM IPTV verwendet ein API-Login (Server-URL + Benutzername + Passwort) und bietet mehr Stabilität, integriertes EPG und erweiterte Player-Funktionen. Eine M3U-Datei ist eine einfache Wiedergabeliste. Prime IPTV unterstützt beide Formate.'),
        ('Kann ich IPTV Online ohne App-Download nutzen?',
         'Ja, manche IPTV Online-Player laufen direkt im Browser. Für ein deutlich besseres Erlebnis empfehlen wir jedoch eine dedizierte App wie TiviMate oder IPTV Smarters mit vollständigem EPG-Guide und Catch-Up-Funktion.'),
        ('Was macht Premium IPTV besser als kostenlose Dienste?',
         'Premium IPTV bietet dedizierte Server, kein Buffering, tägliche Inhaltsaktualisierungen und rund um die Uhr technischen Support. Kostenlose Dienste laufen auf überlasteten Servern mit ständigen Unterbrechungen und ohne jegliche Hilfe.'),
        ('Wie viele Verbindungen erlaubt ein IPTV Pro Abonnement?',
         'Ein IPTV Pro Abonnement bei Prime IPTV erlaubt je nach gewähltem Paket zwischen zwei und fünf gleichzeitige Verbindungen. So können alle Bildschirme in Ihrem Haushalt gleichzeitig ohne Einschränkungen genutzt werden.'),
        ('Funktioniert IPTV HD auf allen Geräten problemlos?',
         'IPTV HD ist mit Smart TV, Android-Boxen, Firestick, iPhone, iPad und Windows/Mac-Computern kompatibel. Prime IPTV stellt sicher, dass Ihr Gerät unabhängig vom Betriebssystem reibungslos funktioniert.'),
        ('Wie richte ich XTREAM IPTV auf meinem Player ein?',
         'Öffnen Sie Ihre Player-App, wählen Sie XTREAM IPTV als Verbindungstyp, geben Sie Server-URL, Benutzernamen und Passwort ein und bestätigen. Die Inhaltsliste wird automatisch geladen. Der gesamte Vorgang dauert weniger als zwei Minuten.'),
    ]
}

# ── TR MAIN ──────────────────────────────────
PAGES['tr/index.html'] = {
    'title': 'Sıkça Sorulan <span class="faq2-grad">Sorular</span>',
    'subtitle': 'IPTV hakkında en sık sorulan sorulara hızlı ve net yanıtlar',
    'cta_title': 'Cevabınızı bulamadınız mı?',
    'cta_sub': 'Destek ekibimiz WhatsApp\'ta hazır',
    'cta_btn': 'WhatsApp ile iletişime geç',
    'stats_titles': ['Güvenilir', 'Kararlı', '7/24 Destek', 'Garantili'],
    'stats_subs': ['Binlerce kullanıcı', 'Kristal netliğinde kalite', 'Her zaman ulaşılabilir', 'Memnuniyet garanti'],
    'qa': [
        ('En İyi IPTV\'yi seçerken nelere dikkat etmeliyim?',
         'En İyi IPTV, %99\'un üzerinde sunucu çalışma süresi, 4K ve 8K yayın kalitesi, 7/24 teknik destek ve rekabetçi fiyat sunmalıdır. Abone olmadan önce bu kriterleri mutlaka kontrol edin.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Al sürecinde hangi teknik özelliklere bakmalıyım?',
         'IPTV Al sürecinde sunucu kararlılığı, desteklenen çözünürlükler, eş zamanlı bağlantı sayısı, cihaz uyumluluğu ve müşteri destek kalitesini değerlendirmelisiniz. Prime IPTV tüm bu konularda en yüksek standartları sunmaktadır.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Fiyat karşılaştırmasında nelere dikkat etmeliyim?',
         'IPTV Fiyat karşılaştırırken yalnızca rakama değil, içerilen bağlantı sayısına, çözünürlük kalitesine, sunucu güvenilirliğine ve destek hizmetine bakın. Çok ucuz teklifler genellikle kararsız sunucular ve yetersiz destek anlamına gelir.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('XTREAM IPTV ile M3U arasındaki fark nedir?',
         'XTREAM IPTV, sunucu URL\'si ile kullanıcı adı ve şifre kullanan API tabanlı bir giriş sistemidir; daha kararlı bağlantı ve yerleşik EPG kılavuzu sunar. M3U ise basit bir çalma listesi dosyasıdır. Prime IPTV her iki formatı da destekler.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Paketleri arasındaki temel farklar nelerdir?',
         'IPTV Paketleri arasındaki temel farklar eş zamanlı bağlantı sayısı, abonelik süresi, desteklenen çözünürlükler ve destek önceliğidir. Prime IPTV, bireysel kullanımdan büyük hanelere kadar uygun esnek paketler sunmaktadır.'),
        ('4K IPTV için ne kadar internet hızı gereklidir?',
         '4K IPTV için en az 25 Mbps bağlantı hızı gereklidir. HD kalite için 10 Mbps, FHD için ise 15 Mbps yeterlidir. Prime IPTV\'nin uyarlamalı bit hızı teknolojisi, daha düşük hızlarda bile görüntü kalitesini otomatik olarak optimize eder.'),
        ('Premium IPTV ücretsiz servislerden nasıl farklıdır?',
         'Premium IPTV, özel sunucular, kesintisiz yayın, günlük içerik güncellemeleri ve 7/24 teknik destek sunar. Ücretsiz servisler ise aşırı yüklü paylaşımlı sunucularda çalışır, sürekli kesintiler yaşanır ve hiçbir destek sağlanmaz.'),
        ('IPTV Satın Al işleminden sonra aktivasyon nasıl yapılır?',
         'IPTV Satın Al işleminin ardından birkaç dakika içinde bağlantı bilgileriniz WhatsApp veya e-posta ile iletilir. Uyumlu bir oynatıcı uygulamasına (TiviMate, IPTV Smarters) bilgilerinizi girin ve hemen izlemeye başlayın.'),
        ('Bir IPTV Abonelik kaç cihazda kullanılabilir?',
         'Prime IPTV\'nin IPTV Abonelik planlarında seçtiğiniz pakete göre aynı anda 1 ila 5 cihaz aktif olabilir. Evinizin tüm ekranlarını kapsayan bir plan seçerek tüm aile üyeleri eş zamanlı olarak kullanabilir.'),
        ('IPTV Pro standart IPTV\'den nasıl farklılaşır?',
         'IPTV Pro, standart plana kıyasla daha fazla eş zamanlı bağlantı, 4K ve 8K kaliteye tam erişim, öncelikli teknik destek ve catch-up işlevini içerir. Yüksek kalite ve maksimum esneklik bekleyen kullanıcılar için ideal seçenektir.'),
    ]
}

# ── IT MAIN ──────────────────────────────────
PAGES['it/index.html'] = {
    'title': 'Domande <span class="faq2-grad">Frequenti</span>',
    'subtitle': 'Risposte rapide alle domande più comuni sull\'IPTV',
    'cta_title': 'Non hai trovato la risposta?',
    'cta_sub': 'Il nostro team è disponibile su WhatsApp',
    'cta_btn': 'Contattaci via WhatsApp',
    'stats_titles': ['Affidabilità', 'Stabilità', 'Supporto 24/7', 'Garantito'],
    'stats_subs': ['Migliaia di utenti', 'Qualità cristallina', 'Sempre disponibile', 'Soddisfazione garantita'],
    'qa': [
        ('Quali caratteristiche definiscono il Miglior IPTV sul mercato?',
         'Il Miglior IPTV offre un uptime dei server superiore al 99 %, qualità 4K e 8K, un\'infrastruttura CDN globale e supporto tecnico continuo. Prime IPTV soddisfa tutti questi parametri con migliaia di utenti soddisfatti in tutto il mondo.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Cos\'è un Abbonamento IPTV e come funziona?',
         'Un Abbonamento IPTV ti dà accesso a flussi digitali tramite internet usando i protocolli HLS o MPEG-TS, senza bisogno di antenna o cavo. Dopo la sottoscrizione ricevi le credenziali e configuri il tuo player in pochi minuti.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('In cosa consiste un Servizio IPTV Premium di qualità?',
         'Un Servizio IPTV Premium garantisce server dedicati, assenza di buffering, aggiornamenti quotidiani dei contenuti e supporto tecnico 24/7. I servizi gratuiti utilizzano server condivisi e sovraccarichi con frequenti interruzioni e nessuna assistenza.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Che velocità internet serve per l\'IPTV 4K?',
         'Per uno streaming IPTV 4K stabile servono almeno 25 Mbps. La qualità HD richiede circa 10 Mbps e la Full HD circa 15 Mbps. Prime IPTV utilizza il bitrate adattivo per ottimizzare automaticamente la qualità in base alla tua connessione.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Come si configura XTREAM IPTV su un\'app player?',
         'Apri la tua app player compatibile (IPTV Smarters, TiviMate), seleziona XTREAM IPTV come tipo di connessione, inserisci URL server, nome utente e password. La lista viene caricata automaticamente in pochi secondi.'),
        ('L\'IPTV Online funziona direttamente dal browser?',
         'Sì, alcuni player IPTV Online funzionano direttamente nel browser senza installazione. Tuttavia un\'app dedicata offre un\'esperienza nettamente superiore con guida elettronica dei programmi, funzione catch-up e riproduzione fluida.'),
        ('Cosa distingue l\'IPTV Pro da un piano base?',
         'L\'IPTV Pro include un maggior numero di connessioni simultanee, accesso completo ai contenuti 4K e 8K, supporto prioritario e funzione catch-up fino a 7 giorni. È la scelta ideale per chi esige prestazioni massime.'),
        ('Come funziona tecnicamente l\'IPTV Streaming?',
         'L\'IPTV Streaming codifica i contenuti digitali sui nostri server e li trasmette in tempo reale al tuo dispositivo tramite internet. La nostra rete di distribuzione globale garantisce la latenza più bassa possibile per una visione senza interruzioni.'),
        ('L\'IPTV HD è compatibile con tutti i dispositivi?',
         'Sì, l\'IPTV HD è compatibile con Smart TV Android, box Android, Firestick, iPhone, iPad e PC Windows/Mac. Prime IPTV è progettato per funzionare su tutti i principali sistemi operativi senza hardware aggiuntivo.'),
        ('Quante connessioni simultanee include Premium IPTV?',
         'I piani Premium IPTV di Prime IPTV includono da due a cinque connessioni simultanee in base al piano scelto. Puoi personalizzare il tuo abbonamento per coprire tutti gli schermi della tua casa.'),
    ]
}

# ── NL MAIN ──────────────────────────────────
PAGES['nl/index.html'] = {
    'title': 'Veelgestelde <span class="faq2-grad">Vragen</span>',
    'subtitle': 'Snelle en duidelijke antwoorden op de meest gestelde vragen over IPTV',
    'cta_title': 'Antwoord niet gevonden?',
    'cta_sub': 'Ons team staat voor je klaar op WhatsApp',
    'cta_btn': 'Contact via WhatsApp',
    'stats_titles': ['Betrouwbaar', 'Stabiliteit', '24/7 Support', 'Gegarandeerd'],
    'stats_subs': ['Duizenden gebruikers', 'Kristalheldere kwaliteit', 'Altijd bereikbaar', 'Tevredenheid gegarandeerd'],
    'qa': [
        ('Wat maakt Prime IPTV de Beste IPTV aanbieder?',
         'De Beste IPTV aanbieder combineert een serveruptime van meer dan 99 %, 4K- en 8K-streamingkwaliteit, een wereldwijd CDN-netwerk en 24/7 technische ondersteuning. Prime IPTV voldoet aan al deze criteria met duizenden tevreden gebruikers.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Hoe werkt IPTV Streaming technisch gezien?',
         'IPTV Streaming codeert digitale inhoud op onze servers en stuurt dit in real-time via internet naar uw apparaat met behulp van HLS- of MPEG-TS-protocollen. Ons gedistribueerde servernetwerk zorgt voor de laagst mogelijke latency.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Wat is het verschil tussen IPTV Pro en een standaard abonnement?',
         'IPTV Pro omvat meer gelijktijdige verbindingen, volledige toegang tot 4K- en 8K-content, prioritaire ondersteuning en catch-up tot 7 dagen. Het standaardabonnement is ideaal voor individuele gebruikers met eenvoudige behoeften.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Welke internetsnelheid heb ik nodig voor IPTV 4K?',
         'Voor stabiele IPTV 4K heb je minimaal 25 Mbps nodig. HD vereist circa 10 Mbps en FHD circa 15 Mbps. Prime IPTV gebruikt adaptieve bitraatstechnologie om de kwaliteit automatisch aan te passen aan uw verbinding.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Kan ik IPTV Online gebruiken zonder een app te installeren?',
         'Ja, sommige IPTV Online players werken rechtstreeks in de browser. Voor een veel betere ervaring raden wij echter een dedicated app aan zoals TiviMate of IPTV Smarters, met volledige EPG-gids en catch-up functionaliteit.'),
        ('Wat is XTREAM IPTV en hoe configureer ik het?',
         'XTREAM IPTV gebruikt een API-login (server-URL + gebruikersnaam + wachtwoord) en biedt meer stabiliteit en ingebouwde EPG vergeleken met een gewoon M3U-bestand. Open uw player-app, kies XTREAM IPTV en vul uw gegevens in.'),
        ('Hoe onderscheidt Premium IPTV zich van gratis alternatieven?',
         'Premium IPTV levert dedicated servercapaciteit, nul buffering, dagelijkse inhoudsupdates en 24/7 technische ondersteuning. Gratis diensten draaien op overbelaste servers met constante onderbrekingen en bieden geen enkele hulp.'),
        ('Op hoeveel apparaten kan ik IPTV HD tegelijk gebruiken?',
         'Met een IPTV HD abonnement van Prime IPTV kunt u afhankelijk van uw gekozen plan tegelijk op één tot vijf apparaten streamen. Kies het plan dat past bij uw gezinssituatie.'),
        ('Wat biedt een kwalitatieve IPTV Service?',
         'Een kwalitatieve IPTV Service biedt ononderbroken digitale streams, compatibiliteit met alle moderne apparaten, meerdere gelijktijdige verbindingen, 24/7 support en transparante abonnementsprijzen zonder verborgen kosten.'),
        ('Werkt IPTV Live op Smart TV, telefoon en tablet tegelijk?',
         'Ja, IPTV Live van Prime IPTV werkt gelijktijdig op Smart TV, Android-smartphone, iPhone, iPad en pc. U kunt op elk apparaat inloggen met dezelfde accountgegevens zolang u binnen uw verbindingslimiet blijft.'),
    ]
}

# ── EN/UK ─────────────────────────────────────
PAGES['en/uk/index.html'] = {
    'title': 'Frequently Asked <span class="faq2-grad">Questions</span>',
    'subtitle': 'Everything you need to know about IPTV UK',
    'cta_title': "Didn't find your answer?",
    'cta_sub': 'Chat with us on WhatsApp anytime',
    'cta_btn': 'Contact via WhatsApp',
    'stats_titles': ['Trusted', 'Stability', '24/7 Support', 'Guaranteed'],
    'stats_subs': ['UK users love us', 'Crystal-clear quality', 'Always available', 'Satisfaction assured'],
    'qa': [
        ('What is the Best IPTV Service available in the UK?',
         'The Best IPTV Service for UK users delivers 99%+ server uptime, 4K and 8K streaming quality, a broad digital content library, and round-the-clock technical support. Prime IPTV is engineered specifically to handle UK broadband speeds and deliver the most stable stream possible.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('How do I set up IPTV on a Firestick in the UK?',
         'Setting up IPTV Firestick in the UK takes under five minutes. Enable the option to install apps from unknown sources in your Firestick settings, install a compatible player such as IPTV Smarters Pro or TiviMate, then enter your Prime IPTV credentials to start streaming immediately.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('What is an IPTV Box and do I need one for IPTV UK?',
         'An IPTV Box is a dedicated media player that runs your IPTV subscription through your television set. For IPTV UK you do not necessarily need a box — any Smart TV, Android device, Firestick or PC works perfectly with Prime IPTV.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('Does Prime IPTV offer an IPTV Trial before I commit?',
         'Yes — Prime IPTV offers an IPTV Trial so you can test the streaming quality and stability on your own devices and connection before choosing a full UK subscription. Contact us via WhatsApp to request your trial.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('What makes an IPTV Subscription UK different from a standard plan?',
         'An IPTV Subscription UK is optimised for UK network infrastructure, with server nodes closer to UK data centres to deliver lower latency and faster response times compared to generic global plans.'),
        ('Is 8K IPTV available and what hardware do I need to watch it?',
         '8K IPTV is available on Prime IPTV for users with compatible 8K-ready televisions and a minimum 50 Mbps internet connection. You will also need a player app that supports 8K HEVC decoding, such as the latest version of TiviMate.'),
        ('What makes a reliable IPTV Provider in the UK?',
         'A reliable IPTV Provider in the UK maintains servers on or close to UK backbone networks, guarantees uptime above 99 %, offers 24/7 English-language support, and updates its content infrastructure regularly to keep streams running smoothly.'),
        ('Can I use UK IPTV while travelling outside the United Kingdom?',
         'Yes — your UK IPTV subscription works on any internet connection worldwide. Simply log into your player app using the same Prime IPTV credentials you use at home and start streaming regardless of your location.'),
        ('How many streams does an IPTV Service typically support simultaneously?',
         'The number of simultaneous streams depends on your chosen plan. Prime IPTV offers plans supporting between one and five concurrent connections so you can select the right IPTV Service package for your household.'),
        ('What internet speed do I need for stable IPTV UK streaming?',
         'For HD IPTV UK you need at least 10 Mbps, for FHD 15 Mbps, and for 4K streaming 25 Mbps or more. Most UK broadband connections easily exceed these requirements, ensuring a smooth viewing experience.'),
    ]
}

# ── EN/USA ────────────────────────────────────
PAGES['en/usa/index.html'] = {
    'title': 'Frequently Asked <span class="faq2-grad">Questions</span>',
    'subtitle': 'Everything you need to know about IPTV USA',
    'cta_title': "Didn't find your answer?",
    'cta_sub': 'Chat with us on WhatsApp anytime',
    'cta_btn': 'Contact via WhatsApp',
    'stats_titles': ['Trusted', 'Stability', '24/7 Support', 'Guaranteed'],
    'stats_subs': ['US users love us', 'Crystal-clear quality', 'Always available', 'Satisfaction assured'],
    'qa': [
        ('What is the Best IPTV USA service for American viewers?',
         'The Best IPTV USA service combines low-latency servers located close to American data centres, 4K streaming quality, reliable uptime above 99 %, and US-based technical support availability. Prime IPTV is optimised for US broadband infrastructure.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('How do I compare IPTV Providers in the US?',
         'When comparing IPTV Providers in the US, evaluate server uptime guarantees, available resolutions, number of simultaneous connections, device compatibility, pricing transparency, and the quality and speed of customer support.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('Does Prime IPTV work as a cable or satellite TV replacement?',
         'Yes — Prime IPTV delivers digital streams over the internet, eliminating the need for expensive cable or satellite contracts. You get access to a broad library of digital content at a fraction of the traditional cost, with no long-term commitment required.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('What is the Best IPTV for streaming in 4K across the USA?',
         'For 4K IPTV streaming across the USA, you need a service with dedicated 4K server infrastructure and a minimum 25 Mbps internet connection. Prime IPTV delivers 4K and 8K streams on all compatible devices including Firestick, Smart TV, and Android boxes.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('How does IPTV US compare to traditional cable TV in terms of cost?',
         'IPTV US services typically cost a fraction of traditional cable subscriptions. With Prime IPTV you pay a single annual fee covering all devices in your home, with no hidden charges, no equipment rental fees, and no installation costs.'),
        ('How do I set up IPTV Streaming on a Firestick in the USA?',
         'On your Firestick go to Settings, then My Fire TV, then Developer Options and enable Apps from Unknown Sources. Install a compatible player app, enter your Prime IPTV credentials, and your IPTV Streaming is ready in under five minutes.'),
        ('What defines an IPTV Premium experience in the USA?',
         'An IPTV Premium experience means zero buffering on any connection, 4K and 8K quality on all streams that support it, instant channel switching, a full electronic programme guide, and 24/7 technical support from real agents.'),
        ('How many simultaneous streams does an IPTV Service USA support?',
         'Prime IPTV Service USA plans support between one and five simultaneous streams depending on the plan you choose. Multi-connection plans are ideal for households where several family members want to stream at the same time.'),
        ('Can IPTV USA be accessed on smartphones and tablets?',
         'Yes — IPTV USA works on Android and iOS smartphones and tablets via compatible apps like IPTV Smarters, GSE Player, or TiviMate. Your Prime IPTV credentials work on any device without any additional configuration.'),
        ('What protocol does Best IPTV USA use — M3U or XTREAM?',
         'Prime IPTV supports both M3U playlist format and XTREAM IPTV API login. XTREAM offers greater stability with built-in EPG, while M3U is universally compatible with almost every IPTV player application available.'),
    ]
}

# ── EN/CANADA ─────────────────────────────────
PAGES['en/canada/index.html'] = {
    'title': 'Frequently Asked <span class="faq2-grad">Questions</span>',
    'subtitle': 'Everything you need to know about IPTV Canada',
    'cta_title': "Didn't find your answer?",
    'cta_sub': 'Chat with us on WhatsApp anytime',
    'cta_btn': 'Contact via WhatsApp',
    'stats_titles': ['Trusted', 'Stability', '24/7 Support', 'Guaranteed'],
    'stats_subs': ['Canadian users love us', 'Crystal-clear quality', 'Always available', 'Satisfaction assured'],
    'qa': [
        ('What should I look for in an IPTV Canada service?',
         'When choosing IPTV Canada look for server proximity to Canadian data centres, 4K streaming support, reliable uptime above 99 %, French and English support availability, and flexible plans covering provinces like Quebec, Ontario, and British Columbia.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('How do I set up Canada IPTV on my Firestick?',
         'Enable Apps from Unknown Sources in your Firestick Developer Options, install a player such as TiviMate or IPTV Smarters, and enter your Prime IPTV Canada credentials. Setup takes under five minutes and works across all Canadian provinces.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('Is there a difference between IPTV Quebec and IPTV Ontario plans?',
         'IPTV Quebec and IPTV Ontario plans use the same global server infrastructure. Regional naming reflects the user base rather than different server locations. All Canadian subscribers get the same high-quality streams regardless of their province.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('What IPTV Box works best for IPTV Canada?',
         'Any Android-based IPTV Box running Android 5.0 or higher works well for IPTV Canada. Popular options include Nvidia Shield, MiBox, and budget Android boxes. A Firestick also works perfectly for Canadian users.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digital Streaming']),
        ('How do I find the Best IPTV Provider in Toronto?',
         'The Best IPTV Provider in Toronto is one with servers optimised for the GTA network infrastructure, 24/7 English support, 4K streaming, and transparent pricing. Prime IPTV serves Toronto users with minimal latency through our North American server nodes.'),
        ('Does IPTV Toronto offer better latency than national IPTV services?',
         'IPTV services with servers located closer to Toronto data centres generally deliver lower latency for Toronto users. Prime IPTV uses a distributed CDN architecture that automatically routes your connection to the nearest available server.'),
        ('What internet speed is recommended for IPTV Canada?',
         'For HD IPTV Canada you need 10 Mbps minimum, for FHD 15 Mbps, and for 4K streaming 25 Mbps or above. Canadian ISPs typically offer speeds well above these thresholds, so most subscribers experience zero buffering.'),
        ('How does IPTV Ontario handle multi-room setups?',
         'For a multi-room IPTV Ontario setup, choose a plan that includes the number of simultaneous connections you need. Prime IPTV supports up to five concurrent streams so different rooms can watch independently without interference.'),
        ('Can I use my IPTV Service from Canada while abroad?',
         'Yes — your Prime IPTV Canada subscription works on any internet connection worldwide. Travel outside Canada and continue using the same credentials on your devices without any additional configuration or VPN required.'),
        ('What makes IPTV Quebec unique compared to other regional plans?',
         'IPTV Quebec caters to French-speaking Canadian subscribers with bilingual support options. The technical infrastructure is identical to all other Canadian plans, ensuring the same 99%+ uptime and 4K streaming quality across the province.'),
    ]
}

# ── FR/FRANCE ─────────────────────────────────
PAGES['fr/france/index.html'] = {
    'title': 'Questions <span class="faq2-grad">Fréquentes</span>',
    'subtitle': 'Tout ce que vous devez savoir sur l\'IPTV France',
    'cta_title': 'Pas trouvé votre réponse ?',
    'cta_sub': 'Notre équipe est disponible sur WhatsApp',
    'cta_btn': 'Contacter via WhatsApp',
    'stats_titles': ['Fiabilité', 'Stabilité', 'Support 24/7', 'Garanti'],
    'stats_subs': ['Les Français nous font confiance', 'Qualité irréprochable', 'Toujours disponible', 'Satisfaction assurée'],
    'qa': [
        ('Qu\'est-ce qu\'un Boitier IPTV et ai-je besoin d\'un pour regarder l\'IPTV France ?',
         'Un Boitier IPTV est un lecteur multimédia dédié qui connecte votre abonnement à votre téléviseur. Pour l\'IPTV France vous n\'en avez pas forcément besoin — une Smart TV, un smartphone, une tablette ou un PC suffisent pour profiter de Prime IPTV.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('Quelle est la différence entre une Box IPTV et une Clé IPTV ?',
         'Une Box IPTV est un boîtier Android complet avec stockage et processeur dédié, idéale pour une installation fixe. Une Clé IPTV (type Firestick) est plus compacte, portable et facile à transporter, parfaite pour une utilisation sur différents écrans.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('Comment configurer XTREAM IPTV sur mon Décodeur IPTV ?',
         'Sur votre application lecteur (IPTV Smarters, TiviMate), sélectionnez le type de connexion XTREAM IPTV, puis saisissez l\'URL serveur, le nom d\'utilisateur et le mot de passe fournis par Prime IPTV. La liste se charge automatiquement en quelques secondes.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('L\'IPTV 4K fonctionne-t-il bien sur les connexions fibre en France ?',
         'Oui — les connexions fibre optique en France (100 Mbps à 1 Gbps) dépassent largement les 25 Mbps requis pour l\'IPTV 4K. Avec la fibre vous bénéficiez d\'une image 4K parfaitement fluide sans aucun buffering.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Qu\'est-ce que le Premier IPTV et pourquoi choisir Prime IPTV France ?',
         'Prime IPTV figure parmi les Premier IPTV fournisseurs en France grâce à sa disponibilité de 99%+, ses résolutions jusqu\'au 8K, son support francophone 24/7 et ses tarifs transparents sans engagement.'),
        ('Un Abonnement IPTV France inclut-il le rattrapage ?',
         'Oui — l\'Abonnement IPTV France de Prime IPTV inclut la fonction catch-up pour revoir les contenus manqués jusqu\'à 7 jours après leur diffusion, directement depuis votre lecteur compatible Décodeur IPTV ou application.'),
        ('Comment fonctionne techniquement l\'IPTV Premium en France ?',
         'L\'IPTV Premium encode les flux numériques sur des serveurs dédiés et les transmet en temps réel à votre appareil via les protocoles HLS ou MPEG-TS. Notre infrastructure distribuée en Europe garantit une latence minimale pour les utilisateurs français.'),
        ('Combien de connexions simultanées une Box IPTV peut-elle gérer ?',
         'Le nombre de connexions simultanées dépend de votre plan. Les abonnements Prime IPTV France permettent de un à cinq flux simultanés. Choisissez le plan correspondant au nombre d\'écrans de votre foyer.'),
        ('Faut-il un Décodeur IPTV dédié ou une Smart TV suffit-elle ?',
         'Une Smart TV Android ou une Smart TV compatible avec les applications IPTV suffit parfaitement. Le Décodeur IPTV dédié reste utile si votre téléviseur est ancien ou ne supporte pas les applications. Prime IPTV est compatible avec les deux options.'),
        ('Comment activer mon Abonnement IPTV France via XTREAM IPTV ?',
         'Après souscription, vous recevez les identifiants XTREAM IPTV par WhatsApp ou e-mail. Ouvrez votre application lecteur, choisissez XTREAM comme type d\'entrée, saisissez les informations reçues et votre IPTV France est actif en moins de deux minutes.'),
    ]
}

# ── FR/BELGIQUE ───────────────────────────────
PAGES['fr/belgique/index.html'] = {
    'title': 'Questions <span class="faq2-grad">Fréquentes</span>',
    'subtitle': 'Tout ce que vous devez savoir sur l\'IPTV Belgique',
    'cta_title': 'Pas trouvé votre réponse ?',
    'cta_sub': 'Notre équipe est disponible sur WhatsApp',
    'cta_btn': 'Contacter via WhatsApp',
    'stats_titles': ['Fiabilité', 'Stabilité', 'Support 24/7', 'Garanti'],
    'stats_subs': ['Les Belges nous font confiance', 'Qualité irréprochable', 'Toujours disponible', 'Satisfaction assurée'],
    'qa': [
        ('Qu\'est-ce que l\'IPTV Belgique et comment fonctionne-t-il ?',
         'L\'IPTV Belgique est un service de diffusion numérique via internet qui remplace le câble ou le satellite. Il achemine les flux directement à votre appareil en HD, FHD, 4K ou 8K via les protocoles HLS et MPEG-TS.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('Quel est le meilleur IPTV Box pour l\'IPTV Belgium ?',
         'N\'importe quelle box Android compatible (Nvidia Shield, MiBox, ou box générique sous Android 5+) fonctionne parfaitement pour l\'IPTV Belgium. Une clé Firestick est également une excellente option compacte.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('Comment fonctionne XTREAM IPTV sur un Décodeur IPTV en Belgique ?',
         'XTREAM IPTV utilise un système API (URL serveur + identifiant + mot de passe) qui offre plus de stabilité qu\'un simple fichier M3U. Sur votre Décodeur IPTV ou application, saisissez les informations reçues après votre abonnement pour accéder immédiatement.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('Quel est le prix typique de l\'IPTV Belgique Premium ?',
         'Les tarifs IPTV Belgique Prix varient selon la durée d\'abonnement et le nombre de connexions. Les abonnements Prime IPTV offrent un excellent rapport qualité/prix avec des serveurs dédiés et un support 24/7 inclus.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('Faut-il une connexion rapide pour l\'IPTV 4K en Belgique ?',
         'Pour l\'IPTV 4K en Belgique il faut au minimum 25 Mbps. Les connexions fibre belges atteignent 200 Mbps à 1 Gbps, ce qui garantit une expérience 4K et même 8K parfaitement fluide sans buffering.'),
        ('Comment acheter IPTV Kopen en Belgique ?',
         'Pour votre IPTV Kopen en Belgique, contactez Prime IPTV via WhatsApp, choisissez votre plan, effectuez le paiement et recevez vos identifiants en quelques minutes. Le processus est rapide, sécurisé et entièrement en ligne.'),
        ('L\'IPTV België fonctionne-t-il sur Smart TV et smartphone ?',
         'Oui — l\'IPTV België est compatible avec toutes les Smart TV Android, les smartphones iOS et Android, les tablettes, les boîtiers Firestick et les PC. Prime IPTV fonctionne sur tous les appareils sans configuration complexe.'),
        ('Combien de flux simultanés supporte un abonnement IPTV Belgium ?',
         'Les abonnements Prime IPTV Belgium supportent entre un et cinq flux simultanés selon le plan choisi. Les formules multi-connexions sont idéales pour les foyers où plusieurs membres souhaitent regarder en même temps.'),
        ('Comment comparer les offres d\'IPTV Belgique Prix ?',
         'Pour comparer les offres IPTV Belgique Prix, regardez au-delà du tarif : vérifiez l\'uptime garanti, les résolutions supportées, le nombre de connexions, la qualité du support technique et les avis clients vérifiés.'),
        ('L\'IPTV Premium Belgium est-il disponible avec un essai gratuit ?',
         'Oui — Prime IPTV propose un essai pour vous permettre de tester la qualité et la stabilité sur vos propres appareils avant de souscrire un abonnement IPTV Belgium complet. Contactez-nous via WhatsApp pour en bénéficier.'),
    ]
}

# ── FR/CANADA ─────────────────────────────────
PAGES['fr/canada/index.html'] = {
    'title': 'Questions <span class="faq2-grad">Fréquentes</span>',
    'subtitle': 'Tout ce que vous devez savoir sur l\'IPTV Canada',
    'cta_title': 'Pas trouvé votre réponse ?',
    'cta_sub': 'Notre équipe est disponible sur WhatsApp',
    'cta_btn': 'Contacter via WhatsApp',
    'stats_titles': ['Fiabilité', 'Stabilité', 'Support 24/7', 'Garanti'],
    'stats_subs': ['Les Canadiens nous font confiance', 'Qualité irréprochable', 'Toujours disponible', 'Satisfaction assurée'],
    'qa': [
        ('Comment trouver le Meilleur IPTV au Québec ?',
         'Pour trouver le Meilleur IPTV au Québec, comparez la disponibilité des serveurs (99%+ minimum), la qualité 4K, le support francophone 24/7 et les tarifs. Prime IPTV est optimisé pour l\'infrastructure réseau québécoise.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('Quelle est la différence entre IPTV Québec et IPTV Canada ?',
         'IPTV Québec fait référence à l\'utilisation du service au Québec, souvent avec support en français. IPTV Canada est le terme générique couvrant l\'ensemble du pays. La qualité du service Prime IPTV est identique dans toutes les provinces canadiennes.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('Quel IPTV Box est recommandé pour Canada IPTV ?',
         'Pour Canada IPTV, les boîtiers Android comme Nvidia Shield, MiBox ou Mecool fonctionnent très bien. Une clé Firestick est une option plus économique et tout aussi efficace pour accéder à votre abonnement Prime IPTV au Canada.',
         ['Disponibilité 99%+', 'HD · FHD · 4K · 8K', 'Support 24/7', 'Streaming digital']),
        ('Comment fonctionne l\'IPTV Service à Montréal ?',
         'L\'IPTV Service à Montréal s\'appuie sur notre infrastructure de serveurs en Amérique du Nord pour garantir une latence minimale. Avec les connexions fibre disponibles à Montréal, vous bénéficiez d\'une qualité 4K et 8K parfaitement fluide.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Existe-t-il des offres IPTV Montréal spécifiques à la région ?',
         'Prime IPTV ne distingue pas les offres par ville — tous les abonnés canadiens, qu\'ils soient à Montréal, Toronto ou Vancouver, bénéficient du même service de haute qualité avec la même infrastructure et les mêmes tarifs.'),
        ('Qu\'est-ce qui distingue un bon IPTV Provider au Canada ?',
         'Un bon IPTV Provider au Canada garantit une disponibilité de 99%+, des serveurs proches des nœuds canadiens, un support bilingue (français/anglais), des résolutions jusqu\'au 8K et des plans flexibles adaptés à toutes les tailles de foyer.'),
        ('L\'IPTV Calgary offre-t-il la même qualité qu\'à Montréal ou Toronto ?',
         'Oui — grâce à notre infrastructure CDN distribuée, les utilisateurs de Calgary bénéficient de la même qualité et stabilité que les utilisateurs de Montréal ou Toronto. La connexion est automatiquement routée vers le serveur le plus proche.'),
        ('Combien de connexions simultanées inclut le Best IPTV Canada ?',
         'Le Best IPTV Canada de Prime IPTV propose des plans de une à cinq connexions simultanées. Pour un foyer avec plusieurs membres souhaitant regarder en même temps, les plans multi-connexions sont la solution idéale.'),
        ('Comment activer Canada IPTV sur ma Smart TV ou ma Box ?',
         'Après souscription vous recevez vos identifiants. Sur votre Smart TV ou Box, installez une application compatible (IPTV Smarters, TiviMate), saisissez l\'URL serveur et vos identifiants XTREAM IPTV — votre Canada IPTV est actif instantanément.'),
        ('L\'IPTV Québec fonctionne-t-il hors du Canada ?',
         'Oui — votre abonnement IPTV Québec fonctionne sur n\'importe quelle connexion internet dans le monde. Que vous soyez en France, en Europe ou ailleurs, vos identifiants Prime IPTV vous donnent accès depuis n\'importe quel appareil.'),
    ]
}

# ── ES/ESPAÑA ─────────────────────────────────
PAGES['es/espana/index.html'] = {
    'title': 'Preguntas <span class="faq2-grad">Frecuentes</span>',
    'subtitle': 'Todo lo que necesitas saber sobre IPTV Spain',
    'cta_title': '¿No encontraste tu respuesta?',
    'cta_sub': 'Nuestro equipo está en WhatsApp',
    'cta_btn': 'Contactar por WhatsApp',
    'stats_titles': ['Confianza', 'Estabilidad', 'Soporte 24/7', 'Garantizado'],
    'stats_subs': ['España confía en nosotros', 'Calidad nítida', 'Siempre disponible', 'Satisfacción asegurada'],
    'qa': [
        ('¿Cómo comprar IPTV Spain de forma segura con IPTV Comprar?',
         'Para IPTV Comprar de forma segura en España, elige un proveedor con uptime garantizado superior al 99 %, soporte técnico en español y política de reembolso clara. Con Prime IPTV el proceso es 100 % online, rápido y sin compromisos.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Qué diferencia hay entre Euro IPTV y un servicio IPTV estándar?',
         'Euro IPTV hace referencia a servicios diseñados para usuarios europeos con servidores próximos a los nodos de red europeos, ofreciendo menor latencia y mejor estabilidad para los usuarios de España y resto de Europa.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Es posible solicitar una IPTV Prueba antes de suscribirse?',
         'Sí — Prime IPTV ofrece una IPTV Prueba para que compruebes la calidad y estabilidad del servicio en tus propios dispositivos antes de contratar un plan completo. Contáctanos por WhatsApp para solicitarla.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Cómo funciona XTREAM IPTV en dispositivos Android y Smart TV en España?',
         'XTREAM IPTV usa un sistema de login API (URL + usuario + contraseña). Abre tu aplicación compatible (IPTV Smarters, TiviMate), selecciona XTREAM IPTV como tipo de entrada y escribe los datos que te proporcionamos. La lista carga automáticamente.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Qué velocidad de internet necesito para el Mejor IPTV en España?',
         'Para HD en España necesitas al menos 10 Mbps, para FHD 15 Mbps y para 4K un mínimo de 25 Mbps. Las conexiones de fibra óptica en España superan habitualmente los 300 Mbps, más que suficiente para streaming en 8K.'),
        ('¿Cuál es la diferencia entre IPTV de Pago y los servicios gratuitos?',
         'El IPTV de Pago garantiza servidores dedicados, sin cortes, actualizaciones diarias del contenido digital y soporte técnico permanente. Los servicios gratuitos funcionan en infraestructura sobrecargada con interrupciones constantes y sin ninguna asistencia.'),
        ('¿Cómo configuro IPTV Online en mi dispositivo favorito en España?',
         'Tras suscribirte recibes tus credenciales de acceso. Instala un reproductor compatible, introduce tu URL de servidor o tus datos XTREAM IPTV y empieza a ver contenido digital en segundos. Compatible con Smart TV, Android, iOS y PC.'),
        ('¿Qué incluye un plan IPTV Premium para España?',
         'Un plan IPTV Premium Spain de Prime IPTV incluye streaming hasta 8K, múltiples conexiones simultáneas, soporte técnico prioritario 24/7, catch-up de hasta 7 días y compatibilidad con todos los dispositivos del mercado.'),
        ('¿Se puede usar IPTV Spain fuera de España?',
         'Sí — tu suscripción IPTV Spain funciona en cualquier conexión a internet del mundo. Tanto si estás de vacaciones en Europa como en cualquier otro continente, tus credenciales Prime IPTV funcionan exactamente igual que en casa.'),
        ('¿Cómo comparar los distintos servicios IPTV disponibles en el mercado español?',
         'Para comparar los servicios IPTV en España, evalúa el uptime garantizado, las resoluciones ofrecidas, el número de conexiones, la calidad del soporte técnico, las políticas de precios y las valoraciones de clientes reales verificadas.'),
    ]
}

# ── ES/ARGENTINA ──────────────────────────────
PAGES['es/argentina/index.html'] = {
    'title': 'Preguntas <span class="faq2-grad">Frecuentes</span>',
    'subtitle': 'Todo lo que necesitas saber sobre IPTV Argentina',
    'cta_title': '¿No encontraste tu respuesta?',
    'cta_sub': 'Nuestro equipo está en WhatsApp',
    'cta_btn': 'Contactar por WhatsApp',
    'stats_titles': ['Confianza', 'Estabilidad', 'Soporte 24/7', 'Garantizado'],
    'stats_subs': ['Argentina confía en nosotros', 'Calidad nítida', 'Siempre disponible', 'Satisfacción asegurada'],
    'qa': [
        ('¿Qué es IPTV Argentina y cómo funciona técnicamente?',
         'IPTV Argentina es un servicio de transmisión digital de contenido a través de internet que reemplaza el cable o el satélite. Usa protocolos HLS o MPEG-TS para enviar flujos digitales en tiempo real a tu dispositivo en HD, FHD o 4K.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Cómo configurar un TV Box IPTV en Argentina?',
         'En tu TV Box Android, instala una aplicación IPTV compatible (IPTV Smarters, TiviMate o GSE Player), selecciona XTREAM IPTV como tipo de conexión, introduce las credenciales de Prime IPTV y tu servicio estará listo en menos de cinco minutos.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Cuál es la diferencia entre una Suscripción IPTV mensual y anual?',
         'Una Suscripción IPTV mensual ofrece mayor flexibilidad pero a un costo por mes más elevado. La suscripción anual proporciona un ahorro significativo y estabilidad del servicio a largo plazo. Prime IPTV ofrece ambas modalidades para Argentina.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Qué es IPTV AL y para qué región está orientado?',
         'IPTV AL hace referencia a servicios IPTV enfocados en América Latina, con infraestructura de servidores optimizada para la región. Prime IPTV ofrece conexiones de baja latencia para usuarios en Argentina y toda Latinoamérica.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Cómo funciona XTREAM IPTV en dispositivos Android en Argentina?',
         'XTREAM IPTV funciona mediante login API con URL de servidor, usuario y contraseña. Es más estable que el formato M3U y compatible con todos los reproductores Android populares en Argentina como TiviMate, IPTV Smarters Pro y GSE Player.'),
        ('¿Qué velocidad de internet necesito para Transmisiones IPTV en HD?',
         'Para Transmisiones IPTV en HD necesitas al menos 10 Mbps, para FHD 15 Mbps y para 4K un mínimo de 25 Mbps. La tecnología de bitrate adaptativo de Prime IPTV ajusta automáticamente la calidad si tu conexión varía.'),
        ('¿Qué diferencia hay entre IPTV Premium y un servicio básico en Argentina?',
         'IPTV Premium Argentina incluye servidores dedicados, calidad hasta 8K, soporte técnico prioritario 24/7 y múltiples conexiones simultáneas. Los servicios básicos utilizan infraestructura compartida que puede sufrir saturación y cortes.'),
        ('¿Es posible usar IPTV Online en Argentina desde cualquier dispositivo?',
         'Sí — IPTV Online de Prime IPTV es compatible con Smart TV, Android, iOS, Firestick, TV Box y PC. Puedes usarlo en todos tus dispositivos con las mismas credenciales y sin configuraciones adicionales.'),
        ('¿Cuántos dispositivos permite una Suscripción IPTV Argentina?',
         'Los planes de Prime IPTV Argentina permiten entre uno y cinco dispositivos simultáneos según el plan elegido. Para hogares donde varios miembros usan el servicio al mismo tiempo, los planes multi-conexión son la opción ideal.'),
        ('¿Cómo activar mi plan IPTV Argentina paso a paso?',
         'Tras contratar tu plan, recibes tus credenciales por WhatsApp en pocos minutos. Instala un reproductor compatible en tu dispositivo, introduce los datos recibidos y comienza a disfrutar del servicio de inmediato. No se necesitan conocimientos técnicos.'),
    ]
}

# ── ES/MEXICO ─────────────────────────────────
PAGES['es/mexico/index.html'] = {
    'title': 'Preguntas <span class="faq2-grad">Frecuentes</span>',
    'subtitle': 'Todo lo que necesitas saber sobre IPTV Mexico',
    'cta_title': '¿No encontraste tu respuesta?',
    'cta_sub': 'Nuestro equipo está en WhatsApp',
    'cta_btn': 'Contactar por WhatsApp',
    'stats_titles': ['Confianza', 'Estabilidad', 'Soporte 24/7', 'Garantizado'],
    'stats_subs': ['México confía en nosotros', 'Calidad nítida', 'Siempre disponible', 'Satisfacción asegurada'],
    'qa': [
        ('¿Cómo funciona IPTV Mexico en términos de velocidad y estabilidad?',
         'IPTV Mexico transmite contenido digital vía internet usando protocolos HLS y MPEG-TS. Prime IPTV cuenta con nodos de servidor en Norteamérica para ofrecer baja latencia y alta estabilidad a los usuarios de México.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Cómo configurar IPTV para Roku en México paso a paso?',
         'En tu Roku, accede a la Roku Channel Store e instala una aplicación IPTV compatible. Introduce el código M3U o los datos XTREAM IPTV de Prime IPTV en la configuración de la app. El proceso tarda menos de cinco minutos.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Qué es XTREAM IPTV y cómo se configura en México?',
         'XTREAM IPTV es un protocolo de acceso API que usa URL de servidor, usuario y contraseña en lugar de un archivo M3U. Ofrece mayor estabilidad y un guía de programación integrado. Prime IPTV soporta XTREAM para todos sus usuarios de México.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Cuál es el Best IPTV disponible en México?',
         'El Best IPTV México combina servidores de baja latencia para la región, calidad 4K y 8K, soporte técnico en español 24/7, planes flexibles y precios competitivos. Prime IPTV cumple todos estos criterios con miles de usuarios activos en México.',
         ['Disponibilidad 99%+', 'HD · FHD · 4K · 8K', 'Soporte 24/7', 'Streaming digital']),
        ('¿Qué diferencia existe entre IPTV Online y la TV tradicional en México?',
         'IPTV Online entrega contenido digital a través de internet sin necesidad de cable, antena o instalación de técnicos. Funciona en todos tus dispositivos existentes con una conexión de banda ancha sin contratos de larga duración ni equipos costosos.'),
        ('¿Cómo funcionan las Transmisiones IPTV Mexico en alta calidad?',
         'Las Transmisiones IPTV Mexico de Prime IPTV usan compresión H.265 avanzada y servidores CDN distribuidos para entregar contenido digital en HD, FHD y 4K con interrupciones mínimas incluso en conexiones de velocidad media.'),
        ('¿Es IPTV Roku compatible con todos los modelos Roku disponibles en México?',
         'IPTV Roku funciona en la mayoría de modelos Roku que soporten la instalación de canales de terceros. Para mejores resultados recomendamos los modelos Roku Express 4K o superiores que ofrecen decodificación de contenido en alta resolución.'),
        ('¿Qué significa IPTV AL y cómo aplica a México?',
         'IPTV AL hace referencia a servicios IPTV para América Latina. Para usuarios de México significa acceso a una infraestructura de servidores más cercana geográficamente, lo que se traduce en menor latencia y transmisiones más estables.'),
        ('¿Cuántas conexiones simultáneas incluye un plan IPTV Premium México?',
         'Los planes IPTV Premium México de Prime IPTV incluyen de uno a cinco conexiones simultáneas. Para familias donde varios miembros quieren usar el servicio a la vez, los planes multi-conexión ofrecen la solución más económica y eficiente.'),
        ('¿Cómo se activa IPTV Transmisiones Mexico en Smart TV?',
         'En tu Smart TV Android, descarga una aplicación IPTV compatible desde la tienda de aplicaciones, selecciona el tipo de entrada (M3U o XTREAM), introduce tus credenciales Prime IPTV y empieza a disfrutar del servicio de inmediato.'),
    ]
}

# ── PT/BRASIL ─────────────────────────────────
PAGES['pt/brasil/index.html'] = {
    'title': 'Perguntas <span class="faq2-grad">Frequentes</span>',
    'subtitle': 'Tudo o que você precisa saber sobre IPTV Brasil',
    'cta_title': 'Não encontrou sua resposta?',
    'cta_sub': 'Nossa equipe está disponível no WhatsApp',
    'cta_btn': 'Contato via WhatsApp',
    'stats_titles': ['Confiança', 'Estabilidade', 'Suporte 24/7', 'Garantido'],
    'stats_subs': ['O Brasil confia em nós', 'Qualidade cristalina', 'Sempre disponível', 'Satisfação garantida'],
    'qa': [
        ('Como encontrar o Melhor IPTV Brasil disponível?',
         'O Melhor IPTV Brasil combina servidores com alta disponibilidade (99%+), qualidade 4K, suporte técnico em português 24/7 e preços acessíveis. Prime IPTV é otimizado para a infraestrutura de internet brasileira.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('O que é uma TV Box IPTV e como configurá-la no Brasil?',
         'Uma TV Box IPTV é um dispositivo Android compacto que conecta seu serviço de streaming à televisão. No Brasil, basta instalar um aplicativo compatível (IPTV Smarters ou TiviMate), inserir suas credenciais Prime IPTV e começar a assistir.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('O IPTV PC funciona bem em notebooks e computadores mais antigos no Brasil?',
         'Sim — o IPTV PC funciona em qualquer computador com navegador moderno ou aplicativo compatível. O processamento de streaming HD e FHD é leve e não exige hardware potente. Para 4K recomenda-se um processador mais recente.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('Como funciona a Revenda IPTV e quais são seus benefícios?',
         'Revenda IPTV permite que parceiros revendam planos Prime IPTV com margens competitivas. Os revendedores têm acesso a um painel de gestão, suporte técnico prioritário e preços de atacado. É uma oportunidade de negócio com baixo investimento inicial.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('O Brasil IPTV exige instalação de aplicativo específico?',
         'Não — Brasil IPTV funciona com qualquer aplicativo IPTV popular: IPTV Smarters Pro, TiviMate, GSE Player ou MX Player. Prime IPTV fornece suporte detalhado para configuração em todos os aplicativos disponíveis no mercado.'),
        ('Qual a velocidade de internet necessária para IPTV 4K no Brasil?',
         'Para IPTV 4K no Brasil é recomendado pelo menos 25 Mbps de velocidade de download. Para HD 10 Mbps é suficiente. A tecnologia de bitrate adaptativo do Prime IPTV ajusta automaticamente a qualidade conforme sua velocidade de conexão.'),
        ('Como configurar IPTV Smart TV no Brasil sem TV Box?',
         'Em uma Smart TV Android, acesse a loja de aplicativos, baixe um aplicativo IPTV compatível, insira as credenciais Prime IPTV (URL, usuário, senha via XTREAM ou link M3U) e o serviço fica ativo imediatamente sem nenhum equipamento adicional.'),
        ('Qual a diferença entre IPTV Box e IPTV Smart TV?',
         'Uma IPTV Box é um dispositivo dedicado que adiciona recursos Android a qualquer televisão. IPTV Smart TV usa o sistema operacional já presente em TVs inteligentes. Ambas funcionam com Prime IPTV, porém a Box oferece maior flexibilidade de aplicativos.'),
        ('Quais são os Melhores IPTV para conexões limitadas no Brasil?',
         'Para conexões mais lentas no Brasil, escolha planos que ofereçam bitrate adaptativo e qualidade HD. Prime IPTV ajusta automaticamente a resolução para garantir uma experiência fluida mesmo em conexões de 5 a 10 Mbps.'),
        ('É possível usar IPTV Online no Brasil sem contrato de fidelidade?',
         'Sim — Prime IPTV oferece planos mensais sem fidelidade no Brasil. Você assina pelo período que desejar e pode cancelar a qualquer momento. Também estão disponíveis planos trimestrais e anuais com preços mais vantajosos.'),
    ]
}

# ── PT/PORTUGAL ───────────────────────────────
PAGES['pt/portugal/index.html'] = {
    'title': 'Perguntas <span class="faq2-grad">Frequentes</span>',
    'subtitle': 'Tudo o que precisa saber sobre IPTV Portugal',
    'cta_title': 'Não encontrou a sua resposta?',
    'cta_sub': 'A nossa equipa está disponível no WhatsApp',
    'cta_btn': 'Contactar via WhatsApp',
    'stats_titles': ['Confiança', 'Estabilidade', 'Suporte 24/7', 'Garantido'],
    'stats_subs': ['Portugal confia em nós', 'Qualidade cristalina', 'Sempre disponível', 'Satisfação garantida'],
    'qa': [
        ('O que é o Tuga IPTV e como se diferencia de outras opções?',
         'Tuga IPTV é o termo usado em Portugal para serviços IPTV de qualidade orientados para utilizadores portugueses. Prime IPTV posiciona-se como uma das melhores opções Tuga IPTV com servidores otimizados para a rede portuguesa.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('Como configurar IPTV Windows para ver streaming em Portugal?',
         'No Windows, instale um reprodutor IPTV compatível como VLC, IPTV Smarters ou TiviMate para PC. Introduza o link M3U ou os dados XTREAM IPTV fornecidos pela Prime IPTV após a subscrição e o serviço fica disponível imediatamente.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('O que torna o Portugal IPTV uma escolha confiável?',
         'O Portugal IPTV de qualidade oferece disponibilidade acima de 99 %, servidores próximos dos nós de internet europeus, suporte técnico em português e compatibilidade total com todos os dispositivos usados em Portugal.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('Como configurar XTREAM IPTV no meu dispositivo em Portugal?',
         'Abra a sua aplicação de reprodução IPTV compatível, selecione XTREAM IPTV como tipo de ligação, insira o URL do servidor, o nome de utilizador e a palavra-passe fornecidos pela Prime IPTV. A lista de conteúdos carrega automaticamente em segundos.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('É possível usar IPTV PC para aceder ao IPTV Portugal?',
         'Sim — IPTV PC funciona em Portugal em qualquer computador Windows, Mac ou Linux com um reprodutor compatível instalado. Prime IPTV suporta VLC, TiviMate para PC, IPTV Smarters e qualquer reprodutor com suporte a M3U ou XTREAM.'),
        ('O que distingue o Melhor IPTV em termos de estabilidade em Portugal?',
         'O Melhor IPTV para Portugal usa servidores redundantes em múltiplas localizações europeias, garantindo que em caso de falha de um servidor a ligação é automaticamente redirecionada. Isto assegura uma disponibilidade consistente acima de 99 %.'),
        ('Qual a diferença entre IPTV Box e IPTV Online em Portugal?',
         'IPTV Box é um dispositivo físico que executa o serviço na sua televisão. IPTV Online permite aceder ao serviço diretamente no browser ou em aplicações sem necessidade de hardware adicional. Ambas as opções funcionam com Prime IPTV em Portugal.'),
        ('O Best IPTV Portugal inclui suporte técnico em português?',
         'Sim — Prime IPTV oferece suporte técnico em português para os seus subscritores em Portugal. A nossa equipa está disponível 24/7 via WhatsApp para responder a todas as questões de configuração e resolução de problemas.'),
        ('Que velocidade de internet é recomendada para IPTV Portugal?',
         'Para HD em Portugal recomendamos 10 Mbps, para FHD 15 Mbps e para 4K pelo menos 25 Mbps. As ligações de fibra ótica disponíveis em Portugal garantem velocidades muito superiores, assegurando streaming 4K e 8K sem qualquer interrupção.'),
        ('Como ativar um plano IPTV Portugal via XTREAM IPTV?',
         'Após a subscrição recebe as credenciais XTREAM IPTV por WhatsApp. Abra a sua aplicação de reprodução, selecione XTREAM como tipo de entrada, insira os dados recebidos e o seu Portugal IPTV fica ativo em menos de dois minutos.'),
    ]
}

# ── PT/ANGOLA ─────────────────────────────────
PAGES['pt/angola/index.html'] = {
    'title': 'Perguntas <span class="faq2-grad">Frequentes</span>',
    'subtitle': 'Tudo o que precisa saber sobre IPTV Angola',
    'cta_title': 'Não encontrou a sua resposta?',
    'cta_sub': 'A nossa equipa está disponível no WhatsApp',
    'cta_btn': 'Contactar via WhatsApp',
    'stats_titles': ['Confiança', 'Estabilidade', 'Suporte 24/7', 'Garantido'],
    'stats_subs': ['Angola confia em nós', 'Qualidade cristalina', 'Sempre disponível', 'Satisfação garantida'],
    'qa': [
        ('O que é o IPTV Angola e como funciona tecnicamente?',
         'IPTV Angola é um serviço de transmissão digital de conteúdo via internet que elimina a necessidade de cabo ou satélite. Utiliza protocolos HLS e MPEG-TS para entregar streams em HD, FHD e 4K diretamente ao seu dispositivo.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('Como configurar uma IPTV Box para Angola IPTV?',
         'Numa IPTV Box Android, instale um reprodutor compatível (IPTV Smarters, TiviMate), selecione XTREAM IPTV como tipo de ligação e introduza as credenciais Prime IPTV. O processo demora menos de cinco minutos.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('O IPTV África cobre Angola com boa estabilidade de streaming?',
         'Sim — Prime IPTV oferece IPTV África com servidores otimizados para ligações em Angola. A nossa infraestrutura CDN distribui o tráfego de forma inteligente para garantir a melhor estabilidade possível mesmo em zonas com largura de banda limitada.',
         ['Disponibilidade 99%+', 'HD · FHD · 4K · 8K', 'Suporte 24/7', 'Streaming digital']),
        ('Que velocidade de internet é necessária para IPTV 4K em Angola?',
         'Para IPTV 4K em Angola recomendamos pelo menos 25 Mbps. Para HD 10 Mbps é suficiente. O bitrate adaptativo do Prime IPTV ajusta automaticamente a qualidade conforme a velocidade disponível na sua ligação.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('O IPTV PC funciona bem nas condições de internet de Angola?',
         'Sim — IPTV PC funciona com ligações a partir de 5 Mbps para HD. Prime IPTV usa tecnologia de compressão avançada que mantém a qualidade mesmo em ligações de largura de banda moderada, comuns em Angola.'),
        ('O que são IPTV Streams e como são distribuídos em Angola?',
         'IPTV Streams são fluxos de dados digitais transmitidos em tempo real via internet. Em Angola, o Prime IPTV roteia estes streams através dos servidores mais próximos para minimizar a latência e maximizar a estabilidade da ligação.'),
        ('Como configurar IPTV Smart TV em Angola sem IPTV Box?',
         'Numa Smart TV Android, aceda à loja de aplicações e instale um reprodutor IPTV compatível. Introduza as suas credenciais Prime IPTV usando XTREAM IPTV ou M3U e o serviço fica ativo imediatamente sem necessidade de equipamento adicional.'),
        ('Qual é o Melhor IPTV para os utilizadores de Angola?',
         'O Melhor IPTV para Angola é um serviço com servidores otimizados para África, suporte técnico em português, bitrate adaptativo para lidar com variações de velocidade e planos acessíveis. Prime IPTV preenche todos estes requisitos.'),
        ('É possível usar IPTV Online em Angola a partir de qualquer dispositivo?',
         'Sim — IPTV Online de Prime IPTV é compatível com Smart TV, Android, iOS, PC e IPTV Box. Pode usar as mesmas credenciais em todos os seus dispositivos em Angola sem configurações adicionais.'),
        ('O Angola IPTV oferece planos adaptados à largura de banda disponível?',
         'Sim — Prime IPTV oferece planos Angola IPTV com tecnologia de bitrate adaptativo que ajusta automaticamente a qualidade conforme a sua ligação. Isto garante uma experiência estável mesmo em zonas com velocidades de internet mais limitadas.'),
    ]
}

# ── DE/DEUTSCHLAND ────────────────────────────
PAGES['de/deutschland/index.html'] = {
    'title': 'Häufig gestellte <span class="faq2-grad">Fragen</span>',
    'subtitle': 'Alles, was Sie über IPTV Deutschland wissen müssen',
    'cta_title': 'Keine Antwort gefunden?',
    'cta_sub': 'Unser Team ist auf WhatsApp erreichbar',
    'cta_btn': 'Kontakt via WhatsApp',
    'stats_titles': ['Vertrauen', 'Stabilität', '24/7 Support', 'Garantiert'],
    'stats_subs': ['Deutschland vertraut uns', 'Kristallklare Qualität', 'Immer erreichbar', 'Zufriedenheit garantiert'],
    'qa': [
        ('Was sollte ich beim IPTV Kaufen in Deutschland beachten?',
         'Beim IPTV Kaufen in Deutschland sollten Sie auf Serverstandorte in Europa, garantierte Verfügbarkeit über 99 %, 4K-Qualität, deutschsprachigen Support und transparente Preise ohne versteckte Kosten achten. Prime IPTV erfüllt alle diese Anforderungen.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Was ist ein IPTV Stick und wie unterscheidet er sich von einer IPTV Box?',
         'Ein IPTV Stick (wie Firestick) ist ein kompakter USB-Dongle der direkt in den HDMI-Anschluss Ihres Fernsehers steckt. Eine IPTV Box ist ein vollständiges Android-Gerät mit eigenem Netzteil und bietet mehr Leistung und Speicher.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Wie finde ich den besten IPTV Anbieter in Deutschland?',
         'Den besten IPTV Anbieter in Deutschland erkennen Sie an garantierter Betriebszeit über 99 %, europäischen Serverstandorten, deutschsprachigem Support, 4K-Streaming und klaren Vertragsbedingungen. Prüfen Sie immer verifizierte Kundenbewertungen.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Welche Internetgeschwindigkeit brauche ich für IPTV 4K in Deutschland?',
         'Für stabiles IPTV 4K in Deutschland benötigen Sie mindestens 25 Mbps. HD erfordert ca. 10 Mbps und Full HD ca. 15 Mbps. Deutsche Glasfaseranschlüsse überschreiten diese Werte deutlich und garantieren ein ruckelfreies 4K-Erlebnis.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Kann ich IPTV Online in Deutschland ohne extra Hardware nutzen?',
         'Ja — IPTV Online lässt sich in Deutschland über jeden modernen Browser nutzen. Für ein deutlich besseres Erlebnis empfehlen wir jedoch eine dedizierte App wie TiviMate oder IPTV Smarters mit vollem EPG-Guide und Catch-Up-Funktion.'),
        ('Was ist der Unterschied zwischen IPTV Germany und internationalen Diensten?',
         'IPTV Germany bezieht sich auf Dienste mit Servern nahe den deutschen Internetknoten, was für deutsche Nutzer niedrigere Latenz und bessere Stabilität bietet. Prime IPTV nutzt europäische CDN-Infrastruktur für optimale IPTV Germany-Performance.'),
        ('Wie richte ich meinen IPTV Stick für IPTV Deutschland ein?',
         'Aktivieren Sie auf Ihrem Firestick die Installation aus unbekannten Quellen unter Entwickleroptionen. Installieren Sie TiviMate oder IPTV Smarters, wählen Sie XTREAM IPTV als Verbindungstyp und geben Sie Ihre Prime IPTV-Zugangsdaten ein.'),
        ('Wie viele Geräte kann ich mit einem Best IPTV Plan gleichzeitig nutzen?',
         'Die Anzahl gleichzeitiger Verbindungen hängt vom gewählten Plan ab. Prime IPTV bietet Pläne für ein bis fünf gleichzeitige Streams an. Wählen Sie den Plan der zu Ihrem Haushalt passt.'),
        ('Welche IPTV Box ist am besten für IPTV Deutschland geeignet?',
         'Für IPTV Deutschland empfehlen sich Android-Boxen wie Nvidia Shield, MiBox oder Mecool-Geräte. Diese bieten leistungsstarke Hardware für 4K-Streaming, ausreichend RAM für flüssige App-Performance und Unterstützung aller gängigen IPTV-Anwendungen.'),
        ('Wie aktiviere ich IPTV Deutschland nach dem IPTV Kaufen?',
         'Nach dem IPTV Kaufen erhalten Sie Ihre Zugangsdaten per WhatsApp oder E-Mail innerhalb weniger Minuten. Installieren Sie eine kompatible Player-App, geben Sie URL, Benutzername und Passwort ein und IPTV Deutschland ist sofort verfügbar.'),
    ]
}

# ── DE/ÖSTERREICH ─────────────────────────────
PAGES['de/oesterreich/index.html'] = {
    'title': 'Häufig gestellte <span class="faq2-grad">Fragen</span>',
    'subtitle': 'Alles, was Sie über IPTV Österreich wissen müssen',
    'cta_title': 'Keine Antwort gefunden?',
    'cta_sub': 'Unser Team ist auf WhatsApp erreichbar',
    'cta_btn': 'Kontakt via WhatsApp',
    'stats_titles': ['Vertrauen', 'Stabilität', '24/7 Support', 'Garantiert'],
    'stats_subs': ['Österreich vertraut uns', 'Kristallklare Qualität', 'Immer erreichbar', 'Zufriedenheit garantiert'],
    'qa': [
        ('Was bietet IPTV Österreich im Vergleich zu deutschen Diensten?',
         'IPTV Österreich ist auf die österreichische Netzinfrastruktur optimiert und nutzt Server nahe den Wiener Internetknoten für minimale Latenz. Prime IPTV bietet österreichischen Nutzern dieselbe Premium-Qualität wie in Deutschland.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Wie finde ich einen zuverlässigen IPTV Anbieter in Wien?',
         'Einen zuverlässigen IPTV Anbieter in Wien erkennen Sie an garantierter Uptime über 99 %, deutschsprachigem Support, 4K-Streaming-Qualität und transparenten Preisen. Verifizierte Kundenbewertungen helfen bei der Entscheidung.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Was ist XTREAM IPTV und wie richte ich es in Österreich ein?',
         'XTREAM IPTV ist ein API-basiertes Anmeldeverfahren (Server-URL + Benutzername + Passwort) das mehr Stabilität und integriertes EPG bietet als ein M3U-Link. In Ihrer Player-App wählen Sie XTREAM IPTV und geben die erhaltenen Zugangsdaten ein.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Welche Verbindungsgeschwindigkeit benötige ich für 4K IPTV in Österreich?',
         'Für 4K IPTV in Österreich benötigen Sie mindestens 25 Mbps. HD läuft ab 10 Mbps problemlos. Österreichische Glasfaserleitungen bieten 100 Mbps bis 1 Gbps — mehr als genug für flüssiges 8K-Streaming.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Bietet IPTV Wien spezifische regionale Streaming-Vorteile?',
         'IPTV Wien profitiert von der hohen Glasfaserdichte und modernen Netzinfrastruktur in Wien. Nutzer in der Bundeshauptstadt erleben durch kurze Leitungswege besonders niedrige Latenz und stabile Verbindungen.'),
        ('Was ist IPTV Balkan und für welche Nutzergruppen ist es gedacht?',
         'IPTV Balkan richtet sich an Nutzer in Österreich die digitale Inhalte aus dem Balkanraum konsumieren möchten. Prime IPTV bietet Zugänge für die gesamte Balkanregion mit hochwertigen Streams in HD und 4K.'),
        ('Wie unterscheidet sich IPTV Premium von Standard-Paketen in Österreich?',
         'IPTV Premium in Österreich umfasst mehr gleichzeitige Verbindungen, 4K und 8K Streaming-Qualität, prioritären Support und Catch-Up bis 7 Tage. Standard-Pakete eignen sich für Einzelnutzer mit grundlegendem Bedarf.'),
        ('Was ist IPTV German und welche Inhaltstypen umfasst es?',
         'IPTV German bezeichnet digitale Streaming-Dienste mit Fokus auf deutschsprachige Inhalte. Prime IPTV bietet IPTV German mit HD- und 4K-Streams für alle kompatiblen Geräte in Österreich und Deutschland.'),
        ('Wie viele simultane Verbindungen erlaubt ein IPTV Provider Plan?',
         'Die Anzahl simultaner Verbindungen hängt vom gewählten Plan ab. Prime IPTV als IPTV Provider bietet österreichischen Nutzern Pläne von einer bis zu fünf gleichzeitigen Verbindungen für alle Haushaltsgrößen.'),
        ('Wie kaufe ich IPTV Österreich und aktiviere es sicher?',
         'Kontaktieren Sie Prime IPTV über WhatsApp, wählen Sie Ihren Plan und schließen Sie die sichere Zahlung ab. Innerhalb weniger Minuten erhalten Sie Ihre XTREAM IPTV-Zugangsdaten und können sofort starten.'),
    ]
}

# ── DE/SCHWEIZ ────────────────────────────────
PAGES['de/schweiz/index.html'] = {
    'title': 'Häufig gestellte <span class="faq2-grad">Fragen</span>',
    'subtitle': 'Alles, was Sie über IPTV Schweiz wissen müssen',
    'cta_title': 'Keine Antwort gefunden?',
    'cta_sub': 'Unser Team ist auf WhatsApp erreichbar',
    'cta_btn': 'Kontakt via WhatsApp',
    'stats_titles': ['Vertrauen', 'Stabilität', '24/7 Support', 'Garantiert'],
    'stats_subs': ['Die Schweiz vertraut uns', 'Kristallklare Qualität', 'Immer erreichbar', 'Zufriedenheit garantiert'],
    'qa': [
        ('Was bedeutet IPTV Schweiz und was bietet es?',
         'IPTV Schweiz ist ein digitaler Streaming-Dienst der Inhalte über das Internet statt über Kabel oder Satellit liefert. Prime IPTV bietet schweizer Nutzern 99%+ Uptime, 4K-Qualität und 24/7-Support in Deutsch, Französisch und Italienisch.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Was ist der Unterschied zwischen IPTV Suisse und IPTV Schweiz?',
         'IPTV Suisse ist der französischsprachige Begriff für dasselbe Angebot — IPTV Schweiz auf Deutsch. Der Dienst selbst ist identisch. Prime IPTV bietet mehrsprachigen Support für alle Sprachregionen der Schweiz.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Welche IPTV Box ist für die Schweiz empfehlenswert?',
         'Für die Schweiz empfehlen sich leistungsstarke Android-Boxen wie Nvidia Shield oder MiBox sowie der Amazon Firestick. Alle diese Geräte unterstützen HD, FHD und 4K-Streaming und sind vollständig mit Prime IPTV kompatibel.',
         ['Verfügbarkeit 99%+', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitales Streaming']),
        ('Welche Mindestgeschwindigkeit brauche ich für IPTV 4K in der Schweiz?',
         'Für IPTV 4K in der Schweiz benötigen Sie mindestens 25 Mbps. Schweizer Glasfaserleitungen erreichen typischerweise 300 Mbps bis 1 Gbps — weit mehr als für 8K-Streaming benötigt wird.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Wie funktioniert IPTV Streaming technisch in der Schweiz?',
         'IPTV Streaming kodiert digitale Inhalte auf unseren Servern und überträgt sie in Echtzeit über das Internet an Ihr Gerät. Unser europäisches CDN-Netzwerk sorgt für minimale Latenz und stabile Verbindungen für schweizer Nutzer.'),
        ('Was umfasst ein typisches IPTV Abo in der Schweiz?',
         'Ein typisches IPTV Abo bei Prime IPTV für die Schweiz umfasst HD/FHD/4K-Streaming-Qualität, eine festgelegte Anzahl simultaner Verbindungen, 24/7-Support und Catch-Up-Funktionalität — ohne lange Vertragsbindung.'),
        ('Kann ich Premium IPTV in der Schweiz über IPTV Online nutzen?',
         'Ja — Premium IPTV lässt sich in der Schweiz über IPTV Online direkt im Browser nutzen. Für optimale Performance empfehlen wir eine dedizierte App wie TiviMate oder IPTV Smarters die mehr Funktionen und bessere Stabilität bieten.'),
        ('Wie finde ich den richtigen IPTV Anbieter für die Schweiz?',
         'Den richtigen IPTV Anbieter für die Schweiz finden Sie durch Vergleich von Uptime-Garantien, Sprachunterstützung (Deutsch/Französisch/Italienisch), 4K-Qualität, Preistransparenz und verifizierten Kundenbewertungen.'),
        ('Wie kaufe ich ein IPTV-Angebot für die Schweiz sicher?',
         'Kontaktieren Sie Prime IPTV über WhatsApp oder unsere Website, wählen Sie Ihren Plan und führen Sie die sichere Zahlung durch. Ihre XTREAM IPTV-Zugangsdaten werden innerhalb weniger Minuten übermittelt.'),
        ('Welche Geräte unterstützen IPTV Schweiz?',
         'IPTV Schweiz von Prime IPTV unterstützt Smart TV (Android, Samsung, LG), Android-Boxen, Firestick, iPhone, iPad, Android-Smartphones und Windows/Mac-Computer — also praktisch alle modernen Geräte ohne zusätzliche Hardware.'),
    ]
}

# ── TR/TÜRKİYE ────────────────────────────────
PAGES['tr/turkiye/index.html'] = {
    'title': 'Sıkça Sorulan <span class="faq2-grad">Sorular</span>',
    'subtitle': 'IPTV Türkiye hakkında bilmeniz gereken her şey',
    'cta_title': 'Cevabınızı bulamadınız mı?',
    'cta_sub': 'Ekibimiz WhatsApp\'ta hazır',
    'cta_btn': 'WhatsApp ile iletişime geç',
    'stats_titles': ['Güvenilir', 'Kararlı', '7/24 Destek', 'Garantili'],
    'stats_subs': ['Türkiye güveniyor', 'Kristal net kalite', 'Her zaman ulaşılabilir', 'Memnuniyet garantili'],
    'qa': [
        ('En İyi IPTV\'yi Türkiye\'de seçerken nelere dikkat etmeliyim?',
         'Türkiye\'de En İyi IPTV seçerken sunucu kararlılığı (%99+ uptime), 4K kalite desteği, Türkçe teknik destek ve rekabetçi fiyatlandırmaya dikkat edin. Prime IPTV bu kriterlerin tamamını karşılamaktadır.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Al sürecinde doğru planı nasıl seçerim?',
         'IPTV Al sürecinde eş zamanlı bağlantı sayısını, desteklenen çözünürlükleri ve abonelik süresini değerlendirin. Bireysel kullanım için tek bağlantılı planlar, büyük haneler için çoklu bağlantı planları daha uygundur.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Deneme süresi nasıl talep edilir?',
         'IPTV Deneme için WhatsApp üzerinden Prime IPTV ile iletişime geçmeniz yeterlidir. Deneme süresinde hizmetin kalitesini ve kararlılığını kendi cihazlarınızda ve internet bağlantınızda test edebilirsiniz.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Fiyat karşılaştırması yaparken hangi kriterlere bakmalıyım?',
         'IPTV Fiyat karşılaştırmasında yalnızca ücrete değil; sunucu kararlılığına, desteklenen çözünürlüklere, eş zamanlı bağlantı sayısına ve teknik destek kalitesine de bakın. Çok düşük fiyatlı teklifler genellikle kararsız altyapı anlamına gelir.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('5G IPTV ne demektir ve kullanıcılara nasıl avantaj sağlar?',
         '5G IPTV, 5G mobil ağlar üzerinden kesintisiz dijital yayın yapılmasına olanak tanır. Yüksek bant genişliği ve düşük gecikme süresi sayesinde 4K ve 8K kalitede akıcı izleme deneyimi sunar.'),
        ('XTREAM IPTV ile M3U arasındaki temel fark nedir?',
         'XTREAM IPTV, sunucu URL\'si ve kullanıcı adı/şifre ile çalışan API tabanlı bir giriş sistemidir; yerleşik program kılavuzu ve daha yüksek kararlılık sunar. M3U ise basit bir çalma listesi dosyasıdır. Her iki format da Prime IPTV tarafından desteklenmektedir.'),
        ('IPTV Paketleri arasındaki temel farklar nelerdir?',
         'IPTV Paketleri arasındaki başlıca farklar: eş zamanlı bağlantı sayısı, abonelik süresi (aylık/yıllık), desteklenen çözünürlükler (HD/4K/8K) ve öncelikli destek erişimidir. Haneye uygun paketi seçmek en verimli çözümdür.'),
        ('IPTV Satın Al işleminden sonra aktivasyon nasıl yapılır?',
         'IPTV Satın Al işleminin ardından birkaç dakika içinde bağlantı bilgileriniz WhatsApp ile iletilir. Uyumlu bir oynatıcıya (TiviMate veya IPTV Smarters) bilgilerinizi girin ve hemen izlemeye başlayın.'),
        ('Bir IPTV Abonelik Türkiye\'de kaç cihazda aktif olabilir?',
         'Prime IPTV\'nin IPTV Abonelik planlarında seçtiğiniz pakete göre aynı anda 1 ila 5 cihaz aktif olabilir. Büyük haneler için çoklu bağlantı paketleri en uygun seçenektir.'),
        ('IPTV Pro standart IPTV Türkiye paketlerinden nasıl farklılaşır?',
         'IPTV Pro, standart planlara kıyasla daha fazla eş zamanlı bağlantı, tam 4K ve 8K kalite erişimi, öncelikli teknik destek ve catch-up işlevselliği içerir. Maksimum kalite ve esneklik bekleyen kullanıcılar için idealdir.'),
    ]
}

# ── TR/KIBRIS ─────────────────────────────────
PAGES['tr/kibris/index.html'] = {
    'title': 'Sıkça Sorulan <span class="faq2-grad">Sorular</span>',
    'subtitle': 'IPTV Kıbrıs hakkında bilmeniz gereken her şey',
    'cta_title': 'Cevabınızı bulamadınız mı?',
    'cta_sub': 'Ekibimiz WhatsApp\'ta hazır',
    'cta_btn': 'WhatsApp ile iletişime geç',
    'stats_titles': ['Güvenilir', 'Kararlı', '7/24 Destek', 'Garantili'],
    'stats_subs': ['Kıbrıs güveniyor', 'Kristal net kalite', 'Her zaman ulaşılabilir', 'Memnuniyet garantili'],
    'qa': [
        ('Kıbrıs\'ta En İyi IPTV hizmetini nasıl bulabilirim?',
         'Kıbrıs\'ta En İyi IPTV bulmak için sunucu kararlılığı (%99+), 4K kalite, Türkçe destek ve şeffaf fiyatlandırmayı karşılaştırın. Prime IPTV, Kıbrıs kullanıcıları için Avrupa CDN altyapısıyla optimize edilmiştir.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Al sürecinde Kıbrıs kullanıcıları nelere dikkat etmeli?',
         'Kıbrıs\'ta IPTV Al sürecinde internet altyapınıza uygun kalite seçeneklerini, desteklenen cihazları ve teknik destek erişilebilirliğini değerlendirin. Prime IPTV, Kıbrıs\'taki internet koşullarına uygun esnek çözümler sunar.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('XTREAM IPTV Kıbrıs\'ta nasıl yapılandırılır?',
         'Uyumlu bir oynatıcı (IPTV Smarters veya TiviMate) açın, bağlantı türü olarak XTREAM IPTV\'yi seçin, ardından Prime IPTV\'den aldığınız sunucu URL\'si, kullanıcı adı ve şifreyi girin. İçerik listesi otomatik olarak yüklenir.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('4K IPTV için Kıbrıs\'ta ne kadar internet hızına ihtiyaç var?',
         '4K IPTV için en az 25 Mbps gereklidir. HD kalite için 10 Mbps yeterlidir. Kıbrıs\'ta fiber internet altyapısı bu gereksinimleri rahatlıkla karşılar ve Prime IPTV\'nin uyarlamalı bit hızı teknolojisi bağlantınızı optimize eder.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Premium IPTV ile standart plan arasındaki fark nedir?',
         'Premium IPTV planı daha fazla eş zamanlı bağlantı, 4K ve 8K tam erişim, öncelikli teknik destek ve catch-up işlevselliği içerir. Standart plan ise bireysel kullanıcılar için temel ihtiyaçları karşılayacak şekilde tasarlanmıştır.'),
        ('IPTV Fiyat aralıkları Kıbrıs\'ta nasıldır?',
         'Prime IPTV\'nin Kıbrıs IPTV Fiyat aralıkları seçilen bağlantı sayısına ve abonelik süresine göre değişmektedir. Aylık planlardan yıllık planlara kadar farklı seçenekler sunulmakta olup yıllık planlar daha avantajlı fiyat sunar.'),
        ('IPTV Paketleri arasında seçim yaparken nelere bakmalıyım?',
         'IPTV Paketleri seçerken hanedeki kullanıcı sayısını, eş zamanlı izleme ihtiyacını ve tercih ettiğiniz kalite seviyesini göz önünde bulundurun. Prime IPTV, Kıbrıs kullanıcıları için bireysel ve aile planları sunmaktadır.'),
        ('IPTV Satın Al sonrası aktivasyon adımları nelerdir?',
         'IPTV Satın Al işleminin ardından birkaç dakika içinde WhatsApp üzerinden bağlantı bilgileriniz iletilir. Uyumlu bir oynatıcı uygulamasına (TiviMate, IPTV Smarters) girişlerinizi yaparak hemen izlemeye başlayabilirsiniz.'),
        ('Bir IPTV Abonelik Kıbrıs\'ta kaç cihazda kullanılabilir?',
         'Seçtiğiniz plana bağlı olarak Prime IPTV aboneliğinizi Kıbrıs\'ta aynı anda 1 ila 5 cihazda aktif olarak kullanabilirsiniz. Çoklu bağlantı planları tüm aile üyelerinin eş zamanlı kullanımına olanak tanır.'),
        ('IPTV Pro Kıbrıs kullanıcıları için ne avantajlar sunar?',
         'IPTV Pro, Kıbrıs kullanıcılarına daha fazla eş zamanlı bağlantı, tam 4K ve 8K kalite erişimi, öncelikli teknik destek ve 7 güne kadar catch-up işlevselliği sunar. Maksimum kalite ve rahatlık arayanlar için en uygun seçenektir.'),
    ]
}

# ── TR/ALMANYA ────────────────────────────────
PAGES['tr/almanya/index.html'] = {
    'title': 'Sıkça Sorulan <span class="faq2-grad">Sorular</span>',
    'subtitle': 'Almanya\'daki IPTV hizmetleri hakkında bilmeniz gerekenler',
    'cta_title': 'Cevabınızı bulamadınız mı?',
    'cta_sub': 'Ekibimiz WhatsApp\'ta hazır',
    'cta_btn': 'WhatsApp ile iletişime geç',
    'stats_titles': ['Güvenilir', 'Kararlı', '7/24 Destek', 'Garantili'],
    'stats_subs': ['Almanya\'dan güven', 'Kristal net kalite', 'Her zaman ulaşılabilir', 'Memnuniyet garantili'],
    'qa': [
        ('IPTV Almanya ile yerel Alman IPTV servisleri arasındaki fark nedir?',
         'IPTV Almanya, Almanya\'daki Türk kullanıcıların ihtiyaçlarına yönelik olarak optimize edilmiş bir hizmettir. Alman CDN altyapısı sayesinde düşük gecikme süresi ve yüksek bant genişliği ile HD ve 4K kalitede dijital içerik sunar.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('Almanya IPTV kurarken hangi cihazları kullanabilirim?',
         'Almanya\'da IPTV için Smart TV, Android box, Firestick, iPhone, iPad ve Windows/Mac bilgisayar kullanabilirsiniz. Prime IPTV tüm bu cihazlarla uyumludur ve eksiksiz Türkçe kurulum desteği sunar.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Stick mi yoksa IPTV Box mi — Almanya için hangisi daha iyi?',
         'Almanya\'da IPTV Stick (Firestick gibi) kompakt ve taşınabilir olup kurulumu çok kolaydır. IPTV Box ise daha güçlü donanım ve daha fazla depolama sunar. Her ikisi de Prime IPTV ile mükemmel çalışmaktadır.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Deutschland\'ı Türk kullanıcılar nasıl aktive eder?',
         'WhatsApp üzerinden Prime IPTV ile iletişime geçin, planınızı seçin ve ödemenizi tamamlayın. Birkaç dakika içinde XTREAM IPTV bağlantı bilgileriniz iletilir. Uyumlu bir oynatıcıya bilgilerinizi girerek hemen izlemeye başlayabilirsiniz.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('IPTV 4K için Almanya\'da ne kadar internet hızı gereklidir?',
         '4K IPTV için en az 25 Mbps gereklidir. Almanya\'daki fiber altyapısı genellikle 100 Mbps ile 1 Gbps arasında hız sunar; bu da akıcı 4K ve 8K izleme deneyimi için fazlasıyla yeterlidir.'),
        ('IPTV Kaufen Almanya\'da nasıl yapılır, hangi adımlar izlenmeli?',
         'IPTV Kaufen için WhatsApp üzerinden Prime IPTV\'ye ulaşın. Tercih ettiğiniz paketi seçin, ödemenizi gerçekleştirin ve bağlantı bilgilerinizi alın. Tüm süreç online olup sadece birkaç dakika sürer.'),
        ('IPTV Anbieter seçerken Almanya\'daki Türk kullanıcılar nelere dikkat etmeli?',
         'Almanya\'daki Türk kullanıcılar IPTV Anbieter seçerken Türkçe destek sunulup sunulmadığını, sunucu kararlılığını ve Almanya\'ya yakın CDN altyapısını öncelikli olarak değerlendirmelidir. Prime IPTV bu kriterlerin tamamını karşılamaktadır.'),
        ('IPTV Online Almanya\'da mobil cihazlarda çalışır mı?',
         'Evet — Prime IPTV\'nin IPTV Online hizmeti Almanya\'daki Android ve iOS cihazlarda sorunsuz çalışır. Aynı bağlantı bilgilerinizi tüm mobil cihazlarınızda kullanarak her yerden izleyebilirsiniz.'),
        ('IPTV Al işlemi Almanya\'dan nasıl gerçekleştirilir?',
         'Almanya\'dan IPTV Al işlemi WhatsApp üzerinden kolayca yapılabilir. Prime IPTV ile iletişime geçin, plan seçiminizi bildirin, ödemenizi tamamlayın ve bağlantı bilgilerinizi alarak hemen kullanmaya başlayın.'),
        ('IPTV Box Almanya için hangi modeller önerilir?',
         'Almanya\'da IPTV Box olarak Nvidia Shield (en güçlü seçenek), MiBox S (uygun fiyatlı) ve Mecool serisi (4K destekli) popüler seçeneklerdir. Tüm bu modeller Prime IPTV ile tam uyumlu olup 4K kalitede mükemmel performans sunar.'),
    ]
}

# ── TR/AZERBAYCAN ─────────────────────────────
PAGES['tr/azerbaycan/index.html'] = {
    'title': 'Sıkça Sorulan <span class="faq2-grad">Sorular</span>',
    'subtitle': 'IPTV Azerbaycan hakkında bilmeniz gereken her şey',
    'cta_title': 'Cevabınızı bulamadınız mı?',
    'cta_sub': 'Ekibimiz WhatsApp\'ta hazır',
    'cta_btn': 'WhatsApp ile iletişime geç',
    'stats_titles': ['Güvenilir', 'Kararlı', '7/24 Destek', 'Garantili'],
    'stats_subs': ['Azerbaycan güveniyor', 'Kristal net kalite', 'Her zaman ulaşılabilir', 'Memnuniyet garantili'],
    'qa': [
        ('IPTV Azerbaycan hizmeti teknik açıdan nasıl çalışır?',
         'IPTV Azerbaycan, HLS ve MPEG-TS protokollerini kullanarak dijital içeriği internet üzerinden doğrudan cihazınıza iletir. Prime IPTV, Azerbaycan kullanıcıları için Avrupa ve bölgesel CDN altyapısından yararlanır.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('Azerbaycan\'da En İyi IPTV nasıl seçilir?',
         'Azerbaycan\'da En İyi IPTV seçerken sunucu kararlılığı, desteklenen çözünürlükler, eş zamanlı bağlantı sayısı, Türkçe/Azerbaycan dili desteği ve fiyat şeffaflığını değerlendirin. Prime IPTV bu kriterlerin tümünü karşılar.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Al işlemi Azerbaycan\'da nasıl yapılır?',
         'Azerbaycan\'da IPTV Al için WhatsApp üzerinden Prime IPTV ile iletişime geçin. Tercih ettiğiniz planı seçin, güvenli ödeme yapın ve birkaç dakika içinde bağlantı bilgilerinizi alarak hemen izlemeye başlayın.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Fiyat seçenekleri Azerbaycan kullanıcıları için nelerdir?',
         'Prime IPTV\'nin IPTV Fiyat seçenekleri aylık, üç aylık ve yıllık planları kapsamaktadır. Uzun vadeli abonelikler daha uygun maliyetlidir. Azerbaycan\'daki kullanıcı sayısına ve ihtiyaçlara göre esnek paketler mevcuttur.',
         ['%99+ Uptime', 'HD · FHD · 4K · 8K', '7/24 Destek', 'Dijital Yayın']),
        ('IPTV Satın Al sonrası kurulum adımları nelerdir?',
         'IPTV Satın Al işleminin ardından XTREAM IPTV bağlantı bilgileriniz WhatsApp ile iletilir. Uyumlu bir oynatıcı (TiviMate veya IPTV Smarters) indirin, bilgilerinizi girin ve içerik listeniz otomatik olarak yüklenir.'),
        ('IPTV 4K Azerbaycan\'daki internet altyapısıyla uyumlu mu?',
         '4K IPTV için 25 Mbps bağlantı hızı yeterlidir. Azerbaycan\'ın büyük şehirlerinde fiber internet altyapısı bu gereksinimi karşılamaktadır. Prime IPTV\'nin uyarlamalı bit hızı teknolojisi daha düşük hızlarda da kaliteyi optimize eder.'),
        ('Bir IPTV Abonelik Azerbaycan\'da kaç cihazda kullanılabilir?',
         'Prime IPTV IPTV Abonelik planları Azerbaycan\'da aynı anda 1 ila 5 cihazda aktif olarak kullanılabilir. Hane büyüklüğüne göre en uygun çoklu bağlantı planını seçebilirsiniz.'),
        ('IPTV Premium ile IPTV Pro arasındaki fark nedir?',
         'IPTV Premium temel premium özellikleri (4K, kararlı sunucular, 24/7 destek) sunarken IPTV Pro daha fazla eş zamanlı bağlantı, catch-up işlevselliği ve öncelikli destek hizmetini içermektedir. Her ikisi de Azerbaycan kullanıcıları için uygundur.'),
        ('IPTV Online Azerbaycan\'da hangi cihazlarla kullanılabilir?',
         'IPTV Online Prime IPTV hizmeti Azerbaycan\'da Android telefon/tablet, iPhone, iPad, Smart TV, PC (Windows/Mac) ve Firestick ile sorunsuz çalışır. Tüm cihazlarda aynı giriş bilgilerini kullanabilirsiniz.'),
        ('IPTV Pro Azerbaycan kullanıcılarına ne avantajlar sağlar?',
         'IPTV Pro Azerbaycan kullanıcılarına daha fazla eş zamanlı bağlantı hakkı, tam 4K ve 8K kaliteye erişim, 7 güne kadar catch-up ve öncelikli teknik destek gibi avantajlar sunar. Kaliteyi ön planda tutan kullanıcılar için idealdir.'),
    ]
}

# ── IT/ITALIA ─────────────────────────────────
PAGES['it/italia/index.html'] = {
    'title': 'Domande <span class="faq2-grad">Frequenti</span>',
    'subtitle': 'Tutto quello che devi sapere su IPTV Italia',
    'cta_title': 'Non hai trovato la risposta?',
    'cta_sub': 'Il nostro team è su WhatsApp',
    'cta_btn': 'Contattaci via WhatsApp',
    'stats_titles': ['Affidabilità', 'Stabilità', 'Supporto 24/7', 'Garantito'],
    'stats_subs': ['L\'Italia si fida di noi', 'Qualità cristallina', 'Sempre disponibile', 'Soddisfazione garantita'],
    'qa': [
        ('Cosa sono gli IPTV Stream Italiani e come funzionano?',
         'Gli IPTV Stream Italiani sono flussi digitali distribuiti via internet che permettono di seguire contenuti in HD, FHD e 4K senza bisogno di antenna o decoder tradizionale. Prime IPTV li distribuisce tramite infrastruttura CDN europea ad alta disponibilità.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Come si configura IPTV Android in Italia?',
         'Su Android installa un\'app IPTV compatibile (IPTV Smarters Pro, TiviMate o GSE Player), seleziona XTREAM IPTV come tipo di connessione, inserisci le credenziali Prime IPTV e la tua lista di contenuti viene caricata automaticamente in pochi secondi.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Qual è il Miglior IPTV Italia per qualità e stabilità?',
         'Il Miglior IPTV Italia unisce un uptime dei server superiore al 99 %, qualità di streaming fino a 8K, infrastruttura CDN con nodi in Europa e supporto tecnico continuo in italiano. Prime IPTV soddisfa tutti questi requisiti.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Cos\'è IPTV ITA e a chi si rivolge?',
         'IPTV ITA è il termine usato dagli utenti italiani per indicare servizi IPTV ottimizzati per la rete italiana. Si rivolge a chi cerca streaming digitale stabile, compatibile con tutti i dispositivi moderni e con supporto in italiano.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Come funziona XTREAM IPTV su dispositivi Android in Italia?',
         'XTREAM IPTV su Android funziona tramite login API: inserisci l\'URL del server, il nome utente e la password nella tua app player. La lista si aggiorna automaticamente e offre una stabilità nettamente superiore rispetto a un semplice file M3U.'),
        ('Come funziona tecnicamente l\'IPTV Streaming in Italia?',
         'L\'IPTV Streaming codifica i contenuti digitali sui nostri server europei e li trasmette in tempo reale al tuo dispositivo tramite i protocolli HLS o MPEG-TS. Il nostro CDN garantisce latenza minima per tutti gli utenti italiani.'),
        ('Cosa include un Abbonamento IPTV Italia?',
         'Un Abbonamento IPTV Italia di Prime IPTV include accesso a stream digitali in HD/FHD/4K, un numero di connessioni simultanee in base al piano, catch-up fino a 7 giorni, supporto tecnico 24/7 e compatibilità con tutti i dispositivi.'),
        ('IPTV Pro è compatibile con tutti i dispositivi in Italia?',
         'Sì — IPTV Pro Italia è compatibile con Smart TV Android, box Android, Firestick, iPhone, iPad e PC Windows/Mac. Prime IPTV fornisce istruzioni di configurazione dettagliate per tutti i sistemi operativi e dispositivi.'),
        ('Come si configura IPTV Online in Italia senza decoder?',
         'Per IPTV Online senza decoder in Italia, installa un\'app player compatibile su qualsiasi Smart TV, smartphone o computer. Con le credenziali Prime IPTV (XTREAM o M3U) accedi istantaneamente senza alcuna attrezzatura aggiuntiva.'),
        ('Quale velocità internet serve per IPTV Italia in 4K?',
         'Per IPTV Italia in 4K servono almeno 25 Mbps. Per HD 10 Mbps sono sufficienti. Le connessioni fibra in Italia raggiungono 200 Mbps e oltre, garantendo un\'esperienza 4K e 8K completamente fluida senza interruzioni.'),
    ]
}

# ── IT/SVIZZERA ───────────────────────────────
PAGES['it/svizzera/index.html'] = {
    'title': 'Domande <span class="faq2-grad">Frequenti</span>',
    'subtitle': 'Tutto quello che devi sapere su IPTV Svizzera',
    'cta_title': 'Non hai trovato la risposta?',
    'cta_sub': 'Il nostro team è su WhatsApp',
    'cta_btn': 'Contattaci via WhatsApp',
    'stats_titles': ['Affidabilità', 'Stabilità', 'Supporto 24/7', 'Garantito'],
    'stats_subs': ['La Svizzera si fida di noi', 'Qualità cristallina', 'Sempre disponibile', 'Soddisfazione garantita'],
    'qa': [
        ('Cosa differenzia IPTV Svizzera da IPTV Suisse e IPTV Schweiz?',
         'IPTV Svizzera (italiano), IPTV Suisse (francese) e IPTV Schweiz (tedesco) si riferiscono allo stesso servizio nelle tre lingue ufficiali della Svizzera. L\'infrastruttura Prime IPTV è identica per tutte le regioni linguistiche con supporto multilingue.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Come si configura un IPTV Box per la Svizzera?',
         'Su qualsiasi IPTV Box Android installa un\'app compatibile (TiviMate o IPTV Smarters), seleziona XTREAM IPTV come tipo di connessione e inserisci le credenziali Prime IPTV. Il servizio diventa operativo in meno di cinque minuti.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Quale velocità internet serve per IPTV 4K in Svizzera?',
         'Per IPTV 4K in Svizzera sono necessari almeno 25 Mbps. Le connessioni fibra svizzere raggiungono tipicamente 300 Mbps - 1 Gbps, più che sufficienti per streaming 4K e 8K perfettamente fluido senza buffering.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Cos\'è un IPTV Abo e cosa include?',
         'IPTV Abo (abbreviazione tedesca di abbonamento) indica il piano di abbonamento IPTV. Include accesso agli stream digitali, qualità HD/FHD/4K, un numero definito di connessioni simultanee e supporto tecnico per la durata del piano.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Come funziona l\'IPTV Streaming nelle zone alpine della Svizzera?',
         'L\'IPTV Streaming funziona su qualsiasi connessione internet, anche nelle zone alpine. Con almeno 10 Mbps puoi guardare in HD. La nostra tecnologia a bitrate adattivo garantisce la qualità migliore disponibile in base alla tua connessione.'),
        ('IPTV Online in Svizzera funziona senza app dedicata?',
         'Sì, alcuni player IPTV Online funzionano direttamente nel browser. Tuttavia per la migliore esperienza in Svizzera raccomandiamo un\'app dedicata come TiviMate che offre guida elettronica completa, catch-up e riproduzione fluida in 4K.'),
        ('Cosa offre Premium IPTV rispetto a un piano base in Svizzera?',
         'Premium IPTV in Svizzera offre più connessioni simultanee, qualità fino a 8K, supporto tecnico prioritario in italiano/francese/tedesco e funzione catch-up. I piani base sono ideali per utenti singoli con esigenze standard.'),
        ('Come si attiva un Abbonamento IPTV per la Svizzera?',
         'Dopo aver scelto il piano contatta Prime IPTV via WhatsApp o sito web, completa il pagamento sicuro e ricevi le credenziali XTREAM IPTV in pochi minuti. L\'attivazione è immediata e non richiede tecnici o hardware aggiuntivo.'),
        ('Quante connessioni simultanee permette un piano IPTV Svizzera?',
         'I piani Prime IPTV Svizzera permettono da una a cinque connessioni simultanee. Per famiglie con più televisori o schermi che necessitano di streaming contemporaneo, i piani multi-connessione sono la soluzione più efficiente.'),
        ('IPTV Box è necessario o una Smart TV è sufficiente in Svizzera?',
         'Una Smart TV Android è più che sufficiente per IPTV Svizzera. L\'IPTV Box dedicato è consigliato solo se il tuo televisore è datato o non supporta le app IPTV. Prime IPTV funziona ugualmente bene su entrambe le soluzioni.'),
    ]
}

# ── IT/GERMANIA ───────────────────────────────
PAGES['it/germania/index.html'] = {
    'title': 'Domande <span class="faq2-grad">Frequenti</span>',
    'subtitle': 'Tutto quello che devi sapere su IPTV Germania',
    'cta_title': 'Non hai trovato la risposta?',
    'cta_sub': 'Il nostro team è su WhatsApp',
    'cta_btn': 'Contattaci via WhatsApp',
    'stats_titles': ['Affidabilità', 'Stabilità', 'Supporto 24/7', 'Garantito'],
    'stats_subs': ['La Germania si fida di noi', 'Qualità cristallina', 'Sempre disponibile', 'Soddisfazione garantita'],
    'qa': [
        ('Cosa sono gli IPTV Stream Italiani disponibili in Germania?',
         'Gli IPTV Stream Italiani in Germania sono flussi digitali in lingua italiana accessibili dalla Germania tramite Prime IPTV. Sono distribuiti via internet usando la nostra infrastruttura CDN europea per latenza minima e massima stabilità.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Come si configura un IPTV Stick per IPTV Germania?',
         'Sul tuo Firestick attiva l\'installazione da origini sconosciute nelle impostazioni sviluppatore, installa IPTV Smarters o TiviMate, seleziona XTREAM IPTV come tipo di connessione e inserisci le credenziali Prime IPTV. Il servizio è attivo in meno di cinque minuti.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Qual è la differenza tra IPTV Deutschland e IPTV Germania?',
         'IPTV Deutschland è il termine tedesco e IPTV Germania è quello italiano per lo stesso servizio. Prime IPTV offre IPTV per utenti italiani residenti in Germania con supporto in italiano e infrastruttura ottimizzata per la rete tedesca.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Come si sceglie il giusto IPTV Anbieter in Germania?',
         'Per scegliere il giusto IPTV Anbieter in Germania valuta uptime garantito sopra il 99 %, qualità 4K, supporto in italiano, prezzi trasparenti e recensioni verificate. Prime IPTV è la scelta naturale per gli italiani residenti in Germania.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('IPTV 4K funziona bene sulle reti tedesche?',
         'Sì — le reti tedesche offrono ampia banda con fibra che raggiunge facilmente 100 Mbps - 1 Gbps nelle principali città. Questa infrastruttura garantisce IPTV 4K e 8K completamente fluido per tutti gli utenti di Prime IPTV in Germania.'),
        ('Come si esegue IPTV Kaufen in Germania?',
         'Per IPTV Kaufen in Germania contatta Prime IPTV via WhatsApp, scegli il tuo piano, completa il pagamento online sicuro e ricevi le credenziali di accesso in pochi minuti. L\'intero processo è digitale e senza necessità di contratti cartacei.'),
        ('IPTV Box è necessario per IPTV Germania o basta uno Smart TV?',
         'Per IPTV Germania una Smart TV Android è più che sufficiente. Un IPTV Box dedicato è utile solo se il tuo televisore non supporta le app IPTV moderne. Prime IPTV garantisce la stessa qualità su entrambe le soluzioni.'),
        ('IPTV Online in Germania è compatibile con dispositivi iOS e Android?',
         'Sì — IPTV Online di Prime IPTV funziona su iPhone, iPad e tutti i dispositivi Android in Germania. Puoi usare le stesse credenziali su tutti i tuoi dispositivi mobili senza configurazioni aggiuntive.'),
        ('Come si attiva un Abbonamento IPTV Germania?',
         'Dopo aver scelto il piano ricevi le credenziali XTREAM IPTV via WhatsApp. Installa un\'app player compatibile, inserisci URL server, nome utente e password e il tuo Abbonamento IPTV Germania è immediatamente attivo.'),
        ('Quante connessioni simultanee supporta un piano IPTV Germania?',
         'I piani Prime IPTV Germania supportano da una a cinque connessioni simultanee in base al piano scelto. I piani multi-connessione sono ideali per famiglie italiane in Germania dove più membri vogliono guardare contemporaneamente.'),
    ]
}

# ── IT/SAN MARINO ─────────────────────────────
PAGES['it/san-marino/index.html'] = {
    'title': 'Domande <span class="faq2-grad">Frequenti</span>',
    'subtitle': 'Tutto quello che devi sapere su IPTV San Marino',
    'cta_title': 'Non hai trovato la risposta?',
    'cta_sub': 'Il nostro team è su WhatsApp',
    'cta_btn': 'Contattaci via WhatsApp',
    'stats_titles': ['Affidabilità', 'Stabilità', 'Supporto 24/7', 'Garantito'],
    'stats_subs': ['San Marino si fida di noi', 'Qualità cristallina', 'Sempre disponibile', 'Soddisfazione garantita'],
    'qa': [
        ('Qual è il Miglior IPTV per San Marino?',
         'Il Miglior IPTV per San Marino è un servizio con server CDN europei, uptime superiore al 99 %, qualità fino a 8K, supporto in italiano 24/7 e prezzi trasparenti. Prime IPTV è ottimizzato per l\'area geografica di San Marino.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Come si configura XTREAM IPTV a San Marino?',
         'Installa un\'app player compatibile (TiviMate o IPTV Smarters), seleziona XTREAM IPTV come tipo di connessione e inserisci le credenziali Prime IPTV ricevute dopo la sottoscrizione. Il servizio è attivo in meno di due minuti.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('Cosa include un Abbonamento IPTV a San Marino?',
         'Un Abbonamento IPTV San Marino di Prime IPTV include accesso a stream digitali in HD, FHD e 4K, un numero di connessioni simultanee definito dal piano, catch-up fino a 7 giorni e supporto tecnico in italiano disponibile 24/7.',
         ['Disponibilità 99%+', 'HD · FHD · 4K · 8K', 'Supporto 24/7', 'Streaming digitale']),
        ('IPTV 4K funziona bene con le connessioni disponibili a San Marino?',
         'Sì — San Marino dispone di un\'infrastruttura internet avanzata con fibra ottica che supera ampiamente i 25 Mbps richiesti per l\'IPTV 4K. Prime IPTV garantisce streaming 4K e 8K completamente fluido per tutti gli utenti di San Marino.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Cos\'è IPTV HD e come si distingue dal 4K?',
         'IPTV HD offre una risoluzione di 1280×720 pixel ed è ideale per connessioni da 10 Mbps. L\'IPTV 4K raggiunge 3840×2160 pixel con dettagli quattro volte superiori. Prime IPTV offre entrambe le qualità con passaggio automatico tramite bitrate adattivo.'),
        ('Cosa offre un Servizio IPTV Premium rispetto a quello base a San Marino?',
         'Un Servizio IPTV Premium a San Marino include più connessioni simultanee, pieno accesso a 4K e 8K, supporto prioritario e funzione catch-up. Il piano base è adatto per singoli utenti con esigenze di streaming standard.'),
        ('IPTV Pro è compatibile con tutti i dispositivi utilizzati a San Marino?',
         'Sì — IPTV Pro Prime IPTV è compatibile con Smart TV, Android box, Firestick, iPhone, iPad e PC Windows/Mac. Non è necessario alcun hardware aggiuntivo; qualsiasi dispositivo moderno è supportato.'),
        ('Come funziona IPTV Streaming tecnicamente a San Marino?',
         'L\'IPTV Streaming codifica i contenuti sui server europei di Prime IPTV e li trasmette in tempo reale tramite internet usando i protocolli HLS o MPEG-TS. La prossimità geografica dei server garantisce latenza minima per gli utenti di San Marino.'),
        ('IPTV Online a San Marino richiede hardware speciale?',
         'No — IPTV Online a San Marino funziona su qualsiasi dispositivo connesso a internet: Smart TV, smartphone, tablet o computer. Non è richiesto hardware speciale. Installa un\'app compatibile e inserisci le credenziali Prime IPTV per iniziare.'),
        ('Premium IPTV offre un periodo di prova a San Marino?',
         'Sì — Prime IPTV offre un periodo di prova per permettere agli utenti di San Marino di testare la qualità e la stabilità del servizio su propri dispositivi prima di sottoscrivere un abbonamento completo. Contattaci via WhatsApp per richiederlo.'),
    ]
}

# ── NL/NEDERLAND ──────────────────────────────
PAGES['nl/nederland/index.html'] = {
    'title': 'Veelgestelde <span class="faq2-grad">Vragen</span>',
    'subtitle': 'Alles wat u moet weten over IPTV Nederland',
    'cta_title': 'Antwoord niet gevonden?',
    'cta_sub': 'Ons team staat voor u klaar op WhatsApp',
    'cta_btn': 'Contact via WhatsApp',
    'stats_titles': ['Betrouwbaar', 'Stabiliteit', '24/7 Support', 'Gegarandeerd'],
    'stats_subs': ['Nederland vertrouwt ons', 'Kristalheldere kwaliteit', 'Altijd bereikbaar', 'Tevredenheid gegarandeerd'],
    'qa': [
        ('Wat zijn de Beste IPTV Nederland opties voor thuisgebruik?',
         'De Beste IPTV Nederland opties combineren een serveruptime boven de 99 %, 4K-streamingkwaliteit, Nederlandstalige ondersteuning en transparante prijzen. Prime IPTV biedt dit alles met een geoptimaliseerde infrastructuur voor Nederlandse internetverbindingen.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Wat is een IPTV Kastje en heb ik het nodig voor IPTV Nederland?',
         'Een IPTV Kastje is een kleine Android mediaspeler die u op uw televisie aansluit. Voor IPTV Nederland is het niet verplicht — elke Smart TV, Firestick, smartphone of pc werkt uitstekend met Prime IPTV zonder extra hardware.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Hoe vergelijk ik verschillende IPTV Aanbieders in Nederland?',
         'Vergelijk IPTV Aanbieders in Nederland op serveruptime, ondersteunde resoluties, aantal gelijktijdige verbindingen, kwaliteit van klantenservice, prijstransparantie en geverifieerde klantbeoordelingen. Prime IPTV scoort uitstekend op al deze punten.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Welke IPTV Box is het beste voor IPTV Nederland?',
         'Voor IPTV Nederland zijn Android-boxes zoals Nvidia Shield, MiBox of Mecool uitstekende keuzes. Een Firestick biedt een goedkoper compact alternatief. Alle opties zijn volledig compatibel met Prime IPTV en ondersteunen 4K-streaming.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Hoe werkt IPTV Kopen in Nederland — welke stappen moet ik volgen?',
         'Voor IPTV Kopen in Nederland neemt u contact op met Prime IPTV via WhatsApp, kiest u uw abonnement, rondt u de beveiligde betaling af en ontvangt u uw inloggegevens binnen enkele minuten. Volledig online, snel en zonder langdurige contracten.'),
        ('Welke internetsnelheid heb ik nodig voor 4K IPTV in Nederland?',
         'Voor 4K IPTV in Nederland heeft u minimaal 25 Mbps nodig. Nederlandse glasvezelverbindingen bieden doorgaans 100 Mbps tot 1 Gbps — ruim voldoende voor vloeiende 4K en zelfs 8K streaming zonder enige vertraging.'),
        ('Wat is het verschil tussen de verschillende IPTV Abonnementen?',
         'IPTV Abonnementen bij Prime IPTV Nederland verschillen in het aantal gelijktijdige verbindingen (1 tot 5), de abonnementsduur (maand/jaar), kwaliteitsniveau (HD/4K/8K) en prioritaire ondersteuning. Kies het abonnement dat bij uw gezin past.'),
        ('Kan ik IPTV Online in Nederland gebruiken zonder IPTV Box?',
         'Ja — IPTV Online werkt in Nederland rechtstreeks in uw browser of via een app op elke Smart TV, smartphone, tablet of pc. Prime IPTV vereist geen speciale hardware voor online gebruik in Nederland.'),
        ('Wat maakt Beste IPTV Nederland uniek ten opzichte van andere landen?',
         'Beste IPTV Nederland profiteert van de uitstekende Nederlandse internetinfrastructuur met hoge glasfaeldichtheid en lage latency. Prime IPTV maakt gebruik van Europese CDN-nodes die voor Nederlandse gebruikers bijzonder lage responsetijden bieden.'),
        ('Hoeveel gelijktijdige verbindingen biedt een typisch IPTV Nederland abonnement?',
         'Prime IPTV Nederland abonnementen bieden tussen één en vijf gelijktijdige verbindingen. Voor huishoudens met meerdere schermen is een multi-verbindingsplan de meest efficiënte oplossing om iedereen tegelijk van streaming te voorzien.'),
    ]
}

# ── NL/BELGIË ─────────────────────────────────
PAGES['nl/belgie/index.html'] = {
    'title': 'Veelgestelde <span class="faq2-grad">Vragen</span>',
    'subtitle': 'Alles wat u moet weten over IPTV België',
    'cta_title': 'Antwoord niet gevonden?',
    'cta_sub': 'Ons team staat voor u klaar op WhatsApp',
    'cta_btn': 'Contact via WhatsApp',
    'stats_titles': ['Betrouwbaar', 'Stabiliteit', '24/7 Support', 'Gegarandeerd'],
    'stats_subs': ['België vertrouwt ons', 'Kristalheldere kwaliteit', 'Altijd bereikbaar', 'Tevredenheid gegarandeerd'],
    'qa': [
        ('Wat is het verschil tussen IPTV België, IPTV Belgique en IPTV Belgium?',
         'IPTV België (Nederlands), IPTV Belgique (Frans) en IPTV Belgium (Engels) zijn drie benamingen voor dezelfde service voor Belgische gebruikers. Prime IPTV biedt identieke kwaliteit voor alle taalregio\'s met meertalige ondersteuning.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Hoe voer ik een IPTV Test uit voordat ik me abonneer?',
         'Voor een IPTV Test neemt u contact op met Prime IPTV via WhatsApp. U kunt de streamingkwaliteit en stabiliteit op uw eigen apparaten en verbinding testen voordat u een volledig abonnement afsluit. Risico\'s zijn er niet.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Hoe configureer ik XTREAM IPTV op een IPTV Box in België?',
         'Open uw IPTV-app (IPTV Smarters of TiviMate) op uw box, selecteer XTREAM IPTV als verbindingstype, voer de server-URL, gebruikersnaam en wachtwoord in die u van Prime IPTV heeft ontvangen. De lijst laadt automatisch in seconden.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Wat is IPTV One en hoe verschilt het van andere plannen?',
         'IPTV One verwijst naar een eenverbindingsplan ideaal voor individuele gebruikers. In tegenstelling tot multi-verbindingsplannen ondersteunt het één actief apparaat tegelijk. Het is de meest betaalbare manier om de dienst van Prime IPTV te gebruiken.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Welke internetsnelheid heb ik nodig voor IPTV 4K in België?',
         'Voor IPTV 4K in België heeft u minimaal 25 Mbps nodig. Belgische glasvezelverbindingen halen doorgaans 200 Mbps of meer, meer dan voldoende voor vloeiende 4K en 8K streaming met Prime IPTV.'),
        ('Hoe werkt IPTV Kopen in België — stap voor stap?',
         'Neem contact op met Prime IPTV via WhatsApp, kies uw plan (één tot vijf verbindingen), voer de betaling online uit en ontvang uw inloggegevens binnen enkele minuten. Geen installatie door technici en geen langdurige contracten vereist.'),
        ('Wat biedt IPTV Premium in België ten opzichte van basisplannen?',
         'IPTV Premium Belgium biedt meer gelijktijdige verbindingen, toegang tot 4K en 8K, prioritaire technische ondersteuning en catch-up functie. Basisplannen zijn geschikt voor gebruikers met enkelvoudige behoeften en eenvoudige instellingen.'),
        ('Is IPTV Box verplicht voor IPTV België of werkt een Smart TV ook?',
         'Een Smart TV Android is meer dan voldoende voor IPTV België. Een IPTV Box is alleen aanbevolen als uw televisie verouderd is of geen IPTV-apps ondersteunt. Prime IPTV werkt uitstekend op beide oplossingen.'),
        ('Hoeveel gelijktijdige verbindingen ondersteunt IPTV Belgium?',
         'Prime IPTV Belgium ondersteunt één tot vijf gelijktijdige verbindingen afhankelijk van het gekozen plan. Multi-verbindingsplannen zijn ideaal voor Belgische huishoudens waar meerdere leden tegelijk willen streamen.'),
        ('Hoe activeer ik mijn IPTV Belgique abonnement na aankoop?',
         'Na uw aankoop ontvangt u via WhatsApp uw XTREAM IPTV-inloggegevens. Open uw player-app, kies XTREAM als verbindingstype, vul uw gegevens in en uw IPTV Belgique abonnement is onmiddellijk actief.'),
    ]
}

# ── NL/SURINAME ───────────────────────────────
PAGES['nl/suriname/index.html'] = {
    'title': 'Veelgestelde <span class="faq2-grad">Vragen</span>',
    'subtitle': 'Alles wat u moet weten over IPTV in Suriname',
    'cta_title': 'Antwoord niet gevonden?',
    'cta_sub': 'Ons team staat voor u klaar op WhatsApp',
    'cta_btn': 'Contact via WhatsApp',
    'stats_titles': ['Betrouwbaar', 'Stabiliteit', '24/7 Support', 'Gegarandeerd'],
    'stats_subs': ['Suriname vertrouwt ons', 'Kristalheldere kwaliteit', 'Altijd bereikbaar', 'Tevredenheid gegarandeerd'],
    'qa': [
        ('Wat is de Beste IPTV optie voor gebruikers in Suriname?',
         'De Beste IPTV voor Suriname is een dienst met adaptieve bitrate-technologie voor variabele verbindingssnelheden, stabiele CDN-infrastructuur, meertalige ondersteuning en flexibele plannen. Prime IPTV is geoptimaliseerd voor gebruikers in Suriname.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Hoe werkt IPTV Streaming technisch in Suriname?',
         'IPTV Streaming codeert digitale inhoud op onze servers en verzendt dit in realtime via internet naar uw apparaat met behulp van HLS- of MPEG-TS-protocollen. Ons wereldwijde CDN-netwerk zorgt voor de best mogelijke verbinding voor Surinaamse gebruikers.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Heeft IPTV 4K een snelle internetverbinding nodig in Suriname?',
         'Voor IPTV 4K heeft u minimaal 25 Mbps nodig. Voor HD volstaat 10 Mbps. De adaptieve bitrate-technologie van Prime IPTV past de kwaliteit automatisch aan de beschikbare verbindingssnelheid in Suriname aan.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Wat is het verschil tussen IPTV HD en IPTV 4K?',
         'IPTV HD biedt een resolutie van 1280×720 pixels en vereist circa 10 Mbps. IPTV 4K levert 3840×2160 pixels met viermaal meer detail en vereist minimaal 25 Mbps. Prime IPTV biedt beide kwaliteiten met automatische aanpassing via adaptieve bitrate.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Hoe stel ik XTREAM IPTV in op mijn apparaat in Suriname?',
         'Open uw IPTV-app op uw apparaat, selecteer XTREAM IPTV als verbindingstype en voer de server-URL, gebruikersnaam en wachtwoord in die u na abonnement van Prime IPTV ontvangt. De lijst laadt automatisch. Klaar in minder dan twee minuten.'),
        ('Wat biedt Premium IPTV ten opzichte van gratis alternatieven?',
         'Premium IPTV levert dedicated servercapaciteit, nul buffering, dagelijkse inhoudsupdates en 24/7 technische ondersteuning. Gratis diensten draaien op overbelaste servers met constante onderbrekingen en bieden geen enkele technische hulp.'),
        ('Is IPTV Live beschikbaar op zowel mobiel als Smart TV in Suriname?',
         'Ja — IPTV Live van Prime IPTV is beschikbaar op Android-smartphone, iPhone, Smart TV en tablet in Suriname. Gebruik overal uw inloggegevens en geniet van live digitale streams op elk scherm van uw keuze.'),
        ('Hoe verhoudt IPTV Service zich tot traditionele televisie in Suriname?',
         'Een IPTV Service levert digitale content via internet zonder dure satellietinstallaties of kabels. In Suriname biedt dit bijzondere voordelen: geen technicibezoek nodig, werkt op bestaande apparaten en is beschikbaar overal met internetverbinding.'),
        ('Hoeveel apparaten ondersteunt een IPTV Pro abonnement tegelijk?',
         'Een IPTV Pro abonnement bij Prime IPTV ondersteunt afhankelijk van het plan twee tot vijf gelijktijdige apparaten. Kies het plan dat past bij het aantal gebruikers in uw huishouden in Suriname.'),
        ('Kan ik IPTV Online in Suriname gebruiken zonder speciale hardware?',
         'Ja — IPTV Online werkt in Suriname op elk apparaat met internetverbinding: Smart TV, smartphone, tablet of computer. Geen speciale hardware vereist. Installeer een compatibele app, voer uw Prime IPTV-gegevens in en begin direct.'),
    ]
}

# ── NL/DUITSLAND ──────────────────────────────
PAGES['nl/duitsland/index.html'] = {
    'title': 'Veelgestelde <span class="faq2-grad">Vragen</span>',
    'subtitle': 'Alles wat u moet weten over IPTV Duitsland',
    'cta_title': 'Antwoord niet gevonden?',
    'cta_sub': 'Ons team staat voor u klaar op WhatsApp',
    'cta_btn': 'Contact via WhatsApp',
    'stats_titles': ['Betrouwbaar', 'Stabiliteit', '24/7 Support', 'Gegarandeerd'],
    'stats_subs': ['Vertrouwen in Duitsland', 'Kristalheldere kwaliteit', 'Altijd bereikbaar', 'Tevredenheid gegarandeerd'],
    'qa': [
        ('Wat is het verschil tussen IPTV Duitsland, IPTV Deutschland en IPTV Germany?',
         'IPTV Duitsland (Nederlands), IPTV Deutschland (Duits) en IPTV Germany (Engels) zijn drie benamingen voor hetzelfde concept — IPTV-diensten in Duitsland. Prime IPTV biedt een geoptimaliseerde service voor alle gebruikers in Duitsland ongeacht hun taal.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Hoe koop ik IPTV voor Duitsland — IPTV Kopen of IPTV Kaufen?',
         'Of u het nu IPTV Kopen (Nederlands) of IPTV Kaufen (Duits) noemt, het proces is identiek: neem contact op via WhatsApp, kies uw plan, voer de betaling uit en ontvang uw inloggegevens binnen minuten. Volledig online en zonder langdurige contracten.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Welke IPTV Stick werkt het beste voor IPTV Duitsland?',
         'De Amazon Firestick is de populairste IPTV Stick voor IPTV Duitsland. Hij is compact, krachtig genoeg voor 4K en eenvoudig in te stellen. Alternatief: de Chromecast met Google TV of een Xiaomi Mi Stick werken ook uitstekend met Prime IPTV.',
         ['99%+ Uptime', 'HD · FHD · 4K · 8K', '24/7 Support', 'Digitaal streamen']),
        ('Wat is de rol van een IPTV Anbieter bij het gebruik van IPTV Germany?',
         'Een IPTV Anbieter beheert de serverinfrastructuur, distribueert digitale streams en biedt technische ondersteuning. Kies een Anbieter met gegarandeerde uptime boven 99 %, 4K-kwaliteit en betrouwbare klantenservice voor de beste IPTV Germany-ervaring.',
         ['HD · 10 Mbps', 'FHD · 15 Mbps', '4K · 25 Mbps', '8K · 50 Mbps']),
        ('Hoe snel moet mijn internet zijn voor IPTV 4K in Duitsland?',
         'Voor IPTV 4K in Duitsland heeft u minimaal 25 Mbps nodig. Het uitgebreide glasvezelnetwerk in Duitsland biedt doorgaans 100 Mbps tot 1 Gbps, wat ruim voldoende is voor vloeiende 4K en 8K streaming met Prime IPTV.'),
        ('Is IPTV Box noodzakelijk voor IPTV Duitsland of werkt een Smart TV ook?',
         'Een moderne Smart TV Android volstaat volledig voor IPTV Duitsland. Een IPTV Box is alleen nodig als uw televisie te oud is om IPTV-apps te draaien. Prime IPTV werkt op beide oplossingen met gelijke kwaliteit.'),
        ('Hoe activeer ik mijn IPTV Deutschland abonnement na IPTV Kaufen?',
         'Na IPTV Kaufen ontvangt u uw XTREAM IPTV-inloggegevens via WhatsApp. Installeer TiviMate of IPTV Smarters op uw apparaat, voer server-URL, gebruikersnaam en wachtwoord in en uw IPTV Deutschland abonnement is direct actief.'),
        ('Kan ik IPTV Online in Duitsland gebruiken op mijn smartphone?',
         'Ja — IPTV Online van Prime IPTV werkt uitstekend op Android- en iOS-smartphones in Duitsland. Gebruik dezelfde inloggegevens als op uw Smart TV of IPTV Box voor naadloos streamen onderweg.'),
        ('Wat zijn de voordelen van IPTV Germany ten opzichte van reguliere tv?',
         'IPTV Germany biedt geen dure hardware-installatie, geen langdurige contracten, 4K en 8K kwaliteit op alle apparaten, meerdere schermen tegelijk en 24/7 technische support — allemaal voor een fractie van de kosten van reguliere kabel-tv.'),
        ('Hoeveel gelijktijdige verbindingen biedt een typisch IPTV Duitsland plan?',
         'Prime IPTV Duitsland plannen bieden één tot vijf gelijktijdige verbindingen. Nederlandstalige gebruikers in Duitsland kunnen kiezen voor multi-verbindingsplannen zodat het hele gezin tegelijk kan genieten van digitale streams.'),
    ]
}

# ─────────────────────────────────────────────
# RUNNER
# ─────────────────────────────────────────────
ok, fail = 0, 0
for rel, cfg in PAGES.items():
    result = update_file(rel, cfg)
    if result:
        ok += 1
    else:
        fail += 1

print(f'\nDone: {ok} updated, {fail} failed')
