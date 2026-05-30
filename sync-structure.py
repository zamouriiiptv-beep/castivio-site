#!/usr/bin/env python3
"""
sync-structure.py
=================
Syncs structural HTML blocks from the AR master (index.html) to all pages.

WHAT IS SYNCED (structural):
  [SYNC-PERF-HEAD]  preconnect + DNS hints + CSS/fonts/FA/tailwind loading
  [SYNC-PERF-FOOT]  footer.css + footer.js loading at bottom of body

WHAT IS NOT SYNCED (content — stays per-page):
  <title>, <meta description/keywords>, <link rel="canonical/alternate">
  Structured data (ld+json), page body content, nav active states

SKIPPED PAGES:
  guide/*, privacy-policy/*, terms-of-service/*

USAGE:
  python3 sync-structure.py              # preview only (dry run)
  python3 sync-structure.py --apply      # apply changes to all pages
  python3 sync-structure.py --init       # first-time: add markers to all pages
"""

import os, re, sys

ROOT    = os.path.dirname(os.path.abspath(__file__))
MASTER  = os.path.join(ROOT, "index.html")

SKIP_SEGMENTS = {"guide", "privacy-policy", "terms-of-service"}

BLOCKS = [
    "SYNC-PERF-HEAD",
    "SYNC-PERF-FOOT",
]

# Patterns used by --init to find insertion points in pages without markers
INIT_PATTERNS = {
    "SYNC-PERF-HEAD": {
        "start_re": r'<link\s+rel="preconnect"\s+href="https://fonts\.gstatic\.com"',
        "end_re":   r'<noscript><link rel="stylesheet" href="/css/tailwind\.min\.css[^>]+></noscript>',
        "fallback_end_re": r'<noscript><link rel="stylesheet" href="[^"]*tailwind[^"]*"></noscript>',
    },
    "SYNC-PERF-FOOT": {
        "start_re": r'<link rel="preload" href="[^"]*footer\.css[^"]*"',
        "end_re":   r'<script src="[^"]*footer\.js[^"]*"\s+defer></script>',
    },
}


# ── helpers ────────────────────────────────────────────────────────────────

def should_skip(path: str) -> bool:
    parts = set(path.replace(ROOT, "").replace("\\", "/").strip("/").split("/"))
    return bool(parts & SKIP_SEGMENTS)


def get_pages() -> list:
    pages = []
    for dirpath, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in ("node_modules", ".git", ".vercel")]
        for f in files:
            if not f.endswith(".html"):
                continue
            p = os.path.join(dirpath, f)
            if p == MASTER or should_skip(p):
                continue
            pages.append(p)
    return sorted(pages)


def extract_block(html: str, name: str) -> str | None:
    s_tag = f"<!-- [{name}-START] -->"
    e_tag = f"<!-- [{name}-END] -->"
    s = html.find(s_tag)
    e = html.find(e_tag)
    if s == -1 or e == -1:
        return None
    return html[s : e + len(e_tag)]


def replace_block(html: str, name: str, new_block: str) -> str | None:
    s_tag = f"<!-- [{name}-START] -->"
    e_tag = f"<!-- [{name}-END] -->"
    s = html.find(s_tag)
    e = html.find(e_tag)
    if s == -1 or e == -1:
        return None
    return html[:s] + new_block + html[e + len(e_tag):]


def add_markers(html: str, name: str) -> str | None:
    """Wrap an existing block with markers using regex anchors."""
    cfg = INIT_PATTERNS.get(name, {})
    start_re = cfg.get("start_re", "")
    end_re   = cfg.get("end_re", "")

    ms = re.search(start_re, html)
    if not ms:
        return None

    # Find the last match of end_re after the start position
    me_iter = re.finditer(end_re, html[ms.start():])
    me = None
    for me in me_iter:
        pass
    if me is None:
        # Try fallback
        fb = cfg.get("fallback_end_re", "")
        if fb:
            me_iter = re.finditer(fb, html[ms.start():])
            for me in me_iter:
                pass
    if me is None:
        return None

    abs_end = ms.start() + me.end()
    block = html[ms.start():abs_end]
    s_tag = f"<!-- [{name}-START] -->\n"
    e_tag = f"\n<!-- [{name}-END] -->"
    return html[:ms.start()] + s_tag + block + e_tag + html[abs_end:]


# ── main ───────────────────────────────────────────────────────────────────

def cmd_init():
    """Add markers to all pages that are missing them."""
    pages = get_pages()
    print(f"Init: checking {len(pages)} pages for missing markers...\n")
    added = 0
    for page in pages:
        with open(page, encoding="utf-8") as f:
            html = f.read()
        original = html
        page_rel = page.replace(ROOT, "")
        changed = False
        for name in BLOCKS:
            if f"<!-- [{name}-START] -->" not in html:
                result = add_markers(html, name)
                if result:
                    html = result
                    changed = True
                    print(f"  + Added [{name}] to {page_rel}")
                else:
                    print(f"  ⚠ Could not auto-add [{name}] to {page_rel} — add manually")
        if changed:
            added += 1
            with open(page, "w", encoding="utf-8") as f:
                f.write(html)
    print(f"\nAdded markers to {added} pages.")


def cmd_sync(apply: bool):
    """Sync block content from master to all pages."""
    with open(MASTER, encoding="utf-8") as f:
        master = f.read()

    blocks = {}
    for name in BLOCKS:
        block = extract_block(master, name)
        if block is None:
            print(f"⚠ [{name}] not found in master. Add markers to index.html first.")
            continue
        blocks[name] = block
        print(f"✓ Read [{name}] from master")

    if not blocks:
        return

    pages = get_pages()
    mode  = "DRY RUN" if not apply else "APPLYING"
    print(f"\n{mode} — {len(pages)} pages\n")

    changed = skipped = 0
    for page in pages:
        with open(page, encoding="utf-8") as f:
            html = f.read()
        original = html
        page_rel = page.replace(ROOT, "")
        missing  = []

        for name, new_block in blocks.items():
            result = replace_block(html, name, new_block)
            if result is None:
                missing.append(name)
            else:
                html = result

        if missing:
            skipped += 1
            print(f"  ⚠ {page_rel} — missing markers: {', '.join(missing)}")
            print(f"     → run: python3 sync-structure.py --init")
            continue

        if html != original:
            changed += 1
            print(f"  ✏  {page_rel}")
            if apply:
                with open(page, "w", encoding="utf-8") as f:
                    f.write(html)

    print(f"\n{'Updated' if apply else 'Would update'} {changed} pages. "
          f"Skipped {skipped} (missing markers).")
    if not apply and changed:
        print("Run with --apply to save.")


def main():
    args = sys.argv[1:]
    if "--init" in args:
        cmd_init()
    elif "--apply" in args:
        cmd_sync(apply=True)
    else:
        cmd_sync(apply=False)


if __name__ == "__main__":
    main()
