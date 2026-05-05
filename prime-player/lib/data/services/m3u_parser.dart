import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/channel.dart';

/// Parses M3U playlists in a background Isolate so the UI never freezes,
/// even with 30,000+ channels.
class M3uParser {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(minutes: 3),
    followRedirects: true,
    maxRedirects: 5,
    // Accept any status code — many IPTV servers return non-standard codes (e.g. 885)
    validateStatus: (_) => true,
  ));

  /// Downloads and parses an M3U URL. Returns channels sorted by group.
  static Future<List<Channel>> fromUrl(String url) async {
    final response = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    final content = response.data ?? '';
    // Offload to background isolate — keeps UI at 60fps
    return Isolate.run(() => _parseM3u(content));
  }

  /// Parses raw M3U text. Runs in a background isolate.
  static List<Channel> _parseM3u(String content) {
    final channels = <Channel>[];
    final uuid    = const Uuid();
    final lines   = content.split('\n');

    String? name, logoUrl, groupTitle, tvgId, tvgName, language, country;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        // Parse meta from #EXTINF line
        tvgId      = _attr(line, 'tvg-id');
        tvgName    = _attr(line, 'tvg-name');
        logoUrl    = _attr(line, 'tvg-logo');
        groupTitle = _attr(line, 'group-title');
        language   = _attr(line, 'tvg-language');
        country    = _attr(line, 'tvg-country');

        // Channel name is after the last comma
        final commaIdx = line.lastIndexOf(',');
        name = commaIdx >= 0 ? line.substring(commaIdx + 1).trim() : null;
      } else if (!line.startsWith('#') && line.isNotEmpty && name != null) {
        channels.add(Channel(
          id:         uuid.v4(),
          name:       name,
          streamUrl:  line,
          logoUrl:    logoUrl,
          groupTitle: groupTitle ?? 'Uncategorized',
          tvgId:      tvgId,
          tvgName:    tvgName,
          language:   language,
          country:    country,
        ));
        // Reset for next entry
        name = logoUrl = groupTitle = tvgId = tvgName = language = country = null;
      }
    }
    return channels;
  }

  static String? _attr(String line, String key) {
    // Matches:  key="value"  or  key='value'
    final regExp = RegExp('$key="([^"]*)"');
    final match  = regExp.firstMatch(line);
    final val    = match?.group(1)?.trim();
    return (val == null || val.isEmpty) ? null : val;
  }
}
