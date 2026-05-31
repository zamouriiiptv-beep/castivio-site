import re, os

ROOT = "/home/user/Prime-iptv"

# Arrow per direction
ARROW = {'ltr': 'fa-arrow-right', 'rtl': 'fa-arrow-left'}

def tile(href, icon, name, desc, arrow):
    return f"""
      <a href="{href}" class="gd-tile">
        <div class="gd-head">
          <div class="gd-badge"><i class="fas {icon}"></i></div>
          <h3>{name}</h3>
        </div>
        <div class="gd-body">
          <p class="gd-mtitle">{name}</p>
          <p class="gd-desc">{desc}</p>
        </div>
        <span class="gd-link">{name} <i class="fas {arrow}"></i></span>
      </a>"""

def banner(href, tag, h3, p, btn, arrow_icon='fa-book-open'):
    return f"""
    <a href="{href}" class="gd-banner" aria-label="{h3}">
      <div class="gd-thumb"><i class="fas fa-book-open"></i></div>
      <div class="gd-banner-body">
        <span class="gd-banner-tag"><i class="fas fa-star"></i> {tag}</span>
        <h3>{h3}</h3>
        <p>{p}</p>
        <span class="gd-btn">
          <i class="fas fa-book-open"></i>
          {btn}
        </span>
      </div>
    </a>"""

