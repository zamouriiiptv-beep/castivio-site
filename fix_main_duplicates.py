#!/usr/bin/env python3
"""Fix duplicate flags on all main language pages."""
import re

BASE = '/home/user/Prime-iptv'

QBOX   = '<svg viewBox="0 0 24 24"><path d="M9.5 7C6.5 7 5 9.2 5 12v5h5v-5H7.5c0-1.7.7-2.8 2-3V7zm9 0c-3 0-4.5 2.2-4.5 5v5h5v-5H16c0-1.7.7-2.8 2-3V7z"/></svg>'
AVATAR = '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>'

TAGS = [
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><polygon points="5,3 19,12 5,21"/></svg>Tivimate',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="2" y="3" width="20" height="14" rx="2" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M8 21h8M12 17v4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>Smart TV'),
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><polygon points="5,3 19,12 5,21"/></svg>Smarters Pro',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="7" y="2" width="10" height="20" rx="3" fill="none" stroke="currentColor" stroke-width="1.8"/><circle cx="12" cy="17.5" r="1.2" fill="currentColor"/></svg>iPhone'),
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><polygon points="5,3 19,12 5,21"/></svg>IPTV Smarters',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M13 2L4.5 13.5H11L8 22l10.5-13H13V2z" stroke="currentColor" stroke-width="0.5"/></svg>Firestick'),
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><polygon points="5,3 19,12 5,21"/></svg>IPTV Pro',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="2" y="4" width="20" height="14" rx="2" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M8 2v2M16 2v2M12 9v4M10 11h4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>Android TV'),
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M13 3L8 13h5l-2 8 7-11h-5l2-7z"/></svg>Amazon Fire TV',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="4" width="18" height="12" rx="2" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M8 20h8M12 16v4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>MAG Box'),
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><polygon points="5,3 19,12 5,21"/></svg>OTT Navigator',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="5" width="18" height="13" rx="2" fill="none" stroke="currentColor" stroke-width="1.8"/><circle cx="12" cy="20" r="1.2" fill="currentColor"/><path d="M9 23h6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>Apple TV'),
]


def make_article(flag, alt, name, loc, text, tag_idx, is_lg=False):
    cls = 'rv-card rv-card--lg' if is_lg else 'rv-card'
    t1, t2 = TAGS[tag_idx]
    return (
        f'      <article class="{cls}">\n'
        f'        <div class="rv-top">\n'
        f'          <span class="rv-qbox" aria-hidden="true">{QBOX}</span>\n'
        f'          <div class="rv-stars" aria-label="5 out of 5 stars">★★★★★</div>\n'
        f'          <img class="rv-flag" src="{flag}" alt="{alt}" loading="lazy" decoding="async">\n'
        f'        </div>\n'
        f'        <div class="rv-person">\n'
        f'          <span class="rv-avatar">{AVATAR}</span>\n'
        f'          <div class="rv-person-info">\n'
        f'            <p class="rv-name">{name}</p>\n'
        f'            <p class="rv-loc">{loc}</p>\n'
        f'          </div>\n'
        f'        </div>\n'
        f'        <p class="rv-text">{text}</p>\n'
        f'        <div class="rv-tags">\n'
        f'          <span class="rv-tag">{t1}</span>\n'
        f'          <span class="rv-tag">{t2}</span>\n'
        f'        </div>\n'
        f'      </article>'
    )


