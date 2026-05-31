#!/usr/bin/env python3
"""
Restores all 36 broken HTML pages:
1. Restores file content from the last good git commit (147f99c)
2. Replaces old inline <style> blocks with the Phase 2 compact version
3. Updates styles.css version number to v=17
"""
import subprocess, re, os, sys

GOOD_COMMIT = "147f99c"
STYLES_OLD_VERSION = "?v=16"
STYLES_NEW_VERSION = "?v=17"

# Phase 2 compact style blocks per page (saved before restoration)
STYLE_BLOCKS = {
    "de/deutschland/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#000000,#DD0000,#FFCC00)}
.sport-name{color:#000000}
</style>""",

    "de/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
</style>""",

    "de/oesterreich/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#ED2939,#F5F5F5,#ED2939)}
.sport-name{color:#ED2939}
</style>""",

    "de/schweiz/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#FF0000,#F5F5F5,#FF0000)}
.sport-name{color:#FF0000}
</style>""",

    "en/canada/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#FF0000,#F5F5F5,#FF0000)}
.sport-name{color:#c00}
.vs-table th{background:linear-gradient(135deg,#FF0000,#F5F5F5,#FF0000)}
</style>""",

    "en/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
</style>""",

    "en/uk/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#012169,#F5F5F5,#C8102E)}
.sport-name{color:#012169}
.vs-table th{background:linear-gradient(135deg,#012169,#F5F5F5,#C8102E)}
</style>""",

    "en/usa/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#B22234,#F5F5F5,#3C3B6E)}
.sport-name{color:#3C3B6E}
</style>""",

    "es/argentina/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#74ACDF,#F5F5F5,#FEDF00)}
.sport-name{color:#2563EB}
.vs-table th{background:linear-gradient(135deg,#74ACDF,#F5F5F5,#FEDF00)}
</style>""",

    "es/espana/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#AA151B,#F1BF00,#AA151B)}
.sport-name{color:#AA151B}
.vs-table th{background:linear-gradient(135deg,#AA151B,#F1BF00,#AA151B)}
</style>""",

    "es/index.html": """<style>
body { font-family: 'Poppins', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Montserrat', sans-serif !important; font-weight: 800; }
</style>""",

    "es/mexico/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#006847,#F5F5F5,#CE1126)}
.sport-name{color:#006847}
.vs-table th{background:linear-gradient(135deg,#006847,#F5F5F5,#CE1126)}
</style>""",

    "fr/belgique/index.html": """<style>
body { font-family:'Inter','Cairo',sans-serif!important; }
h1,h2,h3,h4,h5,h6 { font-family:'Cairo',sans-serif!important; font-weight:800; }
.trust-bar{background:linear-gradient(135deg,#000000,#FDDA24,#EF3340)}
.sport-name{color:#EF3340}
.vs-table th{background:linear-gradient(135deg,#000000,#FDDA24,#EF3340)}
</style>""",

    "fr/canada/index.html": """<style>
body { font-family:'Inter','Cairo',sans-serif!important; }
h1,h2,h3,h4,h5,h6 { font-family:'Cairo',sans-serif!important; font-weight:800; }
.trust-bar{background:linear-gradient(135deg,#FF0000,#F5F5F5,#FF0000)}
.sport-name{color:#003087}
.vs-table th{background:linear-gradient(135deg,#FF0000,#F5F5F5,#FF0000)}
</style>""",

    "fr/france/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#002395,#F5F5F5,#ED2939)}
.sport-name{color:#002395}
.vs-table th{background:linear-gradient(135deg,#002395,#F5F5F5,#ED2939)}
</style>""",

    "fr/index.html": """<style>
body { font-family: 'Poppins', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Montserrat', sans-serif !important; font-weight: 800; }
</style>""",

    "index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
</style>""",

    "it/germania/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#000000,#DD0000,#FFCC00)}
.sport-name{color:#009246}
</style>""",

    "it/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
</style>""",

    "it/italia/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#009246,#F5F5F5,#CE2B37)}
.sport-name{color:#009246}
</style>""",

    "it/san-marino/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#5EB6E4,#F5F5F5,#5EB6E4)}
.sport-name{color:#5EB6E4}
</style>""",

    "it/svizzera/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#FF0000,#F5F5F5,#FF0000)}
.sport-name{color:#FF0000}
</style>""",

    "nl/belgie/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#000000,#FDDA24,#EF0000)}
.sport-name{color:#EF0000}
</style>""",

    "nl/duitsland/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#000000,#DD0000,#FFCC00)}
.sport-name{color:#AE1C28}
</style>""",

    "nl/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
</style>""",

    "nl/nederland/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#AE1C28,#F5F5F5,#21468B)}
.sport-name{color:#AE1C28}
</style>""",

    "nl/suriname/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#377E3F,#B40A2D,#FEDF00)}
.sport-name{color:#377E3F}
</style>""",

    "pt/angola/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#CC0000,#000000,#FFCC00)}
.sport-name{color:#CC0000}
</style>""",

    "pt/brasil/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#009C3B,#FEDF00,#003087)}
.sport-name{color:#009C3B}
</style>""",

    "pt/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
</style>""",

    "pt/portugal/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#006600,#CC0000,#FFCC00)}
.sport-name{color:#006600}
</style>""",

    "tr/almanya/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#000000,#DD0000,#FFCC00)}
.sport-name{color:#E30A17}
</style>""",

    "tr/azerbaycan/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#0092BC,#E8292B,#00B050)}
.sport-name{color:#0092BC}
</style>""",

    "tr/index.html": """<style>
body { font-family: 'Tajawal', sans-serif !important; }
h1, h2, h3, h4, h5, h6, .section-title, .title, .heading { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
</style>""",

    "tr/kibris/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#FF8C00,#F5F5F5,#5A7A3A)}
.sport-name{color:#FF8C00}
</style>""",

    "tr/turkiye/index.html": """<style>
body { font-family: 'Inter', 'Cairo', sans-serif !important; }
h1,h2,h3,h4,h5,h6 { font-family: 'Cairo', sans-serif !important; font-weight: 800; }
.trust-bar{background:linear-gradient(135deg,#E30A17,#F5F5F5,#E30A17)}
.sport-name{color:#E30A17}
</style>""",
}

BASE = "/home/user/Prime-iptv"
ok = 0
err = 0

for rel_path, new_style in STYLE_BLOCKS.items():
    abs_path = os.path.join(BASE, rel_path)
    
    # 1. Get good content from 147f99c
    result = subprocess.run(
        ["git", "show", f"{GOOD_COMMIT}:{rel_path}"],
        capture_output=True, text=True, cwd=BASE
    )
    if result.returncode != 0:
        print(f"ERROR getting {rel_path}: {result.stderr}")
        err += 1
        continue
    
    content = result.stdout
    
    # 2. Remove ALL old <style>...</style> blocks
    # Handle multi-line style blocks
    content = re.sub(r'\s*<style>.*?</style>\s*', '\n', content, flags=re.DOTALL)
    
    # 3. Insert new compact style block right after <head>
    content = content.replace('<head>', f'<head>\n{new_style}', 1)
    
    # 4. Update styles.css version
    content = content.replace(
        'href="/styles.css?v=16"', 
        'href="/styles.css?v=17"'
    )
    
    # 5. Write restored file
    os.makedirs(os.path.dirname(abs_path), exist_ok=True)
    with open(abs_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    # Verify structure
    has_head_close = '</head>' in content
    has_body = '<body' in content
    has_hero = 'hp-hero' in content
    has_styles = 'styles.css?v=17' in content
    
    status = "OK" if (has_head_close and has_body and has_hero and has_styles) else "WARN"
    if status == "WARN":
        print(f"{status} {rel_path}: head={has_head_close} body={has_body} hero={has_hero} styles={has_styles}")
    ok += 1

print(f"\nDone: {ok} restored, {err} errors")
