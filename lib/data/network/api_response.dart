// ─────────────────────────────────────────────────────────────────────────────
// lib/data/api_response.dart
// Generic wrapper returned by every BaseApiService call.
// ─────────────────────────────────────────────────────────────────────────────

class ApiResponse<T> {
  final bool    success;
  final T?      data;
  final String? message;
  final int?    statusCode;
  final ApiErrorType errorType;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errorType = ApiErrorType.none,
  });

  factory ApiResponse.success(T data) => ApiResponse(
        success:   true,
        data:      data,
        errorType: ApiErrorType.none,
      );

  factory ApiResponse.error(
    String message, {
    int?         statusCode,
    ApiErrorType errorType = ApiErrorType.unknown,
  }) =>
      ApiResponse(
        success:    false,
        message:    message,
        statusCode: statusCode,
        errorType:  errorType,
      );
}

/// Every distinguishable failure category.
/// Used by [AppAlert] to pick the right icon/title/action.
enum ApiErrorType {
  none,
  noInternet,
  timeout,
  serverError,      // 5xx
  unauthorized,     // 401
  forbidden,        // 403
  notFound,         // 404
  validation,       // 422
  unknown,
}
