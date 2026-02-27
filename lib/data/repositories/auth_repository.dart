import '../models/auth_response_model.dart';
import '../network/api_constants.dart';
import '../network/api_response.dart';
import '../network/base_api_service.dart';


// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/auth_repository.dart
// All authentication calls live here.
// Uses BaseApiService — no http calls directly.
// ─────────────────────────────────────────────────────────────────────────────

class AuthRepository {

  // ── POST /auth/corporate/login ─────────────────────────────────────────────
  Future<ApiResponse<AuthResponseModel>> login({
    required String email,
    required String password,
  }) async {
    final response = await BaseApiService.post(
      ApiConstants.login,
      {'email': email.trim(), 'password': password},
      requiresAuth: false, // login doesn't need a bearer token
    );

    if (!response.success) {
      return ApiResponse.error(
        response.message ?? 'Login failed. Please try again.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      final model = AuthResponseModel.fromMap(response.data!);

      // The API can return HTTP 200 but still have success: false inside the
      // body (e.g. wrong credentials). Handle that here.
      if (!model.success) {
        return ApiResponse.error(
          model.message ?? 'Invalid email or password.',
          statusCode: response.statusCode,
          errorType:  ApiErrorType.validation,
        );
      }

      return ApiResponse.success(model);
    } catch (_) {
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }
}
