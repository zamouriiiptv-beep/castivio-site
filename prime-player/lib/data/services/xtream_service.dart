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
      receiveTimeout: const Duration(minutes: 2),
      validateStatus: (_) => true,
    ));
  }

  String get _base => 'player_api.php?username=$username&password=$password';

  /// Returns null on success, or a human-readable error string on failure.
  Future<String?> authenticate() async {
    try {
      debugPrint('[Xtream] authenticate → GET $host/$_base&action=get_live_categories');
      final res = await _dio.get<dynamic>(
        '$_base&action=get_live_categories',
      );

      final status = res.statusCode ?? 0;
      debugPrint('[Xtream] auth status: $status');
      debugPrint('[Xtream] auth data type: ${res.data?.runtimeType}');

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
      // Some servers return 200 with an auth=0 field when credentials are wrong
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

  /// Fetches ALL channels: live + VOD movies + series.
  Future<List<Channel>> getAllChannels() async {
    final results = await Future.wait([
      getLiveChannels(),
      getVodChannels(),
      getSeriesChannels(),
    ]);
    return results.expand((c) => c).toList();
  }

  /// Fetches live channels from Xtream API.
  Future<List<Channel>> getLiveChannels() async {
    try {
      final catRes = await _dio.get<dynamic>('$_base&action=get_live_categories');
      final categories = _asList(catRes.data);

      final futures = categories.map((cat) async {
        final catId = cat['category_id'];
        try {
          final res = await _dio.get<dynamic>(
            '$_base&action=get_live_streams&category_id=$catId',
          );
          return _asList(res.data)
              .map((s) => _mapStream(s, cat['category_name'] as String?, 'live'))
              .toList();
        } catch (_) {
          return <Channel>[];
        }
      });

      final all = await Future.wait(futures);
      return all.expand((c) => c).toList();
    } catch (e) {
      debugPrint('[Xtream] getLiveChannels error: $e');
      return [];
    }
  }

  /// Fetches VOD (movies) channels from Xtream API.
  Future<List<Channel>> getVodChannels() async {
    try {
      final catRes = await _dio.get<dynamic>('$_base&action=get_vod_categories');
      final categories = _asList(catRes.data);

      final futures = categories.map((cat) async {
        final catId = cat['category_id'];
        try {
          final res = await _dio.get<dynamic>(
            '$_base&action=get_vod_streams&category_id=$catId',
          );
          return _asList(res.data)
              .map((s) => _mapVod(s, cat['category_name'] as String?))
              .toList();
        } catch (_) {
          return <Channel>[];
        }
      });

      final all = await Future.wait(futures);
      return all.expand((c) => c).toList();
    } catch (e) {
      debugPrint('[Xtream] getVodChannels error: $e');
      return [];
    }
  }

  /// Fetches series from Xtream API.
  Future<List<Channel>> getSeriesChannels() async {
    try {
      final catRes = await _dio.get<dynamic>('$_base&action=get_series_categories');
      final categories = _asList(catRes.data);

      final futures = categories.map((cat) async {
        final catId = cat['category_id'];
        try {
          final res = await _dio.get<dynamic>(
            '$_base&action=get_series&category_id=$catId',
          );
          return _asList(res.data)
              .map((s) => _mapSeries(s, cat['category_name'] as String?))
              .toList();
        } catch (_) {
          return <Channel>[];
        }
      });

      final all = await Future.wait(futures);
      return all.expand((c) => c).toList();
    } catch (e) {
      debugPrint('[Xtream] getSeriesChannels error: $e');
      return [];
    }
  }

  Channel _mapStream(Map<String, dynamic> s, String? groupTitle, String type) {
    final streamId = s['stream_id']?.toString() ?? '';
    final ext      = s['container_extension'] ?? 'ts';
    final url      = '$host/live/$username/$password/$streamId.$ext';
    return Channel(
      id:         _uuid.v4(),
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  url,
      logoUrl:    s['stream_icon'] as String?,
      groupTitle: groupTitle ?? 'Live TV',
      tvgId:      s['epg_channel_id'] as String?,
    );
  }

  Channel _mapVod(Map<String, dynamic> s, String? groupTitle) {
    final streamId = s['stream_id']?.toString() ?? '';
    final ext      = s['container_extension'] ?? 'mp4';
    final url      = '$host/movie/$username/$password/$streamId.$ext';
    return Channel(
      id:         _uuid.v4(),
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  url,
      logoUrl:    s['stream_icon'] as String?,
      groupTitle: groupTitle ?? 'Movies',
      tvgId:      null,
    );
  }

  Channel _mapSeries(Map<String, dynamic> s, String? groupTitle) {
    final seriesId = s['series_id']?.toString() ?? '';
    final url = '$host/series/$username/$password/$seriesId';
    return Channel(
      id:         _uuid.v4(),
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  url,
      logoUrl:    s['cover'] as String?,
      groupTitle: groupTitle ?? 'Series',
      tvgId:      null,
    );
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  /// Generates an M3U URL for direct use.
  String buildM3uUrl() =>
      '$host/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
}
