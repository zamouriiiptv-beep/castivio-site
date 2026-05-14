import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/channel.dart';

/// Fetches channels from an Xtream Codes API endpoint.
class XtreamService {
  final String host;
  final String username;
  final String password;

  late final Dio _dio;
  static const _uuid = Uuid();

  XtreamService({
    required this.host,
    required this.username,
    required this.password,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: host.endsWith('/') ? host : '$host/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 5), // large playlists need more time
      validateStatus: (_) => true,
    ));
  }

  String get _base => 'player_api.php?username=$username&password=$password';

  /// Returns null on success, or a human-readable error string on failure.
  Future<String?> authenticate() async {
    try {
      debugPrint('[Xtream] authenticate → GET $host/$_base&action=get_live_categories');
      final res = await _dio.get<dynamic>('$_base&action=get_live_categories');

      final status = res.statusCode ?? 0;
      debugPrint('[Xtream] auth status: $status');

      if (status == 884) {
        return 'Account not found or disabled (HTTP 884).\n'
            'Check the credentials on your server panel.';
      }
      if (status == 885) {
        return 'Max connections reached (HTTP 885).\n'
            'Close other IPTV apps and try again.';
      }
      if (status == 401 || status == 403) {
        return 'Access denied (HTTP $status). Wrong username or password.';
      }
      if (status != 200) {
        return 'Server error (HTTP $status).';
      }

      final data = res.data;
      if (data is Map) {
        final userInfo = data['user_info'] as Map?;
        final auth     = userInfo?['auth'];
        if (auth != null && auth.toString() == '0') {
          final msg = userInfo?['message']?.toString() ?? 'Authentication failed';
          return 'Server rejected credentials: $msg';
        }
      }

      return null; // success
    } on DioException catch (e) {
      debugPrint('[Xtream] DioException: $e');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Server is not responding.';
      }
      return 'Network error: ${e.message}';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  /// Fetches ALL channels: live + VOD + series — all in parallel.
  Future<List<Channel>> getAllChannels() async {
    final results = await Future.wait([
      getLiveChannels(),
      getVodChannels(),
      getSeriesChannels(),
    ]);
    return results.expand((c) => c).toList();
  }

  /// Fetches ALL live channels in 2 parallel requests (bulk endpoint — no per-category loop).
  Future<List<Channel>> getLiveChannels() async {
    try {
      // Fetch all streams + all categories at the same time
      final responses = await Future.wait([
        _dio.get<dynamic>('$_base&action=get_live_streams'),
        _dio.get<dynamic>('$_base&action=get_live_categories'),
      ]);

      final streams    = _asList(responses[0].data);
      final categories = _asList(responses[1].data);
      final catMap     = _buildCatMap(categories);

      debugPrint('[Xtream] live streams: ${streams.length}');

      return streams.map((s) {
        final catId = s['category_id']?.toString();
        return _mapStream(s, catMap[catId] ?? 'Live TV');
      }).toList();
    } catch (e) {
      debugPrint('[Xtream] getLiveChannels error: $e');
      return [];
    }
  }

  /// Fetches ALL VOD movies in 2 parallel requests.
  Future<List<Channel>> getVodChannels() async {
    try {
      final responses = await Future.wait([
        _dio.get<dynamic>('$_base&action=get_vod_streams'),
        _dio.get<dynamic>('$_base&action=get_vod_categories'),
      ]);

      final streams    = _asList(responses[0].data);
      final categories = _asList(responses[1].data);
      final catMap     = _buildCatMap(categories);

      debugPrint('[Xtream] VOD streams: ${streams.length}');

      return streams.map((s) {
        final catId = s['category_id']?.toString();
        return _mapVod(s, catMap[catId] ?? 'Movies');
      }).toList();
    } catch (e) {
      debugPrint('[Xtream] getVodChannels error: $e');
      return [];
    }
  }

  /// Fetches ALL series in 2 parallel requests.
  Future<List<Channel>> getSeriesChannels() async {
    try {
      final responses = await Future.wait([
        _dio.get<dynamic>('$_base&action=get_series'),
        _dio.get<dynamic>('$_base&action=get_series_categories'),
      ]);

      final streams    = _asList(responses[0].data);
      final categories = _asList(responses[1].data);
      final catMap     = _buildCatMap(categories);

      debugPrint('[Xtream] series: ${streams.length}');

      return streams.map((s) {
        final catId = s['category_id']?.toString();
        return _mapSeries(s, catMap[catId] ?? 'Series');
      }).toList();
    } catch (e) {
      debugPrint('[Xtream] getSeriesChannels error: $e');
      return [];
    }
  }

  /// Builds a category_id → category_name lookup map.
  Map<String, String> _buildCatMap(List<Map<String, dynamic>> categories) {
    final map = <String, String>{};
    for (final c in categories) {
      final id   = c['category_id']?.toString();
      final name = c['category_name'] as String?;
      if (id != null && name != null && name.isNotEmpty) map[id] = name;
    }
    return map;
  }

  Channel _mapStream(Map<String, dynamic> s, String groupTitle) {
    final streamId = s['stream_id']?.toString() ?? '';
    final ext      = s['container_extension'] ?? 'ts';
    final url      = '$host/live/$username/$password/$streamId.$ext';
    return Channel(
      id:         _uuid.v4(),
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  url,
      logoUrl:    s['stream_icon'] as String?,
      groupTitle: groupTitle,
      tvgId:      s['epg_channel_id'] as String?,
    );
  }

  Channel _mapVod(Map<String, dynamic> s, String groupTitle) {
    final streamId = s['stream_id']?.toString() ?? '';
    final ext      = s['container_extension'] ?? 'mp4';
    final url      = '$host/movie/$username/$password/$streamId.$ext';
    return Channel(
      id:         _uuid.v4(),
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  url,
      logoUrl:    s['stream_icon'] as String?,
      groupTitle: groupTitle,
      tvgId:      null,
    );
  }

  Channel _mapSeries(Map<String, dynamic> s, String groupTitle) {
    final seriesId = s['series_id']?.toString() ?? '';
    final url = '$host/series/$username/$password/$seriesId';
    return Channel(
      id:         _uuid.v4(),
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  url,
      logoUrl:    s['cover'] as String?,
      groupTitle: groupTitle,
      tvgId:      null,
    );
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  String buildM3uUrl() =>
      '$host/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
}
