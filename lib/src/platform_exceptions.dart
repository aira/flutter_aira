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

/// Exception thrown when something went wrong but we don't have a localized error message from Platform (e.g. Platform
/// was unreachable).
class PlatformUnknownException implements Exception {
  final String _message;

  const PlatformUnknownException(this._message);

  @override
  String toString() => _message;
}
