import 'package:flutter/foundation.dart';
import '../network/api_constants.dart';
import '../network/api_response.dart';
import '../network/base_api_service.dart';
import '../../models/payment_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/payment_repository.dart
//
// POST /corporate/make_payment
// Body:
// {
//   "branchId":             "1",
//   "vehicleId":            "1",
//   "departmentId":         "1",
//   "bookedFor":            "2025-01-01 10:00:00",
//   "payFromWallet":        false,
//   "notes":                "Some notes",
//   "paymentMethod":        "Wallet balance",
//   "partialWalletPayment": false
// }
//
// 201: {
//   "success": true,
//   "message": "Order placed successfully after payment.",
//   "order": { "id", "bookingCode", "status", "submittedAt", "paymentMethod", "notes" }
// }
// ─────────────────────────────────────────────────────────────────────────────

class PaymentRepository {
  PaymentRepository._();

  static Future<ApiResponse<OrderPaymentResult>> makePayment({
    required String branchId,
    required String vehicleId,
    required String departmentId,
    required DateTime bookedFor,
    required bool payFromWallet,
    required String notes,
    required String? paymentMethod,  // null = monthly billing (omitted from body)
    required bool partialWalletPayment,
  }) async {
    // API expects space separator: "2026-03-10 10:00:00"
    final bookedForStr =
        '${bookedFor.year.toString().padLeft(4, '0')}'
        '-${bookedFor.month.toString().padLeft(2, '0')}'
        '-${bookedFor.day.toString().padLeft(2, '0')}'
        ' ${bookedFor.hour.toString().padLeft(2, '0')}'
        ':${bookedFor.minute.toString().padLeft(2, '0')}'
        ':${bookedFor.second.toString().padLeft(2, '0')}';

    final body = <String, dynamic>{
      'branchId':             branchId,
      'vehicleId':            vehicleId,
      'departmentIds':        [departmentId],   // API expects array
      'bookedFor':            bookedForStr,
      'payFromWallet':        payFromWallet,
      'notes':                notes,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'partialWalletPayment': partialWalletPayment,
    };

    debugPrint('[PaymentRepository] makePayment → POST ${ApiConstants.makePayment}');
    debugPrint('[PaymentRepository] makePayment body: $body');

    final response = await BaseApiService.post(
      ApiConstants.makePayment,
      body,
      requiresAuth: true,
    );

    debugPrint('[PaymentRepository] makePayment ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success || response.data == null) {
      debugPrint('[PaymentRepository] makePayment FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Payment failed. Please try again.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      debugPrint('[PaymentRepository] makePayment raw: ${response.data}');
      final result = OrderPaymentResult.fromMap(response.data!);
      debugPrint('[PaymentRepository] makePayment SUCCESS: '
          'orderId=${result.orderId} '
          'bookingCode=${result.bookingCode} '
          'status=${result.status}');
      return ApiResponse.success(result);
    } catch (e, stack) {
      debugPrint('[PaymentRepository] makePayment PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }
}