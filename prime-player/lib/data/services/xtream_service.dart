import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/channel.dart';

// ─── Isolate-safe input (only primitive fields) ──────────────────────────────

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

// ─── Top-level functions — required for compute() ────────────────────────────
// Each returns (channels, foundCategoryIds) so we can detect missing categories.

(List<Channel>, Set<String>) _parseLiveJsonFull(_ParseInput p) {
  dynamic data;
  try { data = jsonDecode(p.json); } catch (_) { return ([], {}); }
  if (data is! List) return ([], {});
  final result = <Channel>[];
  final catIds = <String>{};
  for (final s in data.cast<Map<String, dynamic>>()) {
    final streamId = s['stream_id']?.toString() ?? '';
    if (streamId.isEmpty) continue;
    final catId = s['category_id']?.toString() ?? '';
    if (catId.isNotEmpty) catIds.add(catId);
    result.add(Channel(
      id:         'live_$streamId',
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  '${p.host}/live/${p.username}/${p.password}/$streamId.${s['container_extension'] ?? 'ts'}',
      logoUrl:    s['stream_icon'] as String?,
      groupTitle: p.catMap[catId] ?? 'Live TV',
      tvgId:      s['epg_channel_id'] as String?,
    ));
  }
  return (result, catIds);
}

(List<Channel>, Set<String>) _parseVodJsonFull(_ParseInput p) {
  dynamic data;
  try { data = jsonDecode(p.json); } catch (_) { return ([], {}); }
  if (data is! List) return ([], {});
  final result = <Channel>[];
  final catIds = <String>{};
  for (final s in data.cast<Map<String, dynamic>>()) {
    final streamId = s['stream_id']?.toString() ?? '';
    if (streamId.isEmpty) continue;
    final catId = s['category_id']?.toString() ?? '';
    if (catId.isNotEmpty) catIds.add(catId);
    result.add(Channel(
      id:         'vod_$streamId',
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  '${p.host}/movie/${p.username}/${p.password}/$streamId.${s['container_extension'] ?? 'mp4'}',
      logoUrl:    s['stream_icon'] as String?,
      groupTitle: p.catMap[catId] ?? 'Movies',
    ));
  }
  return (result, catIds);
}

(List<Channel>, Set<String>) _parseSeriesJsonFull(_ParseInput p) {
  dynamic data;
  try { data = jsonDecode(p.json); } catch (_) { return ([], {}); }
  if (data is! List) return ([], {});
  final result = <Channel>[];
  final catIds = <String>{};
  for (final s in data.cast<Map<String, dynamic>>()) {
    final seriesId = s['series_id']?.toString() ?? '';
    if (seriesId.isEmpty) continue;
    final catId = s['category_id']?.toString() ?? '';
    if (catId.isNotEmpty) catIds.add(catId);
    result.add(Channel(
      id:         'series_$seriesId',
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  '${p.host}/series/${p.username}/${p.password}/$seriesId',
      logoUrl:    s['cover'] as String?,
      groupTitle: p.catMap[catId] ?? 'Series',
    ));
  }
  return (result, catIds);
}

// Legacy single-value parsers (kept for per-category fallback)
List<Channel> _parseLiveJson(_ParseInput p)   => _parseLiveJsonFull(p).$1;
List<Channel> _parseVodJson(_ParseInput p)    => _parseVodJsonFull(p).$1;
List<Channel> _parseSeriesJson(_ParseInput p) => _parseSeriesJsonFull(p).$1;

// ─── XtreamService ────────────────────────────────────────────────────────────

class XtreamService {
  final String host;
  final String username;
  final String password;

  late final Dio _dio;

