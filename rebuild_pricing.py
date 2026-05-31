#!/usr/bin/env python3
"""
Rebuilds the pricing section in all 36 pages with the new dark card design
matching the provided screenshots.
"""
import re, os, glob

BASE = "/home/user/Prime-iptv"

# ── Detect language from file path ─────────────────────────────────────────
def get_lang(path):
    rel = path[len(BASE)+1:]
    parts = rel.split('/')
    if parts[0] == 'index.html':
        return 'ar'
    return parts[0] if parts[0] in ('en','fr','es','de','it','nl','pt','tr') else 'en'

# ── Per-language trust bar ──────────────────────────────────────────────────
TRUST = {
    'ar': [('fa-headset','دعم فني أونلاين'),('fa-bolt','تفعيل فوري'),('fa-clock','دعم 24/7'),('fa-star','جودة عالية')],
    'en': [('fa-headset','Online support'),('fa-bolt','Instant activation'),('fa-clock','24/7 support'),('fa-star','HD quality')],
    'fr': [('fa-headset','Support en ligne'),('fa-bolt','Activation rapide'),('fa-clock','Support 24/7'),('fa-star','Qualité HD')],
    'es': [('fa-headset','Soporte en línea'),('fa-bolt','Activación rápida'),('fa-clock','Soporte 24/7'),('fa-star','Calidad HD')],
    'de': [('fa-headset','Online-Support'),('fa-bolt','Sofortaktivierung'),('fa-clock','24/7 Support'),('fa-star','HD-Qualität')],
    'it': [('fa-headset','Supporto online'),('fa-bolt','Attivazione rapida'),('fa-clock','Supporto 24/7'),('fa-star','Qualità HD')],
    'nl': [('fa-headset','Online support'),('fa-bolt','Directe activering'),('fa-clock','24/7 support'),('fa-star','HD kwaliteit')],
    'pt': [('fa-headset','Suporte online'),('fa-bolt','Ativação imediata'),('fa-clock','Suporte 24/7'),('fa-star','Qualidade HD')],
    'tr': [('fa-headset','Online destek'),('fa-bolt','Anında aktivasyon'),('fa-clock','7/24 destek'),('fa-star','HD kalite')],
}

# ── Data extraction ─────────────────────────────────────────────────────────
def extract(html, plan):
    sec_m = re.search(r'<section id="pricing".*?(?=<section id="testimonials"|<section class="global|<footer)', html, re.DOTALL)
    if not sec_m: return None
    sec = sec_m.group(0)

    wa = re.search(rf'id="whatsapp-link-{plan}"[^h]*href="([^"]*)"', sec)
    pb = re.search(rf'id="price-val-{plan}">([^<]*)</span>\s*<span[^>]*>([^<]*)</span>\s*<span id="period-text-{plan}"[^>]*>([^<]*)</span>', sec)
    feat_m = re.search(rf'<ul id="features-{plan}"[^>]*>(.*?)</ul>', sec, re.DOTALL)
    return {
        'wa': wa.group(1) if wa else '#',
        'price': pb.group(1).strip() if pb else '30',
        'currency': pb.group(2).strip() if pb else 'EUR',
        'period': pb.group(3).strip() if pb else '/ year',
        'features': feat_m.group(1).strip() if feat_m else '',
    }

def extract_meta(html):
    sec_m = re.search(r'<section id="pricing".*?(?=<section id="testimonials"|<section class="global|<footer)', html, re.DOTALL)
    if not sec_m: return {}
    sec = sec_m.group(0)

    aria = re.search(r'<section id="pricing"[^>]*aria-label="([^"]*)"', sec)
    h2 = re.search(r'(<h2 class="section-title-unified">.*?</h2>)', sec, re.DOTALL)
    subtitle = re.search(r'(<p class="text-center mb-10[^>]*>.*?</p>)', sec, re.DOTALL)
    titles = [t.strip() for t in re.findall(r'<h3[^>]*>([^<]+)</h3>', sec)]
    descs  = [d.strip() for d in re.findall(r'<h3[^>]*>[^<]+</h3>\s*<p[^>]*>([^<]+)</p>', sec)]
    ctas   = re.findall(r'id="whatsapp-link-(?:basic|premium|pro)"[^>]*>\s*([^\n<]+?)\s*(?:\n\s*)?</a>', sec)
    tabs   = re.findall(r"onclick=\"moveSlider\(\d+, 'basic'\)\">([^<]+)<", sec)
    script = re.search(r'(<script>\s*window\.customPricingConfig\s*=.*?</script>)', html, re.DOTALL)

    return {
        'aria': aria.group(1) if aria else 'Subscription plans',
        'h2': h2.group(1) if h2 else '',
        'subtitle': subtitle.group(1) if subtitle else '',
        'titles': titles,
        'descs': descs,
        'ctas': ctas,
        'tabs': tabs if len(tabs)==5 else ['mo','3mo','6mo','year','2yr'],
        'script': script.group(1) if script else '',
    }

