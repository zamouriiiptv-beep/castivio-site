import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Resolves hostnames via Cloudflare DNS-over-HTTPS (1.1.1.1).
///
/// Why: ISPs can block IPTV servers by poisoning their DNS responses.
/// DoH sends the DNS query encrypted over HTTPS to Cloudflare, bypassing
/// the ISP's resolver entirely. The ISP sees only an HTTPS request to
/// cloudflare-dns.com — it cannot read or tamper with it.
class DohResolver {
  static const _dohEndpoint = 'https://cloudflare-dns.com/dns-query';

  // In-memory cache: hostname → resolved entry
  static final _cache = <String, _DnsEntry>{};

  /// Returns the resolved IP for [hostname], or null on failure.
  /// Results are cached for their TTL (min 60s, max 5min).
  static Future<String?> resolve(String hostname) async {
    // Skip if already an IP address
    if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(hostname)) return null;

    final cached = _cache[hostname];
    if (cached != null && !cached.isExpired) return cached.ip;

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5)
        ..badCertificateCallback = (_, __, ___) => false; // strict TLS for DoH

      final uri = Uri.parse(
          '$_dohEndpoint?name=${Uri.encodeComponent(hostname)}&type=A');
      final req = await client.getUrl(uri);
      req.headers
        ..set('Accept', 'application/dns-json')
        ..set('User-Agent', 'PrimePlayer/1.0');

      final res  = await req.close().timeout(const Duration(seconds: 5));
      final body = await res.transform(utf8.decoder).join();
      client.close();

      if (res.statusCode != 200) return null;

      final json    = jsonDecode(body) as Map<String, dynamic>;
      final answers = json['Answer'] as List<dynamic>? ?? [];

      for (final a in answers.cast<Map<String, dynamic>>()) {
        if (a['type'] == 1) {                     // A record
          final ip  = a['data'] as String?;
          final ttl = (a['TTL']  as int? ?? 300).clamp(60, 300);
          if (ip != null && ip.isNotEmpty) {
            _cache[hostname] =
                _DnsEntry(ip, DateTime.now().add(Duration(seconds: ttl)));
            debugPrint('[DoH] $hostname → $ip (TTL ${ttl}s)');
            return ip;
          }
        }
      }
    } catch (e) {
      debugPrint('[DoH] resolve($hostname) failed: $e');
    }
    return null;
  }

  static void clearCache() => _cache.clear();
}

class _DnsEntry {
  final String   ip;
  final DateTime expiry;
  const _DnsEntry(this.ip, this.expiry);
  bool get isExpired => DateTime.now().isAfter(expiry);
}
