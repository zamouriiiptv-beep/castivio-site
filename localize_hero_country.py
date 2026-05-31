#!/usr/bin/env python3
"""
Update Hero title + subtitle on country sub-pages to include the country name.
Description (hp-desc) is NOT touched — title and subtitle only.
"""
import re, os

BASE = "/home/user/Prime-iptv"

# ── Per-page content (rel_path → (title_main_html, subtitle_text)) ────────────
PAGES = {
    # ── Arabic guide sub-pages ────────────────────────────────────────────────
    "guide/khalij/index.html": (
        'بث <span class="hp-grad">عالمي</span>',
        'مخصص لمشاهدي الخليج العربي',
    ),
    "guide/maghreb/index.html": (
        'بث <span class="hp-grad">عالمي</span>',
        'مخصص لمشاهدي المغرب العربي',
    ),
    "guide/mashriq/index.html": (
        'بث <span class="hp-grad">عالمي</span>',
        'مخصص لمشاهدي المشرق العربي',
    ),

    # ── English ───────────────────────────────────────────────────────────────
    "en/uk/index.html": (
        'World-Class <span class="hp-grad">Streaming</span>',
        'Built for Viewers Across the United Kingdom',
    ),
    "en/usa/index.html": (
        'Streaming <span class="hp-grad">Without Limits</span>',
        'Optimized for Viewers in the United States',
    ),
    "en/canada/index.html": (
        'Reliable <span class="hp-grad">Streaming</span> Experience',
        'Designed for Canadian Viewers',
    ),

    # ── French ────────────────────────────────────────────────────────────────
    "fr/france/index.html": (
        'Le streaming <span class="hp-grad">nouvelle génération</span>',
        'Pensé pour les utilisateurs en France',
    ),
    "fr/belgique/index.html": (
        'Le streaming <span class="hp-grad">nouvelle génération</span>',
        'Conçu pour les utilisateurs en Belgique',
    ),
    "fr/canada/index.html": (
        'Le streaming <span class="hp-grad">nouvelle génération</span>',
        'Adapté aux utilisateurs francophones au Canada',
    ),

    # ── Spanish ───────────────────────────────────────────────────────────────
    "es/espana/index.html": (
        'Streaming de <span class="hp-grad">nivel mundial</span>',
        'Diseñado para usuarios en España',
    ),
    "es/mexico/index.html": (
        'Streaming de <span class="hp-grad">nivel mundial</span>',
        'Optimizado para usuarios en México',
    ),
    "es/argentina/index.html": (
        'Streaming de <span class="hp-grad">nivel mundial</span>',
        'Pensado para los usuarios en Argentina',
    ),

    # ── German ────────────────────────────────────────────────────────────────
    "de/deutschland/index.html": (
        'Streaming auf <span class="hp-grad">Weltklasse-Niveau</span>',
        'Optimiert für Zuschauer in Deutschland',
    ),
    "de/oesterreich/index.html": (
        'Streaming auf <span class="hp-grad">Weltklasse-Niveau</span>',
        'Maßgeschneidert für Zuschauer in Österreich',
    ),
    "de/schweiz/index.html": (
        'Streaming auf <span class="hp-grad">Weltklasse-Niveau</span>',
        'Für Zuschauer in der Schweiz optimiert',
    ),

    # ── Italian ───────────────────────────────────────────────────────────────
    "it/italia/index.html": (
        'Streaming di <span class="hp-grad">livello mondiale</span>',
        'Progettato per gli utenti in Italia',
    ),
    "it/svizzera/index.html": (
        'Streaming di <span class="hp-grad">livello mondiale</span>',
        'Pensato per gli utenti in Svizzera',
    ),
    "it/germania/index.html": (
        'Streaming di <span class="hp-grad">livello mondiale</span>',
        'Ottimizzato per gli utenti in Germania',
    ),
    "it/san-marino/index.html": (
        'Streaming di <span class="hp-grad">livello mondiale</span>',
        'Progettato per gli utenti di San Marino',
    ),

    # ── Dutch ─────────────────────────────────────────────────────────────────
    "nl/nederland/index.html": (
        'Streaming op <span class="hp-grad">wereldniveau</span>',
        'Ontworpen voor kijkers in Nederland',
    ),
    "nl/belgie/index.html": (
        'Streaming op <span class="hp-grad">wereldniveau</span>',
        'Speciaal voor kijkers in België',
    ),
    "nl/duitsland/index.html": (
        'Streaming op <span class="hp-grad">wereldniveau</span>',
        'Afgestemd op kijkers in Duitsland',
    ),
    "nl/suriname/index.html": (
        'Streaming op <span class="hp-grad">wereldniveau</span>',
        'Beschikbaar voor kijkers in Suriname',
    ),

    # ── Portuguese ────────────────────────────────────────────────────────────
    "pt/portugal/index.html": (
        'Streaming de <span class="hp-grad">classe mundial</span>',
        'Criado para utilizadores em Portugal',
    ),
    "pt/brasil/index.html": (
        'Streaming de <span class="hp-grad">classe mundial</span>',
        'Desenvolvido para os usuários no Brasil',
    ),
    "pt/angola/index.html": (
        'Streaming de <span class="hp-grad">classe mundial</span>',
        'Pensado para os utilizadores em Angola',
    ),

    # ── Turkish ───────────────────────────────────────────────────────────────
    "tr/turkiye/index.html": (
        'Dünya Standartlarında <span class="hp-grad">Yayın</span>',
        'Türkiye\'deki kullanıcılar için optimize edildi',
    ),
    "tr/azerbaycan/index.html": (
        'Dünya Standartlarında <span class="hp-grad">Yayın</span>',
        'Azerbaycan\'daki kullanıcılar için özel hazırlandı',
    ),
    "tr/almanya/index.html": (
        'Dünya Standartlarında <span class="hp-grad">Yayın</span>',
        'Almanya\'daki kullanıcılar için optimize edildi',
    ),
    "tr/kibris/index.html": (
        'Dünya Standartlarında <span class="hp-grad">Yayın</span>',
        'Kıbrıs\'taki kullanıcılar için özel hazırlandı',
    ),
}


def build_title(main, sub):
    return (
        '    <h1 class="hp-title hp-reveal" style="--d:90ms">\n'
        f'      {main}\n'
        f'      <span class="hp-title-sub">{sub}</span>\n'
        '    </h1>'
    )


TITLE_RE = re.compile(
    r'<h1 class="hp-title hp-reveal"[^>]*>.*?</h1>',
    re.DOTALL
)

changed = skipped = 0

for rel, (main, sub) in PAGES.items():
    abs_path = os.path.join(BASE, rel)
    if not os.path.exists(abs_path):
        print(f"[MISS] {rel}")
        continue

    with open(abs_path, "r", encoding="utf-8") as f:
        content = f.read()

    new_title   = build_title(main, sub)
    new_content = TITLE_RE.sub(new_title, content, count=1)

    if new_content == content:
        print(f"[SAME] {rel}")
        skipped += 1
        continue

    with open(abs_path, "w", encoding="utf-8") as f:
        f.write(new_content)
    print(f"[OK]  {rel}")
    changed += 1

print(f"\nDone — {changed} updated, {skipped} skipped.")
