import 'package:dio/dio.dart';
import '../models/tmdb_result.dart';

class TmdbService {
  static const _base = 'https://api.themoviedb.org/3';

  final String _apiKey;
  final Dio    _dio;

  TmdbService(this._apiKey)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  // ── Public entry point ────────────────────────────────────────────────────

  /// Searches movie OR TV depending on the series flag.
  /// Returns full result with credits, or null on any failure.
  Future<TmdbResult?> fetch(String name, {int? year, bool isTv = false}) async {
    try {
      final id = await _searchId(name, year: year, isTv: isTv);
      if (id == null) return null;
      return isTv ? await _tvDetails(id) : await _movieDetails(id);
    } catch (_) {
      return null;
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<int?> _searchId(String name, {int? year, bool isTv = false}) async {
    // Try Arabic first, then English if empty
    final endpoint = isTv ? '/search/tv' : '/search/movie';
    for (final lang in ['ar-SA', 'en-US']) {
      final params = {
        'api_key':  _apiKey,
        'query':    name,
        'language': lang,
        if (!isTv && year != null) 'year': year,
        if (isTv  && year != null) 'first_air_date_year': year,
        'include_adult': false,
        'page': 1,
      };
      final res = await _dio.get<dynamic>('$_base$endpoint',
          queryParameters: params);
      final results = (res.data as Map?)?['results'] as List? ?? [];
      if (results.isNotEmpty) {
        return (results.first as Map)['id'] as int?;
      }
    }
    return null;
  }

  // ── Movie details ──────────────────────────────────────────────────────────

  Future<TmdbResult?> _movieDetails(int id) async {
    final res = await _dio.get<dynamic>(
      '$_base/movie/$id',
      queryParameters: {
        'api_key':             _apiKey,
        'language':            'ar-SA',
        'append_to_response':  'credits',
      },
    );
    final d = res.data as Map<String, dynamic>;
    // Fallback to English overview if Arabic is empty
    String? overview = _str(d['overview']);
    if (overview == null || overview.isEmpty) {
      overview = await _englishOverview(id, isTv: false);
    }

    return TmdbResult(
      id:          id,
      title:       _str(d['title'])           ?? _str(d['original_title']) ?? '',
      posterPath:  _str(d['poster_path']),
      overview:    overview,
      voteAverage: (d['vote_average'] as num?)?.toDouble() ?? 0,
      releaseDate: _str(d['release_date']),
      genres:      _genreNames(d['genres']),
      runtime:     d['runtime'] as int?,
      director:    _director(d['credits']),
      cast:        _castList(d['credits']),
      isMovie:     true,
    );
  }

  // ── TV details ────────────────────────────────────────────────────────────

  Future<TmdbResult?> _tvDetails(int id) async {
    final res = await _dio.get<dynamic>(
      '$_base/tv/$id',
      queryParameters: {
        'api_key':            _apiKey,
        'language':           'ar-SA',
        'append_to_response': 'credits',
      },
    );
    final d = res.data as Map<String, dynamic>;
    String? overview = _str(d['overview']);
    if (overview == null || overview.isEmpty) {
      overview = await _englishOverview(id, isTv: true);
    }

    return TmdbResult(
      id:          id,
      title:       _str(d['name'])            ?? _str(d['original_name']) ?? '',
      posterPath:  _str(d['poster_path']),
      overview:    overview,
      voteAverage: (d['vote_average'] as num?)?.toDouble() ?? 0,
      releaseDate: _str(d['first_air_date']),
      genres:      _genreNames(d['genres']),
      runtime:     _tvRuntime(d),
      director:    _creator(d['created_by']),
      cast:        _castList(d['credits']),
      isMovie:     false,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String?> _englishOverview(int id, {required bool isTv}) async {
    try {
      final path = isTv ? '/tv/$id' : '/movie/$id';
      final res = await _dio.get<dynamic>(
        '$_base$path',
        queryParameters: {'api_key': _apiKey, 'language': 'en-US'},
      );
      return _str((res.data as Map?)?['overview']);
    } catch (_) {
      return null;
    }
  }

  static String? _str(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static String? _genreNames(dynamic genres) {
    if (genres is! List || genres.isEmpty) return null;
    return genres.map((g) => g['name']).whereType<String>().join(', ');
  }

  static String? _director(dynamic credits) {
    if (credits is! Map) return null;
    final crew = (credits['crew'] as List?) ?? [];
    return crew
        .cast<Map<String, dynamic>>()
        .where((c) => c['job'] == 'Director')
        .map((c) => c['name']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .take(2)
        .join(', ');
  }

  static String? _creator(dynamic createdBy) {
    if (createdBy is! List || createdBy.isEmpty) return null;
    return createdBy
        .cast<Map<String, dynamic>>()
        .map((c) => c['name']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .take(2)
        .join(', ');
  }

  static String? _castList(dynamic credits) {
    if (credits is! Map) return null;
    final cast = (credits['cast'] as List?) ?? [];
    return cast
        .cast<Map<String, dynamic>>()
        .map((c) => c['name']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .take(5)
        .join(', ');
  }

  static int? _tvRuntime(Map<String, dynamic> d) {
    final eps = d['episode_run_time'];
    if (eps is List && eps.isNotEmpty) return eps.first as int?;
    return null;
  }
}
