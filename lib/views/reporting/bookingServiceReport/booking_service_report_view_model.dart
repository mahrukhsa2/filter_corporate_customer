import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/app_cache.dart';
import '../../../data/network/api_constants.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/base_api_service.dart';
import '../../../models/booking_service_report_model.dart';
import '../../../models/branch_model.dart';
import '../../../services/excel_export_service.dart';
import '../../../widgets/app_alert.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/features/reports/booking/booking_service_report_view_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum BSLoadStatus { idle, loading, loaded, error }

class BookingServiceReportViewModel extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────
  BSLoadStatus _status        = BSLoadStatus.idle;
  bool         _isTableLoading = false; // filter refetch — does NOT rebuild whole screen
  bool         _isExporting   = false;
  String?      _exportError;
  String?      _errorMessage;

  List<BookingServiceItem>  _all      = [];
  List<BookingServiceItem>  _filtered = [];
  BookingServiceSummary?    _summary;
  BookingServiceFilters     _filters  = const BookingServiceFilters();

  // ── Branches from AppCache (same source as BookingScreen) ─────────────────
  List<BranchModel> get branchModels => AppCache.allowedBranches;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading      => _status == BSLoadStatus.loading;
  bool get isTableLoading => _isTableLoading;
  bool get isExporting    => _isExporting;
  String? get exportError  => _exportError;
  bool get hasError       => _status == BSLoadStatus.error;
  String? get errorMessage => _errorMessage;

  List<BookingServiceItem> get items   => _filtered;
  BookingServiceSummary?   get summary => _summary;
  BookingServiceFilters    get filters => _filters;

  // ── Init ──────────────────────────────────────────────────────────────────
  BookingServiceReportViewModel() {
    _load();
  }

  // ── Public ────────────────────────────────────────────────────────────────

  Future<void> refresh({BuildContext? context}) => _load(context: context);

  void updateFilters(BookingServiceFilters f, {BuildContext? context}) {
    _filters = f;
    _fetchForFilter(context: context);
  }

  void clearFilters({BuildContext? context}) {
    _filters = const BookingServiceFilters();
    _fetchForFilter(context: context);
  }

  Future<void> exportReport() async {
    if (_filtered.isEmpty) {
      _exportError = 'No data available to export.';
      notifyListeners();
      return;
    }
    _isExporting = true;
    notifyListeners();

    try {
      // Use current filtered list — reflects whatever filters are active
      final rows = _filtered.map((item) => {
        'Booking ID':   item.bookingId,
        'Date':         item.date.toIso8601String(),
        'Vehicle':      item.vehiclePlate,
        'Department':   item.department,
        'Amount (SAR)': item.amount ?? 0,
        'Status':       item.status.name,
      }).toList();

      final summary = _summary == null ? null : {
        'Total':       _summary!.totalBookings,
        'Completed':   _summary!.completed,
        'In Progress': _summary!.inProgress,
        'Pending':     _summary!.pending,
        'Cancelled':   _summary!.cancelled,
        'Total Spend': _summary!.totalSpend,
      };

      _exportError = null;
      await ExcelExportService.exportFromList(
        title:    'Booking & Service History',
        rows:     rows,
        fromDate: _filters.fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
        toDate:   _filters.toDate   ?? DateTime.now(),
        summary:  summary,
      );

      debugPrint('[BookingServiceReportVM] export done');
    } on ExcelExportException catch (e) {
      _exportError = e.message;
      debugPrint('[BookingServiceReportVM] no data: ${e.message}');
    } catch (e) {
      _exportError = 'Export failed. Please try again.';
      debugPrint('[BookingServiceReportVM] export error: $e');
    }

    _isExporting = false;
    notifyListeners();
  }

  // ── Initial full load ─────────────────────────────────────────────────────

  Future<void> _load({BuildContext? context}) async {
    _status       = BSLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await _fetchHistory(reset: true, silent: true, context: context);

    _status = BSLoadStatus.loaded;
    notifyListeners();
  }

  // ── Filter-triggered refetch — only the table spins ───────────────────────

  Future<void> _fetchForFilter({BuildContext? context}) async {
    _isTableLoading = true;
    notifyListeners();
    await _fetchHistory(reset: true, silent: true, context: context);
    _isTableLoading = false;
    notifyListeners();
  }

  // ── Core fetch ────────────────────────────────────────────────────────────
  // GET /corporate/reports/history
  // Params: status, startDate, endDate, branchId
  // (limit/offset omitted — backend parses as string, causing errors)

  Future<void> _fetchHistory({
    bool reset          = false,
    bool silent         = false,
    BuildContext? context,
  }) async {
    if (!silent) {
      _status = BSLoadStatus.loading;
      notifyListeners();
    }

    if (reset) _all = [];

    final res = await BaseApiService.get(
      ApiConstants.reportsBookingServiceHistory,
      queryParams: _buildQueryParams(),
      requiresAuth: true,
    );

    debugPrint('[BookingServiceReportVM] fetchHistory ← '
        'success=${res.success} status=${res.statusCode}');

    if (res.success && res.data != null) {
      final rawList = res.data!['history'];
      if (rawList is List) {
        _all = rawList
            .whereType<Map<String, dynamic>>()
            .map(_parseItem)
            .whereType<BookingServiceItem>()
            .toList();
      }

      _filtered     = List.from(_all);
      _summary      = _buildSummary(_all);
      _status       = BSLoadStatus.loaded;
      _errorMessage = null;

      debugPrint('[BookingServiceReportVM] loaded ${_all.length} items');
    } else {
      _status       = BSLoadStatus.error;
      _errorMessage = res.message ?? 'Failed to load booking history.';
      debugPrint('[BookingServiceReportVM] error: ${res.message}');

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: res.errorType,
          message:   res.message,
          onRetry: res.errorType == ApiErrorType.noInternet ||
              res.errorType == ApiErrorType.timeout
              ? () => _load(context: context)
              : null,
        );
      }
    }

    if (!silent) notifyListeners();
  }

  // ── Build query params ────────────────────────────────────────────────────

  Map<String, String> _buildQueryParams() {
    final params = <String, String>{};

    if (_filters.fromDate != null) {
      params['startDate'] =
          _filters.fromDate!.toIso8601String().split('T').first;
    }
    if (_filters.toDate != null) {
      params['endDate'] =
          _filters.toDate!.toIso8601String().split('T').first;
    }
    if (_filters.status != null) {
      // Map enum → API string value
      params['status'] = _statusToApiString(_filters.status!);
    }
    if (_filters.branchId != null) {
      params['branchId'] = _filters.branchId!;
    }

    return params;
  }

  String _statusToApiString(BookingStatus s) {
    switch (s) {
      case BookingStatus.completed:  return 'completed';
      case BookingStatus.inProgress: return 'in_progress';
      case BookingStatus.cancelled:  return 'cancelled';
      case BookingStatus.pending:    return 'pending';
      case BookingStatus.submitted:  return 'submitted';
      case BookingStatus.draft:      return 'draft';
    }
  }

  // ── Parse a single history item ───────────────────────────────────────────

  BookingServiceItem? _parseItem(Map<String, dynamic> map) {
    try {
      return BookingServiceItem.fromApiMap(map);
    } catch (e) {
      debugPrint('[BookingServiceReportVM] _parseItem error: $e');
      return null;
    }
  }

  // ── Build summary from loaded list ────────────────────────────────────────

  BookingServiceSummary _buildSummary(List<BookingServiceItem> list) {
    int completed = 0, inProgress = 0, cancelled = 0, pending = 0, submitted = 0;
    double spend = 0;
    for (final b in list) {
      switch (b.status) {
        case BookingStatus.completed:  completed++;  break;
        case BookingStatus.inProgress: inProgress++; break;
        case BookingStatus.cancelled:  cancelled++;  break;
        case BookingStatus.submitted:  submitted++;  break;
        case BookingStatus.pending:
        case BookingStatus.draft:      pending++;    break;
      }
      if (b.amount != null) spend += b.amount!;
    }
    return BookingServiceSummary(
      totalBookings: list.length,
      completed:     completed,
      inProgress:    inProgress,
      cancelled:     cancelled,
      pending:       pending,
      submitted:     submitted,
      totalSpend:    spend,
    );
  }
}