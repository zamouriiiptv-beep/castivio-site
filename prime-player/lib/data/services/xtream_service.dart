import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/channel.dart';
import '../models/series_info.dart';

// ─── Isolate-safe input ───────────────────────────────────────────────────────

class _ParseInput {
  final String json;
  final Map<String, String> catMap;
  final String host;
  final String username;
  final String password;
  const _ParseInput({
    required this.json,
    required this.catMap,
    required this.host,
    required this.username,
    required this.password,
  });
}

// ─── Isolate parse functions ──────────────────────────────────────────────────

List<Channel> _parseLiveJson(_ParseInput p) {
  dynamic data;
  try { data = jsonDecode(p.json); } catch (_) { return []; }
  if (data is! List) return [];
  final result = <Channel>[];
  for (final s in data.cast<Map<String, dynamic>>()) {
    final streamId = s['stream_id']?.toString() ?? '';
    if (streamId.isEmpty) continue;
    final catId = s['category_id']?.toString() ?? '';
    result.add(Channel(
      id:         'live_$streamId',
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  '${p.host}/live/${p.username}/${p.password}/$streamId.${s['container_extension'] ?? 'ts'}',
      logoUrl:    s['stream_icon'] as String?,
      groupTitle: p.catMap[catId] ?? p.catMap.values.firstOrNull ?? 'Live TV',
      tvgId:      s['epg_channel_id'] as String?,
    ));
  }
  return result;
}

List<Channel> _parseVodJson(_ParseInput p) {
  dynamic data;
  try { data = jsonDecode(p.json); } catch (_) { return []; }
  if (data is! List) return [];
  final result = <Channel>[];
  for (final s in data.cast<Map<String, dynamic>>()) {
    final streamId = s['stream_id']?.toString() ?? '';
    if (streamId.isEmpty) continue;
    final catId = s['category_id']?.toString() ?? '';
    result.add(Channel(
      id:         'vod_$streamId',
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  '${p.host}/movie/${p.username}/${p.password}/$streamId.${s['container_extension'] ?? 'mp4'}',
      logoUrl:    s['stream_icon'] as String?,
      groupTitle: p.catMap[catId] ?? p.catMap.values.firstOrNull ?? 'Movies',
    ));
  }
  return result;
}

List<Channel> _parseSeriesJson(_ParseInput p) {
  dynamic data;
  try { data = jsonDecode(p.json); } catch (_) { return []; }
  if (data is! List) return [];
  final result = <Channel>[];
  for (final s in data.cast<Map<String, dynamic>>()) {
    final seriesId = s['series_id']?.toString() ?? '';
    if (seriesId.isEmpty) continue;
    final catId = s['category_id']?.toString() ?? '';
    result.add(Channel(
      id:         'series_$seriesId',
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  '${p.host}/series/${p.username}/${p.password}/$seriesId',
      logoUrl:    s['cover'] as String?,
      groupTitle: p.catMap[catId] ?? p.catMap.values.firstOrNull ?? 'Series',
    ));
  }
  return result;
}

// ─── XtreamService ────────────────────────────────────────────────────────────

class XtreamService {
  final String host;
  final String username;
  final String password;

  // Fallback per-category concurrency (16 parallel — only used if bulk API returns nothing)
  static const _concurrency = 16;

  late final Dio _dio;

