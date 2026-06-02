#!/usr/bin/env python3
import re

BASE = '/home/user/Prime-iptv'

QBOX = '<svg viewBox="0 0 24 24"><path d="M9.5 7C6.5 7 5 9.2 5 12v5h5v-5H7.5c0-1.7.7-2.8 2-3V7zm9 0c-3 0-4.5 2.2-4.5 5v5h5v-5H16c0-1.7.7-2.8 2-3V7z"/></svg>'
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


def make_article(flag, flag_alt, name, loc, text, tags_pair, is_lg=False):
    cls = 'rv-card rv-card--lg' if is_lg else 'rv-card'
    t1, t2 = tags_pair
    return (
        f'      <article class="{cls}">\n'
        f'        <div class="rv-top">\n'
        f'          <span class="rv-qbox" aria-hidden="true">{QBOX}</span>\n'
        f'          <div class="rv-stars" aria-label="5 out of 5 stars">★★★★★</div>\n'
        f'          <img class="rv-flag" src="{flag}" alt="{flag_alt}" loading="lazy" decoding="async">\n'
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


def update_file(filepath, cards_data):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    articles = []
    for i, card in enumerate(cards_data):
        flag, flag_alt, name, loc, text = card
        is_lg = (i == 5)
        articles.append(make_article(flag, flag_alt, name, loc, text, TAGS[i], is_lg))

    new_grid = '    <div class="rv-grid">\n\n' + '\n'.join(articles) + '\n\n    </div>'
    pattern = r'    <div class="rv-grid">.*?    </div>(?=\n\n    <div class="rv-feats">)'
    new_content = re.sub(pattern, new_grid, content, flags=re.DOTALL)

    if new_content == content:
        print(f'WARNING: No change in {filepath}')
        return

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f'Updated: {filepath}')


