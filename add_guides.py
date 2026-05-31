#!/usr/bin/env python3
"""Add the new premium guides section to all language pages."""

import os
import re

BASE = '/home/user/Prime-iptv'

# ── CSS extracted verbatim from AR index.html lines 726-1019 ──────────────────
CSS_BLOCK = r"""  /* ── Guides Section ── */
  #guides-section {
    padding: 0 0 70px;
    position: relative;
    overflow: hidden;
    scroll-margin-top: 70px;
  }
  #guides-section .gs-inner { position: relative; z-index: 1; }
  #guides-section .gs-title {
    position: relative;
  }
  #guides-section .gs-title::before {
    content: '';
    position: absolute;
    inset: -24px -14px;
    background: radial-gradient(ellipse at 50% 50%, rgba(139,92,246,0.22) 0%, transparent 70%);
    filter: blur(22px);
    pointer-events: none;
    z-index: -1;
  }
  #guides-section .gs-badge {
    display: inline-flex; align-items: center; gap: 8px;
    background: rgba(123,47,255,0.16);
    border: 1px solid rgba(139,92,246,0.42);
    color: #c4b5fd;
    padding: 6px 22px; border-radius: 999px;
    font-size: 0.85rem; font-weight: 700;
    margin-bottom: 20px;
  }
  #guides-section .gs-title {
    color: #ffffff;
    font-size: clamp(1.8rem, 4vw, 2.8rem);
    font-weight: 900;
    line-height: 1.22;
    text-align: center;
    margin-bottom: 12px;
  }
  #guides-section .gs-title span {
    background: linear-gradient(90deg, #a78bfa 0%, #60a5fa 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }
  #guides-section .gs-sub {
    color: #9494bc;
    font-size: 0.92rem;
    text-align: center;
    max-width: 440px;
    margin: 0 auto 36px;
    line-height: 1.75;
  }
  /* ── 3-column grid ── */
  .gd-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    margin-bottom: 22px;
  }
  /* ── Region tile — icon+title row at top ── */
  .gd-tile {
    position: relative;
    background: linear-gradient(160deg, rgba(255,255,255,0.06), rgba(255,255,255,0.025));
    border: 1px solid rgba(139,92,246,0.45);
    border-radius: 22px;
    padding: 26px 22px 22px;
    display: flex; flex-direction: column; gap: 14px;
    text-decoration: none;
    overflow: hidden;
    box-shadow: 0 4px 22px rgba(0,0,0,0.42), 0 0 20px rgba(139,92,246,0.14), 0 0 0 1px rgba(139,92,246,0.14) inset;
    transition: transform 0.25s ease, border-color 0.25s ease, background 0.25s ease, box-shadow 0.25s ease;
    -webkit-tap-highlight-color: transparent;
  }
  .gd-tile::before {
    content: "";
    position: absolute; top: 0; left: 0; right: 0; height: 1px;
    background: linear-gradient(90deg, transparent, rgba(167,139,250,0.75), transparent);
  }
  .gd-tile:hover {
    transform: translateY(-5px);
    background: linear-gradient(160deg, rgba(255,255,255,0.09), rgba(255,255,255,0.04));
    border-color: rgba(167,139,250,0.75);
    box-shadow: 0 14px 38px rgba(0,0,0,0.52), 0 0 38px rgba(139,92,246,0.34), 0 0 0 1px rgba(139,92,246,0.22) inset;
  }
  /* Icon + title row */
  .gd-head {
    display: flex; align-items: center; gap: 14px;
  }
  /* Glowing circular badge — +30% size, stronger glow */
  .gd-badge {
    width: 68px; height: 68px;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
    background: radial-gradient(circle at 50% 38%, rgba(124,58,237,0.50), rgba(76,29,149,0.32));
    border: 1px solid rgba(167,139,250,0.62);
    box-shadow: 0 0 30px rgba(139,92,246,0.65), inset 0 0 16px rgba(139,92,246,0.30);
    transition: box-shadow 0.25s ease, transform 0.25s ease;
  }
  .gd-badge i { color: #ddd0ff; font-size: 1.7rem; }
  .gd-tile:hover .gd-badge {
    box-shadow: 0 0 44px rgba(139,92,246,0.88), inset 0 0 20px rgba(139,92,246,0.42);
    transform: scale(1.07);
  }
  .gd-tile:hover .gd-badge i { color: #ffffff; }
  .gd-tile h3 {
    color: #ffffff;
    font-size: 1.12rem;
    font-weight: 800;
    margin: 0;
    line-height: 1.3;
    flex: 1;
    text-shadow: 0 0 14px rgba(167,139,250,0.24);
  }
  /* Desktop: body wrapper transparent, mobile-title hidden */
  .gd-body { display: contents; }
  .gd-mtitle { display: none; }
  /* Description — 2 lines max */
  .gd-desc {
    color: rgba(255,255,255,0.74);
    font-size: 0.86rem;
    line-height: 1.65;
    margin: 0;
  }
  /* Prominent CTA pinned to bottom (equal-height tiles) */
  .gd-link {
    display: inline-flex; align-items: center; gap: 7px;
    color: #c4b5fd;
    font-size: 0.88rem;
    font-weight: 700;
    margin-top: auto;
    padding: 9px 0 2px;
    transition: color 0.2s, gap 0.2s;
  }
  .gd-link i {
    background: rgba(139,92,246,0.20);
    border: 1px solid rgba(167,139,250,0.40);
    width: 24px; height: 24px; border-radius: 50%;
    display: inline-flex; align-items: center; justify-content: center;
    transition: background 0.2s, border-color 0.2s;
  }
  .gd-tile:hover .gd-link { color: #ffffff; gap: 10px; }
  .gd-tile:hover .gd-link i { background: rgba(139,92,246,0.40); border-color: rgba(167,139,250,0.70); }

  /* ═══ HERO featured card — الدليل الشامل ═══ */
  .gd-banner {
    position: relative;
    background:
      radial-gradient(120% 140% at 100% 0%, rgba(124,58,237,0.28), transparent 60%),
      radial-gradient(120% 140% at 0% 100%, rgba(59,130,246,0.18), transparent 55%),
      linear-gradient(160deg, rgba(255,255,255,0.07), rgba(255,255,255,0.03));
    border: 1.5px solid rgba(167,139,250,0.58);
    border-radius: 28px;
    padding: 36px 34px;
    display: flex; flex-direction: row-reverse; align-items: center; gap: 28px;
    overflow: hidden;
    box-shadow: 0 12px 48px rgba(0,0,0,0.52), 0 0 56px rgba(139,92,246,0.30), 0 0 0 1px rgba(139,92,246,0.18) inset;
    transition: border-color 0.25s ease, box-shadow 0.25s ease, transform 0.25s ease;
    text-decoration: none;
    -webkit-tap-highlight-color: transparent;
  }
  .gd-banner::before {
    content: "";
    position: absolute; top: 0; left: 0; right: 0; height: 2px;
    background: linear-gradient(90deg, transparent, rgba(167,139,250,0.85), transparent);
  }
  .gd-banner:hover {
    border-color: rgba(167,139,250,0.85);
    box-shadow: 0 18px 60px rgba(0,0,0,0.58), 0 0 72px rgba(139,92,246,0.42), 0 0 0 1px rgba(139,92,246,0.26) inset;
    transform: translateY(-4px);
  }
  /* Large illustration — left */
  .gd-thumb {
    width: 116px; height: 116px;
    border-radius: 26px;
    flex-shrink: 0;
    background: linear-gradient(135deg, #7c3aed 0%, #4f46e5 50%, #3b82f6 100%);
    display: flex; align-items: center; justify-content: center;
    font-size: 3rem; color: #fff;
    box-shadow: 0 0 36px rgba(139,92,246,0.66), 0 8px 22px rgba(0,0,0,0.40), inset 0 2px 10px rgba(255,255,255,0.18);
    transition: box-shadow 0.25s ease, transform 0.25s ease;
  }
  .gd-banner:hover .gd-thumb {
    box-shadow: 0 0 50px rgba(139,92,246,0.88), 0 10px 28px rgba(0,0,0,0.46), inset 0 2px 12px rgba(255,255,255,0.24);
    transform: scale(1.05) rotate(-2deg);
  }
  /* Text + button — stacked */
  .gd-banner-body { flex: 1; min-width: 0; }
  .gd-banner-tag {
    display: inline-flex; align-items: center; gap: 6px;
    background: rgba(245,197,24,0.14);
    border: 1px solid rgba(245,197,24,0.40);
    color: #fcd34d;
    font-size: 0.72rem; font-weight: 800;
    padding: 4px 12px; border-radius: 999px;
    margin-bottom: 12px;
  }
  .gd-banner-body h3 {
    color: #ffffff;
    font-size: 1.5rem;
    font-weight: 900;
    margin: 0 0 10px;
    line-height: 1.25;
    text-shadow: 0 0 16px rgba(167,139,250,0.28);
  }
  .gd-banner-body p {
    color: rgba(255,255,255,0.78);
    font-size: 0.94rem;
    line-height: 1.7;
    margin: 0 0 20px;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  /* Big prominent CTA button */
  .gd-btn {
    display: inline-flex; align-items: center; justify-content: center; gap: 9px;
    background: linear-gradient(135deg, #8b5cf6, #6d28d9);
    color: #fff;
    font-size: 1.02rem; font-weight: 800;
    padding: 16px 38px; border-radius: 999px;
    white-space: nowrap;
    transition: transform 0.2s, box-shadow 0.2s, filter 0.2s;
    box-shadow: 0 6px 24px rgba(123,47,255,0.55), inset 0 1px 0 rgba(255,255,255,0.20);
  }
  .gd-banner:hover .gd-btn {
    transform: scale(1.03);
    filter: brightness(1.08);
    box-shadow: 0 10px 34px rgba(123,47,255,0.70), inset 0 1px 0 rgba(255,255,255,0.26);
  }
  /* ── Mobile: compact — whole section fits one screen, no scroll ── */
  @media(max-width: 768px) {
    #guides-section { padding: 6px 0 30px; }
    #guides-section .gs-badge { margin-bottom: 10px; padding: 4px 16px; font-size: 0.74rem; }
    #guides-section .gs-title { font-size: 1.5rem; margin-bottom: 5px; }
    #guides-section .gs-sub { font-size: 0.78rem; margin-bottom: 14px; line-height: 1.5; }
    .gd-grid { grid-template-columns: 1fr; gap: 9px; margin-bottom: 10px; }
    /* Compact horizontal region tile: icon + (title over desc), link inline */
    .gd-tile {
      width: 100%; padding: 12px 14px;
      flex-direction: row; align-items: center; gap: 12px;
      border-radius: 16px;
    }
    .gd-head { flex-direction: column; align-items: center; gap: 0; flex-shrink: 0; }
    .gd-badge { width: 42px; height: 42px; }
    .gd-badge i { font-size: 1.1rem; }
    .gd-tile h3 { display: none; }            /* title shown in body instead */
    .gd-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
    .gd-body .gd-mtitle { display: block; color:#fff; font-weight:800; font-size:0.92rem; margin:0; line-height:1.25; }
    .gd-desc { font-size: 0.72rem; line-height: 1.45; }
    .gd-link {
      font-size: 0.62rem; font-weight: 700;
      white-space: nowrap;
      flex-shrink: 0; flex-direction: row; gap: 4px;
      background: linear-gradient(135deg, rgba(139,92,246,0.85), rgba(109,40,217,0.85));
      border: 1px solid rgba(167,139,250,0.5);
      border-radius: 999px;
      padding: 4px 8px 4px 7px;
      color: #e9d5ff;
      box-shadow: 0 2px 10px rgba(139,92,246,0.40);
    }
    .gd-link i {
      width: 14px; height: 14px; font-size: 0.5rem;
      background: rgba(255,255,255,0.12); border: none;
    }
    /* Hero card → compact horizontal */
    .gd-banner {
      flex-direction: row-reverse; text-align: right;
      padding: 14px 16px; gap: 13px; border-radius: 18px;
    }
    .gd-thumb { width: 60px; height: 60px; font-size: 1.6rem; border-radius: 14px; }
    .gd-banner-body { width: auto; }
    .gd-banner-tag { margin-bottom: 6px; padding: 3px 10px; font-size: 0.64rem; }
    .gd-banner-body h3 { font-size: 1.02rem; margin-bottom: 5px; }
    .gd-banner-body p { font-size: 0.74rem; line-height: 1.45; margin-bottom: 11px; }
    .gd-btn { width: 100%; padding: 10px 20px; font-size: 0.84rem; }
  }
  /* ── Very small phones ── */
  @media(max-width: 380px) {
    .gd-tile { padding: 10px 12px; gap: 10px; }
    .gd-badge { width: 38px; height: 38px; }
    .gd-badge i { font-size: 1rem; }
    .gd-body .gd-mtitle { font-size: 0.86rem; }
    .gd-desc { font-size: 0.68rem; }
    .gd-thumb { width: 54px; height: 54px; font-size: 1.45rem; }
    .gd-banner-body h3 { font-size: 0.96rem; }
  }
  /* ── Tablet & Desktop only ── */
  @media (min-width: 769px) {
    .gd-tile { min-height: 220px; }
    .gd-btn { font-size: 1.12rem; padding: 18px 42px; }
    #guides-section { padding-bottom: 20px; }
  }
  /* ── LTR pages: banner direction fix ── */
  .gd-ltr .gd-banner { flex-direction: row; }
  @media(max-width: 768px) {
    .gd-ltr .gd-banner { flex-direction: row; text-align: left; }
  }"""

