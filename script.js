/* ══════════════════════════════════════════════════════════════════
   THEME TOGGLE — day / night mode
   Runs immediately (before DOMContentLoaded) to avoid flash
   ══════════════════════════════════════════════════════════════════ */
(function () {
  if (localStorage.getItem('theme') === 'light') {
    document.documentElement.classList.add('light-mode');
    document.body.classList.add('light-mode');
  }
})();

/* Strip #hash from the URL after anchor navigation so a refresh
   always reloads at the top of the page instead of the section */
(function () {
  function stripHash() {
    if (location.hash) {
      history.replaceState(null, '', location.pathname + location.search);
    }
  }
  window.addEventListener('load', stripHash);
  window.addEventListener('hashchange', stripHash);
})();

document.addEventListener('DOMContentLoaded', () => {
  const themeBtn = document.getElementById('theme-toggle');
  if (themeBtn) {
    themeBtn.addEventListener('click', () => {
      const isLight = document.body.classList.toggle('light-mode');
      document.documentElement.classList.toggle('light-mode', isLight);
      localStorage.setItem('theme', isLight ? 'light' : 'dark');
      /* Update copyright bar inline styles on theme toggle */
      const copyBar = document.querySelector('[data-ft-copy]');
      if (copyBar) {
        const p = copyBar.querySelector('p');
        if (isLight) {
          copyBar.style.cssText = 'width:100%;background:rgba(212,207,234,.99);padding:22px 16px;text-align:center;border-top:1px solid rgba(91,22,163,.2);';
          if (p) p.style.cssText = 'margin:0;color:#3b0764;font-size:14px;font-weight:500;letter-spacing:.5px;';
        } else {
          copyBar.style.cssText = 'width:100%;background:#04010c;padding:22px 16px;text-align:center;border-top:1px solid rgba(168,85,247,.10);';
          if (p) p.style.cssText = 'margin:0;color:#d8d2ff;font-size:14px;font-weight:500;letter-spacing:.5px;text-shadow:0 0 10px rgba(168,85,247,.18);';
        }
      }
    });
  }

  /* ========================================================= */
  /* ====================== شريط الأعلام ===================== */
  /* ========================================================= */

  const flagsScroll = document.getElementById('flags-scroll');
  const flagsContainer = document.getElementById('flags-container');

  const totalFlags = 20;
  const basePath = '/images/A3lame/';
  let flagsHTML = '';

  for (let i = 1; i <= totalFlags; i++) {
    flagsHTML += `
      <img loading="lazy" src="${basePath}flag${i}.webp" 
           alt="flag ${i}" class="flag-img"
           onerror="this.style.display='none'">
    `;
  }

  function fillFlags() {
    if (!flagsScroll || !flagsContainer) return;
    flagsScroll.innerHTML = '';
    while (flagsScroll.scrollWidth < flagsContainer.clientWidth * 2) {
      flagsScroll.innerHTML += flagsHTML;
    }
  }

  fillFlags();

  if (flagsScroll) {
    const images = flagsScroll.querySelectorAll('img.flag-img');
    images.forEach(img => {
      img.addEventListener('touchstart', () => { img.style.transform = 'scale(1.15)'; }, { passive: true });
      img.addEventListener('touchend', () => { img.style.transform = ''; }, { passive: true });
    });

    let scrollPos = 0;
    let paused = false;

    function getSpeed() {
      if (window.innerWidth < 480) return 0.3;
      if (window.innerWidth < 900) return 0.6;
      return 1.0;
    }

    let speed = getSpeed();

    function animateFlags() {
      if (!paused) {
        scrollPos += speed;
        const halfWidth = flagsScroll.scrollWidth / 2;
        if (scrollPos >= halfWidth) scrollPos -= halfWidth;
        flagsScroll.style.transform = `translateX(${scrollPos}px)`;
      }
      requestAnimationFrame(animateFlags);
    }

    requestAnimationFrame(animateFlags);

    flagsScroll.addEventListener('mouseenter', () => paused = true);
    flagsScroll.addEventListener('mouseleave', () => paused = false);
    flagsScroll.addEventListener('touchstart', () => paused = true, { passive: true });
    flagsScroll.addEventListener('touchend', () => paused = false, { passive: true });

    window.addEventListener('resize', () => {
      scrollPos = 0;
      speed = getSpeed();
      fillFlags();
    });
  }





  /* ========================================================= */
  /* ==================== القائمة الجانبية =================== */
  /* ========================================================= */

  const menuBtn = document.getElementById("menu-btn");
  const sideMenu = document.getElementById("side-menu");
  const overlay = document.getElementById("overlay");
  const closeMenu = document.getElementById("close-menu");

  if (menuBtn && sideMenu && overlay && closeMenu) {
    menuBtn.addEventListener("click", () => {
      sideMenu.classList.add("open");
      overlay.classList.add("active");
    });

    closeMenu.addEventListener("click", () => {
      sideMenu.classList.remove("open");
      overlay.classList.remove("active");
    });

    overlay.addEventListener("click", () => {
      sideMenu.classList.remove("open");
      overlay.classList.remove("active");
    });

    document.querySelectorAll('#side-menu a').forEach(link => {
      link.addEventListener('click', () => {
        sideMenu.classList.remove("open");
        overlay.classList.remove("active");
      });
    });
  }






/* ========================================================= */
/* ========== نظام اختيار اللغة (نسخة نهائية صحيحة) ========= */
/* ========================================================= */

const langBtn = document.getElementById("lang-btn");
const langDropdown = document.getElementById("lang-dropdown");
const currentLang = document.getElementById("current-lang");
const currentFlag = document.getElementById("current-flag");

/* ===================== */
/* تحديد اللغة من URL فقط */
/* ===================== */
(() => {
  const path = window.location.pathname;
  let lang = "en";

  if      (path.startsWith("/ar/")) lang = "ar";
  else if (path.startsWith("/fr/")) lang = "fr";
  else if (path.startsWith("/es/")) lang = "es";
  else if (path.startsWith("/pt/")) lang = "pt";
  else if (path.startsWith("/de/")) lang = "de";
  else if (path.startsWith("/tr/")) lang = "tr";
  else if (path.startsWith("/it/")) lang = "it";
  else if (path.startsWith("/nl/")) lang = "nl";
  else lang = "en";

  document.documentElement.lang = lang;
  localStorage.setItem("site_lang", lang);

  const option = document.querySelector(`.lang-option[data-lang="${lang}"]`);
  if (!option) return;

  if (currentLang) currentLang.textContent = lang.toUpperCase();
  if (currentFlag && option.dataset.flag) {
    currentFlag.src = option.dataset.flag;
    currentFlag.alt = lang + " flag";
  }
})();

/* ===================== */
/* فتح / إغلاق القائمة */
/* ===================== */
if (langBtn && langDropdown) {
  langBtn.addEventListener("click", (e) => {
    e.stopPropagation();
    langDropdown.classList.toggle("hidden");
    langDropdown.classList.toggle("show");
  });
}

/* ===================== */
/* اختيار لغة يدويًا */
/* ===================== */
document.querySelectorAll(".lang-option").forEach(option => {
  option.addEventListener("click", () => {
    const selectedLang = option.dataset.lang;
    if (!selectedLang) return;

    localStorage.setItem("site_lang", selectedLang);

    const path = window.location.pathname;

    const langMap = {
      // الإنجليزية (الجذر)
      "usa":         { ar: "/ar/",         en: "/usa/",        fr: "/fr/france/",   es: "/es/espana/" },
      "uk":          { ar: "/ar/",         en: "/uk/",         fr: "/fr/belgique/", es: "/es/espana/" },
      "canada":      { ar: "/ar/",         en: "/canada/",     fr: "/fr/canada/",   es: "/es/canada/" },

      // الفرنسية
      "fr/france":   { ar: "/ar/",         en: "/uk/",         fr: "/fr/france/",   es: "/es/espana/" },
      "fr/belgique": { ar: "/ar/",         en: "/uk/",         fr: "/fr/belgique/", es: "/es/espana/" },
      "fr/canada":   { ar: "/ar/",         en: "/canada/",     fr: "/fr/canada/",   es: "/es/canada/" },

      // العربية
      "ar/guide/khalij":  { ar: "/ar/guide/khalij/", en: "/",  fr: "/fr/",         es: "/es/" },
      "ar/guide/maghreb": { ar: "/ar/guide/maghreb/",en: "/",  fr: "/fr/france/",  es: "/es/" },
      "ar/guide/mashriq": { ar: "/ar/guide/mashriq/",en: "/",  fr: "/fr/",         es: "/es/" },
      "ar/guide":    { ar: "/ar/guide/",   en: "/guide/",      fr: "/fr/guide/",    es: "/es/guide/" },
      "ar":          { ar: "/ar/",         en: "/",            fr: "/fr/",          es: "/es/" },

      // الأدلة
      "guide":       { ar: "/ar/guide/",   en: "/guide/",      fr: "/fr/guide/",    es: "/es/guide/" },
      "fr/guide":    { ar: "/ar/guide/",   en: "/guide/",      fr: "/fr/guide/",    es: "/es/guide/" },
      "es/guide":    { ar: "/ar/guide/",   en: "/guide/",      fr: "/fr/guide/",    es: "/es/guide/" },

      // الرئيسية
      "fr":          { ar: "/ar/",         en: "/",            fr: "/fr/",          es: "/es/" },
      "es":          { ar: "/ar/",         en: "/",            fr: "/fr/",          es: "/es/" },
    };

    let target = null;

    for (const key in langMap) {
      if (path.includes("/" + key + "/") || path.endsWith("/" + key + "/")) {
        target = langMap[key][selectedLang];
        break;
      }
    }

    if (!target) {
      if (selectedLang === "ar") target = "/ar/";
      else if (selectedLang === "en") target = "/";
      else if (selectedLang === "fr") target = "/fr/";
      else if (selectedLang === "es") target = "/es/";
    }

    location.href = target;
  });
});

/* ===================== */
/* إغلاق القائمة عند الضغط خارجها */
/* ===================== */
document.addEventListener("click", () => {
  if (!langDropdown) return;
  langDropdown.classList.add("hidden");
  langDropdown.classList.remove("show");
});

  /* ========================================================= */
  /* ========== تفعيل ستايل البطاقات LUXURY ============ */
  /* ========================================================= */

  document.querySelectorAll(".plan-card").forEach(card => {

    card.classList.add("luxury-card-wrapper");

    const inner = document.createElement("div");
    inner.classList.add("luxury-card-inner");

    while (card.firstChild) {
      inner.appendChild(card.firstChild);
    }

    card.appendChild(inner);
  });





  /* ========================================================= */
  /* =================== أكورديون الخطط ===================== */
  /* ========================================================= */

  document.querySelectorAll(".toggle-features-btn").forEach(button => {
    button.addEventListener("click", () => {

      const card = button.closest(".plan-card");
      const featuresList = card.querySelector(".plan-features");

      const label = button.querySelector("span:not(.plan-arrow)");
      const arrow = button.querySelector(".plan-arrow");

      document.querySelectorAll(".plan-card").forEach(otherCard => {
        if (otherCard !== card) {

          const otherList = otherCard.querySelector(".plan-features");
          const otherBtn  = otherCard.querySelector(".toggle-features-btn");

          const otherLabel = otherBtn.querySelector("span:not(.plan-arrow)");
          const otherArrow = otherBtn.querySelector(".plan-arrow");

          otherList.classList.add("hidden");
          otherList.classList.remove("open");

          otherLabel.textContent = "عرض الميزات";
          otherArrow.textContent = "🔽";
        }
      });

      if (featuresList.classList.contains("hidden")) {
        featuresList.classList.remove("hidden");
        featuresList.classList.add("open");
        label.textContent = "إخفاء الميزات";
        arrow.textContent = "🔼";
      } else {
        featuresList.classList.remove("open");
        featuresList.classList.add("hidden");
        label.textContent = "عرض الميزات";
        arrow.textContent = "🔽";
      }

    });
  });





/* ========================================================= */
/* =========================== FAQ ========================= */
/* =================== + و × Netflix Style ================= */

// FAQ v2 — accordion
document.querySelectorAll(".faq2-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    const item = btn.closest(".faq2-item");
    const isActive = item.classList.contains("faq2-active");
    document.querySelectorAll(".faq2-item").forEach((i) => {
      i.classList.remove("faq2-active");
      i.querySelector(".faq2-btn").setAttribute("aria-expanded", "false");
    });
    if (!isActive) {
      item.classList.add("faq2-active");
      btn.setAttribute("aria-expanded", "true");
    }
  });
});

  /* ========================================================= */
  /* ============================ SEO ======================== */
  /* ========================================================= */

  document.querySelectorAll('.seo-btn').forEach(btn => {
    btn.addEventListener('click', () => {

      const content = btn.nextElementSibling;
      const icon = btn.querySelector('.seo-icon');

      document.querySelectorAll('.seo-content').forEach(c => {
        if (c !== content) c.classList.add('hidden');
      });

      document.querySelectorAll('.seo-icon').forEach(i => {
        if (i !== icon) i.classList.remove('rotate-180');
      });

      content.classList.toggle('hidden');
      icon.classList.toggle('rotate-180');
    });
  });




  /* ========================================================= */
  /* =========== ⭐ Scroll Reveal لبطاقات الخطط ⭐ =========== */
  /* ========================================================= */

  function revealPricingCards() {
    const cards = document.querySelectorAll(".plan-card");
    cards.forEach(card => {
      const rect = card.getBoundingClientRect();
      if (rect.top < window.innerHeight - 100) {
        card.classList.add("reveal");
      }
    });
  }

  window.addEventListener("scroll", revealPricingCards, { passive: true });
  window.addEventListener("resize", revealPricingCards);
  revealPricingCards();


  /* 🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨 */
  /* 💳 سكريبت قسم طرق الدفع (Payment Methods Carousel) */
  /* 🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨🟨 */

  const box = document.getElementById("cardsContainer");
  const prevBtn = document.getElementById("prevBtn");
  const nextBtn = document.getElementById("nextBtn");

  if (box && prevBtn && nextBtn) {
    prevBtn.addEventListener("click", () => {
      box.scrollBy({ left: -160, behavior: "smooth" });
    });

    nextBtn.addEventListener("click", () => {
      box.scrollBy({ left: 160, behavior: "smooth" });
    });
  }
  /* 🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦 */
  /* ⭐ نهاية سكريبت قسم طرق الدفع ⭐ */
  /* 🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦 */
  /* ========================================================= */
