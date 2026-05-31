#!/usr/bin/env python3
"""
Localize the #why-us section across all language pages.
Replaces the Arabic content with naturally-written local copy per language.
"""
import re
import os

BASE = "/home/user/Prime-iptv"

# ── Helper to build the section HTML ─────────────────────────────────────────
def why_us_html(aria, badge_icon, badge_text, title_line1, title_span,
                sub_html, cards, arrow="arrow-right", badge_k="8K"):
    """Build the full <section id="why-us"> … END WHY-US block."""

    def card(icon_grad, icon, h3, p):
        # h3 may contain the 8K badge markup — pass as raw string
        return f'''\
      <div class="wu-card">
        <div class="wu-card-top">
          <div class="wu-icon-wrap" style="background:linear-gradient(135deg,{icon_grad});"><i class="fas fa-{icon}"></i></div>
          <h3>{h3}</h3>
        </div>
        <p>{p}</p>
        <span class="wu-card-arrow" aria-hidden="true"><i class="fas fa-{arrow}"></i></span>
      </div>'''

    cards_html = "\n\n".join(card(*c) for c in cards)

    return f'''\
<section id="why-us" aria-label="{aria}">
  <div class="wu-inner container mx-auto px-4 max-w-5xl">

    <div class="text-center">
      <span class="wu-badge">
        <i class="fas fa-{badge_icon}" style="color:#f5c518;"></i>
        {badge_text}
      </span>
    </div>

    <h2 class="wu-title">
      {title_line1}<br>
      <span>{title_span}</span>
    </h2>

    <p class="wu-sub">
      {sub_html}
    </p>

    <div class="wu-grid-cards">

{cards_html}

    </div>
  </div>
</section>
<!-- ═══════════════ END WHY-US ═══════════════ -->'''


# ── 8K badge helper ───────────────────────────────────────────────────────────
def badge8k(margin_side="right"):
    return (f'<span class="wu-4k-badge" '
            f'style="background:linear-gradient(90deg,#8b5cf6,#3b82f6);'
            f'margin-{margin_side}:4px;">8K</span>')


# ══════════════════════════════════════════════════════════════════════════════
# LANGUAGE CONTENT
# ══════════════════════════════════════════════════════════════════════════════

LANG_CONTENT = {}

# ── Arabic ────────────────────────────────────────────────────────────────────
LANG_CONTENT["ar"] = why_us_html(
    aria="قسم المميزات",
    badge_icon="crown", badge_text="لماذا Prime IPTV",
    title_line1="تجربة مشاهدة أفضل",
    title_span="جودة أعلى",
    sub_html='استمتع بتقنية <strong style="color:#fff;">IPTV</strong> الحديثة التي تمنحك حرية المشاهدة بجودة عالية، في أي وقت ومن أي مكان.',
    arrow="arrow-left",
    cards=[
        ("#7c3aed,#4f46e5", "play-circle",
         "مشاهدة مرنة",
         "شاهد ما تريد في أي وقت ومن أي مكان بدون قيود."),
        ("#0ea5e9,#6366f1", "tv",
         "توافق شامل",
         "يعمل على Smart TV، Firestick، Android TV، iPhone والكمبيوتر."),
        ("#10b981,#059669", "shield-alt",
         "بث مستقر",
         "تقنية Anti-Freeze تضمن بثاً مستمراً بدون أي تقطيع."),
        ("#f59e0b,#ef4444", "gem",
         f'{badge8k("left")} جودة عالية',
         "استمتع بدقة HD و4K وحتى 8K مع صوت واضح وصورة نقية."),
        ("#8b5cf6,#ec4899", "film",
         "محتوى متنوع",
         "مكتبة رقمية واسعة تلبي مختلف الاهتمامات والأذواق."),
        ("#06b6d4,#3b82f6", "bolt",
         "تفعيل فوري",
         "تفعيل سريع وسهل فور الاشتراك — خلال دقائق."),
        ("#22c55e,#16a34a", "headset",
         "دعم 24/7",
         "فريق دعم متاح على مدار الساعة عبر WhatsApp."),
        ("#f43f5e,#be123c", "tag",
         "أسعار مناسبة",
         "خطط اشتراك تناسب جميع الميزانيات تبدأ من 30€/سنة."),
    ]
)