  XtreamService({
    required this.host,
    required this.username,
    required this.password,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl:        host.endsWith('/') ? host : '$host/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30), // per-category responses are small — 30s is plenty
      validateStatus: (_) => true,
      headers: const {'Accept-Encoding': 'gzip, deflate'},
    ));
  }

  String get _base => 'player_api.php?username=$username&password=$password';

  Future<String?> authenticate() async {
    try {
      final res = await _dio.get<dynamic>('$_base&action=get_live_categories');
      final status = res.statusCode ?? 0;
      debugPrint('[Xtream] auth HTTP $status');

      if (status == 884) return 'Account not found or disabled (HTTP 884).\nCheck the credentials on your server panel.';
      if (status == 885) return 'Max connections reached (HTTP 885).\nClose other IPTV apps and try again.';
      if (status == 401 || status == 403) return 'Access denied (HTTP $status). Wrong username or password.';
      if (status != 200) return 'Server error (HTTP $status).';

      final data = res.data;
      if (data is Map) {
        final userInfo = data['user_info'] as Map?;
        final auth = userInfo?['auth'];
        if (auth != null && auth.toString() == '0') {
          return 'Server rejected credentials: ${userInfo?['message'] ?? 'Authentication failed'}';
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Server is not responding.';
      }
      return 'Network error: ${e.message}';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // ── Live ──────────────────────────────────────────────────────────────────

  /// Fetches live channels. Tries bulk API first (2 parallel requests).
  /// Falls back to per-category only if bulk returns nothing.
  Future<List<Channel>> getLiveChannels() async {
    try {
      final results = await Future.wait([
        _dio.get<dynamic>('$_base&action=get_live_categories'),
        _dio.get<String>('$_base&action=get_live_streams',
            options: Options(
              responseType:   ResponseType.plain,
              receiveTimeout: const Duration(minutes: 3),
            )),
      ]);

      final categories = _asList(results[0].data as dynamic);
      final catMap     = _buildCatMap(categories);
      final json       = ((results[1] as Response<String>).data ?? '').trim();

      if (json.isNotEmpty && json != '[]' && json != 'null') {
        final channels = await compute(_parseLiveJson, _ParseInput(
          json: json, catMap: catMap,
          host: host, username: username, password: password,
        ));
        if (channels.isNotEmpty) {
          debugPrint('[Xtream] live bulk: ${channels.length} channels (2 requests)');
          return channels;
        }
      }

      if (categories.isEmpty) return [];
      debugPrint('[Xtream] live bulk empty — per-category fallback');
      return _fetchAllCategories(
        categories:   categories,
        actionFn:     (id) => '$_base&action=get_live_streams&category_id=$id',
        parseFn:      _parseLiveJson,
        defaultGroup: 'Live TV',
      );
    } catch (e) {
      debugPrint('[Xtream] getLiveChannels error: $e');
      return [];
    }
  }

  // ── VOD ───────────────────────────────────────────────────────────────────

  Future<List<Channel>> getVodChannels() async {
    try {
      final results = await Future.wait([
        _dio.get<dynamic>('$_base&action=get_vod_categories'),
        _dio.get<String>('$_base&action=get_vod_streams',
            options: Options(
              responseType:   ResponseType.plain,
              receiveTimeout: const Duration(minutes: 3),
            )),
      ]);

      final categories = _asList(results[0].data as dynamic);
      final catMap     = _buildCatMap(categories);
      final json       = ((results[1] as Response<String>).data ?? '').trim();

      if (json.isNotEmpty && json != '[]' && json != 'null') {
        final channels = await compute(_parseVodJson, _ParseInput(
          json: json, catMap: catMap,
          host: host, username: username, password: password,
        ));
        if (channels.isNotEmpty) {
          debugPrint('[Xtream] VOD bulk: ${channels.length} films (2 requests)');
          return channels;
        }
      }

      if (categories.isEmpty) return [];
      debugPrint('[Xtream] VOD bulk empty — per-category fallback');
      return _fetchAllCategories(
        categories:   categories,
        actionFn:     (id) => '$_base&action=get_vod_streams&category_id=$id',
        parseFn:      _parseVodJson,
        defaultGroup: 'Movies',
      );
    } catch (e) {
      debugPrint('[Xtream] getVodChannels error: $e');
      return [];
    }
  }

  // ── Series ────────────────────────────────────────────────────────────────

  Future<List<Channel>> getSeriesChannels() async {
    try {
      final results = await Future.wait([
        _dio.get<dynamic>('$_base&action=get_series_categories'),
        _dio.get<String>('$_base&action=get_series',
            options: Options(
              responseType:   ResponseType.plain,
              receiveTimeout: const Duration(minutes: 3),
            )),
      ]);

      final categories = _asList(results[0].data as dynamic);
      final catMap     = _buildCatMap(categories);
      final json       = ((results[1] as Response<String>).data ?? '').trim();

      if (json.isNotEmpty && json != '[]' && json != 'null') {
        final channels = await compute(_parseSeriesJson, _ParseInput(
          json: json, catMap: catMap,
          host: host, username: username, password: password,
        ));
        if (channels.isNotEmpty) {
          debugPrint('[Xtream] series bulk: ${channels.length} shows (2 requests)');
          return channels;
        }
      }

      if (categories.isEmpty) return [];
      debugPrint('[Xtream] series bulk empty — per-category fallback');
      return _fetchAllCategories(
        categories:   categories,
        actionFn:     (id) => '$_base&action=get_series&category_id=$id',
        parseFn:      _parseSeriesJson,
        defaultGroup: 'Series',
      );
    } catch (e) {
      debugPrint('[Xtream] getSeriesChannels error: $e');
      return [];
    }
  }

  // ── Series info (seasons + episodes for one series) ──────────────────────

  Future<SeriesInfo?> getSeriesInfo(String seriesId) async {
    try {
      final res = await _dio.get<dynamic>(
        '$_base&action=get_series_info&series_id=$seriesId',
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) return null;

      final info       = data['info']     as Map<String, dynamic>?      ?? const {};
      final seasonList = data['seasons']  as List<dynamic>?             ?? const [];
      final epsMap     = data['episodes'] as Map<String, dynamic>?      ?? const {};

      final seasons = <Season>[];
      for (final s in seasonList.cast<Map<String, dynamic>>()) {
        final num = (s['season_number'] is int)
            ? s['season_number'] as int
            : int.tryParse(s['season_number']?.toString() ?? '') ?? 0;
        seasons.add(Season(
          number:   num,
          name:    (s['name'] as String?)?.trim() ?? 'Season $num',
          cover:    s['cover']    as String?,
          overview: s['overview'] as String?,
        ));
      }

      final episodes = <Episode>[];
      for (final entry in epsMap.entries) {
        final seasonNum = int.tryParse(entry.key) ?? 0;
        final list = (entry.value as List<dynamic>?) ?? const [];
        for (final e in list.cast<Map<String, dynamic>>()) {
          final id = e['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          final epNum = (e['episode_num'] is int)
              ? e['episode_num'] as int
              : int.tryParse(e['episode_num']?.toString() ?? '') ?? 0;
          final inf = e['info'] as Map<String, dynamic>? ?? const {};
          episodes.add(Episode(
            id:                 id,
            seasonNumber:       seasonNum,
            episodeNumber:      epNum,
            title:             (e['title'] as String?)?.trim() ?? 'Episode $epNum',
            containerExtension: (e['container_extension'] as String?) ?? 'mkv',
            plot:               inf['plot']     as String?,
            cover:              inf['movie_image'] as String? ?? inf['cover_big'] as String?,
            durationSeconds:    inf['duration_secs'] is int
                                ? inf['duration_secs'] as int
                                : int.tryParse(inf['duration_secs']?.toString() ?? ''),
          ));
        }
      }

      // If seasons list is empty but we have episodes, derive seasons from episodes
      if (seasons.isEmpty && episodes.isNotEmpty) {
        final nums = episodes.map((e) => e.seasonNumber).toSet().toList()..sort();
        for (final n in nums) {
          seasons.add(Season(number: n, name: 'Season $n'));
        }
      }

      return SeriesInfo(
        seriesId:    seriesId,
        name:       (info['name'] as String?)?.trim() ?? '',
        cover:       info['cover']       as String?,
        plot:        info['plot']        as String?,
        cast:        info['cast']        as String?,
        director:    info['director']    as String?,
        genre:       info['genre']       as String?,
        releaseDate: info['releaseDate'] as String? ?? info['release_date'] as String?,
        rating:      info['rating']?.toString(),
        seasons:     seasons,
        episodes:    episodes,
      );
    } catch (e) {
      debugPrint('[Xtream] getSeriesInfo error: $e');
      return null;
    }
  }

  // ── Core: per-category fallback with high concurrency ─────────────────────

  Future<List<Channel>> _fetchAllCategories({
    required List<Map<String, dynamic>> categories,
    required String Function(String catId) actionFn,
    required List<Channel> Function(_ParseInput) parseFn,
    required String defaultGroup,
  }) async {
    final seen    = <String>{};
    final result  = <Channel>[];

    for (int i = 0; i < categories.length; i += _concurrency) {
      final chunk = categories.sublist(
          i, (i + _concurrency).clamp(0, categories.length));

      final lists = await Future.wait(chunk.map((cat) async {
        final catId   = cat['category_id']?.toString() ?? '';
        final catName = (cat['category_name'] as String?)?.trim() ?? defaultGroup;
        if (catId.isEmpty) return <Channel>[];
        return _fetchCategoryWithRetry(
            actionFn(catId), {catId: catName}, parseFn);
      }));

      for (final channels in lists) {
        for (final ch in channels) {
          if (seen.add(ch.id)) result.add(ch);   // dedup by channel id
        }
      }
    }
    return result;
  }

  Future<List<Channel>> _fetchCategoryWithRetry(
    String url,
    Map<String, String> catMap,
    List<Channel> Function(_ParseInput) parseFn,
  ) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _dio.get<String>(url,
            options: Options(responseType: ResponseType.plain));
        final json = res.data ?? '[]';
        if (json.trim() == '[]' || json.trim() == 'null' || json.isEmpty) {
          return [];
        }
        return await compute(parseFn, _ParseInput(
            json: json, catMap: catMap,
            host: host, username: username, password: password));
      } catch (_) {
        if (attempt == 0) await Future.delayed(const Duration(seconds: 2));
      }
    }
    return [];
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, String> _buildCatMap(List<Map<String, dynamic>> cats) {
    final map = <String, String>{};
    for (final c in cats) {
      final id   = c['category_id']?.toString();
      final name = c['category_name'] as String?;
      if (id != null && name != null && name.isNotEmpty) map[id] = name;
    }
    return map;
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  String buildM3uUrl() =>
      '$host/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
}
