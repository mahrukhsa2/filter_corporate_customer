import 'package:flutter/material.dart';

import '../../models/payment_model.dart';

enum PaymentLoadStatus { idle, loading, loaded }

class MakePaymentViewModel extends ChangeNotifier {
  // ── Load ──────────────────────────────────────────────────────────────────
  PaymentLoadStatus _loadStatus = PaymentLoadStatus.idle;
  PaymentConfirmStatus _confirmStatus = PaymentConfirmStatus.idle;
  String _errorMessage = '';

  // ── Data ──────────────────────────────────────────────────────────────────
  PaymentSummary? _summary;
  PaymentReceiptModel? _receipt;

  // ── Form state ────────────────────────────────────────────────────────────
  PaymentMethod _selectedMethod = PaymentMethod.wallet;
  bool _useWalletForPartial = false;
  double _walletAmountUsed = 0;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading => _loadStatus == PaymentLoadStatus.loading;
  bool get isProcessing => _confirmStatus == PaymentConfirmStatus.processing;
  bool get isSuccess => _confirmStatus == PaymentConfirmStatus.success;
  PaymentConfirmStatus get confirmStatus => _confirmStatus;
  String get errorMessage => _errorMessage;
  PaymentSummary? get summary => _summary;
  PaymentReceiptModel? get receipt => _receipt;
  PaymentMethod get selectedMethod => _selectedMethod;
  bool get useWalletForPartial => _useWalletForPartial;
  double get walletAmountUsed => _walletAmountUsed;

  double get remainingAmount =>
      _summary?.remaining(_walletAmountUsed) ?? 0;

  /// Show wallet partial section only when a non-wallet method is chosen
  bool get showWalletTopUp =>
      _selectedMethod != PaymentMethod.wallet &&
      (_summary?.walletBalance ?? 0) > 0;

  /// True when the form is ready to confirm
  bool get canConfirm => _summary != null && !isProcessing;

  MakePaymentViewModel({double? totalAmount, String? invoiceRef}) {
    _loadData(totalAmount: totalAmount, invoiceRef: invoiceRef);
  }

  // ── Load data ─────────────────────────────────────────────────────────────
  Future<void> _loadData({double? totalAmount, String? invoiceRef}) async {
    _loadStatus = PaymentLoadStatus.loading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // ── Dummy data – replace with real API / session data when ready ───────
    _summary = PaymentSummary(
      invoiceRef: invoiceRef ?? 'Billing',
      totalAmount: totalAmount ?? 48750,
      walletBalance: 12450,
    );

    // Default wallet amount = max usable when wallet method selected
    _walletAmountUsed = _summary!.maxWalletUsable;

    _loadStatus = PaymentLoadStatus.loaded;
    notifyListeners();
  }

  // ── Method selection ──────────────────────────────────────────────────────
  void selectMethod(PaymentMethod method) {
    _selectedMethod = method;
    if (method == PaymentMethod.wallet) {
      // Full wallet payment → use max usable
      _walletAmountUsed = _summary?.maxWalletUsable ?? 0;
      _useWalletForPartial = false;
    } else {
      // Non-wallet → reset partial wallet usage
      _useWalletForPartial = false;
      _walletAmountUsed = 0;
    }
    notifyListeners();
  }

  // ── Partial wallet toggle (for non-wallet methods) ────────────────────────
  void toggleWalletForPartial() {
    _useWalletForPartial = !_useWalletForPartial;
    _walletAmountUsed = _useWalletForPartial
        ? (_summary?.maxWalletUsable ?? 0)
        : 0;
    notifyListeners();
  }

  void setWalletAmount(double amount) {
    if (_summary == null) return;
    _walletAmountUsed =
        amount.clamp(0, _summary!.maxWalletUsable);
    notifyListeners();
  }

  // ── Confirm payment ───────────────────────────────────────────────────────
  Future<bool> confirmPayment() async {
    if (_summary == null) return false;

    _confirmStatus = PaymentConfirmStatus.processing;
    _errorMessage = '';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1400));

    // ── Dummy success – replace with real payment gateway call ─────────────
    _receipt = PaymentReceiptModel(
      receiptNumber: 'RCP-${DateTime.now().millisecondsSinceEpoch % 100000}',
      method: _selectedMethod.label,
      amountPaid: _summary!.totalAmount,
      walletUsed: _walletAmountUsed,
      timestamp: DateTime.now(),
      status: 'Confirmed',
    );

    _confirmStatus = PaymentConfirmStatus.success;
    notifyListeners();
    return true;
  }

  void resetStatus() {
    _confirmStatus = PaymentConfirmStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