# ── English ───────────────────────────────────────────────────────────────────
LANG_CONTENT["en"] = why_us_html(
    aria="Why Prime IPTV",
    badge_icon="crown", badge_text="Why Prime IPTV",
    title_line1="Streaming That Actually Works",
    title_span="On Any Screen",
    sub_html='From your living-room telly to your phone on the go — sharp picture, <strong style="color:#fff;">reliable streams</strong>, and a setup that takes minutes.',
    cards=[
        ("#10b981,#059669", "shield-alt",
         "Freeze-Free Streams",
         "Anti-buffering tech keeps your stream steady, even during live sport."),
        ("#0ea5e9,#6366f1", "tv",
         "Works on Everything",
         "Firestick, Smart TV, iPhone, Android, laptop — your subscription follows you."),
        ("#f59e0b,#ef4444", "gem",
         f'{badge8k()} Crystal-Clear Picture',
         "HD, 4K, and 8K quality with true-to-life colour and crisp audio."),
        ("#7c3aed,#4f46e5", "bolt",
         "Up and Running Fast",
         "Activate and start watching straight away — no engineer, no waiting."),
        ("#8b5cf6,#ec4899", "film",
         "Thousands of Channels",
         "Live TV, films, box sets, and sport from every corner of the globe."),
        ("#06b6d4,#3b82f6", "tag",
         "Plans From €30/yr",
         "Pay less, watch more. Flexible plans with no hidden charges."),
        ("#22c55e,#16a34a", "headset",
         "24/7 WhatsApp Support",
         "Something not working? We're on WhatsApp any time, day or night."),
        ("#f43f5e,#be123c", "play-circle",
         "Smooth Viewing Experience",
         "A clean, easy-to-navigate service built for everyday viewers."),
    ]
)

# ── French ────────────────────────────────────────────────────────────────────
LANG_CONTENT["fr"] = why_us_html(
    aria="Pourquoi Prime IPTV",
    badge_icon="crown", badge_text="Pourquoi Prime IPTV",
    title_line1="Regardez ce que vous aimez",
    title_span="Sans jamais couper",
    sub_html='Qualité d\'image irréprochable, activation en quelques minutes et un service pensé pour les foyers <strong style="color:#fff;">francophones</strong> du monde entier.',
    cards=[
        ("#10b981,#059669", "shield-alt",
         "Diffusion sans coupure",
         "La technologie Anti-Freeze assure un streaming fluide, même lors des matchs en direct."),
        ("#0ea5e9,#6366f1", "tv",
         "Compatible avec tous vos écrans",
         "Smart TV, box Android, iPhone, PC… un seul abonnement pour tout vos appareils."),
        ("#f59e0b,#ef4444", "gem",
         f'{badge8k()} Qualité d\'image',
         "HD, 4K et 8K avec une image nette et un son cristallin sur chaque chaîne."),
        ("#7c3aed,#4f46e5", "bolt",
         "Activation immédiate",
         "Prêt à regarder en quelques minutes après l'inscription — sans installation compliquée."),
        ("#8b5cf6,#ec4899", "film",
         "Contenu sans limites",
         "Des milliers de chaînes, films, séries et sport en direct depuis le monde entier."),
        ("#06b6d4,#3b82f6", "tag",
         "Dès 30 €/an",
         "Moins qu'un abonnement mensuel classique — avec des formules adaptées à chaque budget."),
        ("#22c55e,#16a34a", "headset",
         "Support 7j/7, 24h/24",
         "Notre équipe vous répond sur WhatsApp à toute heure, sans attente."),
        ("#f43f5e,#be123c", "play-circle",
         "Expérience fluide",
         "Une interface simple, claire et agréable — idéale pour toute la famille."),
    ]
)

# ── Spanish ───────────────────────────────────────────────────────────────────
LANG_CONTENT["es"] = why_us_html(
    aria="Por qué Prime IPTV",
    badge_icon="crown", badge_text="Por qué Prime IPTV",
    title_line1="Mira lo que quieras",
    title_span="Sin cortes ni esperas",
    sub_html='Calidad de imagen excepcional, miles de canales en directo y una activación que se mide en <strong style="color:#fff;">minutos, no en horas</strong>.',
    cards=[
        ("#10b981,#059669", "shield-alt",
         "Sin cortes ni buffering",
         "Tecnología Anti-Freeze para que nunca pierdas ni un segundo de tu contenido favorito."),
        ("#0ea5e9,#6366f1", "tv",
         "Compatible con todo",
         "Smart TV, Firestick, iPhone, Android, portátil — funciona donde quieras."),
        ("#f59e0b,#ef4444", "gem",
         f'{badge8k()} Imagen excepcional',
         "HD, 4K y 8K con colores nítidos y sonido de primera calidad."),
        ("#7c3aed,#4f46e5", "bolt",
         "Activación al instante",
         "En marcha en minutos desde que te suscribes — sin complicaciones técnicas."),
        ("#8b5cf6,#ec4899", "film",
         "Contenido sin límites",
         "Miles de canales, series, películas y deporte en directo de todo el mundo."),
        ("#06b6d4,#3b82f6", "tag",
         "Desde 30 €/año",
         "Más contenido por menos dinero. Planes flexibles para todos los bolsillos."),
        ("#22c55e,#16a34a", "headset",
         "Soporte 24/7 por WhatsApp",
         "Atención personalizada a cualquier hora del día o la noche."),
        ("#f43f5e,#be123c", "play-circle",
         "Uso simple y directo",
         "Una plataforma limpia y rápida, fácil de manejar desde el primer momento."),
    ]
)

