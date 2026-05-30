#!/usr/bin/env python3
"""
add-why-us.py
=============
Adds the #why-us section to all language pages (excluding guide/privacy/terms).
Inserts it BEFORE the #pricing section (or first <section> in <main> as fallback).

The AR content is kept as-is — translate manually after running.
Arrow direction is automatically flipped to fa-arrow-right for LTR pages.

USAGE:
  python3 add-why-us.py          # dry run (preview only)
  python3 add-why-us.py --apply  # apply changes
"""

import os, re, sys

ROOT   = os.path.dirname(os.path.abspath(__file__))
MASTER = os.path.join(ROOT, "index.html")

SKIP_SEGMENTS = {"guide", "privacy-policy", "terms-of-service", "review"}

# The section to inject (extracted from index.html, AR version)
WHY_US_BLOCK = """\
<!-- ═══════════════ WHY-US SECTION ═══════════════ -->
<style>
  /* ── WHY-US: dark luxury redesign ── */
  #why-us {
    position: relative;
    overflow: hidden;
    padding: 90px 0 100px;
  }
  #why-us .wu-inner { position: relative; z-index: 1; }
  #why-us .wu-badge {
    display: inline-flex; align-items: center; gap: 8px;
    background: rgba(123,47,255,0.16);
    border: 1px solid rgba(139,92,246,0.42);
    color: #c4b5fd;
    padding: 6px 22px; border-radius: 999px;
    font-size: 0.85rem; font-weight: 700;
    margin-bottom: 22px;
  }
  #why-us .wu-title {
    color: #ffffff;
    font-size: clamp(1.8rem, 4vw, 2.8rem);
    font-weight: 900;
    line-height: 1.22;
    text-align: center;
    margin-bottom: 14px;
  }
  #why-us .wu-title span {
    background: linear-gradient(90deg, #a78bfa 0%, #60a5fa 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }
  #why-us .wu-sub {
    color: #9494bc;
    font-size: 0.95rem;
    text-align: center;
    max-width: 460px;
    margin: 0 auto 52px;
    line-height: 1.8;
  }
  .wu-grid-cards {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
  }
  .wu-card {
    position: relative;
    background: rgba(255,255,255,0.07);
    border: 1px solid rgba(139,92,246,0.22);
    border-radius: 22px;
    padding: 16px 14px 13px;
    display: flex;
    flex-direction: column;
    gap: 8px;
    cursor: default;
    box-shadow: 0 2px 14px rgba(0,0,0,0.35), 0 0 0 1px rgba(139,92,246,0.07) inset;
    transition: transform 0.22s ease, border-color 0.22s ease, background 0.22s ease;
    overflow: hidden;
  }
  .wu-card::before {
    content: "";
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 1px;
    background: linear-gradient(90deg, transparent, rgba(139,92,246,0.40), transparent);
  }
  .wu-card:hover {
    transform: translateY(-4px);
    background: rgba(255,255,255,0.11);
    border-color: rgba(139,92,246,0.42);
    box-shadow: 0 8px 24px rgba(0,0,0,0.45), 0 0 0 1px rgba(139,92,246,0.12) inset;
  }
  .wu-card-top {
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .wu-icon-wrap {
    width: 36px; height: 36px;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
    position: relative;
  }
  .wu-icon-wrap i { font-size: 0.85rem; color: #fff; }
  .wu-card h3 {
    color: #ffffff;
    font-size: 0.88rem;
    font-weight: 800;
    margin: 0;
    line-height: 1.3;
    flex: 1;
    text-shadow: 0 0 12px rgba(167,139,250,0.18);
  }
  .wu-card p {
    color: rgba(255,255,255,0.75);
    font-size: 0.75rem;
    line-height: 1.55;
    margin: 0;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  .wu-card-arrow {
    display: flex; align-items: center; justify-content: center;
    width: 22px; height: 22px;
    border-radius: 50%;
    background: rgba(123,47,255,0.12);
    border: 1px solid rgba(139,92,246,0.28);
    flex-shrink: 0;
    align-self: flex-start;
    transition: background 0.28s, border-color 0.28s;
  }
  .wu-card-arrow i {
    font-size: 0.6rem;
    color: rgba(167,139,250,0.7);
    transition: color 0.28s;
  }
  .wu-card:hover .wu-card-arrow {
    background: rgba(123,47,255,0.22);
    border-color: rgba(139,92,246,0.55);
  }
  .wu-card:hover .wu-card-arrow i { color: #a78bfa; }
  .wu-4k-badge {
    display: inline-block;
    background: linear-gradient(90deg,#f59e0b,#ef4444);
    color: #fff;
    font-size: 0.48rem;
    font-weight: 800;
    padding: 1px 3px;
    border-radius: 3px;
    vertical-align: middle;
    margin-right: 3px;
  }
  @media(max-width: 768px) {
    #why-us { padding: 26px 0 60px; }
    #why-us .wu-sub { margin-bottom: 24px; }
    #why-us .wu-badge { margin-bottom: 12px; }
    #why-us .wu-title { margin-bottom: 8px; }
    .wu-grid-cards { gap: 10px; }
    .wu-card { padding: 13px 12px 11px; gap: 7px; border-radius: 18px; }
    .wu-icon-wrap { width: 32px; height: 32px; }
    .wu-icon-wrap i { font-size: 0.78rem; }
    .wu-card h3 { font-size: 0.82rem; }
    .wu-card p { font-size: 0.72rem; }
  }
  @media(max-width: 400px) {
    .wu-grid-cards { gap: 8px; }
    .wu-card { padding: 11px 10px 10px; }
  }
</style>

<section id="why-us" aria-label="قسم المميزات">
  <div class="wu-inner container mx-auto px-4 max-w-5xl">

    <div class="text-center">
      <span class="wu-badge">
        <i class="fas fa-crown" style="color:#f5c518;"></i>
        لماذا Prime IPTV
      </span>
    </div>

    <h2 class="wu-title">
      تجربة مشاهدة أفضل<br>
      <span>جودة أعلى</span>
    </h2>

    <p class="wu-sub">
      استمتع بتقنية <strong style="color:#fff;">IPTV</strong> الحديثة التي تمنحك حرية المشاهدة بجودة عالية، في أي وقت ومن أي مكان.
    </p>

    <div class="wu-grid-cards">

      <div class="wu-card">
        <div class="wu-card-top">
          <div class="wu-icon-wrap" style="background:linear-gradient(135deg,#7c3aed,#4f46e5);"><i class="fas fa-play-circle"></i></div>
          <h3>مشاهدة مرنة</h3>
        </div>
        <p>شاهد ما تريد في أي وقت ومن أي مكان بدون قيود.</p>
        <span class="wu-card-arrow" aria-hidden="true"><i class="fas fa-arrow-DIRECTION"></i></span>
      </div>

      <div class="wu-card">
        <div class="wu-card-top">
          <div class="wu-icon-wrap" style="background:linear-gradient(135deg,#0ea5e9,#6366f1);"><i class="fas fa-tv"></i></div>
          <h3>توافق شامل</h3>
        </div>
        <p>يعمل على Smart TV، Firestick، Android TV، iPhone والكمبيوتر.</p>
        <span class="wu-card-arrow" aria-hidden="true"><i class="fas fa-arrow-DIRECTION"></i></span>
      </div>

      <div class="wu-card">
        <div class="wu-card-top">
          <div class="wu-icon-wrap" style="background:linear-gradient(135deg,#10b981,#059669);"><i class="fas fa-shield-alt"></i></div>
          <h3>بث مستقر</h3>
        </div>
        <p>تقنية Anti-Freeze تضمن بثاً مستمراً بدون أي تقطيع.</p>
        <span class="wu-card-arrow" aria-hidden="true"><i class="fas fa-arrow-DIRECTION"></i></span>
      </div>

      <div class="wu-card">
        <div class="wu-card-top">
          <div class="wu-icon-wrap" style="background:linear-gradient(135deg,#f59e0b,#ef4444);"><i class="fas fa-gem"></i></div>
          <h3><span class="wu-4k-badge">4K</span><span class="wu-4k-badge" style="background:linear-gradient(90deg,#8b5cf6,#3b82f6);margin-right:3px;">8K</span> جودة عالية</h3>
        </div>
        <p>استمتع بدقة HD و4K وحتى 8K مع صوت واضح وصورة نقية.</p>
        <span class="wu-card-arrow" aria-hidden="true"><i class="fas fa-arrow-DIRECTION"></i></span>
      </div>

      <div class="wu-card">
        <div class="wu-card-top">
          <div class="wu-icon-wrap" style="background:linear-gradient(135deg,#8b5cf6,#ec4899);"><i class="fas fa-film"></i></div>
          <h3>محتوى متنوع</h3>
        </div>
        <p>مكتبة رقمية واسعة تلبي مختلف الاهتمامات والأذواق.</p>
        <span class="wu-card-arrow" aria-hidden="true"><i class="fas fa-arrow-DIRECTION"></i></span>
      </div>

      <div class="wu-card">
        <div class="wu-card-top">
          <div class="wu-icon-wrap" style="background:linear-gradient(135deg,#06b6d4,#3b82f6);"><i class="fas fa-bolt"></i></div>
          <h3>تفعيل فوري</h3>
        </div>
        <p>تفعيل سريع وسهل فور الاشتراك — خلال دقائق.</p>
        <span class="wu-card-arrow" aria-hidden="true"><i class="fas fa-arrow-DIRECTION"></i></span>
      </div>

      <div class="wu-card">
        <div class="wu-card-top">
          <div class="wu-icon-wrap" style="background:linear-gradient(135deg,#22c55e,#16a34a);"><i class="fas fa-headset"></i></div>
          <h3>دعم 24/7</h3>
        </div>
        <p>فريق دعم متاح على مدار الساعة عبر WhatsApp.</p>
        <span class="wu-card-arrow" aria-hidden="true"><i class="fas fa-arrow-DIRECTION"></i></span>
      </div>

      <div class="wu-card">
        <div class="wu-card-top">
          <div class="wu-icon-wrap" style="background:linear-gradient(135deg,#f43f5e,#be123c);"><i class="fas fa-tag"></i></div>
          <h3>أسعار مناسبة</h3>
        </div>
        <p>خطط اشتراك تناسب جميع الميزانيات تبدأ من 30€/سنة.</p>
        <span class="wu-card-arrow" aria-hidden="true"><i class="fas fa-arrow-DIRECTION"></i></span>
      </div>

    </div>
  </div>
</section>
<!-- ═══════════════ END WHY-US ═══════════════ -->
"""


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


