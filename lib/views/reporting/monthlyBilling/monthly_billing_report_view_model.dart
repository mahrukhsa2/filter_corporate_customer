import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/network/api_constants.dart';
import '../../../data/network/base_api_service.dart';
import '../../../models/monthly_billing_report_model.dart';
import '../../../services/excel_export_service.dart';
import '../../../services/pdf_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/reports/monthly_billing/monthly_billing_report_view_model.dart
//
// API: GET /corporate/billing/monthly?month=MM&year=YYYY&status=paid|pending|overdue
// Response:
// {
//   "success": true,
//   "month": "March 2026",
//   "summary": { totalBilled, totalPaid, outstandingBalance, dueDate, walletUsed },
//   "invoices": [...]
// }
// ─────────────────────────────────────────────────────────────────────────────

enum MBLoadStatus { idle, loading, loaded }

class MonthlyBillingReportViewModel extends ChangeNotifier {

  MBLoadStatus _status          = MBLoadStatus.idle;
  bool         _isTableLoading  = false;
  bool         _isExporting     = false;
  String?      _exportError;
  bool         _isPayingOutstanding = false;

  List<BillingInvoice>    _all      = [];
  List<BillingInvoice>    _filtered = [];
  MonthlyBillingOverview? _overview;
  List<BillingTrendPoint> _trend    = [];
  BillingFilters          _filters;

  bool get isLoading           => _status == MBLoadStatus.loading;
  bool get isTableLoading      => _isTableLoading;
  bool get isExporting         => _isExporting;
  String? get exportError      => _exportError;
  bool get isPayingOutstanding => _isPayingOutstanding;

  List<BillingInvoice>    get items    => _filtered;
  MonthlyBillingOverview? get overview => _overview;
  List<BillingTrendPoint> get trend    => _trend;
  BillingFilters          get filters  => _filters;

  final List<int> availableYears  = [2024, 2025, 2026];
  final List<int> availableMonths = List.generate(12, (i) => i + 1);

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  String monthName(int m) => _monthNames[m - 1];

  MonthlyBillingReportViewModel()
      : _filters = BillingFilters(
    month: DateTime.now().month,
    year:  DateTime.now().year,
  ) {
    debugPrint('[MonthlyBillingReportViewModel] created');
    _load();
  }

  // ── Initial full-screen load ──────────────────────────────────────────────

  Future<void> _load() async {
    debugPrint('[MonthlyBillingReportViewModel] _load START');
    _status = MBLoadStatus.loading;
    notifyListeners();
    await _fetch(_filters);
    _status = MBLoadStatus.loaded;
    notifyListeners();
    debugPrint('[MonthlyBillingReportViewModel] _load END items=${_all.length}');
  }

  Future<void> refresh() => _load();

  // ── Filter change ────────────────────────────────────────────────────────
  // All filter changes use _isTableLoading — only the content area spins.
  // Month/year change also clears overview so it shows a spinner in place
  // of the summary cards until the new data arrives.

