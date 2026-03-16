import 'package:flutter/foundation.dart';
import '../network/api_constants.dart';
import '../network/api_response.dart';
import '../network/base_api_service.dart';
import '../../models/product_quotation.dart';
import '../../models/quotation_history_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/quotation_repository.dart
// ─────────────────────────────────────────────────────────────────────────────

class QuotationRepository {
  QuotationRepository._();

  // ── Search Products ────────────────────────────────────────────────────────

  static Future<ApiResponse<List<QuotationProduct>>> searchProducts({
    required String query,
  }) async {
    if (query.trim().isEmpty) return ApiResponse.success([]);

    final response = await BaseApiService.get(
      ApiConstants.productsSearch,
      queryParams: {'query': query.trim(), 'type': 'product'},
      requiresAuth: true,
    );

    if (!response.success || response.data == null) {
      return ApiResponse.error(
        response.message ?? 'Failed to search products.',
        statusCode: response.statusCode,
        errorType: response.errorType,
      );
    }

    try {
      final results = response.data!['results'] as List<dynamic>? ?? [];
      final products = results
          .whereType<Map<String, dynamic>>()
          .map(_parseProduct)
          .whereType<QuotationProduct>()
          .toList();
      return ApiResponse.success(products);
    } catch (e, stack) {
      debugPrint('[QuotationRepository] searchProducts PARSE ERROR: $e\n$stack');
      return ApiResponse.error('Unexpected response format.',
          errorType: ApiErrorType.unknown);
    }
  }

  // ── Submit Quotation ───────────────────────────────────────────────────────

  static Future<ApiResponse<QuotationSubmitResult>> submitQuotation({
    required List<QuotationLineItem> items,
    String notes = '',
    String branchId = '1',
  }) async {
    if (items.isEmpty) {
      return ApiResponse.error('No items to submit.',
          errorType: ApiErrorType.validation);
    }

    final body = {
      'branchId': branchId,
      'items': items.map((item) => {
        'productId': item.product.id,
        'qty': item.quantity,
        'price': item.offeredPrice,
      }).toList(),
      'notes': notes,
    };

    final response = await BaseApiService.post(
        ApiConstants.quotationsSubmit, body, requiresAuth: true);

    if (!response.success || response.data == null) {
      return ApiResponse.error(
        response.message ?? 'Failed to submit quotation.',
        statusCode: response.statusCode,
        errorType: response.errorType,
      );
    }

    try {
      final message   = response.data!['message']?.toString() ?? 'Quotation submitted';
      final reference = response.data!['reference']?.toString() ?? '';
      return ApiResponse.success(
          QuotationSubmitResult(message: message, reference: reference));
    } catch (e) {
      return ApiResponse.error('Unexpected response format.',
          errorType: ApiErrorType.unknown);
    }
  }

  // ── Fetch Quotation History  GET /corporate/quotations ────────────────────

  static Future<ApiResponse<QuotationHistoryResponse>> fetchQuotations({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? productQuery,
    String? submittedBy,
  }) async {
    final params = <String, String>{};

    if (status != null && status.isNotEmpty) {
      // API expects 'quotation_pending' | 'quotation_approved' | 'quotation_rejected'
      // label comes in as 'Pending' | 'Approved' | 'Rejected' — prefix it
      final s = status.toLowerCase();
      params['status'] = s.startsWith('quotation_') ? s : 'quotation_$s';
    }
    if (startDate != null) params['startDate'] = _fmtDate(startDate);
    if (endDate   != null) params['endDate']   = _fmtDate(endDate);
    if (productQuery != null && productQuery.trim().isNotEmpty) {
      params['query'] = productQuery.trim();
    }
    if (submittedBy != null && submittedBy.isNotEmpty) {
      params['submittedBy'] = submittedBy;
    }

    debugPrint('[QuotationRepository] fetchQuotations → GET ${ApiConstants.quotations}');
    debugPrint('[QuotationRepository] params: $params');

    final response = await BaseApiService.get(
      ApiConstants.quotations,
      queryParams: params,
      requiresAuth: true,
    );

    debugPrint('[QuotationRepository] fetchQuotations ← '
        'statusCode=${response.statusCode} success=${response.success}');

    if (!response.success || response.data == null) {
      debugPrint('[QuotationRepository] FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to load quotations.',
        statusCode: response.statusCode,
        errorType: response.errorType,
      );
    }

    try {
      final list  = response.data!['quotations'] as List<dynamic>? ?? [];
      final total = response.data!['total'] as int? ?? 0;

      final quotations = list
          .whereType<Map<String, dynamic>>()
          .map(_parseQuotationHistoryItem)
          .whereType<QuotationHistoryItem>()
          .toList();

      debugPrint('[QuotationRepository] SUCCESS: '
          '${quotations.length} items, total=$total');

      return ApiResponse.success(
          QuotationHistoryResponse(quotations: quotations, total: total));
    } catch (e, stack) {
      debugPrint('[QuotationRepository] PARSE ERROR: $e\n$stack');
      return ApiResponse.error('Unexpected response format.',
          errorType: ApiErrorType.unknown);
    }
  }

