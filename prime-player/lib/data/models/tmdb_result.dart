const _imgBase   = 'https://image.tmdb.org/t/p/w500';
const _thumbBase = 'https://image.tmdb.org/t/p/w200';

class TmdbResult {
  final int     id;
  final String  title;
  final String? posterPath;
  final String? overview;
  final double  voteAverage;
  final String? releaseDate;
  final String? genres;
  final int?    runtime;
  final String? director;
  final String? cast;
  final bool    isMovie;

  const TmdbResult({
    required this.id,
    required this.title,
    required this.isMovie,
    this.posterPath,
    this.overview,
    this.voteAverage = 0,
    this.releaseDate,
    this.genres,
    this.runtime,
    this.director,
    this.cast,
  });

  String? get posterUrl  => posterPath != null ? '$_imgBase$posterPath'   : null;
  String? get thumbUrl   => posterPath != null ? '$_thumbBase$posterPath' : null;

  String? get year {
    final d = releaseDate;
    if (d == null || d.length < 4) return null;
    return d.substring(0, 4);
  }

  String get ratingString => voteAverage > 0
      ? voteAverage.toStringAsFixed(1)
      : '';

  // ── Serialisation (stored as Map in Hive) ──────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id':           id,
    'title':        title,
    'posterPath':   posterPath,
    'overview':     overview,
    'voteAverage':  voteAverage,
    'releaseDate':  releaseDate,
    'genres':       genres,
    'runtime':      runtime,
    'director':     director,
    'cast':         cast,
    'isMovie':      isMovie,
  };

  factory TmdbResult.fromMap(Map<dynamic, dynamic> m) => TmdbResult(
    id:           m['id'] as int? ?? 0,
    title:        m['title'] as String? ?? '',
    posterPath:   m['posterPath'] as String?,
    overview:     m['overview'] as String?,
    voteAverage:  (m['voteAverage'] as num?)?.toDouble() ?? 0,
    releaseDate:  m['releaseDate'] as String?,
    genres:       m['genres'] as String?,
    runtime:      m['runtime'] as int?,
    director:     m['director'] as String?,
    cast:         m['cast'] as String?,
    isMovie:      m['isMovie'] as bool? ?? true,
  );
}
