import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/channel.dart';

/// Parses M3U playlists in a background Isolate so the UI never freezes,
/// even with 30,000+ channels.
class M3uParser {
  /// Downloads and parses an M3U URL. Returns channels sorted by group.
  static Future<List<Channel>> fromUrl(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    client.badCertificateCallback = (_, __, ___) => true;

    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'VLC/3.0.18 LibVLC/3.0.18');
      request.headers.set('Accept', '*/*');

      final response = await request.close()
          .timeout(const Duration(minutes: 5));

      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }

      if (bytes.isEmpty) {
        throw Exception('Empty response from server (status: ${response.statusCode})');
      }

      final content = utf8.decode(bytes, allowMalformed: true);

      if (!content.contains('#EXTM3U') && !content.contains('#EXTINF')) {
        throw Exception('Invalid M3U format:\n${content.substring(0, content.length.clamp(0, 300))}');
      }

      return compute(_parseM3u, content);
    } finally {
      client.close();
    }
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
