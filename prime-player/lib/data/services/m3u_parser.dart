import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/channel.dart';

/// Parses M3U playlists in a background Isolate so the UI never freezes,
/// even with 30,000+ channels.
class M3uParser {
  static const _userAgents = [
    'VLC/3.0.18 LibVLC/3.0.18',
    'Kodi/19.0 (Linux; Android)',
    'Mozilla/5.0 (Linux; Android)',
  ];

  /// Downloads and parses an M3U URL. Retries up to 3 times with different
  /// User-Agents in case the server blocks a specific client.
  static Future<List<Channel>> fromUrl(String url) async {
    Exception? lastError;

    for (int attempt = 0; attempt < _userAgents.length; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 2));
      }
      try {
        final channels = await _tryFetch(url, _userAgents[attempt]);
        return channels;
      } on Exception catch (e) {
        lastError = e;
        // Stop retrying on unrecoverable errors
        final msg = e.toString();
        if (msg.contains('Cannot find server') ||
            msg.contains('SSL error') ||
            msg.contains('Not a valid M3U')) {
          break;
        }
      }
    }

    throw lastError ?? Exception('Failed to load playlist after 3 attempts.');
  }

  static Future<List<Channel>> _tryFetch(String url, String userAgent) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    client.badCertificateCallback = (_, __, ___) => true;

    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', userAgent);
      request.headers.set('Accept', '*/*');
      request.headers.set('Connection', 'close');

      final response = await request.close()
          .timeout(const Duration(seconds: 30));

      final builder = BytesBuilder();
      await response.forEach((chunk) => builder.add(chunk))
          .timeout(const Duration(minutes: 5));
      final bytes = builder.takeBytes();

      if (bytes.isEmpty) {
        final status = response.statusCode;
        if (status == 885 || status == 403 || status == 429) {
          throw Exception(
              'Server busy or max connections reached (HTTP $status).\n'
              'Close other IPTV apps, wait a moment, then try again.');
        }
        throw Exception(
            'Server returned empty response (HTTP $status).\n'
            'Check the URL and try again.');
      }

      final content = utf8.decode(bytes, allowMalformed: true);

      if (!content.contains('#EXTM3U') && !content.contains('#EXTINF')) {
        throw Exception(
            'Not a valid M3U playlist.\n'
            'Server replied:\n${content.substring(0, content.length.clamp(0, 300))}');
      }

      return compute(_parseM3u, content);
    } on SocketException catch (e) {
      if (e.message.contains('host lookup') || e.message.contains('No address')) {
        throw Exception(
            'Cannot find server.\n'
            'Check the URL or your internet connection.');
      }
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception(
          'Connection timed out.\n'
          'The server took too long to respond. Try again later.');
    } on HandshakeException {
      throw Exception(
          'SSL error — try using http:// instead of https://');
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
          name:       name.isEmpty ? (tvgName ?? 'Channel') : name,
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

  /// Matches both double-quoted and single-quoted attribute values.
  static String? _attr(String line, String key) {
    // Try double quotes first: key="value"
    final rDouble = RegExp('$key="([^"]*)"');
    final mDouble = rDouble.firstMatch(line);
    final vDouble = mDouble?.group(1)?.trim();
    if (vDouble != null && vDouble.isNotEmpty) return vDouble;

    // Fall back to single quotes: key='value'
    final rSingle = RegExp("$key='([^']*)'");
    final mSingle = rSingle.firstMatch(line);
    final vSingle = mSingle?.group(1)?.trim();
    return (vSingle == null || vSingle.isEmpty) ? null : vSingle;
  }
}