# ── New pricing section HTML builder ───────────────────────────────────────
ICONS = ['fa-layer-group', 'fa-star', 'fa-crown']
PLAN_KEYS = ['basic', 'premium', 'pro']
BADGE_CLASSES = ['pc-badge-basic', 'pc-badge-premium', 'pc-badge-pro']
CARD_CLASSES  = ['pc-card-basic',  'pc-card-premium',  'pc-card-pro']
QUALITY = ['HD', 'HD', '4K']

def build_plan_card(idx, meta, data, lang):
    plan = PLAN_KEYS[idx]
    title = meta['titles'][idx] if idx < len(meta['titles']) else plan.title()
    desc  = meta['descs'][idx]  if idx < len(meta['descs'])  else ''
    cta   = meta['ctas'][idx]   if idx < len(meta['ctas'])   else 'Subscribe'
    tabs  = meta['tabs']
    d     = data
    quality = QUALITY[idx]
    dir_attr = 'rtl' if lang == 'ar' else 'ltr'

    # Build tab buttons (index 3 = year is default active)
    tab_btns = ''
    for i, lbl in enumerate(tabs):
        active_cls = ' pc-tab-active' if i == 3 else ''
        tab_btns += f'<button class="pc-tab{active_cls}" onclick="moveSlider({i},\'{plan}\')" type="button">{lbl}</button>\n          '

    # Clean up features — keep as list items, add icon prefix
    raw_feats = re.sub(r'\s*<li>\s*✅\s*', '<li>', d['features'])
    raw_feats = re.sub(r'\s*<li>', '\n<li>', raw_feats).strip()

    return f'''
      <!-- ── {title} ── -->
      <div class="pc-card {CARD_CLASSES[idx]}">
        <span class="pc-badge {BADGE_CLASSES[idx]}">{title}</span>

        <div class="pc-card-head">
          <div class="pc-icon-wrap"><i class="fas {ICONS[idx]}"></i></div>
          <h3 class="pc-plan-title">{title}</h3>
          <p class="pc-plan-sub">{desc}</p>
        </div>

        <div class="pc-tabs">
          {tab_btns.strip()}
          <input type="range" min="0" max="4" value="3" step="1" class="custom-slider sr-only" id="{plan}-plan-slider" oninput="updatePlanData(this.value,'{plan}')">
        </div>

        <div class="pc-price-row" dir="{dir_attr}">
          <span class="pc-price-num" id="price-val-{plan}">{d['price']}</span>
          <span class="pc-price-meta">
            <span class="pc-currency">{d['currency']}</span>
            <span class="pc-period" id="period-text-{plan}">{d['period']}</span>
          </span>
        </div>

        <ul id="features-{plan}" class="pc-features plan-features" dir="{dir_attr}">
          {raw_feats}
        </ul>

        <a id="whatsapp-link-{plan}" href="{d['wa']}" class="pc-cta-btn" target="_blank" rel="noopener noreferrer">{cta}</a>
      </div>'''

def build_trust_bar(lang):
    items = TRUST.get(lang, TRUST['en'])
    html = ''
    for icon, label in items:
        html += f'<div class="pc-trust-item"><i class="fas {icon}"></i><span>{label}</span></div>\n        '
    return html.strip()

def build_section(html, lang):
    meta = extract_meta(html)
    if not meta.get('h2'):
        return None

    d_basic   = extract(html, 'basic')
    d_premium = extract(html, 'premium')
    d_pro     = extract(html, 'pro')
    if not d_basic:
        return None

    cards = ''.join(build_plan_card(i, meta, d, lang) for i, d in enumerate([d_basic, d_premium, d_pro]))
    trust = build_trust_bar(lang)
    script_block = ('\n\n  ' + meta['script']) if meta['script'] else ''

    new_section = f'''<section id="pricing" class="section-spacing pc-section" aria-label="{meta['aria']}">
  <div class="container mx-auto px-4">

    {meta['h2']}

    {meta['subtitle']}

    <div class="pc-grid">
{cards}
    </div>

    <div class="pc-trust-bar">
      {trust}
    </div>

  </div>
</section>'''
    return new_section

# ── Apply to all pages ──────────────────────────────────────────────────────
pages = []
for root, dirs, files in os.walk(BASE):
    for fname in files:
        if fname != 'index.html': continue
        fpath = os.path.join(root, fname)
        if any(x in fpath for x in ['/guide/', '/review/', '/privacy', '/terms']):
            continue
        pages.append(fpath)
pages.sort()

ok = err = skip = 0
for path in pages:
    with open(path, encoding='utf-8') as f:
        html = f.read()

    lang = get_lang(path)
    new_sec = build_section(html, lang)
    if not new_sec:
        print(f'SKIP (no pricing): {path[len(BASE)+1:]}')
        skip += 1
        continue

    # Replace old pricing section
    new_html = re.sub(
        r'<section id="pricing".*?(?=<section id="testimonials"|<section class="global|<footer)',
        new_sec + '\n\n',
        html,
        flags=re.DOTALL
    )

    if new_html == html:
        print(f'WARN (no change): {path[len(BASE)+1:]}')
        err += 1
        continue

    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_html)
    ok += 1

print(f'\nDone: {ok} rebuilt, {skip} skipped, {err} errors')
