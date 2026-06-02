#!/usr/bin/env python3
"""Replace guide page testimonials with rv-card design matching main pages."""
import re

BASE = '/home/user/Prime-iptv'

QBOX   = '<svg viewBox="0 0 24 24"><path d="M9.5 7C6.5 7 5 9.2 5 12v5h5v-5H7.5c0-1.7.7-2.8 2-3V7zm9 0c-3 0-4.5 2.2-4.5 5v5h5v-5H16c0-1.7.7-2.8 2-3V7z"/></svg>'
AVATAR = '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>'

TAGS = [
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><polygon points="5,3 19,12 5,21"/></svg>Tivimate',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="2" y="3" width="20" height="14" rx="2" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M8 21h8M12 17v4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>Smart TV'),
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><polygon points="5,3 19,12 5,21"/></svg>Smarters Pro',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="7" y="2" width="10" height="20" rx="3" fill="none" stroke="currentColor" stroke-width="1.8"/><circle cx="12" cy="17.5" r="1.2" fill="currentColor"/></svg>iPhone'),
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><polygon points="5,3 19,12 5,21"/></svg>IPTV Smarters',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M13 2L4.5 13.5H11L8 22l10.5-13H13V2z" stroke="currentColor" stroke-width="0.5"/></svg>Firestick'),
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><polygon points="5,3 19,12 5,21"/></svg>IPTV Pro',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="2" y="4" width="20" height="14" rx="2" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M8 2v2M16 2v2M12 9v4M10 11h4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>Android TV'),
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M13 3L8 13h5l-2 8 7-11h-5l2-7z"/></svg>Amazon Fire TV',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="4" width="18" height="12" rx="2" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M8 20h8M12 16v4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>MAG Box'),
    ('<svg viewBox="0 0 24 24" aria-hidden="true"><polygon points="5,3 19,12 5,21"/></svg>OTT Navigator',
     '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="5" width="18" height="13" rx="2" fill="none" stroke="currentColor" stroke-width="1.8"/><circle cx="12" cy="20" r="1.2" fill="currentColor"/><path d="M9 23h6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>Apple TV'),
]

F = lambda x: f'/images/A3lame/{x}'


def make_article(flag, alt, name, loc, text, tag_idx, is_lg=False):
    cls = 'rv-card rv-card--lg' if is_lg else 'rv-card'
    t1, t2 = TAGS[tag_idx]
    return (
        f'      <article class="{cls}">\n'
        f'        <div class="rv-top">\n'
        f'          <span class="rv-qbox" aria-hidden="true">{QBOX}</span>\n'
        f'          <div class="rv-stars" aria-label="5 من 5 نجوم">★★★★★</div>\n'
        f'          <img class="rv-flag" src="{flag}" alt="{alt}" loading="lazy" decoding="async">\n'
        f'        </div>\n'
        f'        <div class="rv-person">\n'
        f'          <span class="rv-avatar">{AVATAR}</span>\n'
        f'          <div class="rv-person-info">\n'
        f'            <p class="rv-name">{name}</p>\n'
        f'            <p class="rv-loc">{loc}</p>\n'
        f'          </div>\n'
        f'        </div>\n'
        f'        <p class="rv-text">{text}</p>\n'
        f'        <div class="rv-tags">\n'
        f'          <span class="rv-tag">{t1}</span>\n'
        f'          <span class="rv-tag">{t2}</span>\n'
        f'        </div>\n'
        f'      </article>'
    )


def replace_testimonials(filepath, cards):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    articles = [make_article(*c, tag_idx=i, is_lg=(i == 5)) for i, c in enumerate(cards)]
    new_grid = '    <div class="rv-grid">\n\n' + '\n'.join(articles) + '\n\n    </div>'

    # Replace the old grid (bg-white p-6 style)
    pattern = r'    <div class="grid[^"]*"[^>]*>.*?    </div>(?=\s*\n\s*</div>\s*\n</section>)'
    new_content = re.sub(pattern, new_grid, content, flags=re.DOTALL)

    if new_content == content:
        print(f'WARNING: pattern not matched in {filepath}')
        return
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f'Updated: {filepath}')