/* ============ نظام سلايدر الأسعار التفاعلي الذكي ============= */
/* ========================================================= */

// 1. دالة تحريك السلايدر (المقبض الأزرق) عند الضغط على الكلمات مباشرة
window.moveSlider = function(value, planType) {
    const slider = document.getElementById(`${planType}-plan-slider`);
    if (slider) {
        slider.value = value; // تحريك المقبض برمجياً
        updatePlanData(value, planType); // تحديث الأسعار والرسائل واللون
    }
};

// 2. الدالة الأساسية لتحديث الأسعار والكلمات البارزة
window.updatePlanData = function(value, planType) {
    // مصفوفة البيانات (يمكنك تعديل الأسعار من هنا بسهولة)
    const pricingConfig = window.customPricingConfig || {
        basic: [
            { price: 5,  period: "/ شهر",   text: "شهر واحد" },
            { price: 12, period: "/ 3 أشهر", text: "3 أشهر" },
            { price: 20, period: "/ 6 أشهر", text: "6 أشهر" },
            { price: 30, period: "/ السنة",  text: "سنة كاملة" },
            { price: 50, period: "/ سنتين",  text: "سنتين" }
        ],
        premium: [
            { price: 7,  period: "/ شهر",   text: "شهر واحد" },
            { price: 17, period: "/ 3 أشهر", text: "3 أشهر" },
            { price: 27, period: "/ 6 أشهر", text: "6 أشهر" },
            { price: 40, period: "/ السنة",  text: "سنة كاملة" },
            { price: 70, period: "/ سنتين",  text: "سنتين" }
        ],
        pro: [
            { price: 9,  period: "/ شهر",   text: "شهر واحد" },
            { price: 22, period: "/ 3 أشهر", text: "3 أشهر" },
            { price: 35, period: "/ 6 أشهر", text: "6 أشهر" },
            { price: 50, period: "/ السنة",  text: "سنة كاملة" },
            { price: 90, period: "/ سنتين",  text: "سنتين" }
        ],
    };

    const selected = pricingConfig[planType][value];

    // تحديث رقم السعر في الواجهة
    const priceElem = document.getElementById(`price-val-${planType}`);
    const periodElem = document.getElementById(`period-text-${planType}`);
    if (priceElem) priceElem.innerText = selected.price;
    if (periodElem) periodElem.innerText = selected.period;

    // تحديث رابط الواتساب والرسالة تلقائياً
    const waLink = document.getElementById(`whatsapp-link-${planType}`);
    if (waLink) {
        const planNames = window.customPlanNames || { basic: 'الأساسية', premium: 'المميزة', pro: 'الاحترافية' };
        const planName = planNames[planType] || planNames.basic;
        const buildMsg = window.customWhatsAppMessage ||
            ((n, d) => `مرحباً، أريد الاشتراك في الخطة ${n} لمدة (${d}) - Prime IPTV`);
        waLink.href = `https://wa.me/212666686732?text=${encodeURIComponent(buildMsg(planName, selected.text))}`;
    }

    // Update pc-tab active state for new design
    const slider = document.getElementById(`${planType}-plan-slider`);
    if (slider) {
        const tabsContainer = slider.closest('.pc-tabs');
        if (tabsContainer) {
            tabsContainer.querySelectorAll('.pc-tab').forEach((tab, i) => {
                tab.classList.toggle('pc-tab-active', i === parseInt(value));
            });
        }
    }

    // Legacy: highlight duration-step words (old design)
    const sliderEl = document.getElementById(`${planType}-plan-slider`);
    if (sliderEl) {
        const container = sliderEl.parentElement;
        container.querySelectorAll('.duration-step').forEach((step, index) => {
            step.classList.toggle('active-duration', index == value);
        });
    }
};

