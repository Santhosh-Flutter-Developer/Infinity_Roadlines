/// Base class for all login/auth failures. Carries a user-friendly
/// [message] so the UI never has to guess or parse "Exception: ..." text.
abstract class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Username/password (or device_id) rejected by the server (HTTP 401/403,
/// or status:false with a credentials-related message).
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException([
    super.message = 'Invalid username or password.',
  ]);
}

/// Server explicitly rejected the device (e.g. device not registered /
/// device mismatch / too many devices).
class DeviceNotAuthorizedException extends AuthException {
  const DeviceNotAuthorizedException([
    super.message = 'This device is not authorized for this account.',
  ]);
}

/// No internet connection, DNS failure, or the request timed out.
class NetworkException extends AuthException {
  const NetworkException([
    super.message = 'Please check your internet connection and try again.',
  ]);
}

/// Request reached the server but it responded with an error status
/// (5xx) or an unexpected/unparseable payload.
class ServerException extends AuthException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode});
}

/// Catch-all for anything that doesn't fit the above.
class UnknownAuthException extends AuthException {
  const UnknownAuthException([super.message = 'Something went wrong. Please try again.']);
}