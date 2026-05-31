#!/usr/bin/env python3
"""
Fix section order on sub-pages where #why-us appears BEFORE .hp-hero.
Correct order: hero first, then why-us.
"""
import re, os

BASE = "/home/user/Prime-iptv"

WHYUS_START = '<!-- ═══════════════ WHY-US SECTION ═══════════════ -->'
WHYUS_END   = '<!-- ═══════════════ END WHY-US ═══════════════ -->'


def find_hero_end(text, hero_start):
    """Return position just after the </section> that closes the hp-hero section."""
    depth = 0
    i = hero_start
    while i < len(text):
        open_m  = re.search(r'<section\b', text[i:])
        close_m = re.search(r'</section>', text[i:])
        if open_m and (close_m is None or open_m.start() < close_m.start()):
            depth += 1
            i += open_m.end()
        elif close_m:
            depth -= 1
            if depth == 0:
                return i + close_m.end()
            i += close_m.end()
        else:
            break
    return -1


def fix_page(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Locate WHY-US block
    ws = content.find(WHYUS_START)
    we = content.find(WHYUS_END)
    if ws == -1 or we == -1:
        return None, "no why-us markers"

    we_end = we + len(WHYUS_END)

    # Is why-us BEFORE hero?
    hero_m = re.search(r'<section\b[^>]*\bhp-hero\b[^>]*>', content[we_end:])
    if not hero_m:
        return False, "hero already before why-us or missing"

    hero_abs_start = we_end + hero_m.start()
    hero_abs_end   = find_hero_end(content, hero_abs_start)
    if hero_abs_end == -1:
        return None, "could not find hero closing tag"

    before_whyus = content[:ws]
    whyus_block  = content[ws:we_end]
    between      = content[we_end:hero_abs_start]  # whitespace between END and <section hp-hero>
    hero_block   = content[hero_abs_start:hero_abs_end]
    after_hero   = content[hero_abs_end:]

    new_content = before_whyus + hero_block + between + whyus_block + after_hero

    if new_content == content:
        return False, "no change"

    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    return True, "fixed"


# Collect all index.html files
changed = []
skipped = []

for root, dirs, files in os.walk(BASE):
    dirs[:] = [d for d in dirs if d not in ('.git',)]
    for fname in files:
        if fname != 'index.html':
            continue
        abs_path = os.path.join(root, fname)
        rel      = abs_path[len(BASE)+1:]

        ok, msg = fix_page(abs_path)
        if ok:
            print(f"[FIXED]   {rel}")
            changed.append(rel)
        elif ok is False:
            print(f"[SKIP]    {rel} — {msg}")
        else:
            print(f"[ERROR]   {rel} — {msg}")

print(f"\nDone — {len(changed)} fixed.")
if changed:
    print("Fixed pages:")
    for p in changed:
        print(f"  {p}")
