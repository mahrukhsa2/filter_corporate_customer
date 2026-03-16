import 'package:flutter/foundation.dart';

import '../../../data/network/api_constants.dart';
import '../../../data/network/base_api_service.dart';
import '../../../models/payment_history_report_model.dart';
import '../../../services/excel_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// payment_history_report_view_model.dart
//
// API: GET /corporate/reports/payments
// Params: startDate, endDate, method, status
// Response: { success, summary: { totalPaid, byWallet, byCard, byTransfer }, history: [] }
// ─────────────────────────────────────────────────────────────────────────────

enum PHLoadStatus { idle, loading, loaded }

class PaymentHistoryReportViewModel extends ChangeNotifier {

  PHLoadStatus _status        = PHLoadStatus.idle;
  bool         _isTableLoading = false;
  bool         _isExporting    = false;
  String?      _exportError;

  List<PaymentHistoryItem> _items   = [];
  PaymentHistorySummary?   _summary;
  PaymentHistoryFilters    _filters = const PaymentHistoryFilters();

  bool get isLoading      => _status == PHLoadStatus.loading;
  bool get isTableLoading => _isTableLoading;
  bool get isExporting    => _isExporting;
  String? get exportError  => _exportError;

  List<PaymentHistoryItem> get items   => _items;
  PaymentHistorySummary?   get summary => _summary;
  PaymentHistoryFilters    get filters => _filters;

  PaymentHistoryReportViewModel() {
    debugPrint('[PaymentHistoryReportViewModel] created');
    _load();
  }

  // ── Initial full-screen load ──────────────────────────────────────────────

  Future<void> _load() async {
    debugPrint('[PaymentHistoryReportViewModel] _load START');
    _status = PHLoadStatus.loading;
    notifyListeners();
    await _fetch(_filters);
    _status = PHLoadStatus.loaded;
    notifyListeners();
    debugPrint('[PaymentHistoryReportViewModel] _load END items=${_items.length}');
  }

  Future<void> refresh() => _load();

  // ── Filter change — table-only spinner, summary stays visible ─────────────

  void updateFilters(PaymentHistoryFilters f) {
    _filters = f;
    notifyListeners();
    _fetchForFilter();
  }

  void clearFilters() {
    _filters = const PaymentHistoryFilters();
    notifyListeners();
    _fetchForFilter();
  }

  Future<void> _fetchForFilter() async {
    _isTableLoading = true;
    notifyListeners();
    await _fetch(_filters);
    _isTableLoading = false;
    notifyListeners();
  }

  // ── Core API fetch ────────────────────────────────────────────────────────

  Future<void> _fetch(PaymentHistoryFilters f) async {
    final params = f.toQueryParams();
    debugPrint('[PaymentHistoryReportViewModel] _fetch → '
        'GET ${ApiConstants.reportsPayments} params=$params');

    final response = await BaseApiService.get(
      ApiConstants.reportsPayments,
      queryParams: params,
    );

    debugPrint('[PaymentHistoryReportViewModel] _fetch ← '
        'statusCode=${response.statusCode} success=${response.success}');

    if (!response.success || response.data == null) {
      debugPrint('[PaymentHistoryReportViewModel] _fetch FAILED: ${response.message}');
      _items   = [];
      _summary = null;
      return;
    }

    try {
      final raw        = response.data!;
      final rawHistory = raw['history'] as List? ?? [];
      final rawSummary = raw['summary'] as Map<String, dynamic>? ?? {};

      _items = rawHistory
          .whereType<Map<String, dynamic>>()
          .map((m) => PaymentHistoryItem.fromMap(m))
          .toList();

      _summary = PaymentHistorySummary.fromApiMap(rawSummary, _items);

      debugPrint('[PaymentHistoryReportViewModel] _fetch SUCCESS '
          'items=${_items.length} totalPaid=${_summary!.totalPaid}');
    } catch (e, stack) {
      debugPrint('[PaymentHistoryReportViewModel] _fetch PARSE ERROR: $e\n$stack');
      _items   = [];
      _summary = null;
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> exportReport() async {
    if (_items.isEmpty) {
      _exportError = 'No data available to export.';
      notifyListeners();
      return;
    }
    _isExporting = true;
    notifyListeners();

    try {
      final rows = _items.map((item) => {
        'Date':           item.date.toIso8601String(),
        'Amount (SAR)':   item.amount,
        'Method':         item.method.label,
        'Invoice Ref':    item.invoiceRef,
        'Status':         item.status.label,
        'Reference':      item.reference,
      }).toList();

      final summary = _summary == null ? null : {
        'Total Paid':   _summary!.totalPaid,
        'By Wallet':    _summary!.byWallet,
        'By Card':      _summary!.byCard,
        'By Transfer':  _summary!.byTransfer,
        'By Cash':      _summary!.byCash,
        'Transactions': _summary!.totalTransactions,
      };

      _exportError = null;
      await ExcelExportService.exportFromList(
        title:    'Payment History',
        rows:     rows,
        fromDate: _filters.fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
        toDate:   _filters.toDate   ?? DateTime.now(),
        summary:  summary,
      );

      debugPrint('[PaymentHistoryReportViewModel] export done');
    } on ExcelExportException catch (e) {
      _exportError = e.message;
      debugPrint('[PaymentHistoryReportViewModel] no data: ${e.message}');
    } catch (e) {
      _exportError = 'Export failed. Please try again.';
      debugPrint('[PaymentHistoryReportViewModel] export error: $e');
    }

    _isExporting = false;
    notifyListeners();
  }
}