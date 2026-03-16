import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/network/api_response.dart';
import '../../data/repositories/BillingRepository.dart';
import '../../models/billing_model.dart';
import '../../widgets/app_alert.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Billing/billing_view_model.dart
//
// Simplified to show ONLY current month billing
// API: GET /corporate/billing/monthly
// ─────────────────────────────────────────────────────────────────────────────

enum BillingLoadStatus    { idle, loading, loaded, error }
enum PaymentActionStatus  { idle, processing, success, error }

class MonthlyBillingViewModel extends ChangeNotifier {

  BillingLoadStatus      _loadStatus    = BillingLoadStatus.idle;
  PaymentActionStatus    _paymentStatus = PaymentActionStatus.idle;
  String                 _errorMessage  = '';
  ApiErrorType           _errorType     = ApiErrorType.none;
  MonthlyBillingSummary? _summary;

  BillingLoadStatus      get loadStatus         => _loadStatus;
  PaymentActionStatus    get paymentStatus      => _paymentStatus;
  String                 get errorMessage       => _errorMessage;
  ApiErrorType           get errorType          => _errorType;
  MonthlyBillingSummary? get summary            => _summary;
  bool get isLoading    => _loadStatus    == BillingLoadStatus.loading;
  bool get hasError     => _loadStatus    == BillingLoadStatus.error;
  bool get isProcessing => _paymentStatus == PaymentActionStatus.processing;

  MonthlyBillingViewModel() {
    debugPrint('[MonthlyBillingViewModel] created');
    _loadBilling();
  }

  // ── Load current month billing ──────────── GET /corporate/billing/monthly

  Future<void> _loadBilling({BuildContext? context}) async {
    debugPrint('[MonthlyBillingViewModel] _loadBilling START');

    _loadStatus = BillingLoadStatus.loading;
    _summary    = null;
    notifyListeners();

    final result = await BillingRepository.fetchMonthlyBilling();

    if (result.success && result.data != null) {
      _summary    = result.data;
      _errorMessage = '';
      _errorType    = ApiErrorType.none;
      _loadStatus   = BillingLoadStatus.loaded;
      debugPrint('[MonthlyBillingViewModel] loaded from API: '
          'month=${_summary!.monthLabel} '
          'totalDue=${_summary!.totalDue} '
          'invoices=${_summary!.invoices.length}');
    } else {
      debugPrint('[MonthlyBillingViewModel] API failed: '
          'errorType=${result.errorType} msg=${result.message}');
      _errorMessage = result.message ?? 'Failed to load billing data.';
      _errorType    = result.errorType;
      _loadStatus   = BillingLoadStatus.error;

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: result.errorType,
          message:   result.message,
          onRetry: result.errorType == ApiErrorType.noInternet ||
              result.errorType == ApiErrorType.timeout
              ? () => _loadBilling(context: context)
              : null,
        );
      }
    }

    notifyListeners();
    debugPrint('[MonthlyBillingViewModel] _loadBilling END status=$_loadStatus');
  }

  Future<void> refresh({BuildContext? context}) {
    debugPrint('[MonthlyBillingViewModel] refresh');
    return _loadBilling(context: context);
  }

  // ── Payment actions ───────────────────────────────────────────────────────
  // TODO: wire to real endpoints when available:
  //   POST /corporate/billing/pay { method: "wallet" | "bank" | "partial", amount? }

  Future<bool> payWithWallet()           => _processPayment('wallet');
  Future<bool> payWithBank()             => _processPayment('bank');
  Future<bool> payPartial(double amount) => _processPayment('partial', amount: amount);

  Future<bool> _processPayment(String method, {double? amount}) async {
    debugPrint('[MonthlyBillingViewModel] _processPayment method=$method amount=$amount');
    _paymentStatus = PaymentActionStatus.processing;
    _errorMessage  = '';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1300));

    _paymentStatus = PaymentActionStatus.success;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));
    await _loadBilling();

    _paymentStatus = PaymentActionStatus.idle;
    notifyListeners();
    return true;
  }

  void resetPaymentStatus() {
    _paymentStatus = PaymentActionStatus.idle;
    _errorMessage  = '';
    notifyListeners();
  }
}