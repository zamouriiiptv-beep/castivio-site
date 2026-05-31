#!/usr/bin/env python3
"""
Diversify Hero title (main line) on COUNTRY sub-pages only.
Country name becomes the gradient word. Subtitle and description untouched.
Main language pages and guide pages are NOT modified.
"""
import re, os

BASE = "/home/user/Prime-iptv"

# rel_path -> title main HTML (the line between <h1> and the <span hp-title-sub>)
TITLES = {
    # EN
    "en/uk/index.html":        'World-Class Streaming in the <span class="hp-grad">UK</span>',
    "en/usa/index.html":       'Streaming Without Limits in the <span class="hp-grad">USA</span>',
    "en/canada/index.html":    'Reliable Streaming for <span class="hp-grad">Canada</span>',
    # FR
    "fr/france/index.html":    'Le streaming nouvelle génération en <span class="hp-grad">France</span>',
    "fr/belgique/index.html":  'Votre streaming premium en <span class="hp-grad">Belgique</span>',
    "fr/canada/index.html":    'Le streaming sans coupure au <span class="hp-grad">Canada</span>',
    # ES
    "es/espana/index.html":    'Streaming de nivel mundial en <span class="hp-grad">España</span>',
    "es/mexico/index.html":    'Streaming premium en <span class="hp-grad">México</span>',
    "es/argentina/index.html": 'Streaming sin cortes en <span class="hp-grad">Argentina</span>',
    # DE
    "de/deutschland/index.html": 'Premium-Streaming in <span class="hp-grad">Deutschland</span>',
    "de/oesterreich/index.html": 'Streaming der Spitzenklasse in <span class="hp-grad">Österreich</span>',
    "de/schweiz/index.html":     'Premium-Streaming in der <span class="hp-grad">Schweiz</span>',
    # IT
    "it/italia/index.html":    'Streaming di livello mondiale in <span class="hp-grad">Italia</span>',
    "it/svizzera/index.html":  'Streaming affidabile in <span class="hp-grad">Svizzera</span>',
    "it/germania/index.html":  'Il tuo streaming premium in <span class="hp-grad">Germania</span>',
    "it/san-marino/index.html":'Streaming premium a <span class="hp-grad">San Marino</span>',
    # NL
    "nl/nederland/index.html": 'Streaming op wereldniveau in <span class="hp-grad">Nederland</span>',
    "nl/belgie/index.html":    'Premium streamen in <span class="hp-grad">België</span>',
    "nl/duitsland/index.html": 'Stabiel streamen in <span class="hp-grad">Duitsland</span>',
    "nl/suriname/index.html":  'Betrouwbaar streamen in <span class="hp-grad">Suriname</span>',
    # PT
    "pt/portugal/index.html":  'Streaming de classe mundial em <span class="hp-grad">Portugal</span>',
    "pt/brasil/index.html":    'Streaming premium no <span class="hp-grad">Brasil</span>',
    "pt/angola/index.html":    'Streaming estável em <span class="hp-grad">Angola</span>',
    # TR (country first)
    "tr/turkiye/index.html":   '<span class="hp-grad">Türkiye</span>\'nin Premium Yayın Deneyimi',
    "tr/azerbaycan/index.html":'<span class="hp-grad">Azerbaycan</span> için Premium Yayın',
    "tr/almanya/index.html":   '<span class="hp-grad">Almanya</span>\'da Kesintisiz Yayın',
    "tr/kibris/index.html":    '<span class="hp-grad">Kıbrıs</span> için Premium Yayın',
}

# Replace only the first text line inside the h1 (before hp-title-sub)
H1_RE = re.compile(
    r'(<h1 class="hp-title hp-reveal"[^>]*>\s*\n)'
    r'.*?'
    r'(\n\s*<span class="hp-title-sub">)',
    re.DOTALL
)

changed = 0
for rel, new_title in TITLES.items():
    path = os.path.join(BASE, rel)
    if not os.path.exists(path):
        print(f"[MISS] {rel}")
        continue
    with open(path, encoding="utf-8") as f:
        content = f.read()

    new = H1_RE.sub(rf'\g<1>      {new_title}\g<2>', content, count=1)
    if new == content:
        print(f"[SAME] {rel}")
        continue
    with open(path, "w", encoding="utf-8") as f:
        f.write(new)
    print(f"[OK]  {rel}")
    changed += 1

print(f"\nDone — {changed} updated.")
