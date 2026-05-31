#!/usr/bin/env python3
"""
Localize Hero title + description across all language pages.
Text-only replacement — structure, classes, CSS untouched.
"""
import re, os

BASE = "/home/user/Prime-iptv"

# ── Content per language ──────────────────────────────────────────────────────
# (title_main_html, title_sub, desc_lines)
CONTENT = {
    # AR — reference version (already on index.html; applied to guide pages too)
    "ar": (
        'بث <span class="hp-grad">عالمي</span>',
        'بمعايير حديثة',
        [
            'من أوروبا إلى أمريكا والعالم العربي —',
            'جودة ثابتة، أداء موثوق، وتجربة مشاهدة',
            'مصممة لتواكب تطلعات المستخدمين حول العالم.',
        ]
    ),

    # EN — naturally written British/North-American marketing
    "en": (
        'World-Class <span class="hp-grad">Streaming</span>',
        'Built for the Modern Viewer',
        [
            'Stable performance, sharp picture quality, and full device compatibility —',
            'engineered for viewers who simply expect the best.',
        ]
    ),

    # FR — natural French, no word-for-word translation
    "fr": (
        'Le streaming <span class="hp-grad">nouvelle génération</span>',
        'Fiable, fluide, sans compromis',
        [
            'De l\'Europe aux Amériques et au monde arabe —',
            'qualité d\'image irréprochable et performances stables pour les plus exigeants.',
        ]
    ),

    # ES — natural Spanish, Spain/LatAm tone
    "es": (
        'Streaming de <span class="hp-grad">nivel mundial</span>',
        'Diseñado para los más exigentes',
        [
            'De Europa a América y el mundo árabe —',
            'imagen impecable, rendimiento estable y compatibilidad total con tus dispositivos.',
        ]
    ),

    # DE — natural German, precise and trustworthy tone
    "de": (
        'Streaming auf <span class="hp-grad">Weltklasse-Niveau</span>',
        'Klar. Stabil. Für alle Ihre Geräte.',
        [
            'Von Europa bis Amerika und in die arabische Welt —',
            'kristallklare Bildqualität und zuverlässige Leistung ohne Kompromisse.',
        ]
    ),

    # IT — natural Italian, quality-focused
    "it": (
        'Streaming di <span class="hp-grad">livello mondiale</span>',
        'Nitido, stabile e senza interruzioni',
        [
            'Dall\'Europa alle Americhe e al mondo arabo —',
            'qualità visiva impeccabile e prestazioni affidabili su qualsiasi dispositivo.',
        ]
    ),

    # NL — natural Dutch, direct and reliable tone
    "nl": (
        'Streaming op <span class="hp-grad">wereldniveau</span>',
        'Scherp, stabiel en altijd betrouwbaar',
        [
            'Van Europa tot Amerika en de Arabische wereld —',
            'kristalhelder beeld en topprestaties op elk apparaat.',
        ]
    ),

    # PT — natural Portuguese, Brazil/Portugal tone
    "pt": (
        'Streaming de <span class="hp-grad">classe mundial</span>',
        'Estável, nítido e sem interrupções',
        [
            'Da Europa às Américas e ao mundo árabe —',
            'qualidade de imagem impecável e desempenho que não falha em nenhum dispositivo.',
        ]
    ),

    # TR — natural Turkish, modern and confident
    "tr": (
        'Dünya Standartlarında <span class="hp-grad">Yayın</span>',
        'Kesintisiz, Net ve Her Cihazda',
        [
            'Avrupa\'dan Amerika\'ya ve Arap dünyasına —',
            'kusursuz görüntü kalitesi ve her cihazda güvenilir performans.',
        ]
    ),
}


def build_title(main, sub):
    return (
        '    <h1 class="hp-title hp-reveal" style="--d:90ms">\n'
        f'      {main}\n'
        f'      <span class="hp-title-sub">{sub}</span>\n'
        '    </h1>'
    )


def build_desc(lines):
    br = '\n      <br class="hp-br">\n      '
    body = br.join(lines)
    return (
        '    <p class="hp-desc hp-reveal" style="--d:180ms">\n'
        f'      {body}\n'
        '    </p>'
    )


# Match the full h1.hp-title and p.hp-desc elements
TITLE_RE = re.compile(
    r'<h1 class="hp-title hp-reveal"[^>]*>.*?</h1>',
    re.DOTALL
)
DESC_RE = re.compile(
    r'<p class="hp-desc hp-reveal"[^>]*>.*?</p>',
    re.DOTALL
)


def lang_for(rel_path):
    """Map a relative path to its language code."""
    parts = rel_path.strip("/").split("/")
    top = parts[0]
    skip = {"privacy-policy", "terms-of-service", "review"}
    if any(p in skip for p in parts):
        return None
    if top == "index.html" or top == "guide":
        return "ar"
    if top in CONTENT:
        return top
    return None


changed = skipped = 0

for root, dirs, files in os.walk(BASE):
    dirs[:] = [d for d in dirs if d != ".git"]
    for fname in files:
        if fname != "index.html":
            continue
        abs_path = os.path.join(root, fname)
        rel_path = abs_path[len(BASE):]

        lang = lang_for(rel_path)
        if lang is None:
            skipped += 1
            continue

        with open(abs_path, "r", encoding="utf-8") as f:
            content = f.read()

        if 'hp-title hp-reveal' not in content:
            skipped += 1
            continue

        main, sub, lines = CONTENT[lang]
        new_title = build_title(main, sub)
        new_desc  = build_desc(lines)

        new_content = TITLE_RE.sub(new_title, content, count=1)
        new_content = DESC_RE.sub(new_desc,  new_content, count=1)

        if new_content == content:
            print(f"[SAME] {rel_path}")
            skipped += 1
            continue

        with open(abs_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"[OK]  {lang:2s} → {rel_path}")
        changed += 1

print(f"\nDone — {changed} updated, {skipped} skipped.")
