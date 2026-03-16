import 'package:flutter/foundation.dart';
import '../network/api_constants.dart';
import '../network/api_response.dart';
import '../network/base_api_service.dart';
import '../../models/order_track_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/order_track_repository.dart
//
// GET /corporate/orders/{orderId}/track
// ─────────────────────────────────────────────────────────────────────────────

class OrderTrackRepository {
  OrderTrackRepository._();

  static Future<ApiResponse<OrderTrackModel>> fetchTrack(
      String orderId) async {
    final endpoint = '${ApiConstants.orders}/$orderId/track';

    debugPrint('[OrderTrackRepository] fetchTrack → GET $endpoint');

    final response = await BaseApiService.get(
      endpoint,
      requiresAuth: true,
    );

    debugPrint('[OrderTrackRepository] fetchTrack ← '
        'status=${response.statusCode} success=${response.success}');

    if (!response.success || response.data == null) {
      debugPrint('[OrderTrackRepository] fetchTrack FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to load tracking info.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      final model = OrderTrackModel.fromMap(response.data!);
      debugPrint('[OrderTrackRepository] fetchTrack SUCCESS: '
          'code=${model.bookingCode} '
          'status=${model.currentStatus} '
          'steps=${model.timeline.length}');
      return ApiResponse.success(model);
    } catch (e, stack) {
      debugPrint('[OrderTrackRepository] fetchTrack PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response format.',
        errorType: ApiErrorType.unknown,
      );
    }
  }
}
