import '../config/app_config.dart';

/// Resolves a possibly-relative media URL (e.g. `/api/v1/media/files/x.jpg`)
/// returned by the backend into a fully-qualified URL usable by `Image.network`.
///
/// The backend stores media paths relative to the API root, so every URL
/// must be absolutized against the API origin before it can be loaded over
/// the network.
String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    final base = AppConfig.dev.apiBaseUrl;
    final uri = Uri.tryParse(base);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      final origin = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
      ).toString();
      return '$origin$trimmed';
    }
    if (base.endsWith('/')) {
      return '${base.substring(0, base.length - 1)}$trimmed';
    }
    return '$base$trimmed';
  }
  return trimmed;
}
