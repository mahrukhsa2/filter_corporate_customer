import 'package:flutter/material.dart';

import '../../../models/wallet_transaction_model.dart';

enum WTLoadStatus { idle, loading, loaded }

class WalletTransactionViewModel extends ChangeNotifier {
  WTLoadStatus _loadStatus = WTLoadStatus.idle;
  bool _isExporting = false;

  List<WalletTransaction> _all      = [];
  List<WalletTransaction> _filtered = [];
  WalletSummary?          _summary;
  WalletTransactionFilters _filters = const WalletTransactionFilters();

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading   => _loadStatus == WTLoadStatus.loading;
  bool get isExporting => _isExporting;
  List<WalletTransaction> get items => _filtered;
  WalletSummary? get summary        => _summary;
  WalletTransactionFilters get filters => _filters;

  WalletTransactionViewModel() { _load(); }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    _loadStatus = WTLoadStatus.loading;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    // ── Dummy data – replace with real API ────────────────────────────────
    _all = [
      WalletTransaction(
        id: 'wt-001', date: DateTime(2026, 2, 12),
        description: 'Oil Change Invoice Payment',
        amount: 285, type: WalletTransactionType.debit,
        balanceAfter: 12165, referenceNumber: 'INV-8821',
      ),
      WalletTransaction(
        id: 'wt-002', date: DateTime(2026, 2, 10),
        description: 'Wallet Top-up via Card',
        amount: 10000, type: WalletTransactionType.topUp,
        balanceAfter: 12450, referenceNumber: 'RCP-3310',
      ),
      WalletTransaction(
        id: 'wt-003', date: DateTime(2026, 2, 5),
        description: 'Full Service Payment',
        amount: 2450, type: WalletTransactionType.debit,
        balanceAfter: 2450, referenceNumber: 'INV-8810',
      ),
      WalletTransaction(
        id: 'wt-004', date: DateTime(2026, 1, 28),
        description: 'Brake Pad Replacement',
        amount: 740, type: WalletTransactionType.debit,
        balanceAfter: 4900, referenceNumber: 'INV-8799',
      ),
      WalletTransaction(
        id: 'wt-005', date: DateTime(2026, 1, 20),
        description: 'Wallet Top-up via Bank Transfer',
        amount: 15000, type: WalletTransactionType.topUp,
        balanceAfter: 5640, referenceNumber: 'RCP-3280',
      ),
      WalletTransaction(
        id: 'wt-006', date: DateTime(2026, 1, 15),
        description: 'Air Filter & Oil Filter',
        amount: 435, type: WalletTransactionType.debit,
        balanceAfter: 9360, referenceNumber: 'INV-8785',
      ),
      WalletTransaction(
        id: 'wt-007', date: DateTime(2026, 1, 10),
        description: 'Tyre Rotation Service',
        amount: 180, type: WalletTransactionType.debit,
        balanceAfter: 9795, referenceNumber: 'INV-8770',
      ),
      WalletTransaction(
        id: 'wt-008', date: DateTime(2026, 1, 5),
        description: 'Wallet Top-up via Card',
        amount: 20000, type: WalletTransactionType.topUp,
        balanceAfter: 9975, referenceNumber: 'RCP-3250',
      ),
      WalletTransaction(
        id: 'wt-009', date: DateTime(2025, 12, 28),
        description: 'Full Detailing Package',
        amount: 650, type: WalletTransactionType.debit,
        balanceAfter: 10025, referenceNumber: 'INV-8755',
      ),
      WalletTransaction(
        id: 'wt-010', date: DateTime(2025, 12, 20),
        description: 'Cooling System Service',
        amount: 920, type: WalletTransactionType.debit,
        balanceAfter: 10675, referenceNumber: 'INV-8740',
      ),
      WalletTransaction(
        id: 'wt-011', date: DateTime(2025, 12, 15),
        description: 'Refund – Cancelled Booking',
        amount: 350, type: WalletTransactionType.credit,
        balanceAfter: 11595, referenceNumber: 'REF-0120',
      ),
      WalletTransaction(
        id: 'wt-012', date: DateTime(2025, 12, 8),
        description: 'Spark Plugs Replacement',
        amount: 448, type: WalletTransactionType.debit,
        balanceAfter: 11245, referenceNumber: 'INV-8720',
      ),
    ];

    _filtered = List.from(_all);
    _summary  = _buildSummary(_all);
    _loadStatus = WTLoadStatus.loaded;
    notifyListeners();
  }

  Future<void> refresh() => _load();

  // ── Filters ───────────────────────────────────────────────────────────────
  void updateFilters(WalletTransactionFilters f) {
    _filters = f;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _filters  = const WalletTransactionFilters();
    _filtered = List.from(_all);
    notifyListeners();
  }

  void _applyFilters() {
    _filtered = _all.where((t) {
      if (_filters.fromDate != null &&
          t.date.isBefore(_filters.fromDate!)) return false;
      if (_filters.toDate != null &&
          t.date.isAfter(
              _filters.toDate!.add(const Duration(days: 1)))) return false;
      if (_filters.type != null && t.type != _filters.type) return false;
      if (_filters.minAmount != null && t.amount < _filters.minAmount!)
        return false;
      if (_filters.maxAmount != null && t.amount > _filters.maxAmount!)
        return false;
      return true;
    }).toList();
  }

  // ── Export ────────────────────────────────────────────────────────────────
  Future<void> exportReport(String format) async {
    _isExporting = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    // TODO: real export API
    _isExporting = false;
    notifyListeners();
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  WalletSummary _buildSummary(List<WalletTransaction> list) {
    final topUps = list
        .where((t) => t.type == WalletTransactionType.topUp)
        .fold(0.0, (s, t) => s + t.amount);
    final spent = list
        .where((t) => t.type == WalletTransactionType.debit)
        .fold(0.0, (s, t) => s + t.amount);
    final credits = list
        .where((t) => t.type == WalletTransactionType.credit)
        .fold(0.0, (s, t) => s + t.amount);
    return WalletSummary(
      currentBalance: 12450,
      totalTopUps:    topUps,
      totalSpent:     spent,
      netMovement:    topUps + credits - spent,
    );
  }
}
