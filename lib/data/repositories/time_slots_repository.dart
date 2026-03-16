import 'package:flutter/foundation.dart';
import '../../models/booking_model.dart';
import '../network/api_constants.dart';
import '../network/base_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/time_slots_repository.dart
//
// Fetches available time slots for a specific branch and date
// ─────────────────────────────────────────────────────────────────────────────

class TimeSlotsRepository {
  TimeSlotsRepository._();

  /// GET /corporate/time-slots?branchId=X&date=MM-DD-YYYY
  static Future<List<TimeSlotModel>> fetchTimeSlots({
    required String branchId,
    required DateTime date,
  }) async {
    // Format date as MM-DD-YYYY
    final formattedDate = _formatDate(date);
    
    debugPrint('[TimeSlotsRepository] fetchTimeSlots() START - branchId: $branchId, date: $formattedDate');
    
    final response = await BaseApiService.get(
      ApiConstants.timeSlots,
      queryParams: {
        'branchId': branchId,
        'date': formattedDate,
      },
      requiresAuth: true,
    );

    debugPrint('[TimeSlotsRepository] fetchTimeSlots() response: success=${response.success}, statusCode=${response.statusCode}');

    if (!response.success || response.data == null) {
      debugPrint('[TimeSlotsRepository] fetchTimeSlots() FAILED: ${response.message}');
      return [];
    }

    try {
      // API returns numeric-keyed format: { "0": {...}, "1": {...}, "success": true }
      final slots = _parseNumericKeyedList(response.data!)
          .map((map) => TimeSlotModel.fromMap(map))
          .toList();
      
      debugPrint('[TimeSlotsRepository] fetchTimeSlots() SUCCESS - parsed ${slots.length} slots');
      for (final slot in slots) {
        debugPrint('[TimeSlotsRepository]   → Slot: id=${slot.id}, label=${slot.label}, available=${slot.available}');
      }
      
      return slots;
    } catch (e, stack) {
      debugPrint('[TimeSlotsRepository] fetchTimeSlots() PARSE ERROR: $e');
      debugPrint('[TimeSlotsRepository] Stack: $stack');
      return [];
    }
  }

  /// Format date as MM-DD-YYYY for API
  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month-$day-$year';
  }

  /// Parse numeric-keyed response format
  static List<Map<String, dynamic>> _parseNumericKeyedList(
      Map<String, dynamic> body) {
    final result = <Map<String, dynamic>>[];

    // Sort numeric keys (0, 1, 2, ...)
    final numericKeys = body.keys
        .where((k) => int.tryParse(k) != null)
        .toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    for (final key in numericKeys) {
      final value = body[key];
      if (value is Map<String, dynamic>) {
        result.add(value);
      }
    }

    return result;
  }
}
