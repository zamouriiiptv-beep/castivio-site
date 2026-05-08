import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/channel.dart';

/// Diagnostic info captured during a fetch attempt — useful for debugging.
class M3uDiagnostic {
  final String url;
  final String userAgent;
  final int? statusCode;
  final int? contentLength;
  final String? contentType;
  final int bodyBytes;
  final String? bodyPreview;
  final String? error;

  const M3uDiagnostic({
    required this.url,
    required this.userAgent,
    this.statusCode,
    this.contentLength,
    this.contentType,
    required this.bodyBytes,
    this.bodyPreview,
    this.error,
  });

  @override
  String toString() => [
        '━━━ M3U Diagnostic ━━━',
        'URL        : $url',
        'User-Agent : $userAgent',
        'Status     : ${statusCode ?? "—"}',
        'Content-Len: ${contentLength ?? "—"}',
        'Content-Type: ${contentType ?? "—"}',
        'Body bytes : $bodyBytes',
        if (bodyPreview != null) 'Body preview:\n$bodyPreview',
        if (error != null) 'Error: $error',
        '━━━━━━━━━━━━━━━━━━━━━━',
      ].join('\n');
}

/// Parses M3U playlists in a background Isolate so the UI never freezes,
/// even with 30,000+ channels.
class M3uParser {
  /// All diagnostics captured in the last call to [fromUrl].
  static final List<M3uDiagnostic> lastDiagnostics = [];

  static const _strategies = [
    // (User-Agent, Connection header)
    ('VLC/3.0.18 LibVLC/3.0.18',   'close'),
    ('Kodi/19.4 (Linux; Android)',  'keep-alive'),
    ('okhttp/4.9.0',               'close'),
    ('Mozilla/5.0 (Linux; Android) AppleWebKit/537.36', 'keep-alive'),
  ];

  /// Downloads and parses an M3U URL.
  /// Retries with different strategies and logs everything.
  static Future<List<Channel>> fromUrl(String url) async {
    lastDiagnostics.clear();

    // Validate and normalise URL before anything else
    final Uri uri;
    try {
      uri = Uri.parse(url.trim());
      if (!uri.hasScheme || uri.host.isEmpty) {
        throw Exception('Invalid URL — must start with http:// or https://');
      }
    } catch (_) {
      throw Exception('Invalid URL format: "$url"');
    }

    debugPrint('[M3U] ===== Starting playlist fetch =====');
    debugPrint('[M3U] Full URL   : $uri');
    debugPrint('[M3U] Scheme     : ${uri.scheme}');
    debugPrint('[M3U] Host       : ${uri.host}');
    debugPrint('[M3U] Port       : ${uri.port}');
    debugPrint('[M3U] Path       : ${uri.path}');
    debugPrint('[M3U] Query      : ${uri.query}');

    Exception? lastError;

    for (int i = 0; i < _strategies.length; i++) {
      final (userAgent, connection) = _strategies[i];
      debugPrint('[M3U] ── Attempt ${i + 1}/${_strategies.length} ──');
      debugPrint('[M3U] User-Agent : $userAgent');
      debugPrint('[M3U] Connection : $connection');

      if (i > 0) await Future.delayed(const Duration(seconds: 2));

      final diag = await _tryFetch(uri, userAgent, connection);
      lastDiagnostics.add(diag);
      debugPrint(diag.toString());

      if (diag.error == null) {
        // Success — parse and return
        return compute(_parseM3u, diag.bodyPreview!); // bodyPreview holds full content here
      }

      lastError = Exception(diag.error);

      // Don't retry on permanent failures
      final msg = diag.error!;
      if (msg.contains('Invalid URL') ||
          msg.contains('SSL error') ||
          msg.contains('Not a valid M3U')) {
        break;
      }
    }

    // Build detailed error message from last diagnostic
    final d = lastDiagnostics.last;
    final statusInfo = d.statusCode != null ? 'HTTP ${d.statusCode}' : 'no response';
    final bodyInfo   = d.bodyBytes == 0
        ? 'Response body: EMPTY (0 bytes)'
        : 'Body: ${d.bodyBytes} bytes';

    throw Exception(
        '${lastError?.toString().replaceFirst('Exception: ', '') ?? 'Unknown error'}\n\n'
        '[$statusInfo] $bodyInfo\n'
        'URL: ${d.url}');
  }

  /// Single fetch attempt. Returns a [M3uDiagnostic] with either
  /// content in [bodyPreview] (on success) or [error] (on failure).
  static Future<M3uDiagnostic> _tryFetch(
      Uri uri, String userAgent, String connection) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    client.badCertificateCallback = (cert, host, port) {
      debugPrint('[M3U] SSL cert rejected for $host:$port — allowing anyway');
      return true;
    };

    int? statusCode;
    int? contentLength;
    String? contentType;
    int bodyBytes = 0;

