
import '../../models/booking_model.dart';
import '../network/api_constants.dart';
import '../network/base_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/lookup_repository.dart
//
// Fetches static lookup data (branches, departments) from the API.
// Called ONCE by AppCache.init() during the splash screen.
// No screen or ViewModel ever calls this directly.
//
// ── Unusual response shape ────────────────────────────────────────────────────
// The API returns objects keyed by numeric strings instead of a plain array:
//   { "0": {...}, "1": {...}, "success": true }
//
// _parseList() handles this by iterating keys, skipping non-numeric ones
// ("success", "message", etc.) and collecting values in insertion order.
// ─────────────────────────────────────────────────────────────────────────────

class LookupRepository {
  LookupRepository._();

  // ── GET /corporate/branches ───────────────────────────────────────────────

  static Future<List<BranchModel>> fetchBranches() async {
    final response = await BaseApiService.get(ApiConstants.branches);

    if (!response.success || response.data == null) {
      return [];
    }

    return _parseList(response.data!)
        .map((map) => BranchModel.fromMap(map))
        .toList();
  }

  // ── GET /corporate/departments ────────────────────────────────────────────

  static Future<List<DepartmentModel>> fetchDepartments() async {
    final response = await BaseApiService.get(ApiConstants.departments);

    if (!response.success || response.data == null) {
      return [];
    }

    return _parseList(response.data!)
        .map((map) => DepartmentModel.fromMap(map))
        .toList();
  }

  // ── Helper: extract list from numeric-keyed object ────────────────────────
  // Converts { "0": {...}, "1": {...}, "success": true }
  // into     [ {...}, {...} ]
  // Works for any number of items regardless of how many the backend returns.

  static List<Map<String, dynamic>> _parseList(Map<String, dynamic> body) {
    final result = <Map<String, dynamic>>[];

    // Sort numeric keys so order matches server intent (0, 1, 2, ...)
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
