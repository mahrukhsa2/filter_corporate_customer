import 'package:flutter/material.dart';
import '../../../models/payment_history_report_model.dart';

enum PHLoadStatus { idle, loading, loaded }

class PaymentHistoryReportViewModel extends ChangeNotifier {
  PHLoadStatus _status = PHLoadStatus.idle;
  bool _isExporting    = false;

  List<PaymentHistoryItem> _all      = [];
  List<PaymentHistoryItem> _filtered = [];
  PaymentHistorySummary?   _summary;
  PaymentHistoryFilters    _filters  = const PaymentHistoryFilters();

  bool get isLoading   => _status == PHLoadStatus.loading;
  bool get isExporting => _isExporting;
  List<PaymentHistoryItem> get items   => _filtered;
  PaymentHistorySummary?   get summary => _summary;
  PaymentHistoryFilters    get filters => _filters;

  PaymentHistoryReportViewModel() { _load(); }

  Future<void> _load() async {
    _status = PHLoadStatus.loading;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    _all = [
      PaymentHistoryItem(
        id: 'p01', date: DateTime(2026, 2, 12), amount: 285,
        method: PaymentMethod.wallet,
        invoiceRef: 'INV-7845', status: PaymentStatus.paid,
        reference: 'WAL-98765', actionType: PaymentActionType.viewReceipt,
      ),
      PaymentHistoryItem(
        id: 'p02', date: DateTime(2026, 2, 10), amount: 10000,
        method: PaymentMethod.creditCard,
        invoiceRef: 'Top-up', status: PaymentStatus.success,
        reference: 'TXN-45678', actionType: PaymentActionType.viewReceipt,
      ),
      PaymentHistoryItem(
        id: 'p03', date: DateTime(2026, 2, 5), amount: 2450,
        method: PaymentMethod.bankTransfer,
        invoiceRef: 'INV-7844', status: PaymentStatus.paid,
        reference: 'REF-12345', actionType: PaymentActionType.viewProof,
      ),
      PaymentHistoryItem(
        id: 'p04', date: DateTime(2026, 1, 28), amount: 740,
        method: PaymentMethod.wallet,
        invoiceRef: 'INV-7831', status: PaymentStatus.paid,
        reference: 'WAL-97200', actionType: PaymentActionType.viewReceipt,
      ),
      PaymentHistoryItem(
        id: 'p05', date: DateTime(2026, 1, 20), amount: 15000,
        method: PaymentMethod.bankTransfer,
        invoiceRef: 'Top-up', status: PaymentStatus.success,
        reference: 'REF-11900', actionType: PaymentActionType.viewProof,
      ),
      PaymentHistoryItem(
        id: 'p06', date: DateTime(2026, 1, 15), amount: 435,
        method: PaymentMethod.creditCard,
        invoiceRef: 'INV-7820', status: PaymentStatus.paid,
        reference: 'TXN-44100', actionType: PaymentActionType.viewReceipt,
      ),
      PaymentHistoryItem(
        id: 'p07', date: DateTime(2026, 1, 10), amount: 180,
        method: PaymentMethod.cash,
        invoiceRef: 'INV-7812', status: PaymentStatus.paid,
        reference: 'CSH-00481', actionType: PaymentActionType.viewInvoice,
      ),
      PaymentHistoryItem(
        id: 'p08', date: DateTime(2026, 1, 5), amount: 20000,
        method: PaymentMethod.creditCard,
        invoiceRef: 'Top-up', status: PaymentStatus.success,
        reference: 'TXN-43500', actionType: PaymentActionType.viewReceipt,
      ),
      PaymentHistoryItem(
        id: 'p09', date: DateTime(2025, 12, 28), amount: 650,
        method: PaymentMethod.wallet,
        invoiceRef: 'INV-7798', status: PaymentStatus.paid,
        reference: 'WAL-96400', actionType: PaymentActionType.viewReceipt,
      ),
      PaymentHistoryItem(
        id: 'p10', date: DateTime(2025, 12, 20), amount: 920,
        method: PaymentMethod.bankTransfer,
        invoiceRef: 'INV-7785', status: PaymentStatus.paid,
        reference: 'REF-11200', actionType: PaymentActionType.viewProof,
      ),
      PaymentHistoryItem(
        id: 'p11', date: DateTime(2025, 12, 15), amount: 340,
        method: PaymentMethod.wallet,
        invoiceRef: 'INV-7770', status: PaymentStatus.pending,
        reference: 'WAL-95800', actionType: PaymentActionType.viewInvoice,
      ),
      PaymentHistoryItem(
        id: 'p12', date: DateTime(2025, 12, 8), amount: 448,
        method: PaymentMethod.creditCard,
        invoiceRef: 'INV-7761', status: PaymentStatus.failed,
        reference: 'TXN-42100', actionType: PaymentActionType.viewReceipt,
      ),
    ];

    _filtered = List.from(_all);
    _summary  = _buildSummary(_all);
    _status   = PHLoadStatus.loaded;
    notifyListeners();
  }

  Future<void> refresh() => _load();

  void updateFilters(PaymentHistoryFilters f) {
    _filters = f;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _filters  = const PaymentHistoryFilters();
    _filtered = List.from(_all);
    notifyListeners();
  }

  void _applyFilters() {
    _filtered = _all.where((p) {
      if (_filters.fromDate != null &&
          p.date.isBefore(_filters.fromDate!)) return false;
      if (_filters.toDate != null &&
          p.date.isAfter(
              _filters.toDate!.add(const Duration(days: 1)))) return false;
      if (_filters.method != null && p.method != _filters.method)
        return false;
      if (_filters.status != null && p.status != _filters.status)
        return false;
      return true;
    }).toList();
  }

  PaymentHistorySummary _buildSummary(List<PaymentHistoryItem> list) {
    double total    = 0, wallet = 0, card = 0, transfer = 0, cash = 0;
    for (final p in list) {
      total += p.amount;
      switch (p.method) {
        case PaymentMethod.wallet:       wallet   += p.amount; break;
        case PaymentMethod.creditCard:   card     += p.amount; break;
        case PaymentMethod.bankTransfer: transfer += p.amount; break;
        case PaymentMethod.cash:         cash     += p.amount; break;
      }
    }
    return PaymentHistorySummary(
      totalPaid:         total,
      byWallet:          wallet,
      byCard:            card,
      byTransfer:        transfer,
      byCash:            cash,
      totalTransactions: list.length,
    );
  }

  Future<void> exportReport() async {
    _isExporting = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _isExporting = false;
    notifyListeners();
  }
}
