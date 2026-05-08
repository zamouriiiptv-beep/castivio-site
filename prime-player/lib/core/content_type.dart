/// Detects content type from channel group title and stream URL.
enum ContentType { live, movie, series, radio }

ContentType detectContentType(String? groupTitle, String streamUrl) {
  final g = (groupTitle ?? '').toLowerCase();
  final u = streamUrl.toLowerCase();

  // Radio
  if (_containsAny(g, [
        'radio', 'music', 'راديو', 'إذاعة', 'اذاعة', 'muzik', 'musique',
      ])) {
    return ContentType.radio;
  }

  // Series
  if (_containsAny(g, [
        'series', 'show', 'episode', 'مسلسل', 'مسلسلات', 'serie', 'séries',
        'anime', 'أنمي', 'انمي', 'كرتون', 'cartoon',
      ]) ||
      u.contains('/series/')) {
    return ContentType.series;
  }

  // Movies / VOD — include both أفلام (with hamza) and افلام (without)
  if (_containsAny(g, [
        'movie', 'film', 'vod', 'cinema', 'افلام', 'أفلام', 'فيلم', 'سينما',
        'movies', 'films', 'pelicul', 'أكشن', 'رعب', 'كوميدي', 'دراما',
      ]) ||
      u.contains('/movie/') ||
      u.contains('/vod/')) {
    return ContentType.movie;
  }

  return ContentType.live;
}

bool _containsAny(String text, List<String> keywords) =>
    keywords.any((k) => text.contains(k));
