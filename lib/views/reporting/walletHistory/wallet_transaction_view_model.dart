import 'package:flutter/material.dart';

import '../../../data/network/api_constants.dart';
import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../models/wallet_transaction_model.dart';
import '../../../services/excel_export_service.dart';
import '../../../services/pdf_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/features/wallet/transactions/wallet_transaction_view_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum WTLoadStatus { idle, loading, loaded, error }

class WalletTransactionViewModel extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────
  WTLoadStatus _loadStatus  = WTLoadStatus.idle;
  bool         _isExporting    = false;
  String?      _exportError;
  bool         _isTableLoading = false; // filter/refetch — does NOT rebuild the whole screen
  String?      _errorMessage;

  List<WalletTransaction>  _all      = [];
  List<WalletTransaction>  _filtered = [];
  WalletSummary?           _summary;
  WalletTransactionFilters _filters  = const WalletTransactionFilters();

  // Pagination
  int _total  = 0;
  int _offset = 0;
  static const int _limit = 20;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading   => _loadStatus == WTLoadStatus.loading;
  bool get isExporting    => _isExporting;
  String? get exportError      => _exportError;
  bool get isTableLoading => _isTableLoading;
  bool get hasError    => _loadStatus == WTLoadStatus.error;
  String? get errorMessage => _errorMessage;

  List<WalletTransaction>  get items   => _filtered;
  WalletSummary?           get summary => _summary;
  WalletTransactionFilters get filters => _filters;

  bool get hasMore => _all.length < _total;

  // ── Init ──────────────────────────────────────────────────────────────────
  WalletTransactionViewModel() {
    _loadAll();
  }

  // ── Public ────────────────────────────────────────────────────────────────

  Future<void> refresh() => _loadAll();

  void updateFilters(WalletTransactionFilters f) {
    _filters = f;
    _fetchHistoryForFilter();
  }

  void clearFilters() {
    _filters = const WalletTransactionFilters();
    _fetchHistoryForFilter();
  }

  /// Refetch only the table rows when a filter changes.
  /// The balance card and summary section are NOT touched.
  Future<void> _fetchHistoryForFilter() async {
    _isTableLoading = true;
    notifyListeners();
    await _fetchHistory(reset: true, silent: true);
    _isTableLoading = false;
    notifyListeners();
  }

  Future<void> exportReport(String format) async {
    if (_filtered.isEmpty) {
      _exportError = 'No data available to export.';
      notifyListeners();
      return;
    }
    _isExporting = true;
    notifyListeners();

    try {
      final rows = _filtered.map((t) => {
        'Date':          t.date.toIso8601String(),
        'Description':   t.description,
        'Type':          t.type.label,
        'Amount (SAR)':  t.amount,
        'Balance After': t.balanceAfter,
        'Reference':     t.referenceNumber ?? '—',
      }).toList();

      final summary = _summary == null ? null : {
        'Current Balance': _summary!.currentBalance,
        'Total Top-ups':   _summary!.totalTopUps,
        'Total Spent':     _summary!.totalSpent,
        'Net Movement':    _summary!.netMovement,
      };

      final from = _filters.fromDate ?? DateTime.now().subtract(const Duration(days: 30));
      final to   = _filters.toDate   ?? DateTime.now();

      if (format == 'PDF') {
        _exportError = null;
        await PdfExportService.exportFromList(
          title:    'Wallet Transaction History',
          rows:     rows,
          fromDate: from,
          toDate:   to,
          summary:  summary,
        );
      } else {
        _exportError = null;
        await ExcelExportService.exportFromList(
          title:    'Wallet Transaction History',
          rows:     rows,
          fromDate: from,
          toDate:   to,
          summary:  summary,
        );
      }

      debugPrint('[WalletTransactionVM] export done format=$format');
    } on ExcelExportException catch (e) {
      _exportError = e.message;
      debugPrint('[WalletTransactionVM] no data: ${e.message}');
    } on PdfExportException catch (e) {
      _exportError = e.message;
      debugPrint('[WalletTransactionVM] no data: ${e.message}');
    } catch (e) {
      _exportError = 'Export failed. Please try again.';
      debugPrint('[WalletTransactionVM] export error: $e');
    }

    _isExporting = false;
    notifyListeners();
  }

  // ── Orchestrate ───────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    _loadStatus   = WTLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // Fire both APIs in parallel
    await Future.wait([
      _fetchSummary(),
      _fetchHistory(reset: true, silent: true),
    ]);

    _loadStatus = WTLoadStatus.loaded;
    notifyListeners();
  }

  // ── Summary — via WalletRepository ───────────────────────────────────────
  // GET /corporate/wallet/summary
  // { success, totalTopups, totalSpent, netMovement, currentBalance }

  Future<void> _fetchSummary() async {
    final res = await WalletRepository.fetchSummary();

    if (res.success && res.data != null) {
      final m = res.data!;
      _summary = WalletSummary(
        currentBalance: m.currentBalance,
        totalTopUps:    m.totalTopups,
        totalSpent:     m.totalSpent,
        netMovement:    m.netMovement,
      );
    } else {
      debugPrint('[WalletTransactionVM] summary error: ${res.message}');
      // Don't fail the whole screen — history currentBalance used as fallback
    }
  }

  // ── History — via BaseApiService ──────────────────────────────────────────
  // GET /corporate/wallet/history?startDate&endDate&type&minAmount&maxAmount&limit&offset
  // { success, transactions[], total, currentBalance }

  Future<void> _fetchHistory({
    bool reset  = false,
    bool silent = false,
  }) async {
    if (!silent) {
      _loadStatus = WTLoadStatus.loading;
      notifyListeners();
    }

    if (reset) {
      _offset = 0;
      _all    = [];
    }

    final res = await BaseApiService.get(
      ApiConstants.walletHistory,
      queryParams: _buildQueryParams(),
    );

    if (res.success && res.data != null) {
      final d = res.data!;
      _total  = (d['total'] as num?)?.toInt() ?? 0;

      // Fallback: use currentBalance from history if summary failed
      if (_summary == null) {
        _summary = WalletSummary(
          currentBalance: (d['currentBalance'] as num?)?.toDouble() ?? 0.0,
          totalTopUps:    0,
          totalSpent:     0,
          netMovement:    0,
        );
      }

      final rawList = d['transactions'];
      if (rawList is List) {
        final parsed = rawList
            .whereType<Map<String, dynamic>>()
            .map(_parseTransaction)
            .whereType<WalletTransaction>()
            .toList();

        _all    = reset ? parsed : [..._all, ...parsed];
        _offset = _all.length;
      }


      _applyLocalFilters();
      _loadStatus   = WTLoadStatus.loaded;
      _errorMessage = null;
    } else {
      _loadStatus   = WTLoadStatus.error;
      _errorMessage = res.message ?? 'Failed to load transactions.';
      debugPrint('[WalletTransactionVM] history error: ${res.message}');
    }

    if (!silent) notifyListeners();
  }

  // ── Build query params from current filters ───────────────────────────────

  Map<String, String> _buildQueryParams() {
    // NOTE: The backend expects limit/offset as integers but Prisma throws
    // when they arrive as query-string values ("0" instead of 0).
    // Omitting them lets the backend apply its own defaults until the backend
    // adds parseInt() on its side.
    final params = <String, String>{};

    if (_filters.fromDate != null) {
      params['startDate'] =
          _filters.fromDate!.toIso8601String().split('T').first;
    }
    if (_filters.toDate != null) {
      params['endDate'] =
          _filters.toDate!.toIso8601String().split('T').first;
    }
    if (_filters.type != null) {
      // API accepts "credit" | "debit" only — topUp is a UI sub-type of credit
      params['type'] =
      _filters.type == WalletTransactionType.debit ? 'debit' : 'credit';
    }
    if (_filters.minAmount != null) {
      params['minAmount'] = _filters.minAmount!.toString();
    }
    if (_filters.maxAmount != null) {
      params['maxAmount'] = _filters.maxAmount!.toString();
    }

    return params;
  }

  // ── Local filter ──────────────────────────────────────────────────────────
  // topUp is UI-only (server returns it as "credit").
  // After the server responds with all credit rows, filter down to topUp only.

  void _applyLocalFilters() {
    if (_filters.type == WalletTransactionType.topUp) {
      _filtered = _all
          .where((t) => t.type == WalletTransactionType.topUp)
          .toList();
    } else {
      _filtered = List.from(_all);
    }
  }

  // ── Parse a single transaction map ────────────────────────────────────────

  WalletTransaction? _parseTransaction(Map<String, dynamic> map) {
    try {
      // Type
      final rawType = (map['type'] ??
          map['transaction_type'] ??
          map['transactionType'] ??
          '')
          .toString()
          .toLowerCase();

      WalletTransactionType type;
      if (rawType == 'topup' || rawType == 'top_up' || rawType == 'top-up') {
        type = WalletTransactionType.topUp;
      } else if (rawType == 'credit') {
        type = WalletTransactionType.credit;
      } else {
        type = WalletTransactionType.debit;
      }

      // Date
      final rawDate = map['date'] ??
          map['created_at'] ??
          map['createdAt'] ??
          map['transaction_date'];
      DateTime date;
      try {
        date = rawDate != null
            ? DateTime.parse(rawDate.toString())
            : DateTime.now();
      } catch (_) {
        date = DateTime.now();
      }

      // Description
      final description = (map['description'] ??
          map['note'] ??
          map['remarks'] ??
          map['narration'] ??
          'Transaction')
          .toString();

      // Amount (always positive — sign from type)
      final amount = ((map['amount'] as num?)?.toDouble() ?? 0.0).abs();

      // Balance after
      final balanceAfter =
          ((map['balance_after'] ?? map['balanceAfter'] ?? map['balance'])
          as num?)
              ?.toDouble() ??
              0.0;

      return WalletTransaction(
        id:              map['id']?.toString() ?? '',
        date:            date,
        description:     description,
        amount:          amount,
        type:            type,
        balanceAfter:    balanceAfter,
        referenceNumber: (map['reference_number'] ??
            map['referenceNumber'] ??
            map['invoice_number'] ??
            map['invoiceNumber'] ??
            map['ref'])
            ?.toString(),
      );
    } catch (e) {
      debugPrint('[WalletTransactionVM] _parseTransaction error: $e');
      return null;
    }
  }
}