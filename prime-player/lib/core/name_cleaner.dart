/// Cleans IPTV channel/movie/series names from server-injected tags.
///
/// Handles patterns like:
///   "DSN+: My Spy (2024)"  →  "My Spy (2024)"
///   "Movie Name -4K -DE"   →  "Movie Name"
///   "FR - Movie Name HD"   →  "Movie Name"
///   "Movie [HDR] [HEVC]"   →  "Movie"
///   "NF: Movie (2024) 4K"  →  "Movie (2024)"
  String s = raw.trim();

  // ── 1. Service prefix chains  "DSN+: ", "NF: ", "AMZN: HBO: " ─────────────
  s = s.replaceAll(
    RegExp(r'^(?:[A-Z0-9][A-Z0-9+\-]*:\s*)+', caseSensitive: false),
    '',
  );

  // ── 2. Leading country/lang code before separator  "FR - " / "DE| " / "AR: "
  s = s.replaceAll(
    RegExp(r'^(?:' + _langSet + r')\s*[\-\|:\.]\s*', caseSensitive: false),
    '',
  );

  // ── 3. Bracketed tags  [4K] [HDR] [HEVC] [AR] [DE] ────────────────────────
  s = s.replaceAll(
    RegExp(r'\s*\[(?:' + _allTags + r')\]\s*', caseSensitive: false),
    ' ',
  );

  // ── 4. Parenthesised quality tags — keep 4-digit years  (2024) ─────────────
  s = s.replaceAll(
    RegExp(r'\s*\((?!' + _yearRx + r'\))(?:' + _allTags + r')\)\s*',
        caseSensitive: false),
    ' ',
  );

  // ── 5. Trailing quality/format/lang tokens (loop until stable) ──────────────
  final trailingRx = RegExp(
    r'(?:[\s\-\|\.]+'
    r'(?:' + _allTags + r')'
    r')+$',
    caseSensitive: false,
  );
  for (int i = 0; i < 6; i++) {
    final cleaned = s.replaceAll(trailingRx, '');
    if (cleaned == s) break;
    s = cleaned;
  }

  // ── 6. Leading quality tokens right after prefix removal  "-4K-DE " ─────────
  final leadingRx = RegExp(
    r'^(?:[\s\-\|\.]+'
    r'(?:' + _allTags + r')'
    r')+[\s\-\|\.]*',
    caseSensitive: false,
  );
  s = s.replaceAll(leadingRx, '');

  // ── 7. Clean up stray separators at start / end ──────────────────────────────
  s = s.replaceAll(RegExp(r'^[\s\-\|\.\:]+'), '');
  s = s.replaceAll(RegExp(r'[\s\-\|\.\:]+$'), '');

  // ── 8. Collapse multiple spaces ───────────────────────────────────────────────
  s = s.replaceAll(RegExp(r' {2,}'), ' ').trim();

  return s.isEmpty ? raw.trim() : s;
}

// ── Quality / format / codec tokens ──────────────────────────────────────────
const _qualityTags =
    r'4K|UHD|FHD|2160p|1080p|1080i|720p|480p|360p|240p'
    r'|HEVC|H\.?265|H\.?264|x265|x264|AVC|XVID|DIVX'
    r'|HDR10\+|HDR10|HDR|DV|DoVi|HLG|SDR'
    r'|ATMOS|TrueHD|DTS[-.]?HD\.?MA|DTS[-.]?HD|DTS|DD\+|DD5\.1|DD|EAC3|AAC'
    r'|AC3|DOLBY|TRUEHD|FLAC|MP3'
    r'|WEB[-.]?DL|WEB|WEBRIP|BLURAY|BLU[-.]?RAY|BDRIP|DVDRIP|CAM|TS|HDCAM'
    r'|REMUX|PROPER|REPACK|EXTENDED|UNRATED|THEATRICAL|DIRECTORS[-.]?CUT'
    r'|SD|HD';

// ── Known language / country codes ───────────────────────────────────────────
const _langSet =
    r'AR|EN|FR|DE|ES|PT|IT|RU|ZH|JA|KO|TR|NL|PL|SV|DA|NO|FI|HE|FA|HI|UR'
    r'|EL|CS|HU|RO|SK|BG|HR|SR|UK|TH|VI|ID|MS|CA|AZ|KA|BE|IS|MT|AF|SW'
    r'|ARA|ENG|FRA|DEU|SPA|POR|ITA|RUS|CHI|JPN|KOR|TUR|NLD|POL|SWE|DAN|NOR'
    r'|FIN|HEB|PER|HIN|GRE|CZE|HUN|ROM|SLK|BUL|HRV|SRP|UKR|THA|VIE|IND|MAY'
    r'|USA|GBR|GER|FRN|CHN|JPN|KOR|BRA|MEX|AUS|CAN|SAU|UAE|MAR|DZA|TUN|EGY'
    r'|IRN|IRQ|SYR|LBN|JOR|LIB';