def is_ltr(html: str) -> bool:
    return 'dir="ltr"' in html or "dir='ltr'" in html


def find_insert_pos(html: str) -> int:
    """Return index just BEFORE the #pricing section, or -1 if not found."""
    # Try <section id="pricing"
    m = re.search(r'<section[^>]+id=["\']pricing["\']', html)
    if m:
        return m.start()
    # Fallback: before first <section inside <main>
    main_m = re.search(r'<main[^>]*>', html)
    if main_m:
        sec_m = re.search(r'<section', html[main_m.end():])
        if sec_m:
            return main_m.end() + sec_m.start()
    return -1


def replace_old_why_us(html: str, ltr: bool) -> str | None:
    """Replace old-design <section id="why-us"> with the new block."""
    # Find opening tag
    m_start = re.search(r'<section[^>]+id=["\']why-us["\'][^>]*>', html)
    if not m_start:
        return None
    # Find its matching </section>
    depth = 1
    pos = m_start.end()
    while depth > 0 and pos < len(html):
        open_m  = re.search(r'<section', html[pos:])
        close_m = re.search(r'</section>', html[pos:])
        if close_m is None:
            return None
        if open_m and open_m.start() < close_m.start():
            depth += 1
            pos += open_m.end()
        else:
            depth -= 1
            pos += close_m.end()
    direction = "right" if ltr else "left"
    block = WHY_US_BLOCK.replace("fa-arrow-DIRECTION", f"fa-arrow-{direction}")
    return html[:m_start.start()] + block + html[pos:]


