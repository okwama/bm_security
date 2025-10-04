class ServerException implements Exception {
  final String message;
  final int? code;

  const ServerException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'ServerException: $message (Code: $code)';
}

class NetworkException implements Exception {
  final String message;
  final int? code;

  const NetworkException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'NetworkException: $message (Code: $code)';
}

class CacheException implements Exception {
  final String message;
  final int? code;

  const CacheException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'CacheException: $message (Code: $code)';
}

class ValidationException implements Exception {
  final String message;
  final int? code;

  const ValidationException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'ValidationException: $message (Code: $code)';
}

class AuthenticationException implements Exception {
  final String message;
  final int? code;

  const AuthenticationException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AuthenticationException: $message (Code: $code)';
}

class PermissionException implements Exception {
  final String message;
  final int? code;

  const PermissionException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'PermissionException: $message (Code: $code)';
}

class LocationException implements Exception {
  final String message;
  final int? code;

  const LocationException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'LocationException: $message (Code: $code)';
}
