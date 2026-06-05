#!/usr/bin/env python3
"""Fix navbar order on sub-pages: logo → toggle → btn  →  toggle → logo → btn"""

import re

SUB_PAGES = [
    'en/uk/index.html', 'en/usa/index.html', 'en/canada/index.html',
    'fr/france/index.html', 'fr/belgique/index.html', 'fr/canada/index.html',
    'es/espana/index.html', 'es/argentina/index.html', 'es/mexico/index.html',
    'pt/brasil/index.html', 'pt/portugal/index.html', 'pt/angola/index.html',
    'de/deutschland/index.html', 'de/oesterreich/index.html', 'de/schweiz/index.html',
    'tr/turkiye/index.html', 'tr/kibris/index.html', 'tr/almanya/index.html', 'tr/azerbaycan/index.html',
    'it/italia/index.html', 'it/svizzera/index.html', 'it/germania/index.html', 'it/san-marino/index.html',
    'nl/nederland/index.html', 'nl/belgie/index.html', 'nl/suriname/index.html', 'nl/duitsland/index.html',
]

updated = 0
errors = []

for path in SUB_PAGES:
    with open(path, encoding='utf-8') as f:
        html = f.read()

    orig = html

    # Pattern: logo-name div  THEN  flex-gap-2 div (with toggle+menu inside)
    # We want to SWAP these two blocks
    pattern = re.compile(
        r'(\s*<div id="logo-name"[^>]*>.*?</div>)'
        r'(\s*\n\s*<div class="flex items-center gap-2">.*?</div>)',
        re.DOTALL
    )

    m = pattern.search(html)
    if not m:
        errors.append(f'Pattern not found: {path}')
        continue

    logo_block   = m.group(1)   # e.g.  \n    <div id="logo-name">...</div>
    toggle_block = m.group(2)   # e.g.  \n    <div class="flex items-center gap-2">...</div>

    # Swap: put toggle block first, then logo block
    html = html[:m.start()] + toggle_block + logo_block + html[m.end():]

    if html != orig:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(html)
        updated += 1
        print(f'  ✅  {path}')
    else:
        print(f'  ⏭  {path} (no change needed)')

print(f'\nDone — {updated} files fixed.')
if errors:
    print('ERRORS:')
    for e in errors:
        print(' ', e)
