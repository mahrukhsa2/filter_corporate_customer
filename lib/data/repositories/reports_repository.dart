import 'package:flutter/foundation.dart';
import '../network/api_constants.dart';
import '../network/api_response.dart';
import '../network/base_api_service.dart';
import '../../models/reports_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/reports_repository.dart
//
// GET /corporate/reports/summary
//   → { success, totalSpentThisYear, thisMonthAmount, totalSavings, walletUsed }
// GET /corporate/reports/custom
//   → { success, type, from, to, count, data[] }
// ─────────────────────────────────────────────────────────────────────────────

class ReportsRepository {
  ReportsRepository._();

  // ── GET /corporate/reports/summary ────────────────────────────────────────

  static Future<ApiResponse<ReportsSummary>> fetchSummary() async {
    debugPrint('[ReportsRepository] fetchSummary → GET ${ApiConstants.reportsSummary}');

    final response = await BaseApiService.get(ApiConstants.reportsSummary);

    debugPrint('[ReportsRepository] fetchSummary ← '
        'statusCode=${response.statusCode} '
        'success=${response.success} '
        'errorType=${response.errorType}');

    if (!response.success || response.data == null) {
      debugPrint('[ReportsRepository] fetchSummary FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to load reports summary.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    try {
      debugPrint('[ReportsRepository] fetchSummary raw: ${response.data}');
      final summary = ReportsSummary.fromMap(response.data!);
      debugPrint('[ReportsRepository] fetchSummary parsed: '
          'totalSpentThisYear=${summary.totalSpentThisYear} '
          'thisMonthAmount=${summary.thisMonthAmount} '
          'totalSavings=${summary.totalSavings} '
          'walletUsed=${summary.walletUsed}');
      return ApiResponse.success(summary);
    } catch (e, stack) {
      debugPrint('[ReportsRepository] fetchSummary PARSE ERROR: $e\n$stack');
      return ApiResponse.error(
        'Unexpected response from server.',
        errorType: ApiErrorType.unknown,
      );
    }
  }

  // ── GET /corporate/reports/custom ─────────────────────────────────────────
  // Params: fromDate (required), toDate (required), type (required)
  // Returns raw response map so the ViewModel builds the Excel sheet.

  static Future<ApiResponse<Map<String, dynamic>>> fetchCustomReport({
    required DateTime fromDate,
    required DateTime toDate,
    required String   type,
  }) async {
    final params = {
      'fromDate': _fmtDate(fromDate),
      'toDate':   _fmtDate(toDate),
      'type':     type,
    };

    debugPrint('[ReportsRepository] fetchCustomReport → GET ${ApiConstants.reportsCustom}');
    debugPrint('[ReportsRepository] fetchCustomReport params: $params');

    final response = await BaseApiService.get(
      ApiConstants.reportsCustom,
      queryParams: params,
    );

    debugPrint('[ReportsRepository] fetchCustomReport ← '
        'statusCode=${response.statusCode} success=${response.success}');

    if (!response.success || response.data == null) {
      debugPrint('[ReportsRepository] fetchCustomReport FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to generate report.',
        statusCode: response.statusCode,
        errorType:  response.errorType,
      );
    }

    final d = response.data!;
    debugPrint('[ReportsRepository] fetchCustomReport SUCCESS '
        'type=${d['type']} count=${d['count']}');
    return ApiResponse.success(d);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}'
          '-${d.month.toString().padLeft(2, '0')}'
          '-${d.day.toString().padLeft(2, '0')}';
}