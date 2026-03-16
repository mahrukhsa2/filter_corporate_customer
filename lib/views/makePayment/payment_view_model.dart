import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/network/api_response.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../models/payment_model.dart';
import '../../widgets/app_alert.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Payment/payment_view_model.dart
//
// Flow:
//   1. Load real wallet balance from WalletRepository.fetchSummary()
//   2. On confirm: POST /corporate/order (validate/create order)
//   3. If order success: POST /corporate/make_payment (process payment)
//
// Payment method behaviours:
//   wallet        → payFromWallet=true, deducts from wallet
//   bankTransfer  → payFromWallet=false, manual transfer
//   cashAtBranch  → payFromWallet=false, pay at branch
//   onlineCard    → DISABLED (coming soon)
//   payMonthly    → skip payment, order only via skipPayment()
// ─────────────────────────────────────────────────────────────────────────────

enum PaymentLoadStatus { idle, loading, loaded }

class MakePaymentViewModel extends ChangeNotifier {

  // ── State ──────────────────────────────────────────────────────────────────
  PaymentLoadStatus    _loadStatus    = PaymentLoadStatus.idle;
  PaymentConfirmStatus _confirmStatus = PaymentConfirmStatus.idle;
  String               _errorMessage  = '';

  // ── Data ───────────────────────────────────────────────────────────────────
  PaymentSummary?      _summary;
  PaymentReceiptModel? _receipt;

  // ── Booking context passed from booking screen ─────────────────────────────
  final String   _branchId;
  final String   _vehicleId;
  final String   _departmentId;
  final DateTime _bookedFor;
  final String   _notes;
  final bool     _initialPayFromWallet;

  // ── Form state ─────────────────────────────────────────────────────────────
  PaymentMethod _selectedMethod      = PaymentMethod.wallet;
  bool          _useWalletForPartial = false;
  double        _walletAmountUsed    = 0;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading    => _loadStatus    == PaymentLoadStatus.loading;
  bool get isProcessing => _confirmStatus == PaymentConfirmStatus.processing;
  bool get isSuccess    => _confirmStatus == PaymentConfirmStatus.success;
  bool get isSkipped    => _confirmStatus == PaymentConfirmStatus.skipped;

  PaymentConfirmStatus get confirmStatus       => _confirmStatus;
  String               get errorMessage        => _errorMessage;
  PaymentSummary?      get summary             => _summary;
  PaymentReceiptModel? get receipt             => _receipt;
  PaymentMethod        get selectedMethod      => _selectedMethod;
  bool                 get useWalletForPartial => _useWalletForPartial;
  double               get walletAmountUsed    => _walletAmountUsed;

  double get remainingAmount => _summary?.remaining(_walletAmountUsed) ?? 0;

  bool get showWalletTopUp =>
      _selectedMethod != PaymentMethod.wallet &&
          _selectedMethod != PaymentMethod.payMonthly &&
          (_summary?.walletBalance ?? 0) > 0;

  bool get canConfirm => _summary != null && !isProcessing;

  MakePaymentViewModel({
    double?   totalAmount,
    String?   invoiceRef,
    String    branchId             = '',
    String    vehicleId            = '',
    String    departmentId         = '',
    DateTime? bookedFor,
    String    notes                = '',
    bool      initialPayFromWallet = false,
  })  : _branchId             = branchId,
        _vehicleId            = vehicleId,
        _departmentId         = departmentId,
        _bookedFor            = bookedFor ?? DateTime.now(),
        _notes                = notes,
        _initialPayFromWallet = initialPayFromWallet {
    debugPrint('[MakePaymentViewModel] created '
        'branchId=$branchId vehicleId=$vehicleId '
        'departmentId=$departmentId');
    _loadData(totalAmount: totalAmount, invoiceRef: invoiceRef);
  }

  // ── Load: fetch real wallet balance ───────────────────────────────────────