def process(html: str, ltr: bool) -> str:
    direction = "right" if ltr else "left"
    block = WHY_US_BLOCK.replace("fa-arrow-DIRECTION", f"fa-arrow-{direction}")
    pos = find_insert_pos(html)
    if pos == -1:
        return None
    return html[:pos] + block + "\n" + html[pos:]


def is_old_design(html: str) -> bool:
    """True if the existing why-us uses the old card design (not our new one)."""
    return 'id="why-us"' in html and 'wu-card' not in html


def main():
    apply = "--apply" in sys.argv
    pages = get_pages()
    mode  = "APPLYING" if apply else "DRY RUN"
    print(f"{mode} — {len(pages)} pages\n")

    added = replaced = skipped = already = 0
    for page in pages:
        with open(page, encoding="utf-8") as f:
            html = f.read()

        rel = page.replace(ROOT, "")
        ltr = is_ltr(html)

        # Already has NEW design → skip
        if ('id="why-us"' in html or "id='why-us'" in html) and 'wu-card' in html:
            already += 1
            print(f"  ✓ new design already: {rel}")
            continue

        # Has OLD design → replace
        if 'id="why-us"' in html or "id='why-us'" in html:
            result = replace_old_why_us(html, ltr)
            if result:
                replaced += 1
                print(f"  {'↺' if apply else '~'} REPLACE OLD {'LTR' if ltr else 'RTL'} {rel}")
                if apply:
                    with open(page, "w", encoding="utf-8") as f:
                        f.write(result)
            else:
                skipped += 1
                print(f"  ⚠ could not replace old why-us: {rel}")
            continue

        # No why-us → insert before #pricing
        result = process(html, ltr)
        if result is None:
            skipped += 1
            print(f"  ⚠ no insertion point found: {rel}")
            continue

        added += 1
        print(f"  {'✏' if apply else '+'} ADD {'LTR' if ltr else 'RTL'} {rel}")
        if apply:
            with open(page, "w", encoding="utf-8") as f:
                f.write(result)

    print(f"\n{'Replaced' if apply else 'Would replace'} {replaced} old, "
          f"{'added' if apply else 'add'} {added} new.")
    print(f"Already new design: {already}. Skipped: {skipped}.")
    if not apply and (added + replaced):
        print("Run with --apply to save.")


if __name__ == "__main__":
    main()
