/// Exception thrown when Platform returns a localized error message that should be displayed as-is.
class PlatformLocalizedException implements Exception {
  final String _code;
  final String _message;

  const PlatformLocalizedException(this._code, this._message);

  String get code => _code;

  @override
  String toString() => _message;
}

/// Exception thrown when the user's token is invalid and the user needs to login again.
class PlatformInvalidTokenException implements Exception {
  const PlatformInvalidTokenException();

  @override
  String toString() => 'PlatformInvalidTokenException';
}

/// Exception thrown when the operation requires the user to log in with their business credentials.
class PlatformBusinessLoginRequiredException extends PlatformLocalizedException {
  final String _connection;

  const PlatformBusinessLoginRequiredException(
    String code,
    String message,
    this._connection,
  ) : super(code, message);

  /// The name of the required Auth0 enterprise connection.
  String get connection => _connection;
}

/// Exception thrown when something went wrong but we don't have a localized error message from Platform (e.g. Platform
/// was unreachable).
class PlatformUnknownException implements Exception {
  final String _message;

  const PlatformUnknownException(this._message);

  @override
  String toString() => _message;
}