  Future<void> _loadData({double? totalAmount, String? invoiceRef}) async {
    _loadStatus = PaymentLoadStatus.loading;
    notifyListeners();

    double walletBalance = 0.0;
    try {
      final walletResult = await WalletRepository.fetchSummary();
      if (walletResult.success && walletResult.data != null) {
        walletBalance = walletResult.data!.currentBalance;
        debugPrint('[MakePaymentViewModel] wallet balance loaded: $walletBalance');
      } else {
        debugPrint('[MakePaymentViewModel] wallet fetch failed: ${walletResult.message}');
      }
    } catch (e) {
      debugPrint('[MakePaymentViewModel] wallet fetch error: $e');
    }

    _summary = PaymentSummary(
      invoiceRef:    invoiceRef  ?? 'Service Booking',
      totalAmount:   totalAmount ?? 0.0,
      walletBalance: walletBalance,
    );

    // Pre-select wallet if booking screen had payFromWallet checked
    if (_initialPayFromWallet) {
      _selectedMethod   = PaymentMethod.wallet;
      _walletAmountUsed = _summary!.maxWalletUsable;
    }

    debugPrint('[MakePaymentViewModel] summary loaded: '
        'total=${_summary!.totalAmount} wallet=$walletBalance');

    _loadStatus = PaymentLoadStatus.loaded;
    notifyListeners();
  }

  // ── Method selection ───────────────────────────────────────────────────────

  void selectMethod(PaymentMethod method) {
    if (method == PaymentMethod.onlineCard) return; // disabled
    _selectedMethod = method;
    if (method == PaymentMethod.wallet) {
      _walletAmountUsed    = _summary?.maxWalletUsable ?? 0;
      _useWalletForPartial = false;
    } else {
      _useWalletForPartial = false;
      _walletAmountUsed    = 0;
    }
    debugPrint('[MakePaymentViewModel] selectMethod: ${method.label}');
    notifyListeners();
  }

  void toggleWalletForPartial() {
    _useWalletForPartial = !_useWalletForPartial;
    _walletAmountUsed    = _useWalletForPartial
        ? (_summary?.maxWalletUsable ?? 0)
        : 0;
    notifyListeners();
  }

  void setWalletAmount(double amount) {
    if (_summary == null) return;
    _walletAmountUsed = amount.clamp(0, _summary!.maxWalletUsable);
    notifyListeners();
  }

  // ── Two-step payment: validate order → process payment ────────────────────

  Future<bool> confirmPayment({BuildContext? context}) async {
    if (_summary == null) return false;

    debugPrint('[MakePaymentViewModel] confirmPayment START '
        'method=${_selectedMethod.label}');

    _confirmStatus = PaymentConfirmStatus.processing;
    _errorMessage  = '';
    notifyListeners();

    // ── Step 1: Validate / create order ─────────────────────────────────────
    final orderResult = await OrdersRepository.submitOrder(
      branchId:      _branchId,
      vehicleId:     _vehicleId,
      departmentId:  _departmentId,
      bookedFor:     _bookedFor,
      payFromWallet: _selectedMethod == PaymentMethod.wallet || _useWalletForPartial,
      notes:         _notes,
    );

    if (!orderResult.success) {
      debugPrint('[MakePaymentViewModel] order validation FAILED: ${orderResult.message}');
      _errorMessage  = orderResult.message ?? 'Failed to create order.';
      _confirmStatus = PaymentConfirmStatus.error;
      notifyListeners();

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: orderResult.errorType,
          message:   orderResult.message,
          onRetry: orderResult.errorType == ApiErrorType.noInternet ||
              orderResult.errorType == ApiErrorType.timeout
              ? () => confirmPayment(context: context)
              : null,
        );
      }

