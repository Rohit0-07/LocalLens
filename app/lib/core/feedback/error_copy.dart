import '../network/api_exceptions.dart';

/// Maps an exception to a short, user-facing message without leaking
/// internal details (server payloads, URLs, stack traces).
String friendlyErrorMessage(
  Object err, {
  String fallback = 'Something went wrong',
}) {
  final lower = err.toString().toLowerCase();
  if (err is ApiUnauthorizedException) {
    return 'Your session has expired. Please sign in again';
  }
  if (err is ApiNetworkException) {
    return 'Check your connection and try again';
  }
  if (err is ApiServerException) {
    final code = err.code.toLowerCase();
    if (code.contains('rate') ||
        lower.contains('rate') ||
        lower.contains('too many')) {
      return 'Too many requests. Please try again in a moment';
    }
    if (code.contains('proximity') ||
        code.contains('too_far') ||
        lower.contains('proximity') ||
        lower.contains('too far')) {
      return 'You need to be near this location to do that';
    }
    if (code.contains('guest') ||
        lower.contains('guest') ||
        lower.contains('sign in')) {
      return 'Please sign in to continue';
    }
    if (lower.contains('connection') ||
        lower.contains('network') ||
        lower.contains('reach')) {
      return 'Check your connection and try again';
    }
  }
  if (lower.contains('connection') ||
      lower.contains('network') ||
      lower.contains('timeout')) {
    return 'Check your connection and try again';
  }
  return fallback;
}