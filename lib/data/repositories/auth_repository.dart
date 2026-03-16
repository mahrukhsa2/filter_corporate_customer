import 'package:flutter/cupertino.dart';

import '../../models/registration_model.dart';
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

  static Future<ApiResponse<RegistrationResult>> register(
      RegistrationPayload payload) async {
    final body = payload.toMap();

    debugPrint('[AuthRepository] register → POST ${ApiConstants.register}');
    debugPrint('[AuthRepository] register body: $body');

    final response = await BaseApiService.post(
      ApiConstants.register,
      body,
      requiresAuth: false,
    );

    debugPrint('[AuthRepository] register ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success || response.data == null) {
      debugPrint('[AuthRepository] register FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Registration failed. Please try again.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      debugPrint('[AuthRepository] register raw: ${response.data}');
      final result = RegistrationResult.fromMap(response.data!);
      debugPrint('[AuthRepository] register SUCCESS: ${result.message}');
      return ApiResponse.success(result);
    } catch (e, stack) {
      debugPrint('[AuthRepository] register PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }
}