      _confirmStatus = PaymentConfirmStatus.idle;
      notifyListeners();
      return false;
    }

    debugPrint('[MakePaymentViewModel] order validated OK — proceeding to payment');

    // ── Step 2: Process payment ──────────────────────────────────────────────
    final isWalletMethod = _selectedMethod == PaymentMethod.wallet;
    final payFromWallet  = isWalletMethod || _useWalletForPartial;

    // payMonthly: no paymentMethod sent to API — order is placed, billed later
    final payResult = await PaymentRepository.makePayment(
      branchId:             _branchId,
      vehicleId:            _vehicleId,
      departmentId:         _departmentId,
      bookedFor:            _bookedFor,
      payFromWallet:        payFromWallet,
      notes:                _notes,
      paymentMethod:        _selectedMethod == PaymentMethod.payMonthly
          ? null
          : _selectedMethod.label,
      partialWalletPayment: _useWalletForPartial,
    );

    debugPrint('[MakePaymentViewModel] makePayment result: '
        'success=${payResult.success} msg=${payResult.message}');

    if (payResult.success && payResult.data != null) {
      final order = payResult.data!;

      _receipt = PaymentReceiptModel(
        receiptNumber: order.bookingCode,
        orderId:       order.orderId,
        method:        order.paymentMethod.isNotEmpty
            ? order.paymentMethod
            : _selectedMethod.label,
        amountPaid:    _summary!.totalAmount,
        walletUsed:    _walletAmountUsed,
        timestamp:     order.submittedAt,
        status:        order.status,
        notes:         order.notes,
      );

      _confirmStatus = PaymentConfirmStatus.success;
      notifyListeners();
      debugPrint('[MakePaymentViewModel] confirmPayment SUCCESS ✅');
      return true;
    }

    _errorMessage  = payResult.message ?? 'Payment failed. Please try again.';
    _confirmStatus = PaymentConfirmStatus.error;
    notifyListeners();

    if (context != null && context.mounted) {
      await AppAlert.apiError(
        context,
        errorType: payResult.errorType,
        message:   payResult.message,
        onRetry: payResult.errorType == ApiErrorType.noInternet ||
            payResult.errorType == ApiErrorType.timeout
            ? () => confirmPayment(context: context)
            : null,
      );
    }

    _confirmStatus = PaymentConfirmStatus.idle;
    notifyListeners();
    return false;
  }

  // ── Skip payment — deferred to monthly billing ────────────────────────────
  // Full two-step flow: submitOrder → makePayment (paymentMethod omitted).
  // The absence of paymentMethod tells the backend this is a monthly billing order.

  Future<bool> skipPayment({BuildContext? context}) async {
    debugPrint('[MakePaymentViewModel] skipPayment — monthly billing (full two-step)');

    _confirmStatus = PaymentConfirmStatus.processing;
    _errorMessage  = '';
    notifyListeners();

    // ── Step 1: Create order ──────────────────────────────────────────────────
    final orderResult = await OrdersRepository.submitOrder(
      branchId:      _branchId,
      vehicleId:     _vehicleId,
      departmentId:  _departmentId,
      bookedFor:     _bookedFor,
      payFromWallet: false,
      notes:         _notes,
    );

    if (!orderResult.success) {
      debugPrint('[MakePaymentViewModel] skipPayment order FAILED: ${orderResult.message}');
      _errorMessage  = orderResult.message ?? 'Failed to place order.';
      _confirmStatus = PaymentConfirmStatus.error;
      notifyListeners();

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: orderResult.errorType,
          message:   orderResult.message,
          onRetry: orderResult.errorType == ApiErrorType.noInternet ||
              orderResult.errorType == ApiErrorType.timeout
              ? () => skipPayment(context: context)
              : null,
        );
      }

      _confirmStatus = PaymentConfirmStatus.idle;
      notifyListeners();
      return false;
    }

    debugPrint('[MakePaymentViewModel] skipPayment order OK — calling makePayment without paymentMethod');

    // ── Step 2: makePayment — paymentMethod intentionally omitted ─────────────
    final payResult = await PaymentRepository.makePayment(
      branchId:             _branchId,
      vehicleId:            _vehicleId,
      departmentId:         _departmentId,
      bookedFor:            _bookedFor,
      payFromWallet:        false,
      notes:                _notes,
      paymentMethod:        null,   // null = monthly billing — backend differentiates this
      partialWalletPayment: false,
    );

    if (payResult.success && payResult.data != null) {
      final order = payResult.data!;

      _receipt = PaymentReceiptModel(
        receiptNumber: order.bookingCode,
        orderId:       order.orderId,
        method:        'Monthly Billing',
        amountPaid:    0,
        walletUsed:    0,
        timestamp:     order.submittedAt,
        status:        order.status,
        notes:         order.notes,
      );

      _confirmStatus = PaymentConfirmStatus.skipped;
      notifyListeners();
      debugPrint('[MakePaymentViewModel] skipPayment SUCCESS ✅');
      return true;
    }

    _errorMessage  = payResult.message ?? 'Failed to place order. Please try again.';
    _confirmStatus = PaymentConfirmStatus.error;
    notifyListeners();

    if (context != null && context.mounted) {
      await AppAlert.apiError(
        context,
        errorType: payResult.errorType,
        message:   payResult.message,
        onRetry: payResult.errorType == ApiErrorType.noInternet ||
            payResult.errorType == ApiErrorType.timeout
            ? () => skipPayment(context: context)
            : null,
      );
    }

    _confirmStatus = PaymentConfirmStatus.idle;
    notifyListeners();
    return false;
  }

  void resetStatus() {
    _confirmStatus = PaymentConfirmStatus.idle;
    _errorMessage  = '';
    notifyListeners();
  }
}