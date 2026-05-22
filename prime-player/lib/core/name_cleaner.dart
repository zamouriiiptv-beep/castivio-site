/// Cleans IPTV channel/movie/series names from server-injected tags.
///
/// Handles patterns like:
///   "DSN+: My Spy (2024)"  →  "My Spy (2024)"
///   "Movie Name -4K -DE"   →  "Movie Name"
///   "FR - Movie Name HD"   →  "Movie Name"
///   "Movie [HDR] [HEVC]"   →  "Movie"
///   "NF: Movie (2024) 4K"  →  "Movie (2024)"
String cleanChannelName(String raw) {
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
