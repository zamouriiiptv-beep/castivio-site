#!/usr/bin/env python3
"""
Unified Spacing System
======================
Adds CSS variables --section-gap-mobile / --section-gap-desktop to styles.css
and applies them to ALL content sections (why-us, guides-section, pricing, faq,
testimonials, seo-text).

Values chosen:
  --section-gap-mobile : 40 px  (section padding-top AND padding-bottom on mobile)
  --section-gap-desktop: 80 px  (section padding-top AND padding-bottom on ≥768 px)

  → Visual gap between any two consecutive sections = 80 px mobile / 160 px desktop.

Only padding-top and padding-bottom are touched. Nothing else.
"""
import re, os

BASE = "/home/user/Prime-iptv"

# ── 1. styles.css ─────────────────────────────────────────────────────────────

with open(f"{BASE}/styles.css", encoding="utf-8") as f:
    css = f.read()

# 1a. Add CSS variables to :root
css = css.replace(
    "--hero-height-guide:455px;",
    "--hero-height-guide:455px;--section-gap-mobile:40px;--section-gap-desktop:80px;",
    1
)

# 1b. Update .section-spacing mobile
css = css.replace(
    ".section-spacing{padding-block:32px}",
    ".section-spacing{padding-block:var(--section-gap-mobile)}",
    1
)

# 1c. Update .section-spacing desktop (remove clamp)
css = css.replace(
    ".section-spacing{padding-block:clamp(70px,8vw,110px)}",
    ".section-spacing{padding-block:var(--section-gap-desktop)}",
    1
)

# 1d. Remove legacy body.hp-home #why-us padding-top:90px (1024px media query)
css = css.replace("body.hp-home #why-us{padding-top:90px}", "", 1)

# 1e. Add unified rules for #why-us and #guides-section right after section-spacing rules
anchor = ".section-spacing h1,.section-spacing h2,.section-spacing h3,.section-spacing p{margin-top:0 !important}"
new_rules = (
    "#why-us{padding-top:var(--section-gap-mobile)!important;"
    "padding-bottom:var(--section-gap-mobile)!important}"
    "#guides-section{padding-top:var(--section-gap-mobile)!important;"
    "padding-bottom:var(--section-gap-mobile)!important}"
    "@media (min-width:768px){"
    "#why-us{padding-top:var(--section-gap-desktop)!important;"
    "padding-bottom:var(--section-gap-desktop)!important}"
    "#guides-section{padding-top:var(--section-gap-desktop)!important;"
    "padding-bottom:var(--section-gap-desktop)!important}"
    "}"
)
css = css.replace(anchor, anchor + new_rules, 1)

with open(f"{BASE}/styles.css", "w", encoding="utf-8") as f:
    f.write(css)
print("[OK] styles.css")


# ── 2. HTML pages: remove inline padding overrides ────────────────────────────

def clean_page(path):
    with open(path, encoding="utf-8") as f:
        content = f.read()
    original = content

    # Remove padding from desktop #why-us rule:  padding: 44px 0 100px;
    content = re.sub(
        r'(#why-us\s*\{[^}]*)padding:\s*44px\s+0\s+100px\s*;',
        r'\1',
        content
    )
    # Remove padding from mobile #why-us rule:  padding: 14px 0 60px;
    content = re.sub(
        r'(#why-us\s*\{[^}]*)padding:\s*14px\s+0\s+60px\s*;',
        r'\1',
        content
    )
    # Remove padding from #guides-section desktop rule:  padding: 0 0 70px;
    content = re.sub(
        r'(#guides-section\s*\{[^}]*)padding:\s*0\s+0\s+70px\s*;',
        r'\1',
        content
    )
    # Remove entire #guides-section mobile rule (padding-only rule → empty after removal)
    content = re.sub(
        r'#guides-section\s*\{\s*padding:\s*6px\s+0\s+30px\s*;\s*\}\n?',
        '',
        content
    )
    # Remove empty rules that may remain after padding removal
    content = re.sub(r'#why-us\s*\{\s*\}\n?', '', content)
    content = re.sub(r'#guides-section\s*\{\s*\}\n?', '', content)

    if content == original:
        return False

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    return True


changed = 0
for root, dirs, files in os.walk(BASE):
    dirs[:] = [d for d in dirs if d != ".git"]
    for fname in files:
        if fname != "index.html":
            continue
        path = os.path.join(root, fname)
        rel  = path[len(BASE) + 1:]
        if clean_page(path):
            print(f"[OK] {rel}")
            changed += 1

print(f"\nDone — {changed} HTML files cleaned.")