  XtreamService({
    required this.host,
    required this.username,
    required this.password,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl:        host.endsWith('/') ? host : '$host/',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 10),  // large servers can send 40+ MB
      validateStatus: (_) => true,
      headers: const {'Accept-Encoding': 'gzip, deflate'},
    ));
  }

  String get _base => 'player_api.php?username=$username&password=$password';

  /// Returns null on success, or a human-readable error string on failure.
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

  Future<List<Channel>> getLiveChannels() async {
    try {
      final catRes = await _dio.get<dynamic>('$_base&action=get_live_categories');
      final categories = _asList(catRes.data);
      final catMap = _buildCatMap(categories);

      final streamsRes = await _dio.get<String>('$_base&action=get_live_streams',
          options: Options(responseType: ResponseType.plain));
      final streamsJson = streamsRes.data ?? '[]';

      if (streamsJson.trim() == '[]' || streamsJson.trim() == 'null' || streamsJson.isEmpty) {
        debugPrint('[Xtream] bulk live empty — fetching per category');
        return _livePerCategory(categories, catMap);
      }

      final (channels, foundCatIds) = await compute(_parseLiveJsonFull,
          _ParseInput(json: streamsJson, catMap: catMap, host: host, username: username, password: password));
      debugPrint('[Xtream] live bulk: ${channels.length} channels, ${foundCatIds.length}/${catMap.length} categories');

      // Supplemental fetch for categories the server omitted from bulk response
      final missingCats = categories.where((cat) {
        final id = cat['category_id']?.toString() ?? '';
        return id.isNotEmpty && !foundCatIds.contains(id);
      }).toList();
      if (missingCats.isNotEmpty) {
        debugPrint('[Xtream] live: ${missingCats.length} categories missing from bulk — fetching individually');
        final extra = await _livePerCategory(missingCats, catMap);
        return [...channels, ...extra];
      }
      return channels;
    } catch (e) {
      debugPrint('[Xtream] getLiveChannels error: $e');
      return [];
    }
  }

  Future<List<Channel>> _livePerCategory(
      List<Map<String, dynamic>> cats, Map<String, String> catMap) async {
    final result = <Channel>[];
    for (final cat in cats) {
      final catId   = cat['category_id']?.toString() ?? '';
      final catName = cat['category_name'] as String? ?? 'Live TV';
      final channels = await _fetchWithRetry(() async {
        final res = await _dio.get<String>(
            '$_base&action=get_live_streams&category_id=$catId',
            options: Options(responseType: ResponseType.plain));
        return compute(_parseLiveJson, _ParseInput(
            json: res.data ?? '[]', catMap: {catId: catName},
            host: host, username: username, password: password));
      });
      result.addAll(channels);
    }
    return result;
  }

  // ── VOD ───────────────────────────────────────────────────────────────────

  Future<List<Channel>> getVodChannels() async {
    try {
      final catRes = await _dio.get<dynamic>('$_base&action=get_vod_categories');
      final categories = _asList(catRes.data);
      final catMap = _buildCatMap(categories);

      final streamsRes = await _dio.get<String>('$_base&action=get_vod_streams',
          options: Options(responseType: ResponseType.plain));
      final streamsJson = streamsRes.data ?? '[]';

      if (streamsJson.trim() == '[]' || streamsJson.trim() == 'null' || streamsJson.isEmpty) {
        debugPrint('[Xtream] bulk VOD empty — fetching per category');
        return _vodPerCategory(categories, catMap);
      }

      final (channels, foundCatIds) = await compute(_parseVodJsonFull,
          _ParseInput(json: streamsJson, catMap: catMap, host: host, username: username, password: password));
      debugPrint('[Xtream] VOD bulk: ${channels.length} films, ${foundCatIds.length}/${catMap.length} categories');

      final missingCats = categories.where((cat) {
        final id = cat['category_id']?.toString() ?? '';
        return id.isNotEmpty && !foundCatIds.contains(id);
      }).toList();
      if (missingCats.isNotEmpty) {
        debugPrint('[Xtream] VOD: ${missingCats.length} categories missing from bulk — fetching individually');
        final extra = await _vodPerCategory(missingCats, catMap);
        return [...channels, ...extra];
      }
      return channels;
    } catch (e) {
      debugPrint('[Xtream] getVodChannels error: $e');
      return [];
    }
  }

  Future<List<Channel>> _vodPerCategory(
      List<Map<String, dynamic>> cats, Map<String, String> catMap) async {
    final result = <Channel>[];
    for (final cat in cats) {
      final catId   = cat['category_id']?.toString() ?? '';
      final catName = cat['category_name'] as String? ?? 'Movies';
      final channels = await _fetchWithRetry(() async {
        final res = await _dio.get<String>(
            '$_base&action=get_vod_streams&category_id=$catId',
            options: Options(responseType: ResponseType.plain));
        return compute(_parseVodJson, _ParseInput(
            json: res.data ?? '[]', catMap: {catId: catName},
            host: host, username: username, password: password));
      });
      result.addAll(channels);
    }
    return result;
  }

  // ── Series ────────────────────────────────────────────────────────────────

  Future<List<Channel>> getSeriesChannels() async {
    try {
      final catRes = await _dio.get<dynamic>('$_base&action=get_series_categories');
      final categories = _asList(catRes.data);
      final catMap = _buildCatMap(categories);

      final streamsRes = await _dio.get<String>('$_base&action=get_series',
          options: Options(responseType: ResponseType.plain));
      final streamsJson = streamsRes.data ?? '[]';

      if (streamsJson.trim() == '[]' || streamsJson.trim() == 'null' || streamsJson.isEmpty) {
        debugPrint('[Xtream] bulk series empty — fetching per category');
        return _seriesPerCategory(categories, catMap);
      }

      final (channels, foundCatIds) = await compute(_parseSeriesJsonFull,
          _ParseInput(json: streamsJson, catMap: catMap, host: host, username: username, password: password));
      debugPrint('[Xtream] series bulk: ${channels.length} shows, ${foundCatIds.length}/${catMap.length} categories');

      final missingCats = categories.where((cat) {
        final id = cat['category_id']?.toString() ?? '';
        return id.isNotEmpty && !foundCatIds.contains(id);
      }).toList();
      if (missingCats.isNotEmpty) {
        debugPrint('[Xtream] series: ${missingCats.length} categories missing from bulk — fetching individually');
        final extra = await _seriesPerCategory(missingCats, catMap);
        return [...channels, ...extra];
      }
      return channels;
    } catch (e) {
      debugPrint('[Xtream] getSeriesChannels error: $e');
      return [];
    }
  }

  Future<List<Channel>> _seriesPerCategory(
      List<Map<String, dynamic>> cats, Map<String, String> catMap) async {
    final result = <Channel>[];
    for (final cat in cats) {
      final catId   = cat['category_id']?.toString() ?? '';
      final catName = cat['category_name'] as String? ?? 'Series';
      final channels = await _fetchWithRetry(() async {
        final res = await _dio.get<String>(
            '$_base&action=get_series&category_id=$catId',
            options: Options(responseType: ResponseType.plain));
        return compute(_parseSeriesJson, _ParseInput(
            json: res.data ?? '[]', catMap: {catId: catName},
            host: host, username: username, password: password));
      });
      result.addAll(channels);
    }
    return result;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Retries once on failure — handles transient connection issues.
  Future<List<Channel>> _fetchWithRetry(Future<List<Channel>> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      await Future.delayed(const Duration(seconds: 2));
      try { return await fn(); } catch (_) { return []; }
    }
  }

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