# ── Arabic review texts ───────────────────────────────────────────────────────
AR = [
    'بدأت باستخدام <strong>اشتراك Prime IPTV</strong> وأكثر ما أعجبني هو وضوح الصورة وسهولة الوصول إلى المحتوى في أي وقت بدون انقطاع.',
    'أتابع <strong>مباريات البطولة عبر IPTV</strong> في أوقات الذروة بدون تقطيع. الاستقرار ممتاز حتى مع اتصال إنترنت متوسط.',
    'إعداد <strong>خدمة IPTV على التلفاز الذكي والهاتف</strong> كان سهلاً جداً. أعجبني التنقل السريع بين القنوات وجودة العرض المستقرة.',
    'في المنزل نستخدم <strong>Prime IPTV</strong> لمشاهدة برامج الأطفال والمحتوى العائلي، وكل شيء يعمل بسلاسة في جميع الأوقات.',
    'استخدام <strong>IPTV خارج بلدي</strong> أعطاني إمكانية متابعة قنواتي المفضلة أينما كنت. التجربة مستقرة وسلسة حتى أثناء السفر.',
    'أنصح <strong>Prime IPTV</strong> لكل من يريد متابعة الرياضة والمسلسلات بجودة ممتازة. الخدمة مستقرة جداً والأسعار مناسبة.',
]

# ── guide/khalij/index.html — 6 GCC countries ────────────────────────────────
replace_testimonials(f'{BASE}/guide/khalij/index.html', [
    (F('flag-sa.svg'),  'السعودية',  'محمد الشمري',   'من السعودية',  AR[0]),
    (F('flag-ae.svg'),  'الإمارات',  'أحمد الكثيري',  'من الإمارات',  AR[1]),
    (F('flag-qa.svg'),  'قطر',       'فهد العطية',    'من قطر',       AR[2]),
    (F('flag-kw.svg'),  'الكويت',    'عبدالله الرشيد','من الكويت',    AR[3]),
    (F('flag-om.svg'),  'عُمان',     'سعيد البلوشي',  'من عُمان',     AR[4]),
    (F('flag-bh.svg'),  'البحرين',   'نورة المنصوري', 'من البحرين',   AR[5]),
])

# ── guide/maghreb/index.html — 5 Maghreb + Morocco repeated ──────────────────
replace_testimonials(f'{BASE}/guide/maghreb/index.html', [
    (F('flag1.webp'),   'المغرب',    'محمد العمراني', 'من المغرب',    AR[0]),
    (F('flag-dz.svg'),  'الجزائر',   'يوسف بلقاسم',  'من الجزائر',   AR[1]),
    (F('flag-tn.svg'),  'تونس',      'إيمان بن سالم', 'من تونس',      AR[2]),
    (F('flag-ly.svg'),  'ليبيا',     'سلمى الورفلي',  'من ليبيا',     AR[3]),
    (F('flag-mr.svg'),  'موريتانيا', 'أحمد ولد أحمد', 'من موريتانيا', AR[4]),
    (F('flag1.webp'),   'المغرب',    'خالد الإدريسي', 'من المغرب',    AR[5]),
])

# ── guide/mashriq/index.html — 6 Mashriq countries ───────────────────────────
replace_testimonials(f'{BASE}/guide/mashriq/index.html', [
    (F('flag-eg.svg'),  'مصر',       'محمد الشريف',   'من مصر',       AR[0]),
    (F('flag-lb.svg'),  'لبنان',     'يوسف الحداد',   'من لبنان',     AR[1]),
    (F('flag-iq.svg'),  'العراق',    'أحمد الجبوري',  'من العراق',    AR[2]),
    (F('flag-jo.svg'),  'الأردن',    'سلمى الزعبي',   'من الأردن',    AR[3]),
    (F('flag-sy.svg'),  'سوريا',     'خالد الحلبي',   'من سوريا',     AR[4]),
    (F('flag-ps.svg'),  'فلسطين',    'نورا أبو عمر',  'من فلسطين',    AR[5]),
])

print('All done!')
