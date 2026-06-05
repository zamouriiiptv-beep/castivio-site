#!/usr/bin/env python3
"""Add theme-toggle button + early-init scripts to all language pages."""

import re

THEME_TOGGLE_BTN = '''<button id="theme-toggle" aria-label="Toggle day/night mode">
        <svg class="icon-moon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
        </svg>
        <svg class="icon-sun" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
          <circle cx="12" cy="12" r="5"/>
          <line x1="12" y1="1" x2="12" y2="3" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
          <line x1="12" y1="21" x2="12" y2="23" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
          <line x1="4.22" y1="4.22" x2="5.64" y2="5.64" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
          <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
          <line x1="1" y1="12" x2="3" y2="12" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
          <line x1="21" y1="12" x2="23" y2="12" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
          <line x1="4.22" y1="19.78" x2="5.64" y2="18.36" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
          <line x1="18.36" y1="5.64" x2="19.78" y2="4.22" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
        </svg>
      </button>'''

PAGES = [
    'en/index.html', 'fr/index.html', 'es/index.html', 'pt/index.html',
    'de/index.html', 'tr/index.html', 'it/index.html', 'nl/index.html',
    'en/uk/index.html', 'en/usa/index.html', 'en/canada/index.html',
    'fr/france/index.html', 'fr/belgique/index.html', 'fr/canada/index.html',
    'es/espana/index.html', 'es/argentina/index.html', 'es/mexico/index.html',
    'pt/brasil/index.html', 'pt/portugal/index.html', 'pt/angola/index.html',
    'de/deutschland/index.html', 'de/oesterreich/index.html', 'de/schweiz/index.html',
    'tr/turkiye/index.html', 'tr/kibris/index.html', 'tr/almanya/index.html', 'tr/azerbaycan/index.html',
    'it/italia/index.html', 'it/svizzera/index.html', 'it/germania/index.html', 'it/san-marino/index.html',
    'nl/nederland/index.html', 'nl/belgie/index.html', 'nl/suriname/index.html', 'nl/duitsland/index.html',
]

EARLY_INIT = "<script>try{if(localStorage.getItem('theme')==='light'){document.documentElement.classList.add('light-mode');}}catch(e){}</script>"
BODY_INIT  = "<script>try{if(localStorage.getItem('theme')==='light'){document.body.classList.add('light-mode');}}catch(e){}</script>"

updated = 0
errors = []

for rel_path in PAGES:
    with open(rel_path, encoding='utf-8') as f:
        html = f.read()

    orig = html

    # 1. Early-init script in <head> after stylesheet
    if EARLY_INIT not in html:
        html = html.replace(
            '<link rel="stylesheet" href="/styles.css?v=114">',
            '<link rel="stylesheet" href="/styles.css?v=114">\n  ' + EARLY_INIT,
            1
        )

    # 2. Body early-init right after <body ...>
    if BODY_INIT not in html:
        body_match = re.search(r'<body[^>]*>', html)
        if body_match:
            body_tag = body_match.group(0)
            html = html.replace(body_tag, body_tag + '\n' + BODY_INIT, 1)

    # 3. Wrap menu-btn with theme-toggle in a flex div
    if 'id="theme-toggle"' not in html:
        menu_match = re.search(r'(<button id="menu-btn"[^>]*>.*?</button>)', html, re.DOTALL)
        if menu_match:
            menu_html = menu_match.group(1)
            wrapped = (
                '<div class="flex items-center gap-2">\n      '
                + THEME_TOGGLE_BTN
                + '\n      '
                + menu_html
                + '\n    </div>'
            )
            html = html[:menu_match.start()] + wrapped + html[menu_match.end():]
        else:
            errors.append(f'No menu-btn found: {rel_path}')

    # 4. Bump script.js to latest version
    html = re.sub(r'/script\.js\?v=\d+', '/script.js?v=12', html)

    if html != orig:
        with open(rel_path, 'w', encoding='utf-8') as f:
            f.write(html)
        updated += 1
        print(f'  OK  {rel_path}')

print(f'\nDone — {updated} files updated.')
if errors:
    print('ERRORS:')
    for e in errors:
        print(' ', e)
