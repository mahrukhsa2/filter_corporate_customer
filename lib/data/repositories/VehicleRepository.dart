import 'package:flutter/foundation.dart';
import '../network/api_constants.dart';
import '../network/api_response.dart';
import '../network/base_api_service.dart';
import '../../models/vehicle_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/vehicle_repository.dart
//
// Handles:
//   GET  /corporate/vehicles  → fetchVehicles()
//   POST /corporate/vehicles  → createVehicle()
//
// Edit / delete / setDefault have no API yet — ViewModel handles them locally.
//
// ── Response quirks ───────────────────────────────────────────────────────────
// GET  → { "success": true, "vehicles": [ {...}, ... ] }
// POST → 201 on success  { "success": true, "id": "6", "plateNo": ..., ... }
//      → 409 on duplicate plate  { "success": false, "message": "...", "statusCode": 409 }
//
// BaseApiService._parse() treats 201 as success (200–299 range).
// 409 falls into the default branch — we re-read the message from the body
// since the server already provides a user-friendly string.
// ─────────────────────────────────────────────────────────────────────────────

class VehicleRepository {
  VehicleRepository._();

  // ── GET /corporate/vehicles ───────────────────────────────────────────────

  static Future<ApiResponse<List<VehicleModel>>> fetchVehicles() async {
    debugPrint('[VehicleRepository] fetchVehicles → GET ${ApiConstants.vehicles}');

    final response = await BaseApiService.get(ApiConstants.vehicles);

    debugPrint('[VehicleRepository] fetchVehicles ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success || response.data == null) {
      debugPrint('[VehicleRepository] fetchVehicles FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to load vehicles.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      debugPrint('[VehicleRepository] fetchVehicles raw data keys: ${response.data!.keys.toList()}');

      final rawList = response.data!['vehicles'];
      debugPrint('[VehicleRepository] fetchVehicles vehicles field type: ${rawList.runtimeType}');

      if (rawList == null) {
        debugPrint('[VehicleRepository] fetchVehicles: "vehicles" key missing from response');
        return ApiResponse.success([]);
      }

      final list = (rawList as List)
          .map((item) => VehicleModel.fromMap(item as Map<String, dynamic>))
          .toList();

      debugPrint('[VehicleRepository] fetchVehicles parsed ${list.length} vehicles');
      for (final v in list) {
        debugPrint('  → id=${v.id} plate=${v.plateNumber} make=${v.make} model=${v.model} year=${v.year}');
      }

      return ApiResponse.success(list);
    } catch (e, stack) {
      debugPrint('[VehicleRepository] fetchVehicles PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }

  // ── POST /corporate/vehicles ──────────────────────────────────────────────
  // Returns the newly created VehicleModel on success (built from the
  // 201 response body so we have the server-assigned id).
  // Returns error with the server's duplicate-plate message on 409.

  static Future<ApiResponse<VehicleModel>> createVehicle({
    required String make,
    required String model,
    required String plateNumber,
    required int    year,
    required String color,
    required int    odometer,
  }) async {
    final body = {
      'make':      make,
      'model':     model,
      'plateNo':   plateNumber,   // API expects "plateNo", not "plateNumber"
      'year':      year,
      'color':     color,
      'odometer':  odometer,
    };

    debugPrint('[VehicleRepository] createVehicle → POST ${ApiConstants.vehicles}');
    debugPrint('[VehicleRepository] createVehicle body: $body');

    final response = await BaseApiService.post(ApiConstants.vehicles, body);

    debugPrint('[VehicleRepository] createVehicle ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success || response.data == null) {
      // 409 duplicate — server message is already user-friendly
      debugPrint('[VehicleRepository] createVehicle FAILED: '
          'status=${response.statusCode} msg=${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to create vehicle.',
        statusCode: response.statusCode,
        errorType:  response.statusCode == 409
            ? ApiErrorType.validation   // show as validation error in AppAlert
            : response.errorType,
      );
    }

    try {
      debugPrint('[VehicleRepository] createVehicle raw response: ${response.data}');

      // 201 body uses same field names as GET items, so fromMap works directly.
      // The 201 body doesn't include "display" — that's fine, displayLabel = null.
      final created = VehicleModel.fromMap(response.data!);
      debugPrint('[VehicleRepository] createVehicle SUCCESS: '
          'id=${created.id} plate=${created.plateNumber}');

      return ApiResponse.success(created);
    } catch (e, stack) {
      debugPrint('[VehicleRepository] createVehicle PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }

  // ── PUT /corporate/vehicles/{id} ──────────────────────────────────────────
  static Future<ApiResponse<VehicleModel>> updateVehicle({
    required String id,
    required String make,
    required String model,
    required String plateNumber,
    required int    year,
    required String color,
    required int    odometer,
  }) async {
    final endpoint = '${ApiConstants.vehicles}/$id';
    final body = {
      'make':     make,
      'model':    model,
      'plateNo':  plateNumber,   // API expects "plateNo"
      'year':     year,
      'color':    color,
      'odometer': odometer,
    };

    debugPrint('[VehicleRepository] updateVehicle → PUT $endpoint');
    debugPrint('[VehicleRepository] updateVehicle body: $body');

    final response = await BaseApiService.put(endpoint, body);

    debugPrint('[VehicleRepository] updateVehicle ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success || response.data == null) {
      debugPrint('[VehicleRepository] updateVehicle FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to update vehicle.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      debugPrint('[VehicleRepository] updateVehicle raw response: ${response.data}');
      final updated = VehicleModel.fromMap(response.data!);
      debugPrint('[VehicleRepository] updateVehicle SUCCESS: '
          'id=${updated.id} plate=${updated.plateNumber}');
      return ApiResponse.success(updated);
    } catch (e, stack) {
      debugPrint('[VehicleRepository] updateVehicle PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }

// ── DELETE /corporate/vehicles/{id} ───────────────────────────────────────
  static Future<ApiResponse<bool>> deleteVehicle(String id) async {
    final endpoint = '${ApiConstants.vehicles}/$id';

    debugPrint('[VehicleRepository] deleteVehicle → DELETE $endpoint');

    final response = await BaseApiService.delete(endpoint);

    debugPrint('[VehicleRepository] deleteVehicle ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success) {
      debugPrint('[VehicleRepository] deleteVehicle FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to delete vehicle.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    debugPrint('[VehicleRepository] deleteVehicle SUCCESS: id=$id');
    return ApiResponse.success(true);
  }
}