# ── German ────────────────────────────────────────────────────────────────────
LANG_CONTENT["de"] = why_us_html(
    aria="Warum Prime IPTV",
    badge_icon="crown", badge_text="Warum Prime IPTV",
    title_line1="Fernsehen ohne Kompromisse",
    title_span="Jederzeit und überall",
    sub_html='Kristallklares Bild, tausende Sender live und eine Aktivierung, die keine <strong style="color:#fff;">fünf Minuten</strong> dauert — egal auf welchem Gerät.',
    cards=[
        ("#10b981,#059669", "shield-alt",
         "Kein Ruckeln, kein Buffering",
         "Anti-Freeze-Technologie für stabilen Empfang — auch bei Livesport und Filmen in 4K."),
        ("#0ea5e9,#6366f1", "tv",
         "Auf jedem Gerät",
         "Smart TV, Firestick, iPhone, Android, Laptop — überall sofort einsatzbereit."),
        ("#f59e0b,#ef4444", "gem",
         f'{badge8k()} Bis zu 8K-Qualität',
         "Gestochen scharfes HD, 4K und 8K — mit klarem Ton auf jedem Sender."),
        ("#7c3aed,#4f46e5", "bolt",
         "Sofortige Aktivierung",
         "In wenigen Minuten startklar nach der Anmeldung — ohne technisches Vorwissen."),
        ("#8b5cf6,#ec4899", "film",
         "Riesige Inhaltsvielfalt",
         "Tausende Live-Sender, Spielfilme, Serien und Sportübertragungen aus aller Welt."),
        ("#06b6d4,#3b82f6", "tag",
         "Ab 30 €/Jahr",
         "Faire Preise ohne versteckte Kosten — flexible Laufzeiten nach Ihren Wünschen."),
        ("#22c55e,#16a34a", "headset",
         "Support rund um die Uhr",
         "Unser Team ist per WhatsApp immer erreichbar, wenn Sie Unterstützung benötigen."),
        ("#f43f5e,#be123c", "play-circle",
         "Einfache Bedienung",
         "Übersichtlich, schnell und intuitiv — ideal für die ganze Familie."),
    ]
)

# ── Italian ───────────────────────────────────────────────────────────────────
LANG_CONTENT["it"] = why_us_html(
    aria="Perché Prime IPTV",
    badge_icon="crown", badge_text="Perché Prime IPTV",
    title_line1="La TV come piace a te",
    title_span="Senza interruzioni",
    sub_html='Immagine nitida, attivazione rapida e migliaia di canali live pensati per chi vuole il <strong style="color:#fff;">meglio dello streaming</strong> digitale.',
    cards=[
        ("#10b981,#059669", "shield-alt",
         "Streaming senza blocchi",
         "La tecnologia Anti-Freeze garantisce una visione fluida anche durante le partite in diretta."),
        ("#0ea5e9,#6366f1", "tv",
         "Funziona su tutto",
         "Smart TV, Firestick, iPhone, Android, PC — un solo abbonamento per tutti i tuoi schermi."),
        ("#f59e0b,#ef4444", "gem",
         f'{badge8k()} Fino a 8K',
         "HD, 4K e 8K con colori vivaci e audio cristallino su ogni canale."),
        ("#7c3aed,#4f46e5", "bolt",
         "Attivazione in pochi minuti",
         "Pronto subito dopo l'iscrizione — nessuna configurazione complicata richiesta."),
        ("#8b5cf6,#ec4899", "film",
         "Contenuti illimitati",
         "Migliaia di canali live, film, serie TV e sport da tutto il mondo."),
        ("#06b6d4,#3b82f6", "tag",
         "A partire da 30 €/anno",
         "Il miglior rapporto qualità-prezzo per lo streaming digitale — senza costi nascosti."),
        ("#22c55e,#16a34a", "headset",
         "Assistenza 24 ore su 24",
         "Il nostro team risponde su WhatsApp in qualsiasi momento della giornata."),
        ("#f43f5e,#be123c", "play-circle",
         "Facile da usare",
         "Un servizio pensato per essere semplice, veloce e accessibile a tutti."),
    ]
)

