#!/usr/bin/env python3
"""Remove old white-card guides sections from 6 language pages."""
import re

files = {
    "fr/index.html": {
        "start": "<!-- 🚀 Section Guides IPTV par région -->",
        "end":   "<!-- ✅ Fin section guides -->",
    },
    "es/index.html": {
        "start": "<!-- 🚀 Sección Guías IPTV por región -->",
        "end":   "<!-- ✅ Fin sección guías -->",
    },
    "nl/index.html": {
        "start": "<!-- Regionale IPTV-gidsen sectie -->",
        "end":   "<!-- Regionale gidsen sectie einde -->",
    },
    "pt/index.html": {
        "start": "<!-- Seção de Guias Regionais IPTV -->",
        "end":   "<!-- Fim da seção de Guias Regionais -->",
    },
    "tr/index.html": {
        "start": "<!-- Bölgesel IPTV Rehberleri Bölümü -->",
        "end":   "<!-- Bölgesel Rehberler Bölümü Sonu -->",
    },
}

# it/index.html has no comment markers — use the section tag boundary
it_start_pattern = re.compile(
    r'\n?<!-- ═══════════════ END WHY-US ═══════════════ -->\n.*?<section class="container mx-auto px-4 mt-12 mb-12">',
    re.DOTALL
)

BASE = "/home/user/Prime-iptv"

for rel_path, markers in files.items():
    path = f"{BASE}/{rel_path}"
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    start_marker = markers["start"]
    end_marker   = markers["end"]

    if start_marker not in content:
        print(f"[WARN] start marker not found in {rel_path}")
        continue
    if end_marker not in content:
        print(f"[WARN] end marker not found in {rel_path}")
        continue

    # Remove from start_marker through end_marker (inclusive), plus surrounding newlines
    pattern = re.compile(
        r'\n?' + re.escape(start_marker) + r'.*?' + re.escape(end_marker) + r'\n?',
        re.DOTALL
    )
    new_content = pattern.sub('\n', content)

    if new_content == content:
        print(f"[WARN] no change in {rel_path}")
    else:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"[OK]  removed old guides section from {rel_path}")

# Handle it/index.html separately
it_path = f"{BASE}/it/index.html"
with open(it_path, "r", encoding="utf-8") as f:
    it_content = f.read()

# Find old section: from line after END WHY-US up to (not including) the new IPTV Guides Section comment
new_guides_marker = "<!-- ═══════════════ IPTV Guides Section ═══════════════ -->"
end_why_us_marker = "<!-- ═══════════════ END WHY-US ═══════════════ -->"

if end_why_us_marker in it_content and new_guides_marker in it_content:
    end_why_us_pos = it_content.index(end_why_us_marker) + len(end_why_us_marker)
    new_guides_pos = it_content.index(new_guides_marker)

    # Extract the chunk between the two markers
    chunk = it_content[end_why_us_pos:new_guides_pos]

    # Replace it with a single newline
    it_new = it_content[:end_why_us_pos] + '\n' + it_content[new_guides_pos:]

    with open(it_path, "w", encoding="utf-8") as f:
        f.write(it_new)
    print(f"[OK]  removed old guides section from it/index.html")
    print(f"      (removed {len(chunk)} chars between END WHY-US and new section)")
else:
    print(f"[WARN] markers not found in it/index.html")

print("\nDone.")
