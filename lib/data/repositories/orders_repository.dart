import 'package:flutter/foundation.dart';
import '../../models/booking_model.dart';
import '../network/api_constants.dart';
import '../network/api_response.dart';
import '../network/base_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/orders_repository.dart
// ─────────────────────────────────────────────────────────────────────────────

class OrdersRepository {
  OrdersRepository._();

  // ── GET /corporate/orders ──────────────────────────────────────────────────

  static Future<ApiResponse<OrdersResponseModel>> fetchOrders({
    String?   status,
    DateTime? startDate,
    DateTime? endDate,
    String?   branchId,
    int       limit  = 10,
    int       offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      if (offset > 0) 'offset': offset.toString(),
    };

    if (status   != null && status.isNotEmpty)   params['status']   = status;
    if (branchId != null && branchId.isNotEmpty) params['branchId'] = branchId;
    if (startDate != null) params['startDate'] = _fmtDate(startDate);
    if (endDate   != null) params['endDate']   = _fmtDate(endDate);

    debugPrint('[OrdersRepository] fetchOrders params=$params');

    final response = await BaseApiService.get(
      ApiConstants.orders,
      queryParams: params,
      requiresAuth: true,
    );

    debugPrint('[OrdersRepository] fetchOrders ← '
        'status=${response.statusCode} success=${response.success}');

    if (!response.success) {
      debugPrint('[OrdersRepository] fetchOrders FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to load orders.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      final model = OrdersResponseModel.fromMap(response.data!);
      debugPrint('[OrdersRepository] fetchOrders SUCCESS: '
          '${model.orders.length} orders, total=${model.total}');
      return ApiResponse.success(model);
    } catch (e, stack) {
      debugPrint('[OrdersRepository] fetchOrders PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response format.',
        errorType: ApiErrorType.unknown,
      );
    }
  }

  // ── GET /corporate/orders/:id ──────────────────────────────────────────────

  static Future<ApiResponse<OrderDetailModel>> fetchOrderDetail(
      String orderId) async {
    final response = await BaseApiService.get(
      '${ApiConstants.orders}/$orderId',
      requiresAuth: true,
    );

    if (!response.success) {
      return ApiResponse.error(
        response.message ?? 'Failed to load order details.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      return ApiResponse.success(OrderDetailModel.fromMap(response.data!));
    } catch (e) {
      return ApiResponse.error('Unexpected response format.',
          errorType: ApiErrorType.unknown);
    }
  }

  // ── POST /corporate/order ──────────────────────────────────────────────────

  static Future<ApiResponse<OrderSubmitResult>> submitOrder({
    required String   branchId,
    required String   vehicleId,
    required String   departmentId,
    required DateTime bookedFor,
    required bool     payFromWallet,
    required String   notes,
  }) async {
    final bookedForStr =
        '${bookedFor.year.toString().padLeft(4, '0')}'
        '-${bookedFor.month.toString().padLeft(2, '0')}'
        '-${bookedFor.day.toString().padLeft(2, '0')}'
        ' ${bookedFor.hour.toString().padLeft(2, '0')}'
        ':${bookedFor.minute.toString().padLeft(2, '0')}'
        ':${bookedFor.second.toString().padLeft(2, '0')}';

    final body = {
      'branchId':      branchId,
      'vehicleId':     vehicleId,
      'departmentIds': [departmentId],   // API expects array
      'bookedFor':     bookedForStr,
      'payFromWallet': payFromWallet,
      'notes':         notes,
    };

    debugPrint('[OrdersRepository] submitOrder → POST ${ApiConstants.orderSubmit}');
    debugPrint('[OrdersRepository] submitOrder body: $body');

    final response = await BaseApiService.post(
      ApiConstants.orderSubmit,
      body,
      requiresAuth: true,
    );

    debugPrint('[OrdersRepository] submitOrder ← '
        'statusCode=${response.statusCode} success=${response.success}');

    if (!response.success || response.data == null) {
      debugPrint('[OrdersRepository] submitOrder FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to submit order. Please try again.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    final message = response.data!['message']?.toString() ??
        'Order submitted successfully.';
    debugPrint('[OrdersRepository] submitOrder SUCCESS: $message');
    return ApiResponse.success(OrderSubmitResult(message: message));
  }

  // ── POST /corporate/orders/:id/cancel ✅ NEW ───────────────────────────────

  static Future<ApiResponse<OrderCancelResult>> cancelOrder(String orderId) async {
    final endpoint = '${ApiConstants.orders}/$orderId/cancel';

    debugPrint('[OrdersRepository] cancelOrder → POST $endpoint');

    final response = await BaseApiService.post(
      endpoint,
      {}, // Empty body
      requiresAuth: true,
    );

    debugPrint('[OrdersRepository] cancelOrder ← '
        'statusCode=${response.statusCode} success=${response.success}');

    if (!response.success || response.data == null) {
      debugPrint('[OrdersRepository] cancelOrder FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to cancel order. Please try again.',
        statusCode: response.statusCode,
        errorType: response.errorType,
      );
    }

    final message = response.data!['message']?.toString() ?? 'Order cancelled';
    debugPrint('[OrdersRepository] cancelOrder SUCCESS: $message');

    return ApiResponse.success(OrderCancelResult(message: message));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4,'0')}'
          '-${d.month.toString().padLeft(2,'0')}'
          '-${d.day.toString().padLeft(2,'0')}';
}

// ─────────────────────────────────────────────────────────────────────────────

class OrderSubmitResult {
  final String message;
  const OrderSubmitResult({required this.message});
}

// ✅ NEW
class OrderCancelResult {
  final String message;
  const OrderCancelResult({required this.message});
}