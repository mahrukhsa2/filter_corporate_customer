
import '../../models/home_model.dart';
import '../network/api_constants.dart';
import '../network/api_response.dart';
import '../network/base_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/dashboard_repository.dart
// ─────────────────────────────────────────────────────────────────────────────

class DashboardRepository {
  DashboardRepository._();

  // ── GET /corporate/dashboard ──────────────────────────────────────────────

  static Future<ApiResponse<HomeKpiData>> fetchKpis() async {
    final response = await BaseApiService.get(ApiConstants.dashboard);

    if (!response.success || response.data == null) {
      return ApiResponse.error(
        response.message ?? 'Failed to load dashboard.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      final kpi = HomeKpiData.fromMap(response.data!);
      return ApiResponse.success(kpi);
    } catch (_) {
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }
}