# ── Language data ─────────────────────────────────────────────────────────────
LANGS = {
    'en': {
        'badge': 'IPTV Guides by Region',
        'title': 'Guides <span>Built</span> for Your Market',
        'sub': 'Pick your country and discover the best apps, devices, and streaming options available where you are.',
        'tiles': [
            {'href': '/en/uk/', 'icon': 'fa-crown', 'name': 'United Kingdom', 'desc': 'Everything you need to get started with IPTV in the UK — apps, devices, and setup tips.'},
            {'href': '/en/usa/', 'icon': 'fa-star', 'name': 'United States', 'desc': 'Top IPTV options, streaming apps, and compatible devices for viewers across the United States.'},
            {'href': '/en/canada/', 'icon': 'fa-leaf', 'name': 'Canada', 'desc': 'Your complete resource for IPTV setup, apps, and digital services available across Canada.'},
        ],
        'banner': {
            'href': '/en/guide/', 'tag': '⭐ Featured Guide',
            'h3': 'The Complete IPTV Guide',
            'p': 'Setup tutorials, device compatibility, and streaming tips — all in one place.',
            'btn': 'Read the Full Guide',
        },
    },
    'fr': {
        'badge': 'Guides IPTV par région',
        'title': 'Des guides <span>conçus</span> pour votre marché',
        'sub': 'Choisissez votre pays et explorez les meilleures applications, appareils et services de streaming disponibles chez vous.',
        'tiles': [
            {'href': '/fr/france/', 'icon': 'fa-landmark', 'name': 'France', 'desc': "Tout ce qu'il faut savoir pour profiter de l'IPTV en France — apps, box et conseils de configuration."},
            {'href': '/fr/belgique/', 'icon': 'fa-gem', 'name': 'Belgique', 'desc': 'Guide complet pour découvrir les meilleures options IPTV disponibles en Belgique francophone.'},
            {'href': '/fr/canada/', 'icon': 'fa-leaf', 'name': 'Canada', 'desc': 'Ressources et conseils pour accéder aux meilleurs services IPTV depuis le Canada francophone.'},
        ],
        'banner': {
            'href': '/fr/guide/', 'tag': '⭐ Guide vedette',
            'h3': 'Le Guide Complet IPTV',
            'p': 'Configuration, compatibilité des appareils et conseils streaming — tout en un seul endroit.',
            'btn': 'Lire le Guide Complet',
        },
    },
    'es': {
        'badge': 'Guías IPTV por región',
        'title': 'Guías <span>diseñadas</span> para tu mercado',
        'sub': 'Elige tu país y descubre las mejores apps, dispositivos y opciones de streaming disponibles en tu zona.',
        'tiles': [
            {'href': '/es/espana/', 'icon': 'fa-sun', 'name': 'España', 'desc': 'Todo lo que necesitas para disfrutar del IPTV en España — apps, dispositivos y guía de configuración.'},
            {'href': '/es/mexico/', 'icon': 'fa-mountain-sun', 'name': 'México', 'desc': 'Descubre las mejores opciones de IPTV disponibles en México — guía completa para empezar.'},
            {'href': '/es/argentina/', 'icon': 'fa-futbol', 'name': 'Argentina', 'desc': 'Tu recurso definitivo para configurar y aprovechar al máximo el IPTV desde Argentina.'},
        ],
        'banner': {
            'href': '/es/guide/', 'tag': '⭐ Guía destacada',
            'h3': 'La Guía Completa de IPTV',
            'p': 'Configuración, compatibilidad de dispositivos y consejos de streaming — todo lo que necesitas.',
            'btn': 'Leer la Guía Completa',
        },
    },
    'de': {
        'badge': 'IPTV-Guides nach Region',
        'title': '<span>Maßgeschneiderte</span> Guides für deinen Markt',
        'sub': 'Wähle dein Land und entdecke die besten Apps, Geräte und Streaming-Optionen in deiner Region.',
        'tiles': [
            {'href': '/de/deutschland/', 'icon': 'fa-building', 'name': 'Deutschland', 'desc': 'Alles, was du für IPTV in Deutschland brauchst — Apps, Geräte und Einrichtungstipps.'},
            {'href': '/de/oesterreich/', 'icon': 'fa-mountain', 'name': 'Österreich', 'desc': 'Entdecke die besten IPTV-Optionen für Österreich — vollständiger Setup-Guide auf Deutsch.'},
            {'href': '/de/schweiz/', 'icon': 'fa-water', 'name': 'Schweiz', 'desc': 'Dein umfassender Leitfaden für IPTV in der Schweiz — Apps, Geräte und verfügbare Dienste.'},
        ],
        'banner': {
            'href': '/de/guide/', 'tag': '⭐ Empfohlener Guide',
            'h3': 'Der vollständige IPTV-Guide',
            'p': 'Einrichtung, Gerätekompatibilität und Streaming-Tipps — alles an einem Ort zusammengefasst.',
            'btn': 'Vollständigen Guide lesen',
        },
    },
    'it': {
        'badge': 'Guide IPTV per regione',
        'title': 'Guide <span>pensate</span> per il tuo mercato',
        'sub': 'Scegli il tuo paese e scopri le migliori app, dispositivi e opzioni di streaming disponibili nella tua zona.',
        'tiles': [
            {'href': '/it/italia/', 'icon': 'fa-landmark', 'name': 'Italia', 'desc': "Tutto ciò che ti serve per goderti l'IPTV in Italia — app, dispositivi e consigli di configurazione."},
            {'href': '/it/svizzera/', 'icon': 'fa-mountain', 'name': 'Svizzera', 'desc': 'La guida completa per accedere ai migliori servizi IPTV disponibili in Svizzera in italiano.'},
            {'href': '/it/germania/', 'icon': 'fa-building', 'name': 'Germania', 'desc': "Scopri come configurare e usare l'IPTV dalla Germania — guida completa in italiano."},
        ],
        'banner': {
            'href': '/it/guide/', 'tag': '⭐ Guida in evidenza',
            'h3': "La Guida Completa all'IPTV",
            'p': 'Configurazione, compatibilità dispositivi e consigli per lo streaming — tutto in un unico posto.',
            'btn': 'Leggi la Guida Completa',
        },
    },
    'nl': {
        'badge': 'IPTV-gidsen per regio',
        'title': '<span>Op maat gemaakte</span> gidsen voor jouw markt',
        'sub': 'Kies je land en ontdek de beste apps, apparaten en streamingopties beschikbaar in jouw regio.',
        'tiles': [
            {'href': '/nl/nederland/', 'icon': 'fa-water', 'name': 'Nederland', 'desc': 'Alles wat je nodig hebt voor IPTV in Nederland — apps, apparaten en installatietips.'},
            {'href': '/nl/belgie/', 'icon': 'fa-gem', 'name': 'België', 'desc': 'Ontdek de beste IPTV-opties beschikbaar in België — volledige Nederlandstalige installatiegids.'},
            {'href': '/nl/duitsland/', 'icon': 'fa-building', 'name': 'Duitsland', 'desc': 'Jouw complete gids voor IPTV vanuit Duitsland — apps, diensten en configuratie in het Nederlands.'},
        ],
        'banner': {
            'href': '/nl/guide/', 'tag': '⭐ Aanbevolen gids',
            'h3': 'De Complete IPTV-Gids',
            'p': 'Installatie, apparaatcompatibiliteit en streamingtips — alles op één plek voor je verzameld.',
            'btn': 'Lees de Volledige Gids',
        },
    },
    'pt': {
        'badge': 'Guias IPTV por região',
        'title': 'Guias <span>criados</span> para o seu mercado',
        'sub': 'Escolha o seu país e descubra as melhores apps, dispositivos e opções de streaming disponíveis na sua região.',
        'tiles': [
            {'href': '/pt/portugal/', 'icon': 'fa-monument', 'name': 'Portugal', 'desc': 'Tudo o que precisa para desfrutar do IPTV em Portugal — apps, dispositivos e dicas de configuração.'},
            {'href': '/pt/brasil/', 'icon': 'fa-futbol', 'name': 'Brasil', 'desc': 'Descubra as melhores opções de IPTV disponíveis no Brasil — guia completo para começar.'},
            {'href': '/pt/angola/', 'icon': 'fa-earth-africa', 'name': 'Angola', 'desc': 'O seu guia completo para aceder aos melhores serviços IPTV e plataformas digitais em Angola.'},
        ],
        'banner': {
            'href': '/pt/guide/', 'tag': '⭐ Guia em destaque',
            'h3': 'O Guia Completo de IPTV',
            'p': 'Configuração, compatibilidade de dispositivos e dicas de streaming — tudo num só lugar.',
            'btn': 'Ler o Guia Completo',
        },
    },
    'tr': {
        'badge': 'Bölgeye Göre IPTV Rehberleri',
        'title': 'Pazarınıza <span>Özel</span> Rehberler',
        'sub': 'Ülkenizi seçin ve bulunduğunuz bölgede mevcut en iyi uygulamaları, cihazları ve yayın seçeneklerini keşfedin.',
        'tiles': [
            {'href': '/tr/turkiye/', 'icon': 'fa-mosque', 'name': 'Türkiye', 'desc': "Türkiye'de IPTV'den en iyi şekilde yararlanmak için ihtiyacınız olan her şey — uygulamalar ve kurulum."},
            {'href': '/tr/almanya/', 'icon': 'fa-building', 'name': 'Almanya', 'desc': "Almanya'dan Türkçe IPTV hizmetlerine nasıl erişeceğinizi öğrenin — eksiksiz Türkçe rehber."},
            {'href': '/tr/kibris/', 'icon': 'fa-sun', 'name': 'Kıbrıs', 'desc': "Kıbrıs'ta IPTV kurulumu ve en iyi yayın seçenekleri için kapsamlı Türkçe rehberiniz."},
        ],
        'banner': {
            'href': '/tr/guide/', 'tag': '⭐ Öne Çıkan',
            'h3': 'Eksiksiz IPTV Rehberi',
            'p': 'Kurulum, cihaz uyumluluğu ve yayın ipuçları — ihtiyacınız olan her şey tek bir yerde.',
            'btn': 'Rehberi Oku',
        },
    },
}

