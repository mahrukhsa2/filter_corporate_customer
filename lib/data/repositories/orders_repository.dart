import '../../models/booking_model.dart';
import '../network/api_constants.dart';
import '../network/api_response.dart';
import '../network/base_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/orders_repository.dart
// All orders/bookings API calls.
// ─────────────────────────────────────────────────────────────────────────────

class OrdersRepository {
  OrdersRepository._();

  // ── GET /corporate/orders ──────────────────────────────────────────────────
  /// Fetches order history with optional filters
  /// 
  /// Parameters:
  /// - status: Filter by order status (optional)
  /// - limit: Number of records to fetch (default: 20)
  /// - offset: Pagination offset (default: 0)
  static Future<ApiResponse<OrdersResponseModel>> fetchOrders({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    // Build query parameters
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await BaseApiService.get(
      ApiConstants.orders,
      queryParams: queryParams,
      requiresAuth: true,
    );

    if (!response.success) {
      return ApiResponse.error(
        response.message ?? 'Failed to load orders.',
        statusCode: response.statusCode,
        errorType: response.errorType,
      );
    }

    try {
      final model = OrdersResponseModel.fromMap(response.data!);
      return ApiResponse.success(model);
    } catch (e) {
      return ApiResponse.error(
        'Unexpected response format.',
        errorType: ApiErrorType.unknown,
      );
    }
  }

  // ── GET /corporate/orders/:id (if needed for details) ──────────────────────
  static Future<ApiResponse<OrderDetailModel>> fetchOrderDetail(
    String orderId,
  ) async {
    final response = await BaseApiService.get(
      '${ApiConstants.orders}/$orderId',
      requiresAuth: true,
    );

    if (!response.success) {
      return ApiResponse.error(
        response.message ?? 'Failed to load order details.',
        statusCode: response.statusCode,
        errorType: response.errorType,
      );
    }

    try {
      final model = OrderDetailModel.fromMap(response.data!);
      return ApiResponse.success(model);
    } catch (e) {
      return ApiResponse.error(
        'Unexpected response format.',
        errorType: ApiErrorType.unknown,
      );
    }
  }
}