// All tags that can be stripped (quality + language)
const _allTags = _qualityTags + r'|' + _langSet;

// Matches a 4-digit year like 2024
const _yearRx = r'\d{4}';

// ── Quality badge detection ───────────────────────────────────────────────────

enum QualityBadgeType { video, hdr, audio, codec }

class QualityBadge {
  final String           label;
  final QualityBadgeType type;
  const QualityBadge(this.label, this.type);
}

/// Scans [rawText] (raw server name, groupTitle, etc.) and returns detected
/// quality badges. Most-specific pattern wins within each category.
List<QualityBadge> extractQualityBadges(String rawText) {
  final badges = <QualityBadge>[];

  // Video resolution — most specific first
  if (_tag(rawText, r'4K|UHD|2160p'))
    badges.add(const QualityBadge('4K',  QualityBadgeType.video));
  else if (_tag(rawText, r'FHD|1080[pi]'))
    badges.add(const QualityBadge('FHD', QualityBadgeType.video));
  else if (_tag(rawText, r'720p'))
    badges.add(const QualityBadge('HD',  QualityBadgeType.video));

  // HDR variants — most specific first
  if (_tag(rawText, r'HDR10\+'))
    badges.add(const QualityBadge('HDR10+',       QualityBadgeType.hdr));
  else if (_tag(rawText, r'HDR10'))
    badges.add(const QualityBadge('HDR10',        QualityBadgeType.hdr));
  else if (_tag(rawText, r'DV|DoVi'))
    badges.add(const QualityBadge('Dolby Vision', QualityBadgeType.hdr));
  else if (_tag(rawText, r'HDR'))
    badges.add(const QualityBadge('HDR',          QualityBadgeType.hdr));

  // Audio format — most specific first
  if (_tag(rawText, r'ATMOS'))
    badges.add(const QualityBadge('Atmos',  QualityBadgeType.audio));
  else if (_tag(rawText, r'TrueHD'))
    badges.add(const QualityBadge('TrueHD', QualityBadgeType.audio));
  else if (_tag(rawText, r'DTS[-.]?HD'))
    badges.add(const QualityBadge('DTS-HD', QualityBadgeType.audio));
  else if (_tag(rawText, r'DTS'))
    badges.add(const QualityBadge('DTS',    QualityBadgeType.audio));
  else if (_tag(rawText, r'DD5\.1|DD\+|EAC3|AC3|5\.1'))
    badges.add(const QualityBadge('5.1',    QualityBadgeType.audio));

  // Video codec
  if (_tag(rawText, r'HEVC|H\.?265|x265'))
    badges.add(const QualityBadge('HEVC',  QualityBadgeType.codec));
  else if (_tag(rawText, r'H\.?264|x264|AVC'))
    badges.add(const QualityBadge('H.264', QualityBadgeType.codec));

  return badges;
}

/// Augments [badges] with Xtream technical video/audio fields when text
/// detection found nothing for that category.
List<QualityBadge> augmentFromXtream(
    List<QualityBadge> badges, Map<dynamic, dynamic> xtreamInfo) {
  final video = xtreamInfo['video'];
  final audio = xtreamInfo['audio'];

  if (badges.every((b) => b.type != QualityBadgeType.video)) {
    final w = video is Map ? (video['width']  as num?)?.toInt() : null;
    final h = video is Map ? (video['height'] as num?)?.toInt() : null;
    final dim = ((w ?? 0) > (h ?? 0) ? w : h) ?? 0;
    if (dim >= 2160)
      badges.insert(0, const QualityBadge('4K',  QualityBadgeType.video));
    else if (dim >= 1080)
      badges.insert(0, const QualityBadge('FHD', QualityBadgeType.video));
    else if (dim >= 720)
      badges.insert(0, const QualityBadge('HD',  QualityBadgeType.video));
  }

  if (badges.every((b) => b.type != QualityBadgeType.audio)) {
    final ch = audio is Map ? (audio['channels'] as num?)?.toInt() : null;
    if (ch != null) {
      badges.add(ch >= 6
          ? const QualityBadge('5.1',    QualityBadgeType.audio)
          : const QualityBadge('Stereo', QualityBadgeType.audio));
    }
  }

  return badges;
}

bool _tag(String s, String pattern) =>
    RegExp(r'(?:^|[\s\[\(\-_\.])(?:' + pattern + r')(?:$|[\s\]\)\-_\.])',
        caseSensitive: false)
        .hasMatch(s);