# ── File-to-language mapping ───────────────────────────────────────────────────
FILE_LANG = {
    'en/index.html': 'en', 'en/uk/index.html': 'en',
    'en/usa/index.html': 'en', 'en/canada/index.html': 'en',
    'fr/index.html': 'fr', 'fr/france/index.html': 'fr',
    'fr/belgique/index.html': 'fr', 'fr/canada/index.html': 'fr',
    'es/index.html': 'es', 'es/espana/index.html': 'es',
    'es/mexico/index.html': 'es', 'es/argentina/index.html': 'es',
    'de/index.html': 'de', 'de/deutschland/index.html': 'de',
    'de/oesterreich/index.html': 'de', 'de/schweiz/index.html': 'de',
    'it/index.html': 'it', 'it/italia/index.html': 'it',
    'it/svizzera/index.html': 'it', 'it/germania/index.html': 'it',
    'it/san-marino/index.html': 'it',
    'nl/index.html': 'nl', 'nl/nederland/index.html': 'nl',
    'nl/belgie/index.html': 'nl', 'nl/duitsland/index.html': 'nl',
    'nl/suriname/index.html': 'nl',
    'pt/index.html': 'pt', 'pt/portugal/index.html': 'pt',
    'pt/brasil/index.html': 'pt', 'pt/angola/index.html': 'pt',
    'tr/index.html': 'tr', 'tr/turkiye/index.html': 'tr',
    'tr/almanya/index.html': 'tr', 'tr/kibris/index.html': 'tr',
    'tr/azerbaycan/index.html': 'tr',
}