# ── Review texts per language ──────────────────────────────────────────────────
EN = [
    'I started using this <strong>Prime IPTV subscription</strong> and what impressed me most was the picture clarity and easy access to content at any time.',
    "At home we use <strong>Prime IPTV</strong> for kids' programs and family entertainment, everything works smoothly and without any interruptions.",
    'I use <strong>Prime IPTV outside my country</strong> to follow my favorite content. The experience is stable and smooth even while traveling.',
    'I follow live <strong>matches via IPTV</strong> during peak hours without interruption. Stability is excellent even with an average internet connection.',
    'Setting up the <strong>IPTV service on TV and phone</strong> was very easy. I love the fast channel switching and consistent display quality.',
    'I recommend <strong>Prime IPTV</strong> to everyone who wants to follow sports and series in excellent quality. The service is stable and very affordable.',
]
FR = [
    "J'ai commencé à utiliser cet <strong>abonnement Prime IPTV</strong> et ce qui m'a le plus impressionné c'est la clarté de l'image et l'accès facile au contenu à tout moment.",
    'À la maison, nous utilisons <strong>Prime IPTV</strong> pour les émissions pour enfants et le divertissement familial, tout fonctionne parfaitement sans interruption.',
    "J'utilise <strong>Prime IPTV hors de mon pays</strong> pour suivre mes contenus préférés. L'expérience est stable et fluide même en voyage.",
    'Je suis les matchs en direct <strong>via IPTV</strong> aux heures de pointe sans coupures. La stabilité est excellente même avec une connexion Internet moyenne.',
    "Configurer le <strong>service IPTV sur la télé et le téléphone</strong> était très facile. J'aime le changement rapide de chaînes et la qualité d'affichage stable.",
    'Je recommande <strong>Prime IPTV</strong> à tous ceux qui veulent suivre le sport et les séries en excellente qualité. Le service est stable et très abordable.',
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
    'Uso <strong>Prime IPTV fuori dal mio paese</strong> per seguire i miei contenuti preferiti. L\'esperienza è stabile e fluida anche in viaggio.',
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

# ── Flag paths (absolute) ──────────────────────────────────────────────────────
F_UK = '/images/A3lame/flag10.webp'
F_US = '/images/A3lame/flag-us.svg'
F_CA = '/images/A3lame/flag-ca.svg'
F_AU = '/images/A3lame/flag-au.svg'
F_IE = '/images/A3lame/flag-ie.svg'
F_NZ = '/images/A3lame/flag-nz.svg'
F_FR = '/images/A3lame/flag2.webp'
F_BE = '/images/A3lame/flag-be.svg'
F_CH = '/images/A3lame/flag-ch.svg'
F_MA = '/images/A3lame/flag1.webp'
F_DZ = '/images/A3lame/flag-dz.svg'
F_DE = '/images/A3lame/flag5.webp'
F_AT = '/images/A3lame/flag-at.svg'
F_ES = '/images/A3lame/flag3.webp'
F_MX = '/images/A3lame/flag-mx.svg'
F_AR = '/images/A3lame/flag-ar.svg'
F_CO = '/images/A3lame/flag-co.svg'
F_PT = '/images/A3lame/flag8.webp'
F_BR = '/images/A3lame/flag-br.svg'
F_AO = '/images/A3lame/flag-ao.svg'
F_IT = '/images/A3lame/flag20.webp'
F_SM = '/images/A3lame/flag-sm.svg'
F_NL = '/images/A3lame/flag19.webp'
F_SR = '/images/A3lame/flag-sr.svg'
F_TR = '/images/A3lame/flag13.webp'
F_AZ = '/images/A3lame/flag-az.svg'
F_CY = '/images/A3lame/flag-cy.svg'

# ── Page definitions ───────────────────────────────────────────────────────────
PAGES = {
    # ── English ──
    f'{BASE}/en/index.html': [
        (F_UK, 'UK',          'James Miller',    'From the UK',          EN[0]),
        (F_US, 'USA',         'Michael Johnson', 'From the USA',         EN[1]),
        (F_CA, 'Canada',      'Sarah Thompson',  'From Canada',          EN[2]),
        (F_AU, 'Australia',   'Liam Wilson',     'From Australia',       EN[3]),
        (F_IE, 'Ireland',     'Aoife Murphy',    'From Ireland',         EN[4]),
        (F_NZ, 'New Zealand', 'Emma Clarke',     'From New Zealand',     EN[5]),
    ],
    f'{BASE}/en/uk/index.html': [
        (F_UK, 'UK', 'James Miller',    'From the UK', EN[0]),
        (F_UK, 'UK', 'Sophie Clarke',   'From the UK', EN[1]),
        (F_UK, 'UK', 'Oliver Harrison', 'From the UK', EN[2]),
        (F_UK, 'UK', 'Charlotte Hughes','From the UK', EN[3]),
        (F_UK, 'UK', 'William Cooper',  'From the UK', EN[4]),
        (F_UK, 'UK', 'Emily Watson',    'From the UK', EN[5]),
    ],
    f'{BASE}/en/usa/index.html': [
        (F_US, 'USA', 'Michael Johnson',  'From the USA', EN[0]),
        (F_US, 'USA', 'Jessica Williams', 'From the USA', EN[1]),
        (F_US, 'USA', 'Brandon Davis',    'From the USA', EN[2]),
        (F_US, 'USA', 'Ashley Martinez',  'From the USA', EN[3]),
        (F_US, 'USA', 'Tyler Anderson',   'From the USA', EN[4]),
        (F_US, 'USA', 'Madison Thompson', 'From the USA', EN[5]),
    ],
    f'{BASE}/en/canada/index.html': [
        (F_CA, 'Canada', 'Sarah Thompson',   'From Canada', EN[0]),
        (F_CA, 'Canada', 'Ryan McKenzie',    'From Canada', EN[1]),
        (F_CA, 'Canada', 'Olivia Tremblay',  'From Canada', EN[2]),
        (F_CA, 'Canada', 'Nathan Leblanc',   'From Canada', EN[3]),
        (F_CA, 'Canada', 'Chloe Robertson',  'From Canada', EN[4]),
        (F_CA, 'Canada', 'Matthew Bergeron', 'From Canada', EN[5]),
    ],
    # ── French ──
    f'{BASE}/fr/index.html': [
        (F_FR, 'France',   'Pierre Martin',    'De France',   FR[0]),
        (F_BE, 'Belgique', 'Sophie Lambert',   'De Belgique', FR[1]),
        (F_CA, 'Canada',   'Jean-Luc Tremblay','Du Canada',   FR[2]),
        (F_CH, 'Suisse',   'Marie Leroy',      'De Suisse',   FR[3]),
        (F_FR, 'France',   'Nicolas Laurent',  'De France',   FR[4]),
        (F_BE, 'Belgique', 'Maxime Fontaine',  'De Belgique', FR[5]),
    ],
    f'{BASE}/fr/france/index.html': [
        (F_FR, 'France', 'Pierre Martin',  'De France', FR[0]),
        (F_FR, 'France', 'Sophie Dubois',  'De France', FR[1]),
        (F_FR, 'France', 'Antoine Bernard','De France', FR[2]),
        (F_FR, 'France', 'Camille Moreau', 'De France', FR[3]),
        (F_FR, 'France', 'Nicolas Laurent','De France', FR[4]),
        (F_FR, 'France', 'Léa Petit',      'De France', FR[5]),
    ],
    f'{BASE}/fr/belgique/index.html': [
        (F_BE, 'Belgique', 'Sophie Lambert', 'De Belgique', FR[0]),
        (F_BE, 'Belgique', 'Lucas Dupont',   'De Belgique', FR[1]),
        (F_BE, 'Belgique', 'Amélie Simon',   'De Belgique', FR[2]),
        (F_BE, 'Belgique', 'Thomas Lejeune', 'De Belgique', FR[3]),
        (F_BE, 'Belgique', 'Clara Peeters',  'De Belgique', FR[4]),
        (F_BE, 'Belgique', 'Maxime Fontaine','De Belgique', FR[5]),
    ],
    f'{BASE}/fr/canada/index.html': [
        (F_CA, 'Canada', 'Jean-Luc Tremblay',  'Du Canada', FR[0]),
        (F_CA, 'Canada', 'Marie-Ève Gagnon',   'Du Canada', FR[1]),
        (F_CA, 'Canada', 'François Bouchard',  'Du Canada', FR[2]),
        (F_CA, 'Canada', 'Isabelle Roy',        'Du Canada', FR[3]),
        (F_CA, 'Canada', 'Philippe Côté',       'Du Canada', FR[4]),
        (F_CA, 'Canada', 'Nathalie Bélanger',   'Du Canada', FR[5]),
    ],
    # ── German ──
    f'{BASE}/de/index.html': [
        (F_DE, 'Deutschland', 'Thomas Müller',    'Aus Deutschland',  DE[0]),
        (F_AT, 'Österreich',  'Maria Huber',      'Aus Österreich',   DE[1]),
        (F_CH, 'Schweiz',     'Peter Zimmermann', 'Aus der Schweiz',  DE[2]),
        (F_DE, 'Deutschland', 'Luisa Becker',     'Aus Deutschland',  DE[3]),
        (F_AT, 'Österreich',  'Klaus Wagner',     'Aus Österreich',   DE[4]),
        (F_CH, 'Schweiz',     'Anna Keller',      'Aus der Schweiz',  DE[5]),
    ],
    f'{BASE}/de/deutschland/index.html': [
        (F_DE, 'Deutschland', 'Thomas Müller', 'Aus Deutschland', DE[0]),
        (F_DE, 'Deutschland', 'Luisa Becker',  'Aus Deutschland', DE[1]),
        (F_DE, 'Deutschland', 'Karl Schmidt',  'Aus Deutschland', DE[2]),
        (F_DE, 'Deutschland', 'Hannah Fischer','Aus Deutschland', DE[3]),
        (F_DE, 'Deutschland', 'Martin Weber',  'Aus Deutschland', DE[4]),
        (F_DE, 'Deutschland', 'Julia Wagner',  'Aus Deutschland', DE[5]),
    ],
    f'{BASE}/de/oesterreich/index.html': [
        (F_AT, 'Österreich', 'Maria Huber',     'Aus Österreich', DE[0]),
        (F_AT, 'Österreich', 'Klaus Wagner',    'Aus Österreich', DE[1]),
        (F_AT, 'Österreich', 'Elisabeth Gruber','Aus Österreich', DE[2]),
        (F_AT, 'Österreich', 'Stefan Moser',    'Aus Österreich', DE[3]),
        (F_AT, 'Österreich', 'Andrea Bauer',    'Aus Österreich', DE[4]),
        (F_AT, 'Österreich', 'Michael Steiner', 'Aus Österreich', DE[5]),
    ],
    f'{BASE}/de/schweiz/index.html': [
        (F_CH, 'Schweiz', 'Peter Zimmermann', 'Aus der Schweiz', DE[0]),
        (F_CH, 'Schweiz', 'Anna Keller',      'Aus der Schweiz', DE[1]),
        (F_CH, 'Schweiz', 'Hans Mäder',       'Aus der Schweiz', DE[2]),
        (F_CH, 'Schweiz', 'Sabine Brunner',   'Aus der Schweiz', DE[3]),
        (F_CH, 'Schweiz', 'Markus Frei',      'Aus der Schweiz', DE[4]),
        (F_CH, 'Schweiz', 'Christine Hofer',  'Aus der Schweiz', DE[5]),
    ],
    # ── Spanish ──
    f'{BASE}/es/index.html': [
        (F_ES, 'España',    'Carlos García',       'De España',    ES[0]),
        (F_MX, 'México',    'María López',         'De México',    ES[1]),
        (F_AR, 'Argentina', 'Alejandro Pérez',     'De Argentina', ES[2]),
        (F_CO, 'Colombia',  'Valentina Rodríguez', 'De Colombia',  ES[3]),
        (F_ES, 'España',    'Diego Martínez',      'De España',    ES[4]),
        (F_MX, 'México',    'Sofía Hernández',     'De México',    ES[5]),
    ],
    f'{BASE}/es/espana/index.html': [
        (F_ES, 'España', 'Carlos García',     'De España', ES[0]),
        (F_ES, 'España', 'María López',       'De España', ES[1]),
        (F_ES, 'España', 'Diego Martínez',    'De España', ES[2]),
        (F_ES, 'España', 'Lucía Fernández',   'De España', ES[3]),
        (F_ES, 'España', 'Alejandro Jiménez', 'De España', ES[4]),
        (F_ES, 'España', 'Carmen Ruiz',       'De España', ES[5]),
    ],
    f'{BASE}/es/argentina/index.html': [
        (F_AR, 'Argentina', 'Alejandro Pérez',  'De Argentina', ES[0]),
        (F_AR, 'Argentina', 'Sofía Torres',     'De Argentina', ES[1]),
        (F_AR, 'Argentina', 'Mateo González',   'De Argentina', ES[2]),
        (F_AR, 'Argentina', 'Valentina Castro', 'De Argentina', ES[3]),
        (F_AR, 'Argentina', 'Sebastián Romero', 'De Argentina', ES[4]),
        (F_AR, 'Argentina', 'Florencia Medina', 'De Argentina', ES[5]),
    ],
    f'{BASE}/es/mexico/index.html': [
        (F_MX, 'México', 'María López',     'De México', ES[0]),
        (F_MX, 'México', 'Juan Ramírez',    'De México', ES[1]),
        (F_MX, 'México', 'Sofía Hernández', 'De México', ES[2]),
        (F_MX, 'México', 'Luis Morales',    'De México', ES[3]),
        (F_MX, 'México', 'Isabella Vargas', 'De México', ES[4]),
        (F_MX, 'México', 'Miguel Reyes',    'De México', ES[5]),
    ],
    # ── Portuguese ──
    f'{BASE}/pt/index.html': [
        (F_PT, 'Portugal', 'João Silva',     'De Portugal', PT[0]),
        (F_BR, 'Brasil',   'Ana Oliveira',   'Do Brasil',   PT[1]),
        (F_AO, 'Angola',   'Eduardo Santos', 'De Angola',   PT[2]),
        (F_PT, 'Portugal', 'Mariana Costa',  'De Portugal', PT[3]),
        (F_BR, 'Brasil',   'Lucas Ferreira', 'Do Brasil',   PT[4]),
        (F_AO, 'Angola',   'Sofia Mendes',   'De Angola',   PT[5]),
    ],
    f'{BASE}/pt/portugal/index.html': [
        (F_PT, 'Portugal', 'João Silva',      'De Portugal', PT[0]),
        (F_PT, 'Portugal', 'Mariana Costa',   'De Portugal', PT[1]),
        (F_PT, 'Portugal', 'Pedro Pereira',   'De Portugal', PT[2]),
        (F_PT, 'Portugal', 'Ana Rodrigues',   'De Portugal', PT[3]),
        (F_PT, 'Portugal', 'Tiago Fernandes', 'De Portugal', PT[4]),
        (F_PT, 'Portugal', 'Catarina Sousa',  'De Portugal', PT[5]),
    ],
    f'{BASE}/pt/brasil/index.html': [
        (F_BR, 'Brasil', 'Ana Oliveira',   'Do Brasil', PT[0]),
        (F_BR, 'Brasil', 'Lucas Ferreira', 'Do Brasil', PT[1]),
        (F_BR, 'Brasil', 'Gabriela Almeida','Do Brasil', PT[2]),
        (F_BR, 'Brasil', 'Rafael Lima',    'Do Brasil', PT[3]),
        (F_BR, 'Brasil', 'Beatriz Ramos',  'Do Brasil', PT[4]),
        (F_BR, 'Brasil', 'Marcos Carvalho','Do Brasil', PT[5]),
    ],
    f'{BASE}/pt/angola/index.html': [
        (F_AO, 'Angola', 'Eduardo Santos', 'De Angola', PT[0]),
        (F_AO, 'Angola', 'Sofia Mendes',   'De Angola', PT[1]),
        (F_AO, 'Angola', 'Adriano Lopes',  'De Angola', PT[2]),
        (F_AO, 'Angola', 'Cristina Neto',  'De Angola', PT[3]),
        (F_AO, 'Angola', 'Filipe Gomes',   'De Angola', PT[4]),
        (F_AO, 'Angola', 'Teresa Cruz',    'De Angola', PT[5]),
    ],
    # ── Italian ──
    f'{BASE}/it/index.html': [
        (F_IT, 'Italia',     'Marco Romano',   "Dall'Italia",    IT[0]),
        (F_CH, 'Svizzera',   'Giulia Ferrari', 'Dalla Svizzera', IT[1]),
        (F_SM, 'San Marino', 'Luca Bianchi',   'Da San Marino',  IT[2]),
        (F_IT, 'Italia',     'Chiara Ricci',   "Dall'Italia",    IT[3]),
        (F_CH, 'Svizzera',   'Paolo Esposito', 'Dalla Svizzera', IT[4]),
        (F_IT, 'Italia',     'Francesca Russo',"Dall'Italia",    IT[5]),
    ],
    f'{BASE}/it/italia/index.html': [
        (F_IT, 'Italia', 'Marco Romano',   "Dall'Italia", IT[0]),
        (F_IT, 'Italia', 'Giulia Ferrari', "Dall'Italia", IT[1]),
        (F_IT, 'Italia', 'Luca Bianchi',   "Dall'Italia", IT[2]),
        (F_IT, 'Italia', 'Chiara Ricci',   "Dall'Italia", IT[3]),
        (F_IT, 'Italia', 'Paolo Esposito', "Dall'Italia", IT[4]),
        (F_IT, 'Italia', 'Francesca Russo',"Dall'Italia", IT[5]),
    ],
    f'{BASE}/it/svizzera/index.html': [
        (F_CH, 'Svizzera', 'Giulia Ferrari', 'Dalla Svizzera', IT[0]),
        (F_CH, 'Svizzera', 'Matteo Rossi',   'Dalla Svizzera', IT[1]),
        (F_CH, 'Svizzera', 'Sofia Mancini',  'Dalla Svizzera', IT[2]),
        (F_CH, 'Svizzera', 'Lorenzo Costa',  'Dalla Svizzera', IT[3]),
        (F_CH, 'Svizzera', 'Elena Conte',    'Dalla Svizzera', IT[4]),
        (F_CH, 'Svizzera', 'Andrea Moretti', 'Dalla Svizzera', IT[5]),
    ],
    f'{BASE}/it/san-marino/index.html': [
        (F_SM, 'San Marino', 'Luca Bianchi',     'Da San Marino', IT[0]),
        (F_SM, 'San Marino', 'Maria Valentini',  'Da San Marino', IT[1]),
        (F_SM, 'San Marino', 'Roberto Giordano', 'Da San Marino', IT[2]),
        (F_SM, 'San Marino', 'Alessia Fontana',  'Da San Marino', IT[3]),
        (F_SM, 'San Marino', 'Davide Marini',    'Da San Marino', IT[4]),
        (F_SM, 'San Marino', 'Cristina Serra',   'Da San Marino', IT[5]),
    ],
    f'{BASE}/it/germania/index.html': [
        (F_DE, 'Germania', 'Hans Müller',      'Dalla Germania', IT[0]),
        (F_DE, 'Germania', 'Angela Schneider', 'Dalla Germania', IT[1]),
        (F_DE, 'Germania', 'Klaus Fischer',    'Dalla Germania', IT[2]),
        (F_DE, 'Germania', 'Ursula Wagner',    'Dalla Germania', IT[3]),
        (F_DE, 'Germania', 'Werner Bauer',     'Dalla Germania', IT[4]),
        (F_DE, 'Germania', 'Ingrid Meyer',     'Dalla Germania', IT[5]),
    ],
    # ── Dutch ──
    f'{BASE}/nl/index.html': [
        (F_NL, 'Nederland', 'Jan de Vries',   'Uit Nederland', NL[0]),
        (F_BE, 'België',    'Sarah Peeters',  'Uit België',    NL[1]),
        (F_SR, 'Suriname',  'Kevin Jaipersad','Uit Suriname',  NL[2]),
        (F_NL, 'Nederland', 'Emma Bakker',    'Uit Nederland', NL[3]),
        (F_BE, 'België',    'Thomas Dubois',  'Uit België',    NL[4]),
        (F_NL, 'Nederland', 'Lotte Visser',   'Uit Nederland', NL[5]),
    ],
    f'{BASE}/nl/nederland/index.html': [
        (F_NL, 'Nederland', 'Jan de Vries',      'Uit Nederland', NL[0]),
        (F_NL, 'Nederland', 'Emma Bakker',        'Uit Nederland', NL[1]),
        (F_NL, 'Nederland', 'Lotte Visser',       'Uit Nederland', NL[2]),
        (F_NL, 'Nederland', 'Pieter van den Berg','Uit Nederland', NL[3]),
        (F_NL, 'Nederland', 'Sophie Jansen',      'Uit Nederland', NL[4]),
        (F_NL, 'Nederland', 'Daan Meijer',        'Uit Nederland', NL[5]),
    ],
    f'{BASE}/nl/belgie/index.html': [
        (F_BE, 'België', 'Sarah Peeters',    'Uit België', NL[0]),
        (F_BE, 'België', 'Thomas Dubois',    'Uit België', NL[1]),
        (F_BE, 'België', 'Nathalie Claes',   'Uit België', NL[2]),
        (F_BE, 'België', 'Raf Janssen',      'Uit België', NL[3]),
        (F_BE, 'België', 'Elise Vermeersch', 'Uit België', NL[4]),
        (F_BE, 'België', 'Wout Declercq',    'Uit België', NL[5]),
    ],
    f'{BASE}/nl/duitsland/index.html': [
        (F_DE, 'Duitsland', 'Hans Müller',      'Uit Duitsland', NL[0]),
        (F_DE, 'Duitsland', 'Angela Schneider', 'Uit Duitsland', NL[1]),
        (F_DE, 'Duitsland', 'Klaus Fischer',    'Uit Duitsland', NL[2]),
        (F_DE, 'Duitsland', 'Ursula Wagner',    'Uit Duitsland', NL[3]),
        (F_DE, 'Duitsland', 'Werner Bauer',     'Uit Duitsland', NL[4]),
        (F_DE, 'Duitsland', 'Ingrid Meyer',     'Uit Duitsland', NL[5]),
    ],
    f'{BASE}/nl/suriname/index.html': [
        (F_SR, 'Suriname', 'Kevin Jaipersad',   'Uit Suriname', NL[0]),
        (F_SR, 'Suriname', 'Priya Ramkhelawan', 'Uit Suriname', NL[1]),
        (F_SR, 'Suriname', 'Marcus Bhoedoe',    'Uit Suriname', NL[2]),
        (F_SR, 'Suriname', 'Sandra Aboikoni',   'Uit Suriname', NL[3]),
        (F_SR, 'Suriname', 'Jerome Mathoera',   'Uit Suriname', NL[4]),
        (F_SR, 'Suriname', 'Nisha Hindoepersad','Uit Suriname', NL[5]),
    ],
    # ── Turkish ──
    f'{BASE}/tr/index.html': [
        (F_TR, 'Türkiye',   'Ahmet Yılmaz',   "Türkiye'den",    TR[0]),
        (F_AZ, 'Azerbaycan','Əli Hüseynov',   "Azerbaycan'dan", TR[1]),
        (F_CY, 'Kıbrıs',   'Mehmet Kaya',    "Kıbrıs'tan",     TR[2]),
        (F_TR, 'Türkiye',   'Fatma Demir',    "Türkiye'den",    TR[3]),
        (F_AZ, 'Azerbaycan','Leyla Mammadova',"Azerbaycan'dan", TR[4]),
        (F_TR, 'Türkiye',   'Mustafa Şahin',  "Türkiye'den",    TR[5]),
    ],
    f'{BASE}/tr/turkiye/index.html': [
        (F_TR, 'Türkiye', 'Ahmet Yılmaz',  "Türkiye'den", TR[0]),
        (F_TR, 'Türkiye', 'Fatma Demir',   "Türkiye'den", TR[1]),
        (F_TR, 'Türkiye', 'Mustafa Şahin', "Türkiye'den", TR[2]),
        (F_TR, 'Türkiye', 'Ayşe Kaya',     "Türkiye'den", TR[3]),
        (F_TR, 'Türkiye', 'Mehmet Çelik',  "Türkiye'den", TR[4]),
        (F_TR, 'Türkiye', 'Zeynep Arslan', "Türkiye'den", TR[5]),
    ],
    f'{BASE}/tr/almanya/index.html': [
        (F_DE, 'Almanya', 'Ahmet Yılmaz',  "Almanya'dan", TR[0]),
        (F_DE, 'Almanya', 'Fatma Demir',   "Almanya'dan", TR[1]),
        (F_DE, 'Almanya', 'Mustafa Şahin', "Almanya'dan", TR[2]),
        (F_DE, 'Almanya', 'Ayşe Kaya',     "Almanya'dan", TR[3]),
        (F_DE, 'Almanya', 'Mehmet Çelik',  "Almanya'dan", TR[4]),
        (F_DE, 'Almanya', 'Zeynep Arslan', "Almanya'dan", TR[5]),
    ],
    f'{BASE}/tr/azerbaycan/index.html': [
        (F_AZ, 'Azerbaycan', 'Əli Hüseynov',   "Azerbaycan'dan", TR[0]),
        (F_AZ, 'Azerbaycan', 'Leyla Mammadova', "Azerbaycan'dan", TR[1]),
        (F_AZ, 'Azerbaycan', 'Rəşad Həsənli',  "Azerbaycan'dan", TR[2]),
        (F_AZ, 'Azerbaycan', 'Günel Əliyeva',  "Azerbaycan'dan", TR[3]),
        (F_AZ, 'Azerbaycan', 'Tural Babayev',  "Azerbaycan'dan", TR[4]),
        (F_AZ, 'Azerbaycan', 'Sevinc Quliyeva',"Azerbaycan'dan", TR[5]),
    ],
    f'{BASE}/tr/kibris/index.html': [
        (F_CY, 'Kıbrıs', 'Mehmet Kaya',   "Kıbrıs'tan", TR[0]),
        (F_CY, 'Kıbrıs', 'Ayşe Öztürk',  "Kıbrıs'tan", TR[1]),
        (F_CY, 'Kıbrıs', 'Ali Erdoğan',  "Kıbrıs'tan", TR[2]),
        (F_CY, 'Kıbrıs', 'Fatma Yiğit',  "Kıbrıs'tan", TR[3]),
        (F_CY, 'Kıbrıs', 'Hüseyin Polat',"Kıbrıs'tan", TR[4]),
        (F_CY, 'Kıbrıs', 'Hatice Güler', "Kıbrıs'tan", TR[5]),
    ],
}

# ── Run ────────────────────────────────────────────────────────────────────────
for filepath, cards_data in PAGES.items():
    update_file(filepath, cards_data)

print('Done!')