  // ── Fetch Quotation Summary  GET /corporate/quotations/summary ─────────────

  static Future<ApiResponse<QuotationHistorySummary>> fetchSummary() async {
    debugPrint('[QuotationRepository] fetchSummary → GET ${ApiConstants.quotationsSummary}');

    final response = await BaseApiService.get(
      ApiConstants.quotationsSummary,
      requiresAuth: true,
    );

    debugPrint('[QuotationRepository] fetchSummary ← '
        'statusCode=${response.statusCode} success=${response.success}');

    if (!response.success || response.data == null) {
      debugPrint('[QuotationRepository] fetchSummary FAILED: ${response.message}');
      return ApiResponse.error(
        response.message ?? 'Failed to load summary.',
        statusCode: response.statusCode,
        errorType: response.errorType,
      );
    }

    try {
      final d = response.data!;
      final summary = QuotationHistorySummary(
        total:            d['totalQuotations'] as int?    ?? 0,
        approved:         d['approved']        as int?    ?? 0,
        rejected:         d['rejected']        as int?    ?? 0,
        pending:          d['pending']         as int?    ?? 0,
        totalQuotedValue: (d['totalQuotedValue'] as num?)?.toDouble() ?? 0.0,
      );
      debugPrint('[QuotationRepository] fetchSummary SUCCESS: '
          'total=${summary.total} pending=${summary.pending}');
      return ApiResponse.success(summary);
    } catch (e, stack) {
      debugPrint('[QuotationRepository] fetchSummary PARSE ERROR: $e\n$stack');
      return ApiResponse.error('Unexpected response format.',
          errorType: ApiErrorType.unknown);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static QuotationProduct? _parseProduct(Map<String, dynamic> map) {
    try {
      final id    = map['id']?.toString();
      final name  = map['name']?.toString();
      final unit  = map['unit']?.toString();
      final price = (map['price'] as num?)?.toDouble();
      if (id == null || name == null || unit == null || price == null) return null;
      return QuotationProduct(
        id: id, name: name, unit: unit,
        marketPrice: price, corporatePrice: price,
        minAllowedPrice: 0, maxAllowedPrice: price * 10,
      );
    } catch (_) { return null; }
  }

  static QuotationHistoryItem? _parseQuotationHistoryItem(
      Map<String, dynamic> map) {
    try {
      final id             = map['id']?.toString();
      final quotationNo    = map['quotationNo']?.toString();
      final dateStr        = map['date']?.toString();
      final productService = map['productService']?.toString();
      final qty            = map['qty'];
      final quotedPrice    = (map['quotedPrice'] as num?)?.toDouble();
      final statusStr      = map['status']?.toString();
      final submittedBy    = map['submittedBy']?.toString();

      if (id == null || quotationNo == null || dateStr == null ||
          productService == null || qty == null || quotedPrice == null ||
          statusStr == null || submittedBy == null) {
        debugPrint('[QuotationRepository] Missing fields: $map');
        return null;
      }

      DateTime date;
      try { date = DateTime.parse(dateStr); } catch (_) { date = DateTime.now(); }

      final rawStatus = statusStr.toLowerCase();
      final QuotationStatus status = switch (rawStatus) {
        'quotation_approved' => QuotationStatus.approved,
        'quotation_rejected' => QuotationStatus.rejected,
        'quotation_pending' => QuotationStatus.pending,
        _          => QuotationStatus.pending,
      };

      return QuotationHistoryItem(
        id:               id,
        quotationNumber:  quotationNo,
        date:             date,
        productService:   productService,
        qty:              qty.toString(),
        quotedPrice:      quotedPrice,
        unit:             '',
        status:           status,
        submittedBy:      submittedBy,
        rejectionReason:  map['rejectionReason']?.toString(),
      );
    } catch (e) {
      debugPrint('[QuotationRepository] Error parsing: $e');
      return null;
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}'
          '-${d.month.toString().padLeft(2, '0')}'
          '-${d.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────

class QuotationSubmitResult {
  final String message;
  final String reference;
  const QuotationSubmitResult({required this.message, required this.reference});
}

class QuotationHistoryResponse {
  final List<QuotationHistoryItem> quotations;
  final int total;
  const QuotationHistoryResponse({required this.quotations, required this.total});
}