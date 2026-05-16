import 'package:dio/dio.dart';
import 'doh_resolver.dart';

/// Dio interceptor that transparently resolves hostnames via Cloudflare DoH
/// for plain HTTP connections (most IPTV Xtream servers use HTTP).
///
/// For HTTPS: skipped — SSL certificate verification requires the original
/// hostname, so we leave HTTPS requests untouched (HTTPS is already harder
/// to block at the DNS level because of SNI encryption in TLS 1.3).
///
/// Failure is always silent — if DoH resolution fails the request proceeds
/// normally using the device's system DNS.
class DohInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final uri = options.uri;
      if (uri.scheme == 'http') {
        final originalHost = uri.host;
        final ip = await DohResolver.resolve(originalHost);
        if (ip != null && ip != originalHost) {
          // Replace hostname with IP in the full URL.
          // When options.path starts with 'http', Dio uses it as the
          // complete URL instead of combining it with baseUrl.
          options.path = uri.replace(host: ip).toString();
          // The Host header tells the server its original hostname
          // (required for virtual hosting / name-based routing).
          options.headers['Host'] = originalHost;
        }
      }
    } catch (_) {
      // Never block a request due to DoH failure
    }
    handler.next(options);
  }
}