# ── Markers for old guides section to replace ─────────────────────────────────
OLD_START = '<!-- 🚀 Regional IPTV Guides Section -->'
OLD_END   = '<!-- ✅ End Regional Guides Section -->'


def build_tile(tile, arrow):
    return (
        f'\n      <a href="{tile["href"]}" class="gd-tile">\n'
        f'        <div class="gd-head">\n'
        f'          <div class="gd-badge"><i class="fas {tile["icon"]}"></i></div>\n'
        f'          <h3>{tile["name"]}</h3>\n'
        f'        </div>\n'
        f'        <div class="gd-body">\n'
        f'          <p class="gd-mtitle">{tile["name"]}</p>\n'
        f'          <p class="gd-desc">{tile["desc"]}</p>\n'
        f'        </div>\n'
        f'        <span class="gd-link">{tile["name"]} <i class="fas {arrow}"></i></span>\n'
        f'      </a>\n'
    )


def build_section(lang_key):
    d = LANGS[lang_key]
    ltr_class = 'gd-ltr'
    arrow = 'fa-arrow-right'

    tiles_html = ''
    for tile in d['tiles']:
        tiles_html += build_tile(tile, arrow)

    b = d['banner']
    # Strip leading "⭐ " from tag for the <i class="fas fa-star"> version
    tag_text = b['tag'].replace('⭐ ', '').strip()

    section = (
        '\n<!-- ═══════════════ IPTV Guides Section ═══════════════ -->\n'
        '<style>\n'
        + CSS_BLOCK + '\n'
        '</style>\n'
        '\n'
        f'<section id="guides-section" class="{ltr_class}" aria-label="{d["badge"]}">\n'
        f'  <div class="gs-inner container mx-auto px-4 max-w-5xl">\n'
        '\n'
        '    <div class="text-center">\n'
        '      <span class="gs-badge">\n'
        '        <i class="fas fa-map-marker-alt" style="color:#f5c518;"></i>\n'
        f'        {d["badge"]}\n'
        '      </span>\n'
        '    </div>\n'
        '\n'
        '    <h2 class="gs-title">\n'
        f'      {d["title"]}\n'
        '    </h2>\n'
        '\n'
        '    <p class="gs-sub">\n'
        f'      {d["sub"]}\n'
        '    </p>\n'
        '\n'
        '    <div class="gd-grid">\n'
        + tiles_html +
        '    </div>\n'
        '\n'
        f'    <a href="{b["href"]}" class="gd-banner" aria-label="{b["h3"]}">\n'
        '      <div class="gd-thumb"><i class="fas fa-book-open"></i></div>\n'
        '      <div class="gd-banner-body">\n'
        f'        <span class="gd-banner-tag"><i class="fas fa-star"></i> {tag_text}</span>\n'
        f'        <h3>{b["h3"]}</h3>\n'
        f'        <p>{b["p"]}</p>\n'
        '        <span class="gd-btn">\n'
        '          <i class="fas fa-book-open"></i>\n'
        f'          {b["btn"]}\n'
        '        </span>\n'
        '      </div>\n'
        '    </a>\n'
        '\n'
        '  </div>\n'
        '</section>\n'
        '<!-- ═══════════════ End Guides Section ═══════════════ -->\n'
    )
    return section


