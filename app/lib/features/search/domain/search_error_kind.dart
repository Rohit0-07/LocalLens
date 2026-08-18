import '../../../core/network/api_exceptions.dart';

/// Classifies a thrown search error into a UI-facing kind so the screen can
/// render a distinct, actionable empty state per failure mode.
enum SearchErrorKind {
  /// Could not reach the server at all (offline, DNS, refused connection).
  network,

  /// The server rate-limited the request (HTTP 429).
  rateLimited,

  /// The server rejected the query as invalid (HTTP 422).
  invalidQuery,

  /// The server failed while processing the request (HTTP 5xx / other).
  server,

  /// The session is no longer valid (HTTP 401).
  unauthorized,

  /// Anything else: parse failures, unexpected exceptions.
  unexpected,
}

/// Maps an arbitrary thrown [error] to a [SearchErrorKind].
///
/// Pure and code-blind: unit tests can drive it directly with typed
/// exceptions. Note the ordering — `ApiUnauthorizedException` extends
/// `ApiServerException`, so it must be checked before the server branch.
SearchErrorKind classifySearchError(Object error) {
  if (error is ApiNetworkException) return SearchErrorKind.network;
  if (error is ApiUnauthorizedException) return SearchErrorKind.unauthorized;
  if (error is ApiServerException) {
    return switch (error.statusCode) {
      429 => SearchErrorKind.rateLimited,
      422 => SearchErrorKind.invalidQuery,
      _ => SearchErrorKind.server,
    };
  }
  return SearchErrorKind.unexpected;
}
