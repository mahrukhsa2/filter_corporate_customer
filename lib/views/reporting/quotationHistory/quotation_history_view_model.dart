import 'package:flutter/material.dart';

import '../../../models/quotation_history_model.dart';

enum QHLoadStatus { idle, loading, loaded }

class QuotationHistoryViewModel extends ChangeNotifier {
  QHLoadStatus _loadStatus = QHLoadStatus.idle;
  bool _isExporting = false;

  List<QuotationHistoryItem> _all     = [];
  List<QuotationHistoryItem> _filtered = [];
  QuotationHistorySummary?   _summary;
  QuotationHistoryFilters    _filters = const QuotationHistoryFilters();

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading   => _loadStatus == QHLoadStatus.loading;
  bool get isExporting => _isExporting;
  List<QuotationHistoryItem> get items => _filtered;
  QuotationHistorySummary? get summary => _summary;
  QuotationHistoryFilters  get filters => _filters;

  final List<String> submittedByOptions = [
    'Ahmed Al-Rashid',
    'Sara Mohammed',
    'Khalid Ibrahim',
    'All',
  ];

  QuotationHistoryViewModel() { _load(); }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    _loadStatus = QHLoadStatus.loading;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    // ── Dummy data – replace with real API ────────────────────────────────
    _all = [
      QuotationHistoryItem(
        quotationNumber: 'Q-4567', date: DateTime(2026, 2, 10),
        productService: '5W-30 Engine Oil', qty: '10 L',
        quotedPrice: 29.50, unit: '/L',
        status: QuotationStatus.approved, submittedBy: 'Ahmed Al-Rashid',
      ),
      QuotationHistoryItem(
        quotationNumber: 'Q-4566', date: DateTime(2026, 2, 8),
        productService: 'Brake Pads (Front)', qty: '4 pcs',
        quotedPrice: 220, unit: '/set',
        status: QuotationStatus.rejected,
        rejectionReason: 'Price exceeds approved corporate rate for this product.',
        submittedBy: 'Sara Mohammed',
      ),
      QuotationHistoryItem(
        quotationNumber: 'Q-4565', date: DateTime(2026, 2, 5),
        productService: 'Full Car Wash', qty: '1',
        quotedPrice: 150, unit: '',
        status: QuotationStatus.pending, submittedBy: 'Khalid Ibrahim',
      ),
      QuotationHistoryItem(
        quotationNumber: 'Q-4564', date: DateTime(2026, 1, 28),
        productService: 'Air Filter', qty: '6 pcs',
        quotedPrice: 72, unit: '/pc',
        status: QuotationStatus.approved, submittedBy: 'Ahmed Al-Rashid',
      ),
      QuotationHistoryItem(
        quotationNumber: 'Q-4563', date: DateTime(2026, 1, 22),
        productService: 'Coolant 1L', qty: '20 L',
        quotedPrice: 14.50, unit: '/L',
        status: QuotationStatus.approved, submittedBy: 'Sara Mohammed',
      ),
      QuotationHistoryItem(
        quotationNumber: 'Q-4562', date: DateTime(2026, 1, 18),
        productService: 'Wiper Blades', qty: '10 pair',
        quotedPrice: 44, unit: '/pair',
        status: QuotationStatus.rejected,
        rejectionReason: 'Requested quantity exceeds monthly limit.',
        submittedBy: 'Khalid Ibrahim',
      ),
      QuotationHistoryItem(
        quotationNumber: 'Q-4561', date: DateTime(2026, 1, 15),
        productService: 'Transmission Fluid', qty: '8 L',
        quotedPrice: 34, unit: '/L',
        status: QuotationStatus.approved, submittedBy: 'Ahmed Al-Rashid',
      ),
      QuotationHistoryItem(
        quotationNumber: 'Q-4560', date: DateTime(2026, 1, 10),
        productService: 'Spark Plugs', qty: '16 pcs',
        quotedPrice: 28, unit: '/pc',
        status: QuotationStatus.pending, submittedBy: 'Sara Mohammed',
      ),
      QuotationHistoryItem(
        quotationNumber: 'Q-4559', date: DateTime(2026, 1, 5),
        productService: 'Oil Filter', qty: '12 pcs',
        quotedPrice: 38.50, unit: '/pc',
        status: QuotationStatus.approved, submittedBy: 'Khalid Ibrahim',
      ),
      QuotationHistoryItem(
        quotationNumber: 'Q-4558', date: DateTime(2025, 12, 28),
        productService: 'Brake Pads (Rear)', qty: '4 pcs',
        quotedPrice: 160, unit: '/set',
        status: QuotationStatus.pending, submittedBy: 'Ahmed Al-Rashid',
      ),
      QuotationHistoryItem(
        quotationNumber: 'Q-4557', date: DateTime(2025, 12, 20),
        productService: '10W-40 Engine Oil', qty: '30 L',
        quotedPrice: 25, unit: '/L',
        status: QuotationStatus.approved, submittedBy: 'Sara Mohammed',
      ),
      QuotationHistoryItem(
        quotationNumber: 'Q-4556', date: DateTime(2025, 12, 15),
        productService: 'Mobil 1 5W-30', qty: '15 L',
        quotedPrice: 65, unit: '/L',
        status: QuotationStatus.rejected,
        rejectionReason: 'Product not listed in corporate catalogue.',
        submittedBy: 'Khalid Ibrahim',
      ),
    ];

    _filtered = List.from(_all);
    _summary  = _buildSummary(_all);
    _loadStatus = QHLoadStatus.loaded;
    notifyListeners();
  }

  Future<void> refresh() => _load();

  // ── Filters ───────────────────────────────────────────────────────────────
  void updateFilters(QuotationHistoryFilters f) {
    _filters  = f;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _filters  = const QuotationHistoryFilters();
    _filtered = List.from(_all);
    notifyListeners();
  }

  void _applyFilters() {
    _filtered = _all.where((item) {
      if (_filters.fromDate != null &&
          item.date.isBefore(_filters.fromDate!)) return false;
      if (_filters.toDate != null &&
          item.date.isAfter(_filters.toDate!.add(const Duration(days: 1))))
        return false;
      if (_filters.productQuery != null &&
          _filters.productQuery!.isNotEmpty &&
          !item.productService.toLowerCase()
              .contains(_filters.productQuery!.toLowerCase())) return false;
      if (_filters.status != null && item.status != _filters.status)
        return false;
      if (_filters.submittedBy != null &&
          _filters.submittedBy != 'All' &&
          item.submittedBy != _filters.submittedBy) return false;
      return true;
    }).toList();
  }

  // ── Export ────────────────────────────────────────────────────────────────
  Future<void> exportReport() async {
    _isExporting = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    // TODO: real export API
    _isExporting = false;
    notifyListeners();
  }

  // ── Summary builder ───────────────────────────────────────────────────────
  QuotationHistorySummary _buildSummary(List<QuotationHistoryItem> list) {
    return QuotationHistorySummary(
      total:    list.length,
      approved: list.where((i) => i.status == QuotationStatus.approved).length,
      rejected: list.where((i) => i.status == QuotationStatus.rejected).length,
      pending:  list.where((i) => i.status == QuotationStatus.pending).length,
      totalQuotedValue: list.fold(
          0, (s, i) => s + (i.quotedPrice * (double.tryParse(i.qty.split(' ').first) ?? 1))),
    );
  }
}