LANGS = {
    'en': {
        'dir': 'ltr', 'ltr_class': ' class="gd-ltr"',
        'badge': 'Guides by Region',
        'title': 'Explore Guides <span>Tailored</span> to Your Region',
        'sub': 'Discover local streaming options, compatible devices, setup resources, and viewing recommendations designed for your country.',
        'tiles': [
            ('/en/uk/',     'fa-crown',   'United Kingdom', 'Apps, devices, and setup guides to help you get the most out of digital streaming in the United Kingdom.'),
            ('/en/usa/',    'fa-flag',    'United States',  'Streaming options, compatible devices, and tips tailored to viewers across the United States.'),
            ('/en/canada/', 'fa-leaf',    'Canada',         'Setup resources, apps, and viewing recommendations available for streaming across Canada.'),
        ],
        'banner': ('/en/guide/', '⭐ Featured Guide', 'The Complete Streaming Guide',
                   'Everything in one place — setup tutorials, device compatibility, and tips to enhance your viewing experience.',
                   'Read the Full Guide'),
        'cta': 'Explore Guide',
    },
    'fr': {
        'dir': 'ltr', 'ltr_class': ' class="gd-ltr"',
        'badge': 'Guides par région',
        'title': 'Des guides <span>adaptés</span> à votre région',
        'sub': 'Découvrez les meilleures options de streaming, appareils compatibles et conseils de configuration disponibles dans votre pays.',
        'tiles': [
            ('/fr/france/',   'fa-landmark', 'France',   "Applications, appareils et guides de configuration pour profiter au maximum du streaming en France."),
            ('/fr/belgique/', 'fa-gem',      'Belgique', 'Options de streaming, appareils compatibles et conseils adaptés aux spectateurs de Belgique francophone.'),
            ('/fr/canada/',   'fa-leaf',     'Canada',   'Ressources, applications et recommandations de visionnage disponibles pour le Canada francophone.'),
        ],
        'banner': ('/fr/guide/', '⭐ Guide vedette', 'Le Guide Complet du Streaming',
                   'Tout en un seul endroit — tutoriels de configuration, compatibilité des appareils et conseils pour une meilleure expérience.',
                   'Lire le Guide Complet'),
        'cta': 'Voir le guide',
    },
    'es': {
        'dir': 'ltr', 'ltr_class': ' class="gd-ltr"',
        'badge': 'Guías por región',
        'title': 'Guías <span>adaptadas</span> a tu región',
        'sub': 'Descubre opciones de streaming locales, dispositivos compatibles y recomendaciones pensadas para tu país.',
        'tiles': [
            ('/es/espana/',    'fa-sun',          'España',    'Apps, dispositivos y guías de configuración para sacar el máximo partido del streaming digital en España.'),
            ('/es/mexico/',    'fa-mountain-sun',  'México',   'Opciones de streaming, dispositivos compatibles y consejos pensados para espectadores en México.'),
            ('/es/argentina/', 'fa-futbol',       'Argentina', 'Recursos de configuración, apps y recomendaciones de visualización disponibles para Argentina.'),
        ],
        'banner': ('/es/guide/', '⭐ Guía destacada', 'La Guía Completa de Streaming',
                   'Todo en un solo lugar — tutoriales de configuración, compatibilidad de dispositivos y consejos para mejorar tu experiencia.',
                   'Leer la Guía Completa'),
        'cta': 'Explorar guía',
    },
    'de': {
        'dir': 'ltr', 'ltr_class': ' class="gd-ltr"',
        'badge': 'Guides nach Region',
        'title': 'Guides <span>speziell</span> für deinen Markt',
        'sub': 'Entdecke lokale Streaming-Optionen, kompatible Geräte, Setup-Ressourcen und Empfehlungen für dein Land.',
        'tiles': [
            ('/de/deutschland/', 'fa-building',  'Deutschland', 'Apps, Geräte und Einrichtungsleitfäden für das beste digitale Streaming-Erlebnis in Deutschland.'),
            ('/de/oesterreich/', 'fa-mountain',  'Österreich',  'Streaming-Optionen, kompatible Geräte und Tipps speziell für Zuschauer in Österreich.'),
            ('/de/schweiz/',     'fa-water',     'Schweiz',     'Einrichtungsressourcen, Apps und Empfehlungen für ein optimales Streaming-Erlebnis in der Schweiz.'),
        ],
        'banner': ('/de/guide/', '⭐ Empfohlener Guide', 'Der vollständige Streaming-Guide',
                   'Alles an einem Ort — Einrichtung, Gerätekompatibilität und Tipps für ein besseres Seherlebnis.',
                   'Vollständigen Guide lesen'),
        'cta': 'Guide ansehen',
    },
    'it': {
        'dir': 'ltr', 'ltr_class': ' class="gd-ltr"',
        'badge': 'Guide per regione',
        'title': 'Guide <span>pensate</span> per la tua regione',
        'sub': 'Scopri le opzioni di streaming locali, dispositivi compatibili e consigli di configurazione pensati per il tuo paese.',
        'tiles': [
            ('/it/italia/',    'fa-landmark', 'Italia',   "App, dispositivi e guide di configurazione per sfruttare al meglio lo streaming digitale in Italia."),
            ('/it/svizzera/',  'fa-mountain', 'Svizzera', 'Opzioni di streaming, dispositivi compatibili e consigli per gli spettatori in Svizzera.'),
            ('/it/germania/',  'fa-building', 'Germania', 'Risorse di configurazione, app e consigli di visione disponibili per la Germania in italiano.'),
        ],
        'banner': ('/it/guide/', '⭐ Guida in evidenza', 'La Guida Completa allo Streaming',
                   'Tutto in un unico posto — tutorial di configurazione, compatibilità dispositivi e consigli per migliorare la tua esperienza.',
                   'Leggi la Guida Completa'),
        'cta': 'Vedi la guida',
    },
    'nl': {
        'dir': 'ltr', 'ltr_class': ' class="gd-ltr"',
        'badge': 'Gidsen per regio',
        'title': 'Gidsen <span>op maat</span> voor jouw regio',
        'sub': 'Ontdek lokale streamingopties, compatibele apparaten en configuratietips beschikbaar in jouw land.',
        'tiles': [
            ('/nl/nederland/', 'fa-water',    'Nederland', 'Apps, apparaten en installatiegidsen om het meeste uit digitaal streaming te halen in Nederland.'),
            ('/nl/belgie/',    'fa-gem',      'België',    'Streamingopties, compatibele apparaten en tips speciaal voor kijkers in Nederlandstalig België.'),
            ('/nl/duitsland/', 'fa-building', 'Duitsland', 'Configuratieresources, apps en kijkaanbevelingen beschikbaar voor streaming vanuit Duitsland.'),
        ],
        'banner': ('/nl/guide/', '⭐ Aanbevolen gids', 'De Complete Streaming Gids',
                   'Alles op één plek — installatietutorials, apparaatcompatibiliteit en tips voor een betere kijkervaring.',
                   'Lees de Volledige Gids'),
        'cta': 'Bekijk gids',
    },
    'pt': {
        'dir': 'ltr', 'ltr_class': ' class="gd-ltr"',
        'badge': 'Guias por região',
        'title': 'Guias <span>pensados</span> para a sua região',
        'sub': 'Descubra opções de streaming locais, dispositivos compatíveis e recomendações de configuração disponíveis no seu país.',
        'tiles': [
            ('/pt/portugal/', 'fa-monument',    'Portugal', 'Apps, dispositivos e guias de configuração para tirar o máximo partido do streaming digital em Portugal.'),
            ('/pt/brasil/',   'fa-futbol',      'Brasil',   'Opções de streaming, dispositivos compatíveis e dicas pensadas para os espectadores no Brasil.'),
            ('/pt/angola/',   'fa-earth-africa','Angola',   'Recursos de configuração, apps e recomendações de visualização disponíveis para streaming em Angola.'),
        ],
        'banner': ('/pt/guide/', '⭐ Guia em destaque', 'O Guia Completo de Streaming',
                   'Tudo num só lugar — tutoriais de configuração, compatibilidade de dispositivos e dicas para melhorar a sua experiência.',
                   'Ler o Guia Completo'),
        'cta': 'Ver o guia',
    },
    'tr': {
        'dir': 'ltr', 'ltr_class': ' class="gd-ltr"',
        'badge': 'Bölgeye Göre Rehberler',
        'title': 'Bölgenize <span>Özel</span> Rehberler',
        'sub': 'Ülkenizde mevcut yerel yayın seçeneklerini, uyumlu cihazları ve kurulum kaynaklarını keşfedin.',
        'tiles': [
            ('/tr/turkiye/', 'fa-mosque',   'Türkiye', "Türkiye'de dijital yayından en iyi şekilde yararlanmak için uygulamalar, cihazlar ve kurulum rehberleri."),
            ('/tr/almanya/', 'fa-building', 'Almanya', "Almanya'daki izleyiciler için akış seçenekleri, uyumlu cihazlar ve Türkçe kurulum ipuçları."),
            ('/tr/kibris/',  'fa-sun',      'Kıbrıs',  "Kıbrıs'ta streaming için yapılandırma kaynakları, uygulamalar ve izleme önerileri."),
        ],
        'banner': ('/tr/guide/', '⭐ Öne Çıkan', 'Eksiksiz Streaming Rehberi',
                   'Her şey tek bir yerde — kurulum rehberleri, cihaz uyumluluğu ve daha iyi bir izleme deneyimi için ipuçları.',
                   'Rehberi Oku'),
        'cta': 'Rehberi gör',
    },
}