  void updateFilters(BillingFilters f) {
    final monthOrYearChanged =
        f.month != _filters.month || f.year != _filters.year;
    _filters = f;
    if (monthOrYearChanged) _overview = null; // clear stale summary
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

  Future<void> _fetch(BillingFilters f) async {
    final params = f.toQueryParams();
    debugPrint('[MonthlyBillingReportViewModel] _fetch → '
        'GET ${ApiConstants.billingMonthly} params=$params');

    final response = await BaseApiService.get(
      ApiConstants.billingMonthly,
      queryParams: params,
    );

    debugPrint('[MonthlyBillingReportViewModel] _fetch ← '
        'statusCode=${response.statusCode} success=${response.success}');

    if (!response.success || response.data == null) {
      debugPrint('[MonthlyBillingReportViewModel] _fetch FAILED: ${response.message}');
      _all      = [];
      _filtered = [];
      _overview = null;
      return;
    }

    try {
      final raw        = response.data!;
      final monthLabel = (raw['month'] as String?)?.trim() ?? '';
      final rawSummary = raw['summary'] as Map<String, dynamic>? ?? {};
      final rawInvoices = raw['invoices'] as List? ?? [];

      _overview = MonthlyBillingOverview.fromApiMap(rawSummary, monthLabel);

      _all = rawInvoices
          .whereType<Map<String, dynamic>>()
          .map((m) => BillingInvoice.fromMap(m))
          .toList();

      _filtered = List.from(_all);

      // Build trend from loaded invoices grouped by month
      _trend = _buildTrend(_all);

      debugPrint('[MonthlyBillingReportViewModel] _fetch SUCCESS '
          'month=$monthLabel invoices=${_all.length} '
          'totalBilled=${_overview!.totalBilled}');
    } catch (e, stack) {
      debugPrint('[MonthlyBillingReportViewModel] _fetch PARSE ERROR: $e\n$stack');
      _all      = [];
      _filtered = [];
      _overview = null;
    }
  }

  // ── Build trend from invoice list ────────────────────────────────────────
  // Groups invoices by month label (derived from date) and sums paid/pending.
  // Since the API returns only the selected month's invoices, we also seed
  // the 5 months before it with zero values so the chart always shows 6 bars.

  List<BillingTrendPoint> _buildTrend(List<BillingInvoice> invoices) {
    const monthAbbr = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
      'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final now   = DateTime.now();
    final month = _filters.month ?? now.month;
    final year  = _filters.year  ?? now.year;

    // Build 6-month window ending at selected month
    final points = <BillingTrendPoint>[];
    for (int i = 5; i >= 0; i--) {
      int m = month - i;
      int y = year;
      while (m <= 0) { m += 12; y--; }
      final label = monthAbbr[m];

      if (i == 0) {
        // Current selected month — use actual invoice data
        double paid    = 0;
        double pending = 0;
        for (final inv in invoices) {
          if (inv.status == BillingInvoiceStatus.paid) {
            paid += inv.amount;
          } else {
            pending += inv.amount;
          }
        }
        points.add(BillingTrendPoint(
            monthLabel: label, paid: paid, pending: pending));
      } else {
        // Past months — no data available, show empty bar
        points.add(BillingTrendPoint(
            monthLabel: label, paid: 0, pending: 0));
      }
    }
    return points;
  }

  // ── Export ────────────────────────────────────────────────────────────────
  // format: 'Excel' | 'PDF'

  Future<void> exportReport(String format) async {
    if (_filtered.isEmpty) {
      _exportError = 'No data available to export.';
      notifyListeners();
      return;
    }
    _isExporting = true;
    notifyListeners();

    try {
      final rows = _filtered.map((inv) => {
        'Invoice #':    inv.invoiceNumber,
        'Date':         inv.date.toIso8601String(),
        'Vehicle':      inv.vehiclePlate,
        'Department':   inv.department,
        'Amount (SAR)': inv.amount,
        'Status':       inv.status.label,
      }).toList();

      final summary = _overview == null ? null : {
        'Month':        _overview!.monthLabel,
        'Total Billed': _overview!.totalBilled,
        'Total Paid':   _overview!.totalPaid,
        'Outstanding':  _overview!.outstanding,
        'Wallet Used':  _overview!.walletUsed,
      };

      final now     = DateTime.now();
      final month   = _filters.month ?? now.month;
      final year    = _filters.year  ?? now.year;
      final from    = DateTime(year, month, 1);
      final to      = DateTime(year, month + 1, 0); // last day of month
      final title   = 'Monthly Billing – ${_overview?.monthLabel ?? monthName(month)}';
      final sub     = _overview != null
          ? 'Due: ${_overview!.dueDate.toIso8601String().split('T').first}  |  '
          'Total Billed: SAR ${_overview!.totalBilled.toStringAsFixed(2)}'
          : null;

      if (format == 'PDF') {
        _exportError = null;
        await PdfExportService.exportFromList(
          title:    title,
          subtitle: sub,
          rows:     rows,
          fromDate: from,
          toDate:   to,
          summary:  summary,
        );
      } else {
        _exportError = null;
        await ExcelExportService.exportFromList(
          title:    title,
          rows:     rows,
          fromDate: from,
          toDate:   to,
          summary:  summary,
        );
      }

      debugPrint('[MonthlyBillingReportViewModel] export done format=$format');
    } on ExcelExportException catch (e) {
      _exportError = e.message;
      debugPrint('[MonthlyBillingReportViewModel] no data: ${e.message}');
    } on PdfExportException catch (e) {
      _exportError = e.message;
      debugPrint('[MonthlyBillingReportViewModel] no data: ${e.message}');
    } catch (e) {
      _exportError = 'Export failed. Please try again.';
      debugPrint('[MonthlyBillingReportViewModel] export error: $e');
    }

    _isExporting = false;
    notifyListeners();
  }

  // ── Pay outstanding ───────────────────────────────────────────────────────

  Future<void> payOutstanding() async {
    _isPayingOutstanding = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1500));
    // TODO: real payment API
    _isPayingOutstanding = false;
    notifyListeners();
    await _load(); // refresh after payment
  }
}