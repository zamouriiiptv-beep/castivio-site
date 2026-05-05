/// Detects content type from channel group title and stream URL.
enum ContentType { live, movie, series, radio }

ContentType detectContentType(String? groupTitle, String streamUrl) {
  final g = (groupTitle ?? '').toLowerCase();
  final u = streamUrl.toLowerCase();

  // Radio
  if (_containsAny(g, ['radio', 'music', 'راديو', 'إذاعة', 'muzik', 'musique'])) {
    return ContentType.radio;
  }

  // Series
  if (_containsAny(g, ['series', 'show', 'episode', 'مسلسل', 'serie', 'séries']) ||
      u.contains('/series/')) {
    return ContentType.series;
  }

  // Movies / VOD
  if (_containsAny(g, [
        'movie', 'film', 'vod', 'cinema', 'افلام', 'فيلم', 'سينما',
        'movies', 'films', 'pelicul',
      ]) ||
      u.contains('/movie/') ||
      u.contains('/vod/')) {
    return ContentType.movie;
  }

  return ContentType.live;
}

bool _containsAny(String text, List<String> keywords) =>
    keywords.any((k) => text.contains(k));