# ── Dutch ─────────────────────────────────────────────────────────────────────
LANG_CONTENT["nl"] = why_us_html(
    aria="Waarom Prime IPTV",
    badge_icon="crown", badge_text="Waarom Prime IPTV",
    title_line1="Kijken op jouw manier",
    title_span="Altijd en overal",
    sub_html='Scherp beeld, directe activering en duizenden zenders — voor een kijkervaring die <strong style="color:#fff;">echt werkt</strong>, op elk apparaat.',
    cards=[
        ("#10b981,#059669", "shield-alt",
         "Nooit meer haperingen",
         "Anti-Freeze-technologie houdt je stream soepel draaiend, ook bij live sport en series."),
        ("#0ea5e9,#6366f1", "tv",
         "Werkt op elk apparaat",
         "Smart TV, Firestick, iPhone, Android, laptop — overal direct te gebruiken."),
        ("#f59e0b,#ef4444", "gem",
         f'{badge8k()} Tot 8K beeldkwaliteit',
         "HD, 4K en 8K met helder beeld en heldere audio op elk kanaal."),
        ("#7c3aed,#4f46e5", "bolt",
         "Direct actief na aanmelding",
         "Binnen enkele minuten klaar om te kijken — zonder gedoe of technische kennis."),
        ("#8b5cf6,#ec4899", "film",
         "Eindeloos aanbod",
         "Duizenden live zenders, films, series en sportwedstrijden uit de hele wereld."),
        ("#06b6d4,#3b82f6", "tag",
         "Vanaf €30 per jaar",
         "Betaalbare abonnementen zonder verborgen kosten, afgestemd op jouw budget."),
        ("#22c55e,#16a34a", "headset",
         "24/7 support via WhatsApp",
         "Altijd iemand bereikbaar als je een vraag hebt of hulp nodig hebt."),
        ("#f43f5e,#be123c", "play-circle",
         "Gebruiksvriendelijk",
         "Een overzichtelijke en snelle kijkervaring, prettig voor elke gebruiker."),
    ]
)

# ── Portuguese ────────────────────────────────────────────────────────────────
LANG_CONTENT["pt"] = why_us_html(
    aria="Por que Prime IPTV",
    badge_icon="crown", badge_text="Por que Prime IPTV",
    title_line1="Streaming que funciona de verdade",
    title_span="Em qualquer lugar",
    sub_html='Imagem nítida, ativação rápida e um serviço pensado para quem quer o <strong style="color:#fff;">melhor do streaming</strong> digital — sem complicações.',
    cards=[
        ("#10b981,#059669", "shield-alt",
         "Sem travamentos",
         "A tecnologia Anti-Freeze mantém a transmissão estável, mesmo nos jogos ao vivo."),
        ("#0ea5e9,#6366f1", "tv",
         "Compatível com tudo",
         "Smart TV, Firestick, iPhone, Android, PC — um único plano para todos os seus dispositivos."),
        ("#f59e0b,#ef4444", "gem",
         f'{badge8k()} Qualidade até 8K',
         "Imagem HD, 4K e 8K com áudio nítido e cores vibrantes em cada canal."),
        ("#7c3aed,#4f46e5", "bolt",
         "Ativação imediata",
         "Pronto para usar em minutos após a subscrição — sem instalações complicadas."),
        ("#8b5cf6,#ec4899", "film",
         "Conteúdo sem limites",
         "Milhares de canais ao vivo, filmes, séries e desporto de todo o mundo."),
        ("#06b6d4,#3b82f6", "tag",
         "A partir de 30 €/ano",
         "Preços acessíveis com planos flexíveis para todos os orçamentos."),
        ("#22c55e,#16a34a", "headset",
         "Suporte 24h por dia",
         "Equipa disponível no WhatsApp a qualquer hora para ajudar com qualquer questão."),
        ("#f43f5e,#be123c", "play-circle",
         "Fácil de usar",
         "Uma experiência simples, intuitiva e agradável desde o primeiro momento."),
    ]
)

