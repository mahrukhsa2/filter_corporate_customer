import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'api_response.dart';
import '../../services/session_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/base_api_service.dart
// Every HTTP call in the app goes through this service.
// Handles auth headers, all error types, and response parsing centrally.
// ─────────────────────────────────────────────────────────────────────────────

class BaseApiService {
  BaseApiService._();

  // ── Headers ───────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({
    bool requiresAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept':       'application/json',
    };
    if (requiresAuth) {
      final token = await SessionService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ── Response parser ────────────────────────────────────────────────────────

  static ApiResponse<Map<String, dynamic>> _parse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return ApiResponse.error(
        'Server returned an unexpected response.',
        statusCode: response.statusCode,
        errorType:  ApiErrorType.unknown,
      );
    }

    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse.success(body);
    }

    final serverMessage =
        body['message']?.toString() ?? body['error']?.toString();

    switch (statusCode) {
      case 400:
        return ApiResponse.error(
          serverMessage ?? 'Bad request. Please check your input.',
          statusCode: statusCode,
          errorType:  ApiErrorType.validation,
        );
      case 401:
        return ApiResponse.error(
          serverMessage ?? 'Session expired. Please log in again.',
          statusCode: statusCode,
          errorType:  ApiErrorType.unauthorized,
        );
      case 403:
        return ApiResponse.error(
          serverMessage ?? 'You don\'t have permission to do this.',
          statusCode: statusCode,
          errorType:  ApiErrorType.forbidden,
        );
      case 404:
        return ApiResponse.error(
          serverMessage ?? 'The requested resource was not found.',
          statusCode: statusCode,
          errorType:  ApiErrorType.notFound,
        );
      case 422:
        return ApiResponse.error(
          serverMessage ?? 'Validation failed. Please check your input.',
          statusCode: statusCode,
          errorType:  ApiErrorType.validation,
        );
      default:
        if (statusCode >= 500) {
          return ApiResponse.error(
            serverMessage ?? 'Server error. Please try again later.',
            statusCode: statusCode,
            errorType:  ApiErrorType.serverError,
          );
        }
        return ApiResponse.error(
          serverMessage ?? 'Something went wrong.',
          statusCode: statusCode,
          errorType:  ApiErrorType.unknown,
        );
    }
  }

  // ── Error mapper ──────────────────────────────────────────────────────────

  static ApiResponse<Map<String, dynamic>> _mapException(Object e) {
    if (e is SocketException || e is OSError) {
      return ApiResponse.error(
        'No internet connection. Please check your network and try again.',
        errorType: ApiErrorType.noInternet,
      );
    }
    if (e is TimeoutException) {
      return ApiResponse.error(
        'The request timed out. Please try again.',
        errorType: ApiErrorType.timeout,
      );
    }
    if (e is HttpException) {
      return ApiResponse.error(
        'A network error occurred. Please try again.',
        errorType: ApiErrorType.unknown,
      );
    }
    if (e is FormatException) {
      return ApiResponse.error(
        'Unexpected server response. Please try again.',
        errorType: ApiErrorType.unknown,
      );
    }
    return ApiResponse.error(
      'Something went wrong. Please try again.',
      errorType: ApiErrorType.unknown,
    );
  }

  // ── HTTP verbs ─────────────────────────────────────────────────────────────

  static Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: await _headers(requiresAuth: requiresAuth),
            body:    jsonEncode(body),
          )
          .timeout(ApiConstants.requestTimeout);
      return _parse(response);
    } catch (e) {
      return _mapException(e);
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http
          .get(uri, headers: await _headers(requiresAuth: requiresAuth))
          .timeout(ApiConstants.requestTimeout);
      return _parse(response);
    } catch (e) {
      return _mapException(e);
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: await _headers(requiresAuth: requiresAuth),
            body:    jsonEncode(body),
          )
          .timeout(ApiConstants.requestTimeout);
      return _parse(response);
    } catch (e) {
      return _mapException(e);
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: await _headers(requiresAuth: requiresAuth),
            body:    jsonEncode(body),
          )
          .timeout(ApiConstants.requestTimeout);
      return _parse(response);
    } catch (e) {
      return _mapException(e);
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: await _headers(requiresAuth: requiresAuth),
          )
          .timeout(ApiConstants.requestTimeout);
      return _parse(response);
    } catch (e) {
      return _mapException(e);
    }
  }
}
