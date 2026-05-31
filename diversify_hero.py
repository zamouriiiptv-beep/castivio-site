#!/usr/bin/env python3
"""
Rewrite Hero descriptions uniquely per page (no translated template),
and give guide pages a guide-focused subtitle.
Title and country subtitles are left as-is. AR main index is untouched.
Only the <p class="hp-desc"> block (and guide subtitles) change.
"""
import re, os

BASE = "/home/user/Prime-iptv"

# rel_path -> ([desc_line1, desc_line2], guide_subtitle_or_None)
PAGES = {
    # ══ English ══
    "en/index.html": (
        ["Rock-solid performance and razor-sharp picture quality —",
         "smooth, dependable playback on every screen you own."], None),
    "en/uk/index.html": (
        ["Crystal-clear quality and a stream that holds steady —",
         "from the living room to your phone, anywhere in the UK."], None),
    "en/usa/index.html": (
        ["Effortless setup and stunning clarity —",
         "reliable, smooth playback wherever you are in the States."], None),
    "en/canada/index.html": (
        ["Consistent performance and sharp, detailed picture —",
         "the same dependable experience on every device, coast to coast."], None),
    "en/guide/index.html": (
        ["Clear, step-by-step help to get you set up —",
         "Prime IPTV running smoothly on any device, first time."],
        "Your complete setup guide"),

    # ══ French ══
    "fr/index.html": (
        ["Une image d'une netteté remarquable et des performances stables,",
         "sur chacun de vos écrans, sans le moindre effort."], None),
    "fr/france/index.html": (
        ["Une qualité d'image impeccable et une lecture fluide,",
         "du salon au smartphone, partout en France."], None),
    "fr/belgique/index.html": (
        ["Des performances constantes et une image nette,",
         "sur tous vos appareils, où que vous soyez en Belgique."], None),
    "fr/canada/index.html": (
        ["Une expérience stable et limpide,",
         "sur chacun de vos écrans, d'un océan à l'autre."], None),
    "fr/guide/index.html": (
        ["Un accompagnement clair, étape par étape,",
         "pour configurer Prime IPTV sans la moindre difficulté."],
        "Votre guide d'installation complet"),

    # ══ Spanish ══
    "es/index.html": (
        ["Imagen impecable y un rendimiento que nunca falla,",
         "en todos y cada uno de tus dispositivos."], None),
    "es/espana/index.html": (
        ["Calidad nítida y reproducción estable,",
         "del salón al móvil, en toda España."], None),
    "es/mexico/index.html": (
        ["Una experiencia fluida y en alta definición,",
         "en cada pantalla, en todo México."], None),
    "es/argentina/index.html": (
        ["Rendimiento constante y una imagen impecable,",
         "en todos tus dispositivos, en toda la Argentina."], None),
    "es/guide/index.html": (
        ["Te acompañamos paso a paso,",
         "para configurar Prime IPTV sin complicaciones."],
        "Tu guía de instalación completa"),

    # ══ German ══
    "de/index.html": (
        ["Gestochen scharfe Bilder und eine zuverlässige Wiedergabe,",
         "auf jedem Ihrer Geräte — ganz ohne Aufwand."], None),
    "de/deutschland/index.html": (
        ["Klare Bildqualität und stabile Leistung,",
         "vom Wohnzimmer bis aufs Smartphone, in ganz Deutschland."], None),
    "de/oesterreich/index.html": (
        ["Verlässliche Wiedergabe und brillante Schärfe,",
         "auf jedem Bildschirm, in ganz Österreich."], None),
    "de/schweiz/index.html": (
        ["Konstante Leistung und kristallklare Bilder,",
         "auf all Ihren Geräten, in der ganzen Schweiz."], None),
    "de/guide/index.html": (
        ["Schritt für Schritt verständlich erklärt —",
         "so richten Sie Prime IPTV mühelos auf jedem Gerät ein."],
        "Ihre vollständige Einrichtungsanleitung"),

    # ══ Italian ══
    "it/index.html": (
        ["Immagini nitide e una riproduzione sempre stabile,",
         "su tutti i tuoi dispositivi, senza alcuno sforzo."], None),
    "it/italia/index.html": (
        ["Qualità d'immagine impeccabile e prestazioni costanti,",
         "dal salotto allo smartphone, in tutta Italia."], None),
    "it/svizzera/index.html": (
        ["Riproduzione fluida e dettaglio cristallino,",
         "su ogni schermo, in tutta la Svizzera."], None),
    "it/germania/index.html": (
        ["Prestazioni costanti e immagini nitide,",
         "su tutti i tuoi dispositivi, in tutta la Germania."], None),
    "it/san-marino/index.html": (
        ["Un'esperienza stabile e in alta definizione,",
         "su ogni dispositivo, a San Marino."], None),
    "it/guide/index.html": (
        ["Ti guidiamo passo dopo passo,",
         "per configurare Prime IPTV senza alcuna difficoltà."],
        "La tua guida all'installazione completa"),

    # ══ Dutch ══
    "nl/index.html": (
        ["Haarscherp beeld en een stabiele weergave,",
         "op al je apparaten — helemaal moeiteloos."], None),
    "nl/nederland/index.html": (
        ["Kraakhelder beeld en betrouwbare prestaties,",
         "van de woonkamer tot je telefoon, in heel Nederland."], None),
    "nl/belgie/index.html": (
        ["Stabiele weergave en een scherp beeld,",
         "op elk scherm, overal in België."], None),
    "nl/duitsland/index.html": (
        ["Constante prestaties en helder beeld,",
         "op al je apparaten, in heel Duitsland."], None),
    "nl/suriname/index.html": (
        ["Een soepele kijkervaring in hoge kwaliteit,",
         "op elk scherm, in heel Suriname."], None),
    "nl/guide/index.html": (
        ["Stap voor stap leggen we het je uit,",
         "zodat je Prime IPTV moeiteloos op elk apparaat instelt."],
        "Jouw complete installatiegids"),

    # ══ Portuguese ══
    "pt/index.html": (
        ["Imagem nítida e um desempenho que nunca falha,",
         "em todos os seus dispositivos, sem qualquer esforço."], None),
    "pt/portugal/index.html": (
        ["Qualidade de imagem impecável e reprodução estável,",
         "da sala ao telemóvel, em todo o Portugal."], None),
    "pt/brasil/index.html": (
        ["Uma experiência fluida e em alta definição,",
         "em todas as telas, em todo o Brasil."], None),
    "pt/angola/index.html": (
        ["Desempenho consistente e imagem clara,",
         "em todos os seus dispositivos, em todo o Angola."], None),
    "pt/guide/index.html": (
        ["Acompanhamos cada passo do processo,",
         "para configurar o Prime IPTV sem complicações."],
        "O seu guia de instalação completo"),

    # ══ Turkish ══
    "tr/index.html": (
        ["Keskin görüntü kalitesi ve kararlı bir oynatma deneyimi,",
         "tüm cihazlarınızda, hiçbir zorluk yaşamadan."], None),
    "tr/turkiye/index.html": (
        ["Net görüntü ve kararlı performans,",
         "salondan telefonunuza, tüm Türkiye'de."], None),
    "tr/azerbaycan/index.html": (
        ["Her ekranda akıcı ve yüksek kaliteli bir deneyim,",
         "tüm Azerbaycan'da, kesintisiz."], None),
    "tr/almanya/index.html": (
        ["Tutarlı performans ve berrak görüntü,",
         "tüm cihazlarınızda, Almanya'nın her yerinde."], None),
    "tr/kibris/index.html": (
        ["Her cihazda kararlı ve yüksek çözünürlüklü bir deneyim,",
         "Kıbrıs'ın her yerinde."], None),
    "tr/guide/index.html": (
        ["Adım adım, sade bir anlatımla,",
         "Prime IPTV'yi her cihazda zahmetsizce kurun."],
        "Eksiksiz kurulum rehberiniz"),

    # ══ Arabic (guide pages only; main index left untouched) ══
    "guide/index.html": (
        ["خطوات واضحة وبسيطة",
         "لتشغيل Prime IPTV بسلاسة على أي جهاز من أول محاولة."],
        "دليلك الكامل للإعداد والتشغيل"),
    "guide/khalij/index.html": (
        ["جودة ثابتة وأداء موثوق على كل أجهزتك،",
         "أينما كنت في منطقة الخليج."], None),
    "guide/maghreb/index.html": (
        ["صورة نقية وتشغيل مستقر على جميع شاشاتك،",
         "في كل أنحاء المغرب العربي."], None),
    "guide/mashriq/index.html": (
        ["تجربة مشاهدة سلسة وعالية الوضوح على أي جهاز،",
         "في كل أنحاء المشرق العربي."], None),
}


def build_desc(lines):
    body = lines[0] + '\n      <br class="hp-br">\n      ' + lines[1]
    return ('    <p class="hp-desc hp-reveal" style="--d:180ms">\n'
            f'      {body}\n'
            '    </p>')


DESC_RE = re.compile(r'<p class="hp-desc hp-reveal"[^>]*>.*?</p>', re.DOTALL)
SUB_RE  = re.compile(r'(<span class="hp-title-sub">)[^<]*(</span>)')

changed = 0
for rel, (lines, guide_sub) in PAGES.items():
    path = os.path.join(BASE, rel)
    if not os.path.exists(path):
        print(f"[MISS] {rel}")
        continue
    with open(path, encoding="utf-8") as f:
        content = f.read()

    new = DESC_RE.sub(build_desc(lines), content, count=1)
    if guide_sub is not None:
        new = SUB_RE.sub(rf'\g<1>{guide_sub}\g<2>', new, count=1)

    if new == content:
        print(f"[SAME] {rel}")
        continue
    with open(path, "w", encoding="utf-8") as f:
        f.write(new)
    print(f"[OK]  {rel}")
    changed += 1

print(f"\nDone — {changed} updated.")