# Language-specific pricing section IDs (for sub-pages that don't use "pricing")
PRICING_IDS = [
    'pricing',   # EN, default
    'precios',   # ES
    'preise',    # DE
    'prezzi',    # IT
    'prijzen',   # NL
    'precos',    # PT
    'fiyatlar',  # TR
]


def process_file(rel_path, lang_key):
    full_path = os.path.join(BASE, rel_path)
    if not os.path.exists(full_path):
        print(f'  SKIPPED (not found): {rel_path}')
        return False

    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_section = build_section(lang_key)

    NEW_MARKER = '<!-- ═══════════════ IPTV Guides Section ═══════════════ -->'

    if OLD_START in content:
        # Replace old section from OLD_START to OLD_END (inclusive)
        start_idx = content.index(OLD_START)
        end_idx = content.index(OLD_END, start_idx) + len(OLD_END)
        content = content[:start_idx] + new_section + content[end_idx:]
        action = 'REPLACED old section'
    elif NEW_MARKER in content:
        # Already has the new section — skip
        print(f'  SKIPPED (already done): {rel_path}')
        return False
    else:
        # Try all known pricing section IDs
        insert_marker = None
        for pid in PRICING_IDS:
            marker = f'<section id="{pid}"'
            if marker in content:
                insert_marker = marker
                break

        if insert_marker is None:
            print(f'  SKIPPED (no insertion point): {rel_path}')
            return False

        pricing_idx = content.index(insert_marker)
        content = content[:pricing_idx] + new_section + '\n' + content[pricing_idx:]
        action = f'INSERTED before {insert_marker[:30]}'

    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f'  FIXED ({action}): {rel_path}')
    return True


def main():
    modified = 0
    for rel_path, lang_key in FILE_LANG.items():
        result = process_file(rel_path, lang_key)
        if result:
            modified += 1

    print(f'\nTotal modified: {modified} / {len(FILE_LANG)} files')


if __name__ == '__main__':
    main()