    try {
      final request = await client.getUrl(uri)
          .timeout(const Duration(seconds: 30));

      request.headers.set('User-Agent',   userAgent);
      request.headers.set('Accept',       '*/*');
      request.headers.set('Connection',   connection);

      debugPrint('[M3U] Sending request...');
      final response = await request.close()
          .timeout(const Duration(seconds: 30));

      statusCode    = response.statusCode;
      contentLength = response.contentLength;
      contentType   = response.headers.contentType?.toString();

      debugPrint('[M3U] Status code  : $statusCode');
      debugPrint('[M3U] Content-Len  : $contentLength');
      debugPrint('[M3U] Content-Type : $contentType');
      debugPrint('[M3U] Server       : ${response.headers.value('server') ?? '—'}');

      final builder = BytesBuilder();
      await response.forEach((chunk) {
        builder.add(chunk);
        debugPrint('[M3U] Received chunk: ${chunk.length} bytes (total: ${builder.length})');
      }).timeout(const Duration(minutes: 5));

      final bytes   = builder.takeBytes();
      bodyBytes     = bytes.length;

      debugPrint('[M3U] Total body size: $bodyBytes bytes');

      if (bytes.isEmpty) {
        String hint = '';
        if (statusCode == 885) {
          hint = '\nHTTP 885 = Xtream Codes "max connections" error. '
                 'Close other IPTV apps and retry, or use the Xtream Codes tab.';
        } else if (statusCode == 401 || statusCode == 403) {
          hint = '\nCredentials rejected by server.';
        }

        return M3uDiagnostic(
          url: uri.toString(), userAgent: userAgent,
          statusCode: statusCode, contentLength: contentLength,
          contentType: contentType, bodyBytes: 0,
          error: 'Server returned empty body (HTTP $statusCode).$hint',
        );
      }

      final content = utf8.decode(bytes, allowMalformed: true);
      final preview = content.substring(0, content.length.clamp(0, 300));
      debugPrint('[M3U] Body preview:\n$preview');

      if (!content.contains('#EXTM3U') && !content.contains('#EXTINF')) {
        return M3uDiagnostic(
          url: uri.toString(), userAgent: userAgent,
          statusCode: statusCode, contentLength: contentLength,
          contentType: contentType, bodyBytes: bodyBytes,
          bodyPreview: preview,
          error: 'Not a valid M3U playlist. Server replied:\n$preview',
        );
      }

      // ✅ Success — store full content in bodyPreview for caller to parse
      return M3uDiagnostic(
        url: uri.toString(), userAgent: userAgent,
        statusCode: statusCode, contentLength: contentLength,
        contentType: contentType, bodyBytes: bodyBytes,
        bodyPreview: content, // full content for parsing
      );
    } on SocketException catch (e) {
      debugPrint('[M3U] SocketException: ${e.message}');
      final msg = e.message.contains('host lookup') || e.message.contains('No address')
          ? 'DNS error — cannot resolve "${uri.host}". Check your internet connection.'
          : 'Network error: ${e.message}';
      return M3uDiagnostic(
          url: uri.toString(), userAgent: userAgent,
          statusCode: statusCode, bodyBytes: bodyBytes, error: msg);
    } on TimeoutException catch (e) {
      debugPrint('[M3U] TimeoutException: $e');
      return M3uDiagnostic(
          url: uri.toString(), userAgent: userAgent,
          statusCode: statusCode, bodyBytes: bodyBytes,
          error: 'Connection timed out. Server took too long to respond.');
    } on HandshakeException catch (e) {
      debugPrint('[M3U] HandshakeException: $e');
      return M3uDiagnostic(
          url: uri.toString(), userAgent: userAgent,
          statusCode: statusCode, bodyBytes: bodyBytes,
          error: 'SSL error — try http:// instead of https://');
    } catch (e) {
      debugPrint('[M3U] Unexpected error: $e');
      return M3uDiagnostic(
          url: uri.toString(), userAgent: userAgent,
          statusCode: statusCode, bodyBytes: bodyBytes,
          error: 'Unexpected error: $e');
    } finally {
      client.close();
    }
  }

  /// Parses raw M3U text. Runs in a background isolate via [compute].
  static List<Channel> _parseM3u(String content) {
    final channels = <Channel>[];
    final uuid    = const Uuid();
    final lines   = content.split('\n');

    String? name, logoUrl, groupTitle, tvgId, tvgName, language, country;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        tvgId      = _attr(line, 'tvg-id');
        tvgName    = _attr(line, 'tvg-name');
        logoUrl    = _attr(line, 'tvg-logo');
        groupTitle = _attr(line, 'group-title');
        language   = _attr(line, 'tvg-language');
        country    = _attr(line, 'tvg-country');

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
        name = logoUrl = groupTitle = tvgId = tvgName = language = country = null;
      }
    }
    return channels;
  }

  /// Handles both double-quoted and single-quoted attribute values.
  static String? _attr(String line, String key) {
    final rDouble = RegExp('$key="([^"]*)"');
    final mDouble = rDouble.firstMatch(line);
    final vDouble = mDouble?.group(1)?.trim();
    if (vDouble != null && vDouble.isNotEmpty) return vDouble;

    final rSingle = RegExp("$key='([^']*)'");
    final mSingle = rSingle.firstMatch(line);
    final vSingle = mSingle?.group(1)?.trim();
    return (vSingle == null || vSingle.isEmpty) ? null : vSingle;
  }

  /// Detects if a URL is an Xtream Codes export URL and extracts credentials.
  /// Returns {'host', 'username', 'password'} or null.
  static Map<String, String>? extractXtreamCredentials(String url) {
    try {
      final uri = Uri.parse(url.trim());
      final q   = uri.queryParameters;
      if (q.containsKey('username') && q.containsKey('password')) {
        final host = '${uri.scheme}://${uri.host}'
            '${(uri.port != 80 && uri.port != 443) ? ":${uri.port}" : ""}';
        return {
          'host':     host,
          'username': q['username']!,
          'password': q['password']!,
        };
      }
    } catch (_) {}
    return null;
  }
}