def replace_grid(filepath, all_cards):
    """Replace the full rv-grid content."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    articles = [make_article(*c, tag_idx=i, is_lg=(i == 5)) for i, c in enumerate(all_cards)]
    new_grid = '    <div class="rv-grid">\n\n' + '\n'.join(articles) + '\n\n    </div>'
    pattern = r'    <div class="rv-grid">.*?    </div>(?=\n\n    <div class="rv-feats">)'
    new_content = re.sub(pattern, new_grid, content, flags=re.DOTALL)

    if new_content == content:
        print(f'WARNING: No change in {filepath}')
        return
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f'Updated: {filepath}')


F = lambda x: f'/images/A3lame/{x}'

# ── English review texts ──────────────────────────────────────────────────────
EN = [
    'I started using this <strong>Prime IPTV subscription</strong> and what impressed me most was the picture clarity and easy access to content at any time.',
    "At home we use <strong>Prime IPTV</strong> for kids' programs and family entertainment, everything works smoothly and without any interruptions.",
    'I use <strong>Prime IPTV outside my country</strong> to follow my favorite content. The experience is stable and smooth even while traveling.',
    'I follow live <strong>matches via IPTV</strong> during peak hours without interruption. Stability is excellent even with an average internet connection.',
    'Setting up the <strong>IPTV service on TV and phone</strong> was very easy. I love the fast channel switching and consistent display quality.',
    'I recommend <strong>Prime IPTV</strong> to everyone who wants to follow sports and series in excellent quality. The service is stable and very affordable.',
]
DE = [
    'Ich nutze dieses <strong>Prime IPTV-Abonnement</strong> und was mich am meisten beeindruckt hat, ist die Bildschärfe und der einfache Zugriff auf Inhalte jederzeit.',
    'Zu Hause nutzen wir <strong>Prime IPTV</strong> für Kinderprogramme und Familienunterhaltung, alles funktioniert problemlos ohne Unterbrechungen.',
    'Ich nutze <strong>Prime IPTV außerhalb meines Landes</strong>, um meine Lieblingsinhalte zu verfolgen. Das Erlebnis ist stabil und reibungslos, auch auf Reisen.',
    'Ich verfolge Live-Spiele <strong>via IPTV</strong> zu Spitzenzeiten ohne Unterbrechungen. Die Stabilität ist ausgezeichnet, auch bei durchschnittlichem Internet.',
    'Die Einrichtung des <strong>IPTV-Dienstes auf TV und Handy</strong> war sehr einfach. Ich liebe das schnelle Umschalten und die stabile Bildqualität.',
    'Ich empfehle <strong>Prime IPTV</strong> jedem, der Sport und Serien in ausgezeichneter Qualität verfolgen möchte. Der Dienst ist stabil und erschwinglich.',
]
ES = [
    'Empecé a usar este <strong>servicio Prime IPTV</strong> y lo que más me impresionó fue la claridad de imagen y el fácil acceso al contenido en cualquier momento.',
    'En casa usamos <strong>Prime IPTV</strong> para programas infantiles y entretenimiento familiar, todo funciona perfectamente sin ninguna interrupción.',
    'Uso <strong>Prime IPTV fuera de mi país</strong> para seguir mis contenidos favoritos. La experiencia es estable y fluida incluso viajando.',
    'Sigo los partidos en directo <strong>via IPTV</strong> en horas punta sin interrupciones. La estabilidad es excelente incluso con Internet medio.',
    'Configurar el <strong>servicio IPTV en TV y móvil</strong> fue muy fácil. Me encanta el cambio rápido de canales y la calidad de imagen estable.',
    'Recomiendo <strong>Prime IPTV</strong> a todos los que quieran seguir deportes y series con excelente calidad. El servicio es estable y muy asequible.',
]
PT = [
    'Comecei a usar este <strong>serviço Prime IPTV</strong> e o que mais me impressionou foi a clareza da imagem e o fácil acesso ao conteúdo a qualquer momento.',
    'Em casa usamos o <strong>Prime IPTV</strong> para programas infantis e entretenimento familiar, tudo funciona perfeitamente sem qualquer interrupção.',
    'Uso o <strong>Prime IPTV fora do meu país</strong> para acompanhar os meus conteúdos favoritos. A experiência é estável e fluida mesmo viajando.',
    'Acompanho jogos ao vivo <strong>via IPTV</strong> nos horários de pico sem interrupções. A estabilidade é excelente mesmo com internet média.',
    'Configurar o <strong>serviço IPTV na TV e no telemóvel</strong> foi muito fácil. Adoro a mudança rápida de canais e a qualidade de exibição estável.',
    'Recomendo o <strong>Prime IPTV</strong> a todos que querem acompanhar desporto e séries com excelente qualidade. O serviço é estável e muito acessível.',
]
IT = [
    'Ho iniziato a usare questo <strong>servizio Prime IPTV</strong> e quello che mi ha colpito di più è la chiarezza delle immagini e il facile accesso ai contenuti.',
    "A casa usiamo <strong>Prime IPTV</strong> per i programmi per bambini e l'intrattenimento familiare, tutto funziona perfettamente senza interruzioni.",
    "Uso <strong>Prime IPTV fuori dal mio paese</strong> per seguire i miei contenuti preferiti. L'esperienza è stabile e fluida anche in viaggio.",
    'Seguo le partite in diretta <strong>via IPTV</strong> nelle ore di punta senza interruzioni. La stabilità è eccellente anche con internet medio.',
    'Configurare il <strong>servizio IPTV su TV e telefono</strong> è stato molto facile. Adoro il cambio rapido di canale e la qualità di visualizzazione stabile.',
    'Consiglio <strong>Prime IPTV</strong> a tutti coloro che vogliono seguire sport e serie in qualità eccellente. Il servizio è stabile e molto conveniente.',
]
NL = [
    'Ik ben begonnen met dit <strong>Prime IPTV-abonnement</strong> en wat me het meest imponeerde was de beeldhelderheid en eenvoudige toegang tot content op elk moment.',
    "Thuis gebruiken we <strong>Prime IPTV</strong> voor kinderprogramma's en familievermaak, alles werkt perfect zonder onderbrekingen.",
    'Ik gebruik <strong>Prime IPTV buiten mijn land</strong> om mijn favoriete content te volgen. De ervaring is stabiel en soepel, zelfs onderweg.',
    'Ik volg live wedstrijden <strong>via IPTV</strong> tijdens piektijden zonder onderbrekingen. De stabiliteit is uitstekend, zelfs met een gemiddelde internetverbinding.',
    'Het instellen van de <strong>IPTV-service op TV en telefoon</strong> was heel eenvoudig. Ik hou van het snelle overschakelen en de stabiele beeldkwaliteit.',
    'Ik beveel <strong>Prime IPTV</strong> aan bij iedereen die sport en series in uitstekende kwaliteit wil volgen. De service is stabiel en zeer betaalbaar.',
]
TR = [
    'Bu <strong>Prime IPTV aboneliğini</strong> kullanmaya başladım ve beni en çok etkileyen şey görüntü netliği ve içeriklere her zaman kolayca erişim oldu.',
    'Evde çocuk programları ve aile eğlencesi için <strong>Prime IPTV</strong> kullanıyoruz, her şey sorunsuz ve kesintisiz çalışıyor.',
    'Favori içeriklerimi takip etmek için <strong>ülkem dışında Prime IPTV</strong> kullanıyorum. Seyahat ederken bile deneyim kararlı ve akıcı.',
    'Yoğun saatlerde <strong>IPTV üzerinden</strong> canlı maçları kesintisiz izliyorum. Ortalama internet bağlantısıyla bile istikrar mükemmel.',
    '<strong>TV ve telefonda IPTV hizmetini</strong> kurmak çok kolaydı. Hızlı kanal değiştirmeyi ve kararlı görüntü kalitesini çok seviyorum.',
    "Spor ve dizileri mükemmel kalitede takip etmek isteyenlere <strong>Prime IPTV</strong>'yi tavsiye ediyorum. Hizmet kararlı ve çok uygun fiyatlı.",
]

# ── en/index.html — all 6 unique English-speaking countries ──────────────────
replace_grid(f'{BASE}/en/index.html', [
    (F('flag-gb.svg'),  'UK',           'James Miller',    'From the UK',           EN[0]),
    (F('flag10.webp'),  'USA',          'Michael Johnson', 'From the USA',          EN[1]),
    (F('flag-ca.svg'),  'Canada',       'Sarah Thompson',  'From Canada',           EN[2]),
    (F('flag-za.svg'),  'South Africa', 'Thabo Nkosi',     'From South Africa',     EN[3]),
    (F('flag-ie.svg'),  'Ireland',      'Aoife Murphy',    'From Ireland',          EN[4]),
    (F('flag-jm.svg'),  'Jamaica',      'Keisha Brown',    'From Jamaica',          EN[5]),
])

# ── es/index.html — all 6 unique Spanish-speaking countries ──────────────────
replace_grid(f'{BASE}/es/index.html', [
    (F('flag3.webp'),   'España',     'Carlos García',       'De España',     ES[0]),
    (F('flag-mx.svg'),  'México',     'María López',         'De México',     ES[1]),
    (F('flag-ar.svg'),  'Argentina',  'Alejandro Pérez',     'De Argentina',  ES[2]),
    (F('flag-pe.svg'),  'Perú',       'Ana Mendoza',         'De Perú',       ES[3]),
    (F('flag-ve.svg'),  'Venezuela',  'Sofía González',      'De Venezuela',  ES[4]),
    (F('flag-cl.svg'),  'Chile',      'Matías Herrera',      'De Chile',      ES[5]),
])

# ── de/index.html — all 6 unique German-speaking countries ──────────────────
replace_grid(f'{BASE}/de/index.html', [
    (F('flag5.webp'),   'Deutschland',  'Thomas Müller',    'Aus Deutschland',    DE[0]),
    (F('flag-at.svg'),  'Österreich',   'Maria Huber',      'Aus Österreich',     DE[1]),
    (F('flag-ch.svg'),  'Schweiz',      'Peter Zimmermann', 'Aus der Schweiz',    DE[2]),
    (F('flag-li.svg'),  'Liechtenstein','Kurt Wanger',      'Aus Liechtenstein',  DE[3]),
    (F('flag-lu.svg'),  'Luxemburg',    'Marc Braun',       'Aus Luxemburg',      DE[4]),
    (F('flag-na.svg'),  'Namibia',      'Klaus Mayer',      'Aus Namibia',        DE[5]),
])

# ── pt/index.html — all 6 unique Portuguese-speaking countries ──────────────
replace_grid(f'{BASE}/pt/index.html', [
    (F('flag8.webp'),   'Portugal',          'João Silva',        'De Portugal',            PT[0]),
    (F('flag-br.svg'),  'Brasil',            'Ana Oliveira',      'Do Brasil',              PT[1]),
    (F('flag-ao.svg'),  'Angola',            'Eduardo Santos',    'De Angola',              PT[2]),
    (F('flag-mz.svg'),  'Moçambique',        'Carlos Nhantumbo',  'De Moçambique',          PT[3]),
    (F('flag-cv.svg'),  'Cabo Verde',        'Maria Fonseca',     'De Cabo Verde',          PT[4]),
    (F('flag-st.svg'),  'São Tomé',          'Miguel Pinto',      'De São Tomé e Príncipe', PT[5]),
])

# ── it/index.html — 5 unique Italian-speaking entities + 1 repeat ─────────────
replace_grid(f'{BASE}/it/index.html', [
    (F('flag20.webp'),  'Italia',     'Marco Romano',   "Dall'Italia",    IT[0]),
    (F('flag-ch.svg'),  'Svizzera',   'Giulia Ferrari', 'Dalla Svizzera', IT[1]),
    (F('flag-sm.svg'),  'San Marino', 'Luca Bianchi',   'Da San Marino',  IT[2]),
    (F('flag-va.svg'),  'Vaticano',   'Giovanni Moretti','Dal Vaticano',  IT[3]),
    (F('flag-mt.svg'),  'Malta',      'Carlo Borg',     'Da Malta',       IT[4]),
    (F('flag20.webp'),  'Italia',     'Chiara Ricci',   "Dall'Italia",    IT[5]),
])

# ── nl/index.html — all 6 unique Dutch-speaking countries ───────────────────
replace_grid(f'{BASE}/nl/index.html', [
    (F('flag19.webp'),  'Nederland', 'Jan de Vries',   'Uit Nederland', NL[0]),
    (F('flag-be.svg'),  'België',    'Sarah Peeters',  'Uit België',    NL[1]),
    (F('flag-sr.svg'),  'Suriname',  'Kevin Jaipersad','Uit Suriname',  NL[2]),
    (F('flag-aw.svg'),  'Aruba',     'Kevin Thijsen',  'Uit Aruba',     NL[3]),
    (F('flag-cw.svg'),  'Curaçao',   'Ryan Martina',   'Uit Curaçao',   NL[4]),
    (F('flag19.webp'),  'Nederland', 'Lotte Visser',   'Uit Nederland', NL[5]),
])

# ── tr/index.html — all 6 Turkic-speaking countries ─────────────────────────
replace_grid(f'{BASE}/tr/index.html', [
    (F('flag13.webp'),  'Türkiye',    'Ahmet Yılmaz',   "Türkiye'den",     TR[0]),
    (F('flag-az.svg'),  'Azerbaycan', 'Əli Hüseynov',   "Azerbaycan'dan",  TR[1]),
    (F('flag-cy.svg'),  'Kıbrıs',    'Mehmet Kaya',    "Kıbrıs'tan",      TR[2]),
    (F('flag-uz.svg'),  'Özbekistan', 'Timur Xasanov',  "Özbekistan'dan",  TR[3]),
    (F('flag-kz.svg'),  'Kazakistan', 'Aigerim Bekova', "Kazakistan'dan",  TR[4]),
    (F('flag-tm.svg'),  'Türkmenistan','Yusup Durdiyev',"Türkmenistan'dan",TR[5]),
])

print('All done!')
