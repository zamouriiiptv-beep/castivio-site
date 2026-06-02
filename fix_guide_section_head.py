#!/usr/bin/env python3
"""Replace guide testimonials section wrapper+heading with rv-inner/rv-head like main Arabic page."""
import re

FILES = [
    '/home/user/Prime-iptv/guide/khalij/index.html',
    '/home/user/Prime-iptv/guide/maghreb/index.html',
    '/home/user/Prime-iptv/guide/mashriq/index.html',
]

NEW_HEAD = '''\
<section id="testimonials" aria-label="آراء العملاء">
  <div class="rv-inner">

    <div class="rv-head">
      <span class="rv-badge">
        <svg viewBox="0 0 20 14" aria-hidden="true"><rect x="1" y="1" width="18" height="10" rx="2" ry="2" stroke="currentColor" stroke-width="1.5" fill="none"/><path d="M6 11v2M14 11v2M4 13h12" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
        Prime IPTV
      </span>
      <div class="rv-title">
        <h2>تجارب <span class="rv-grad">حقيقية</span> من مستخدمينا</h2>
      </div>
      <p class="rv-sub">آلاف المستخدمين يعتمدون على Prime IPTV يومياً للاستمتاع بتجربة مشاهدة مستقرة وعالية الجودة.</p>
      <div>
        <span class="rv-trust">
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2l2.9 6.26L22 9.27l-5 4.87L18.18 22 12 18.56 5.82 22 7 14.14l-5-4.87 7.1-1.01L12 2z"/></svg>
          موثوق من آلاف المستخدمين
        </span>
      </div>
    </div>

    <div class="rv-grid">'''

for path in FILES:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Match: section opening + container div + old heading block + rv-grid opening
    pattern = (
        r'<section id="testimonials"[^>]*>.*?'   # section tag
        r'<div class="[^"]*container[^"]*">.*?'  # container div
        r'<div class="rv-grid">'                  # up to rv-grid opening
    )
    new_content = re.sub(pattern, NEW_HEAD, content, flags=re.DOTALL)

    # Fix closing: </div>\n  </div>\n</section> → same (rv-inner closes correctly)
    # The old closing has container div + section; we now need rv-inner + section
    new_content = new_content.replace(
        '    </div>\n  </div>\n</section>\n<section id="faq"',
        '    </div>\n\n  </div>\n</section>\n<section id="faq"'
    )

    if new_content == content:
        print(f'WARNING: no change in {path}')
        continue
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f'Updated: {path}')

print('Done!')