FILE_LANG = {
    'en/index.html': 'en', 'en/uk/index.html': 'en',
    'en/usa/index.html': 'en', 'en/canada/index.html': 'en',
    'fr/index.html': 'fr', 'fr/france/index.html': 'fr',
    'fr/belgique/index.html': 'fr', 'fr/canada/index.html': 'fr',
    'es/index.html': 'es', 'es/espana/index.html': 'es',
    'es/mexico/index.html': 'es', 'es/argentina/index.html': 'es',
    'de/index.html': 'de', 'de/deutschland/index.html': 'de',
    'de/oesterreich/index.html': 'de', 'de/schweiz/index.html': 'de',
    'it/index.html': 'it', 'it/italia/index.html': 'it',
    'it/svizzera/index.html': 'it', 'it/germania/index.html': 'it',
    'it/san-marino/index.html': 'it',
    'nl/index.html': 'nl', 'nl/nederland/index.html': 'nl',
    'nl/belgie/index.html': 'nl', 'nl/duitsland/index.html': 'nl',
    'nl/suriname/index.html': 'nl',
    'pt/index.html': 'pt', 'pt/portugal/index.html': 'pt',
    'pt/brasil/index.html': 'pt', 'pt/angola/index.html': 'pt',
    'tr/index.html': 'tr', 'tr/turkiye/index.html': 'tr',
    'tr/almanya/index.html': 'tr', 'tr/kibris/index.html': 'tr',
    'tr/azerbaycan/index.html': 'tr',
}

def build_section(lang_data):
    d = lang_data
    arrow = ARROW[d['dir']]
    cta = d['cta']
    tiles_html = ''.join(
        f"""
      <a href="{t[0]}" class="gd-tile">
        <div class="gd-head">
          <div class="gd-badge"><i class="fas {t[1]}"></i></div>
          <h3>{t[2]}</h3>
        </div>
        <div class="gd-body">
          <p class="gd-mtitle">{t[2]}</p>
          <p class="gd-desc">{t[3]}</p>
        </div>
        <span class="gd-link">{cta} <i class="fas {arrow}"></i></span>
      </a>"""
        for t in d['tiles']
    )
    b = d['banner']
    ltr = d['ltr_class']
    return f"""<section id="guides-section"{ltr} aria-label="{d['badge']}">
  <div class="gs-inner container mx-auto px-4 max-w-5xl">

    <div class="text-center">
      <span class="gs-badge">
        <i class="fas fa-map-marker-alt" style="color:#f5c518;"></i>
        {d['badge']}
      </span>
    </div>

    <h2 class="gs-title">
      {d['title']}
    </h2>

    <p class="gs-sub">
      {d['sub']}
    </p>

    <div class="gd-grid">{tiles_html}

    </div>

    <a href="{b[0]}" class="gd-banner" aria-label="{b[2]}">
      <div class="gd-thumb"><i class="fas fa-book-open"></i></div>
      <div class="gd-banner-body">
        <span class="gd-banner-tag"><i class="fas fa-star"></i> {b[1]}</span>
        <h3>{b[2]}</h3>
        <p>{b[3]}</p>
        <span class="gd-btn">
          <i class="fas fa-book-open"></i>
          {b[4]}
        </span>
      </div>
    </a>

  </div>
</section>
<!-- ═══════════════ End Guides Section ═══════════════ -->"""

# Pattern to match from <section id="guides-section" to End marker
SECTION_PATTERN = re.compile(
    r'<section id="guides-section".*?<!-- ═══════════════ End Guides Section ═══════════════ -->',
    re.DOTALL
)

count = 0
for rel, lang in FILE_LANG.items():
    fpath = os.path.join(ROOT, rel)
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    new_section = build_section(LANGS[lang])
    new_content = SECTION_PATTERN.sub(new_section, content)
    if new_content != content:
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"FIXED: {rel}")
        count += 1
    else:
        print(f"SKIP:  {rel}")

print(f"\nTotal: {count} files updated")
