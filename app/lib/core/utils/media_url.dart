import '../config/app_config.dart';

/// Resolves a possibly-relative media URL (e.g. `/api/v1/media/files/x.jpg`)
/// returned by the backend into a fully-qualified URL usable by `Image.network`.
///
/// The backend stores media paths relative to the API root, so every URL
/// must be absolutized against [AppConfig.apiBaseUrl] before it can be
/// loaded over the network.
String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    final base = AppConfig.dev.apiBaseUrl;
    if (base.endsWith('/')) {
      return '${base.substring(0, base.length - 1)}$trimmed';
    }
    return '$base$trimmed';
  }
  return trimmed;
}
