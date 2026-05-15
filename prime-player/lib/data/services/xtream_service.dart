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
      groupTitle: p.catMap[catId] ?? 'Live TV',
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
      groupTitle: p.catMap[catId] ?? 'Movies',
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
      groupTitle: p.catMap[catId] ?? 'Series',
    ));
  }
  return result;
}

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
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 5),
      validateStatus: (_) => true,
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

  /// Fetches ALL channels (live + VOD + series) in parallel.
  Future<List<Channel>> getAllChannels() async {
    final results = await Future.wait([
      getLiveChannels(),
      getVodChannels(),
      getSeriesChannels(),
    ]);
    return results.expand((c) => c).toList();
  }

  // ── Live ──────────────────────────────────────────────────────────────────

  Future<List<Channel>> getLiveChannels() async {
    try {
      // Fetch streams (plain text — skip Dio JSON parsing) + categories in parallel
      final responses = await Future.wait([
        _dio.get<String>('$_base&action=get_live_streams',
            options: Options(responseType: ResponseType.plain)),
        _dio.get<dynamic>('$_base&action=get_live_categories'),
      ]);

      final streamsJson = responses[0].data ?? '[]';
      final categories  = _asList(responses[1].data);

      if (streamsJson.trim() == '[]' || streamsJson.trim() == 'null' || streamsJson.isEmpty) {
        debugPrint('[Xtream] bulk live empty — falling back to per-category');
        return _livePerCategory(categories);
      }

      final catMap = _buildCatMap(categories);
      // Parse + build Channel objects in background isolate
      final channels = await compute(_parseLiveJson,
          _ParseInput(json: streamsJson, catMap: catMap, host: host, username: username, password: password));
      debugPrint('[Xtream] live: ${channels.length}');
      return channels;
    } catch (e) {
      debugPrint('[Xtream] getLiveChannels error: $e');
      return [];
    }
  }

  Future<List<Channel>> _livePerCategory(List<Map<String, dynamic>> cats) async {
    final result = <Channel>[];
    for (final chunk in _chunked(cats, 10)) {
      final lists = await Future.wait(chunk.map((cat) async {
        try {
          final res = await _dio.get<String>(
              '$_base&action=get_live_streams&category_id=${cat['category_id']}',
              options: Options(responseType: ResponseType.plain));
          final name = cat['category_name'] as String? ?? 'Live TV';
          final catId = cat['category_id']?.toString() ?? '';
          return compute(_parseLiveJson, _ParseInput(
              json: res.data ?? '[]', catMap: {catId: name},
              host: host, username: username, password: password));
        } catch (_) { return <Channel>[]; }
      }));
      result.addAll((await Future.wait(lists)).expand((c) => c));
    }
    return result;
  }

  // ── VOD ───────────────────────────────────────────────────────────────────

  Future<List<Channel>> getVodChannels() async {
    try {
      final responses = await Future.wait([
        _dio.get<String>('$_base&action=get_vod_streams',
            options: Options(responseType: ResponseType.plain)),
        _dio.get<dynamic>('$_base&action=get_vod_categories'),
      ]);

      final streamsJson = responses[0].data ?? '[]';
      final categories  = _asList(responses[1].data);

      if (streamsJson.trim() == '[]' || streamsJson.trim() == 'null' || streamsJson.isEmpty) {
        debugPrint('[Xtream] bulk VOD empty — falling back to per-category');
        return _vodPerCategory(categories);
      }

      final catMap = _buildCatMap(categories);
      final channels = await compute(_parseVodJson,
          _ParseInput(json: streamsJson, catMap: catMap, host: host, username: username, password: password));
      debugPrint('[Xtream] VOD: ${channels.length}');
      return channels;
    } catch (e) {
      debugPrint('[Xtream] getVodChannels error: $e');
      return [];
    }
  }

  Future<List<Channel>> _vodPerCategory(List<Map<String, dynamic>> cats) async {
    final result = <Channel>[];
    for (final chunk in _chunked(cats, 10)) {
      final lists = await Future.wait(chunk.map((cat) async {
        try {
          final res = await _dio.get<String>(
              '$_base&action=get_vod_streams&category_id=${cat['category_id']}',
              options: Options(responseType: ResponseType.plain));
          final name = cat['category_name'] as String? ?? 'Movies';
          final catId = cat['category_id']?.toString() ?? '';
          return compute(_parseVodJson, _ParseInput(
              json: res.data ?? '[]', catMap: {catId: name},
              host: host, username: username, password: password));
        } catch (_) { return <Channel>[]; }
      }));
      result.addAll((await Future.wait(lists)).expand((c) => c));
    }
    return result;
  }

  // ── Series ────────────────────────────────────────────────────────────────

  Future<List<Channel>> getSeriesChannels() async {
    try {
      final responses = await Future.wait([
        _dio.get<String>('$_base&action=get_series',
            options: Options(responseType: ResponseType.plain)),
        _dio.get<dynamic>('$_base&action=get_series_categories'),
      ]);

      final streamsJson = responses[0].data ?? '[]';
      final categories  = _asList(responses[1].data);

      if (streamsJson.trim() == '[]' || streamsJson.trim() == 'null' || streamsJson.isEmpty) {
        debugPrint('[Xtream] bulk series empty — falling back to per-category');
        return _seriesPerCategory(categories);
      }

      final catMap = _buildCatMap(categories);
      final channels = await compute(_parseSeriesJson,
          _ParseInput(json: streamsJson, catMap: catMap, host: host, username: username, password: password));
      debugPrint('[Xtream] series: ${channels.length}');
      return channels;
    } catch (e) {
      debugPrint('[Xtream] getSeriesChannels error: $e');
      return [];
    }
  }

  Future<List<Channel>> _seriesPerCategory(List<Map<String, dynamic>> cats) async {
    final result = <Channel>[];
    for (final chunk in _chunked(cats, 10)) {
      final lists = await Future.wait(chunk.map((cat) async {
        try {
          final res = await _dio.get<String>(
              '$_base&action=get_series&category_id=${cat['category_id']}',
              options: Options(responseType: ResponseType.plain));
          final name = cat['category_name'] as String? ?? 'Series';
          final catId = cat['category_id']?.toString() ?? '';
          return compute(_parseSeriesJson, _ParseInput(
              json: res.data ?? '[]', catMap: {catId: name},
              host: host, username: username, password: password));
        } catch (_) { return <Channel>[]; }
      }));
      result.addAll((await Future.wait(lists)).expand((c) => c));
    }
    return result;
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

  List<List<T>> _chunked<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return chunks;
  }

  String buildM3uUrl() =>
      '$host/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
}