# ── Turkish ───────────────────────────────────────────────────────────────────
LANG_CONTENT["tr"] = why_us_html(
    aria="Neden Prime IPTV",
    badge_icon="crown", badge_text="Neden Prime IPTV",
    title_line1="İstediğin İçerik",
    title_span="Kesintisiz Akıyor",
    sub_html='Net görüntü kalitesi, hızlı aktivasyon ve dünya genelinde binlerce kanal — hepsi <strong style="color:#fff;">tek abonelikte</strong>, her cihazda.',
    cards=[
        ("#10b981,#059669", "shield-alt",
         "Donma Yok, Kesinti Yok",
         "Anti-Freeze teknolojisi sayesinde canlı yayınlar bile aksamadan devam eder."),
        ("#0ea5e9,#6366f1", "tv",
         "Her Cihazda Çalışır",
         "Smart TV, Firestick, iPhone, Android, dizüstü — aboneliğin her yerde seninle."),
        ("#f59e0b,#ef4444", "gem",
         f'{badge8k()} 8K\'ya Kadar Kalite',
         "HD, 4K ve 8K net görüntü ve kristal ses kalitesi her kanalda."),
        ("#7c3aed,#4f46e5", "bolt",
         "Anında Aktivasyon",
         "Abone olduktan sonra dakikalar içinde izlemeye başla — kurulum derdi yok."),
        ("#8b5cf6,#ec4899", "film",
         "Sonsuz İçerik",
         "Binlerce canlı kanal, film, dizi ve spor yayını, dünya genelinden seçilmiş."),
        ("#06b6d4,#3b82f6", "tag",
         "Yılda 30 €'dan Başlıyor",
         "Bütçene uygun esnek planlar — gizli ücret yok, sürpriz yok."),
        ("#22c55e,#16a34a", "headset",
         "7/24 WhatsApp Desteği",
         "Günün her saatinde gerçek bir destek ekibine anında ulaş."),
        ("#f43f5e,#be123c", "play-circle",
         "Kullanımı Kolay",
         "Sade, hızlı ve her yaşa uygun bir yayın deneyimi — hiçbir teknik bilgi gerekmez."),
    ]
)

# ══════════════════════════════════════════════════════════════════════════════
# FILE → LANGUAGE MAPPING  (skip privacy-policy, terms-of-service, review, guides)
# ══════════════════════════════════════════════════════════════════════════════

SKIP_PATHS = {"privacy-policy", "terms-of-service", "review"}

def lang_for(rel_path):
    parts = rel_path.strip("/").split("/")
    top = parts[0] if parts else ""
    # Is this inside a guide sub-dir?  e.g. en/uk → keep it
    # Skip privacy / terms / review at top level or lang sub-level
    for p in parts:
        if p in SKIP_PATHS:
            return None
    if top == "index.html" or top == "":
        return "ar"
    if top in ("en", "fr", "es", "de", "it", "nl", "pt", "tr"):
        return top
    return None


# ══════════════════════════════════════════════════════════════════════════════
# APPLY
# ══════════════════════════════════════════════════════════════════════════════

START_RE = re.compile(
    r'<section id="why-us".*?<!-- ═══════════════ END WHY-US ═══════════════ -->',
    re.DOTALL
)

changed = 0
skipped = 0
errors  = 0

for root, dirs, files in os.walk(BASE):
    # prune .git
    dirs[:] = [d for d in dirs if d != ".git"]
    for fname in files:
        if fname != "index.html":
            continue
        abs_path = os.path.join(root, fname)
        rel_path = abs_path[len(BASE):]  # e.g. /en/uk/index.html

        lang = lang_for(rel_path)
        if lang is None:
            skipped += 1
            continue

        new_section = LANG_CONTENT[lang]

        with open(abs_path, "r", encoding="utf-8") as f:
            content = f.read()

        if 'id="why-us"' not in content:
            print(f"[SKIP] no why-us found: {rel_path}")
            skipped += 1
            continue

        new_content, n = START_RE.subn(new_section, content)
        if n == 0:
            print(f"[WARN] regex matched 0 times in {rel_path}")
            errors += 1
            continue

        if new_content == content:
            print(f"[SAME] already up-to-date: {rel_path}")
            skipped += 1
            continue

        with open(abs_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"[OK]  {lang:2s} → {rel_path}")
        changed += 1

print(f"\nDone — {changed} updated, {skipped} skipped, {errors} errors.")
