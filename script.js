/* ========================================================= */
/* منع المتصفح من استرجاع آخر صفحة (Session Restore Fix) */
/* ========================================================= */

if ("scrollRestoration" in history) {
  history.scrollRestoration = "manual";
}

window.addEventListener("pageshow", (event) => {
  if (event.persisted) {
    window.location.reload();
  }
});


document.addEventListener('DOMContentLoaded', () => {

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
  let lang = "ar";

  if      (path.startsWith("/en/")) lang = "en";
  else if (path.startsWith("/fr/")) lang = "fr";
  else if (path.startsWith("/es/")) lang = "es";
  else if (path.startsWith("/pt/")) lang = "pt";
  else if (path.startsWith("/de/")) lang = "de";
  else if (path.startsWith("/tr/")) lang = "tr";
  else if (path.startsWith("/it/")) lang = "it";
  else if (path.startsWith("/nl/")) lang = "nl";
  else lang = "ar";

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
      // الإنجليزية
      "en/usa":      { ar: "/ar/mashriq/", en: "/en/usa/",     fr: "/fr/france/",   es: "/es/espana/" },
      "en/uk":       { ar: "/ar/mashriq/", en: "/en/uk/",      fr: "/fr/belgique/", es: "/es/espana/" },
      "en/canada":   { ar: "/",            en: "/en/canada/",  fr: "/fr/canada/",   es: "/es/canada/" },

      // الفرنسية
      "fr/france":   { ar: "/ar/maghreb/", en: "/en/uk/",      fr: "/fr/france/",   es: "/es/espana/" },
      "fr/belgique": { ar: "/ar/maghreb/", en: "/en/uk/",      fr: "/fr/belgique/", es: "/es/espana/" },
      "fr/canada":   { ar: "/",            en: "/en/canada/",  fr: "/fr/canada/",   es: "/es/canada/" },

      // العربية
      "ar/khalij":   { ar: "/ar/khalij/",  en: "/en/",         fr: "/fr/",          es: "/es/" },
      "ar/maghreb":  { ar: "/ar/maghreb/", en: "/en/",         fr: "/fr/france/",   es: "/es/" },
      "ar/mashriq":  { ar: "/ar/mashriq/", en: "/en/",         fr: "/fr/",          es: "/es/" },

      // الأدلة
      "en/guide":    { ar: "/guide/",      en: "/en/guide/",   fr: "/fr/guide/",    es: "/es/guide/" },
      "fr/guide":    { ar: "/guide/",      en: "/en/guide/",   fr: "/fr/guide/",    es: "/es/guide/" },
      "guide":       { ar: "/guide/",      en: "/en/guide/",   fr: "/fr/guide/",    es: "/es/guide/" },

      // الرئيسية
      "en":          { ar: "/",            en: "/en/",         fr: "/fr/",          es: "/es/" },
      "fr":          { ar: "/",            en: "/en/",         fr: "/fr/",          es: "/es/" },
      "es":          { ar: "/",            en: "/en/",         fr: "/fr/",          es: "/es/" },
    };

    let target = null;

    for (const key in langMap) {
      if (path.includes("/" + key + "/") || path.endsWith("/" + key + "/")) {
        target = langMap[key][selectedLang];
        break;
      }
    }

    if (!target) {
      if (selectedLang === "ar") target = "/";
      else if (selectedLang === "en") target = "/en/";
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

document.querySelectorAll(".faq-btn").forEach((btn) => {
  btn.addEventListener("click", () => {

    const card = btn.closest("#faq .grid > div");
    const content = card.querySelector(".faq-content");
    const icon = btn.querySelector(".faq-icon");

    document.querySelectorAll("#faq .grid > div").forEach((item) => {
      if (item !== card) {
        item.classList.remove("faq-item-active");

        const c = item.querySelector(".faq-content");
        const i = item.querySelector(".faq-icon");

        if (c) c.classList.add("hidden");
        if (i) i.textContent = "+";
      }
    });

    card.classList.toggle("faq-item-active");
    content.classList.toggle("hidden");

    if (card.classList.contains("faq-item-active")) {
      icon.textContent = "×";
    } else {
      icon.textContent = "+";
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

    // --- إبراز الكلمة المختارة وجعلها مثيرة للانتباه ---
    // نبحث عن الكلمات داخل قسم السلايدر الخاص بهذه الخطة فقط
    const container = document.getElementById(`${planType}-plan-slider`).parentElement;
    const steps = container.querySelectorAll('.duration-step');
    
    steps.forEach((step, index) => {
        if (index == value) {
            step.classList.add('active-duration'); // الكلمة المختارة تصبح بارزة
        } else {
            step.classList.remove('active-duration'); // إزالة التمييز عن الباقي
        }
    });
};

/* ========================================================= */
/* =================== إدارة أحداث الصفحة ===================== */
/* ========================================================= */

document.addEventListener('DOMContentLoaded', () => {

    /* --- تفعيل الأكورديون (عرض الميزات) بدون حذف أي ميزة --- */
    document.querySelectorAll(".toggle-features-btn").forEach(button => {
        button.addEventListener("click", () => {
            const card = button.closest(".plan-card");
            const featuresList = card.querySelector(".plan-features");
            const label = button.querySelector("span:not(.plan-arrow)");
            const arrow = button.querySelector(".plan-arrow");

            if (featuresList.classList.contains("hidden")) {
                featuresList.classList.remove("hidden");
                label.textContent = "إخفاء الميزات";
                arrow.textContent = "🔼";
            } else {
                featuresList.classList.add("hidden");
                label.textContent = "عرض الميزات";
                arrow.textContent = "🔽";
            }
        });
    });

    /* --- تهيئة السلايدر عند تحميل الصفحة (ليبدأ من خيار "سنة") --- */
    ['basic', 'premium', 'pro'].forEach(type => {
        const slider = document.getElementById(`${type}-plan-slider`);
        if (slider) updatePlanData(slider.value, type);
    });

    /* ========================================================= */
    /* كود شريط الأعلام (Flags Animation) كما كان لديك سابقاً */
    /* ========================================================= */
    const flagsScroll = document.getElementById('flags-scroll');
    if (flagsScroll) {
        let scrollPos = 0;
        let paused = false;
        function animateFlags() {
            if (!paused) {
                scrollPos += 0.6;
                if (scrollPos >= flagsScroll.scrollWidth / 2) scrollPos = 0;
                flagsScroll.style.transform = `translateX(${scrollPos}px)`;
            }
            requestAnimationFrame(animateFlags);
        }
        requestAnimationFrame(animateFlags);
        
        flagsScroll.addEventListener('mouseenter', () => paused = true);
        flagsScroll.addEventListener('mouseleave', () => paused = false);
    }

}); // نهاية DOMContentLoaded



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

  /* ── Apply unified hero system to all matching sections ── */
  function initUnifiedHero() {
    var hpHome = document.querySelector('.hp-hero'); // Arabic page
    document.querySelectorAll(
      '.hero-section, .hero, .page-hero, header.hero'
    ).forEach(function (el) {
      if (el === hpHome || el.classList.contains('hp-hero')) return;
      injectHeroBg(el);
    });

    /* Particles for the Arabic page (uses legacy id) */
    var arLayer = document.getElementById('hpParticles');
    if (arLayer) spawnParticles(arLayer);
  }

  /* ── Transparent navbar scrolls to solid on the AR homepage ── */
  function initNavbarScroll() {
    var header = document.getElementById('header');
    var hero   = document.getElementById('home');
    if (!header || !hero) return;

    /* Dark navbar for any page with a unified hero */
    if (document.querySelector('.hero-section, .hero, .page-hero, .hp-hero')) {
      header.classList.add('hp-scrolled-ready');
    }

    if (!document.body.classList.contains('hp-home')) return;
    var onScroll = function () {
      var past = window.scrollY > (hero.offsetHeight - 120);
      header.classList.toggle('hp-scrolled', past);
    };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  function start() {
    initUnifiedHero();
    initNavbarScroll();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
