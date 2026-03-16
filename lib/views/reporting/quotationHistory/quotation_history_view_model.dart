import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/quotation_repository.dart';
import '../../../data/network/api_response.dart';
import '../../../models/quotation_history_model.dart';
import '../../../services/excel_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/QuotationHistory/quotation_history_view_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum QHLoadStatus { idle, loading, loaded, error }

class QuotationHistoryViewModel extends ChangeNotifier {

  // ── Load state ─────────────────────────────────────────────────────────────
  QHLoadStatus _loadStatus    = QHLoadStatus.idle;
  bool         _isFiltering   = false;  // silent reload — list stays visible
  bool         _isLoadingMore = false;
  bool         _isExporting   = false;
  String?      _exportError;
  String       _errorMessage  = '';

  // ── Data ───────────────────────────────────────────────────────────────────
  List<QuotationHistoryItem> _items   = [];
  QuotationHistorySummary?   _summary;
  QuotationHistoryFilters    _filters = const QuotationHistoryFilters();

  // ── Pagination ─────────────────────────────────────────────────────────────
  int  _total         = 0;
  int  _currentOffset = 0;
  final int _pageSize = 10;
  bool _hasMore       = true;

  // ── Debounce for search field ──────────────────────────────────────────────
  Timer? _searchDebounce;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading     => _loadStatus == QHLoadStatus.loading;
  bool get isFiltering   => _isFiltering;   // overlay spinner on table only
  bool get hasError      => _loadStatus == QHLoadStatus.error;
  bool get isLoadingMore => _isLoadingMore;
  bool get isExporting   => _isExporting;
  String? get exportError  => _exportError;
  bool get hasMore       => _hasMore;
  String get errorMessage => _errorMessage;

  List<QuotationHistoryItem> get items   => _items;
  QuotationHistorySummary?   get summary => _summary;
  QuotationHistoryFilters    get filters => _filters;
  int get total => _total;

  final List<String> submittedByOptions = [
    'All', 'Ahmed Al-Rashid', 'Sara Mohammed', 'Khalid Ibrahim',
  ];

  String monthName(int m) => const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
    'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];

  QuotationHistoryViewModel() {
    _loadInitial();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ── Initial load ───────────────────────────────────────────────────────────

  Future<void> _loadInitial({bool silent = false}) async {
    if (silent) {
      // Filtering: keep existing items visible, show small overlay spinner
      _isFiltering = true;
      notifyListeners();
    } else {
      _loadStatus = QHLoadStatus.loading;
      _items      = [];
      notifyListeners();
    }

    _currentOffset = 0;
    _hasMore       = true;

    // Fetch list + summary in parallel
    final results = await Future.wait([
      _fetchPage(offset: 0),
      QuotationRepository.fetchSummary(),
    ]);

    final summaryResult = results[1] as ApiResponse<QuotationHistorySummary>;
    if (summaryResult.success && summaryResult.data != null) {
      _summary = summaryResult.data;
      debugPrint('[QuotationHistoryVM] summary loaded: '
          'total=${_summary!.total} pending=${_summary!.pending}');
    }

    if (_loadStatus != QHLoadStatus.error) {
      _loadStatus = QHLoadStatus.loaded;
    }
    _isFiltering = false;
    notifyListeners();
  }

  // ── Fetch page ─────────────────────────────────────────────────────────────

  Future<void> _fetchPage({required int offset}) async {
    final result = await QuotationRepository.fetchQuotations(
      status:       _filters.status?.label,   // repo lowercases this
      startDate:    _filters.fromDate,
      endDate:      _filters.toDate,
      productQuery: _filters.productQuery,
    );

    if (result.success && result.data != null) {
      final data = result.data!;
      if (offset == 0) {
        _items = data.quotations;
      } else {
        _items.addAll(data.quotations);
      }
      _total         = data.total;
      _currentOffset = offset + data.quotations.length;
      _hasMore       = _items.length < _total;
      _loadStatus    = QHLoadStatus.loaded;
      debugPrint('[QuotationHistoryVM] page loaded: '
          '${data.quotations.length} items, total=$_total hasMore=$_hasMore');
    } else {
      debugPrint('[QuotationHistoryVM] API failed: ${result.message}');
      _errorMessage = result.message ?? 'Failed to load quotations.';
      _loadStatus   = QHLoadStatus.error;
    }
  }

  // ── Load more (pagination) ─────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || isLoading) return;
    _isLoadingMore = true;
    notifyListeners();
    await _fetchPage(offset: _currentOffset);
    _isLoadingMore = false;
    notifyListeners();
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    debugPrint('[QuotationHistoryVM] refresh');
    await _loadInitial();
  }

  // ── Filters ───────────────────────────────────────────────────────────────
  // ✅ Fix: use silent=true so the list doesn't blank out while reloading.
  // For the search field, debounce 500ms to avoid firing on every keystroke.

  Future<void> updateFilters(QuotationHistoryFilters f) async {
    final wasSearchChange = f.productQuery != _filters.productQuery;
    _filters = f;

    if (wasSearchChange) {
      // Debounce search — wait until user stops typing
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        _loadInitial(silent: true);
      });
    } else {
      // Instant for dropdowns/dates
      await _loadInitial(silent: true);
    }
  }

  Future<void> clearFilters() async {
    _searchDebounce?.cancel();
    _filters = const QuotationHistoryFilters();
    await _loadInitial(silent: true);
  }

  // ── Export ─────────────────────────────────────────────────────────────────

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
        'Quotation #':    item.quotationNumber,
        'Date':           item.date.toIso8601String(),
        'Product/Service': item.productService,
        'Qty':            item.qty,
        'Price (SAR)':    item.formattedPrice,
        'Status':         item.status.label,
      }).toList();

      final summary = _summary == null ? null : {
        'Total':         _summary!.total,
        'Approved':      _summary!.approved,
        'Pending':       _summary!.pending,
        'Rejected':      _summary!.rejected,
        'Total Value':   _summary!.totalQuotedValue,
      };

      _exportError = null;
      await ExcelExportService.exportFromList(
        title:    'Quotation History',
        rows:     rows,
        fromDate: _filters.fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
        toDate:   _filters.toDate   ?? DateTime.now(),
        summary:  summary,
      );

      debugPrint('[QuotationHistoryVM] export done');
    } on ExcelExportException catch (e) {
      _exportError = e.message;
      debugPrint('[QuotationHistoryVM] no data: ${e.message}');
    } catch (e) {
      _exportError = 'Export failed. Please try again.';
      debugPrint('[QuotationHistoryVM] export error: $e');
    }

    _isExporting = false;
    notifyListeners();
  }
}