// Toggle the full feature list (new pricing design)
window.togglePlanFeatures = function(btn, planType) {
    const list = document.getElementById(`features-${planType}`);
    if (!list) return;
    const isOpen = !list.hasAttribute('hidden');
    if (isOpen) {
        list.setAttribute('hidden', '');
        btn.setAttribute('aria-expanded', 'false');
        const lbl = btn.querySelector('span'); if (lbl) lbl.textContent = 'عرض الميزات';
    } else {
        list.removeAttribute('hidden');
        btn.setAttribute('aria-expanded', 'true');
        const lbl = btn.querySelector('span'); if (lbl) lbl.textContent = 'إخفاء الميزات';
    }
};

  /* --- تهيئة السلايدر عند تحميل الصفحة --- */
  ['basic', 'premium', 'pro'].forEach(type => {
    const slider = document.getElementById(`${type}-plan-slider`);
    if (slider) updatePlanData(slider.value, type);
  });

}); // END DOMContentLoaded


/* ========================================================= */
/* ✦ Hero Premium Dark — Unified System                       */
/*   • injects hp-bg into every .hero-section / .hero        */
/*   • generates particles per hero                          */
/*   • transparent navbar scroll behaviour                   */
/* ========================================================= */
(function () {
  var reduceMotion = window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ── Particles into any layer element ── */
  function spawnParticles(layer) {
    if (reduceMotion) return;
    var count = window.innerWidth < 640 ? 10 : 22;
    var frag = document.createDocumentFragment();
    for (var i = 0; i < count; i++) {
      var p = document.createElement('span');
      p.className = 'hp-particle';
      var size = (Math.random() * 2.5 + 1.5).toFixed(2);
      p.style.left             = (Math.random() * 100).toFixed(2) + '%';
      p.style.width            = size + 'px';
      p.style.height           = size + 'px';
      p.style.animationDuration= (Math.random() * 10 + 9).toFixed(2) + 's';
      p.style.animationDelay   = (-Math.random() * 18).toFixed(2) + 's';
      p.style.opacity          = (Math.random() * 0.5 + 0.3).toFixed(2);
      frag.appendChild(p);
    }
    layer.appendChild(frag);
  }

  /* ── Inject hp-bg into a hero element that doesn't already have one ── */
  function injectHeroBg(heroEl) {
    if (heroEl.querySelector(':scope > .hp-bg')) return; // already done

    /* Hide old background elements (absolute, aria-hidden, direct children) */
    Array.prototype.forEach.call(heroEl.children, function (child) {
      if (child.getAttribute('aria-hidden') === 'true' &&
          !child.classList.contains('hp-bg')) {
        child.style.cssText += ';display:none!important';
      }
    });

    /* Build the background layer */
    var bg = document.createElement('div');
    bg.className = 'hp-bg';
    bg.setAttribute('aria-hidden', 'true');
    bg.innerHTML =
      '<div class="hp-grid"></div>' +
      '<div class="hp-glow hp-glow--core"></div>' +
      '<div class="hp-glow hp-glow--left"></div>' +
      '<div class="hp-glow hp-glow--right"></div>' +
      '<div class="hp-beam"></div>' +
      '<span class="hp-orb hp-orb--1"></span>' +
      '<span class="hp-orb hp-orb--2"></span>' +
      '<span class="hp-orb hp-orb--3"></span>' +
      '<span class="hp-orb hp-orb--4"></span>' +
      '<div class="hp-particles"></div>' +
      '<div class="hp-vignette"></div>';

    heroEl.insertBefore(bg, heroEl.firstChild);

    spawnParticles(bg.querySelector('.hp-particles'));
  }

  /* ── Populate particles in ALL hero sections on this page ── */
  function initAllParticles() {
    document.querySelectorAll('.hp-particles').forEach(function (layer) {
      if (layer.dataset.loaded) return;
      layer.dataset.loaded = '1';
      spawnParticles(layer);
    });
  }

  /* ── Fallback: inject hp-bg into any legacy .hero-section still without it ── */
  function initUnifiedHero() {
    document.querySelectorAll(
      '.hero-section, .hero:not(.hp-hero), .page-hero, header.hero'
    ).forEach(function (el) {
      if (el.classList.contains('hp-hero')) return;
      injectHeroBg(el);
    });
  }

  /* ── Navbar: transparent over hero → solid glass on scroll (all pages) ── */
  function initNavbarScroll() {
    var header = document.getElementById('header');
    var hero   = document.querySelector('.hp-hero');
    if (!header || !hero) return;   /* no hero → CSS handles static solid state */
    var onScroll = function () {
      var past = window.scrollY > (hero.offsetHeight - 120);
      header.classList.toggle('hp-scrolled', past);
    };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  function start() {
    initAllParticles();   // works for every .hp-hero on every page
    initUnifiedHero();    // fallback for any remaining legacy hero sections
    initNavbarScroll();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();

/* ── WhatsApp Conversion Tracking (GA4 + Google Ads) ── */
document.addEventListener('click', function (e) {
  var link = e.target.closest('a[href*="wa.me"], a[href*="whatsapp"]');
  if (!link) return;
  if (typeof gtag !== 'function') return;

  /* GA4 event */
  gtag('event', 'whatsapp_click', {
    event_category: 'engagement',
    event_label: link.href
  });

  /* Google Ads conversion — replace YOUR_CONVERSION_LABEL with the label
     from Google Ads > Goals > Conversions > your WhatsApp conversion action */
  gtag('event', 'conversion', {
    send_to: 'AW-18138909640/YOUR_CONVERSION_LABEL'
  });

});

/* ── Highlight IPTV / Prime IPTV in purple ── */
(function () {
  function runHighlight() {
    var re = /(Prime IPTV|IPTV)/gi;
    var SKIP_TAGS = /^(SCRIPT|STYLE|NOSCRIPT|TEXTAREA|INPUT|SVG|IMG|CANVAS|VIDEO|AUDIO|CODE|PRE|TITLE)$/;
    var SKIP_CLASS = /\b(hp-grad|rv-grad|faq2-grad|iptv-highlight)\b/;
    var SKIP_ID    = /^(logo-name)$/;

    function skip(el) {
      if (!el) return false;
      if (SKIP_TAGS.test(el.tagName || '')) return true;
      if (SKIP_CLASS.test(el.className || '')) return true;
      if (SKIP_ID.test(el.id || '')) return true;
      return false;
    }

    function walk(node) {
      if (node.nodeType === 3) {
        var val = node.nodeValue;
        if (!re.test(val)) { re.lastIndex = 0; return; }
        re.lastIndex = 0;
        var frag = document.createDocumentFragment(), last = 0, m;
        while ((m = re.exec(val)) !== null) {
          if (m.index > last) frag.appendChild(document.createTextNode(val.slice(last, m.index)));
          var s = document.createElement('span');
          s.className = 'iptv-highlight';
          s.textContent = m[0];
          frag.appendChild(s);
          last = m.index + m[0].length;
        }
        if (last < val.length) frag.appendChild(document.createTextNode(val.slice(last)));
        node.parentNode.replaceChild(frag, node);
        return;
      }
      if (node.nodeType !== 1 || skip(node)) return;
      Array.from(node.childNodes).forEach(walk);
    }

    walk(document.body);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', runHighlight);
  } else {
    runHighlight();
  }
})();
