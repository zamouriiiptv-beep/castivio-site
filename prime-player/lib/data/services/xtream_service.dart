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
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(minutes: 2),
      validateStatus: (_) => true,
    ));
  }

  String get _base => 'player_api.php?username=$username&password=$password';

  Future<bool> authenticate() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$_base&action=get_live_categories',
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches all live channels from Xtream API (background isolate).
  Future<List<Channel>> getLiveChannels() async {
    // 1. Get categories
    final catRes = await _dio.get<List>('$_base&action=get_live_categories');
    final categories = (catRes.data ?? []).cast<Map<String, dynamic>>();

    // 2. Get streams for each category in parallel
    final futures = categories.map((cat) async {
      final catId = cat['category_id'];
      try {
        final res = await _dio.get<List>(
          '$_base&action=get_live_streams&category_id=$catId',
        );
        return (res.data ?? []).cast<Map<String, dynamic>>()
            .map((s) => _mapStream(s, cat['category_name'] as String?))
            .toList();
      } catch (_) {
        return <Channel>[];
      }
    });

    final results  = await Future.wait(futures);
    return results.expand((c) => c).toList();
  }

  Channel _mapStream(Map<String, dynamic> s, String? groupTitle) {
    final streamId = s['stream_id']?.toString() ?? '';
    // Build direct stream URL — container_extension gives .ts / .m3u8
    final ext = s['container_extension'] ?? 'ts';
    final url = '$host/live/$username/$password/$streamId.$ext';

    return Channel(
      id:         _uuid.v4(),
      name:       (s['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl:  url,
      logoUrl:    s['stream_icon'] as String?,
      groupTitle: groupTitle ?? 'Live TV',
      tvgId:      s['epg_channel_id'] as String?,
    );
  }

  /// Generates an M3U for direct use by the player (fallback mode)
  String buildM3uUrl() =>
      '$host/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
}
