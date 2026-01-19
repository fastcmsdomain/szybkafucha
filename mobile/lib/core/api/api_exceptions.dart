/// Base class for API exceptions
sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Network error (no connection, timeout, etc.)
class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Brak połączenia z internetem',
    super.statusCode,
    super.data,
  });
}

/// Server error (5xx)
class ServerException extends ApiException {
  const ServerException({
    super.message = 'Błąd serwera. Spróbuj ponownie później.',
    super.statusCode,
    super.data,
  });
}

/// Unauthorized (401)
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Sesja wygasła. Zaloguj się ponownie.',
    super.statusCode = 401,
    super.data,
  });
}

/// Forbidden (403)
class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'Brak uprawnień do wykonania tej operacji.',
    super.statusCode = 403,
    super.data,
  });
}

/// Not found (404)
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'Nie znaleziono zasobu.',
    super.statusCode = 404,
    super.data,
  });
}

/// Validation error (400, 422)
class ValidationException extends ApiException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    super.message = 'Nieprawidłowe dane.',
    super.statusCode = 400,
    super.data,
    this.errors,
  });

  /// Get first error message for a field
  String? getFieldError(String field) {
    return errors?[field]?.firstOrNull;
  }

  /// Get all error messages as a single string
  String get allErrors {
    if (errors == null || errors!.isEmpty) return message;
    return errors!.values.expand((e) => e).join('\n');
  }
}

/// Request cancelled
class CancelledException extends ApiException {
  const CancelledException({
    super.message = 'Żądanie zostało anulowane.',
    super.data,
  });
}

/// Unknown error
class UnknownApiException extends ApiException {
  const UnknownApiException({
    super.message = 'Wystąpił nieoczekiwany błąd.',
    super.statusCode,
    super.data,
  });
}
