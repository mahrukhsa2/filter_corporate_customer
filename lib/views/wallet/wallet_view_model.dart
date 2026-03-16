import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/network/api_response.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../models/wallet_model.dart';
import '../../widgets/app_alert.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Wallet/wallet_view_model.dart
//
// API coverage:
//   ✅ GET  /corporate/wallet       → _loadWalletData() / refresh()
//   🔲 POST /corporate/wallet/topup → processTopUp() — local optimistic for now
//                                     (see WalletRepository for the stub)
// ─────────────────────────────────────────────────────────────────────────────

enum WalletLoadStatus { idle, loading, loaded, error }
enum TopUpStatus      { idle, processing, success, error }

class WalletViewModel extends ChangeNotifier {

  // ── State ─────────────────────────────────────────────────────────────────
  WalletLoadStatus _loadStatus  = WalletLoadStatus.idle;
  TopUpStatus      _topUpStatus = TopUpStatus.idle;

  WalletSummaryModel? _summary;   // null until first successful load
  String              _errorMessage = '';

  // Top-up UI state — local config, not from API
  TopUpOptionModel?  _selectedTopUpOption;
  double?            _customAmount;
  int                _currentTabIndex = 0;

  // ── Getters ───────────────────────────────────────────────────────────────
  WalletLoadStatus get loadStatus  => _loadStatus;
  TopUpStatus      get topUpStatus => _topUpStatus;
  String           get errorMessage => _errorMessage;
  int              get currentTabIndex => _currentTabIndex;

  // Derived from summary — safe defaults when not yet loaded
  double get balance      => _summary?.balance      ?? 0.0;
  double get totalTopups  => _summary?.totalTopups  ?? 0.0;
  double get totalSpent   => _summary?.totalSpent   ?? 0.0;
  String get currency     => _summary?.currency     ?? 'SAR';
  List<WalletTransactionModel> get transactions =>
      _summary?.transactions ?? [];

  // Local config lists — always available, no API dependency
  List<TopUpOptionModel> get topUpOptions => const [
    TopUpOptionModel(id: 'o1', amount: 5000),
    TopUpOptionModel(id: 'o2', amount: 10000),
    TopUpOptionModel(id: 'o3', amount: 25000),
    TopUpOptionModel(id: 'o4', amount: 0, isCustom: true),
  ];

  List<PaymentMethodModel> get paymentMethods => const [
    PaymentMethodModel(id: 'pm1', name: 'Bank Transfer',          icon: '🏦'),
    PaymentMethodModel(id: 'pm2', name: 'Credit/Debit Card',      icon: '💳'),
    PaymentMethodModel(id: 'pm3', name: 'Apple Pay / Google Pay', icon: '📱'),
  ];

  TopUpOptionModel? get selectedTopUpOption => _selectedTopUpOption;
  double?           get customAmount        => _customAmount;

  bool get isLoading         => _loadStatus  == WalletLoadStatus.loading;
  bool get isProcessingTopUp => _topUpStatus == TopUpStatus.processing;

  bool get canProceedWithTopUp {
    if (_selectedTopUpOption == null) return false;
    if (_selectedTopUpOption!.isCustom) {
      return _customAmount != null && _customAmount! > 0;
    }
    return true;
  }

  WalletViewModel() {
    debugPrint('[WalletViewModel] created');
    _loadWalletData();
  }

  // ── Load ────────────────────────────────────── GET /corporate/wallet

  Future<void> _loadWalletData({BuildContext? context}) async {
    debugPrint('[WalletViewModel] _loadWalletData START');

    _loadStatus = WalletLoadStatus.loading;
    notifyListeners();

    final result = await WalletRepository.fetchWallet();

    if (result.success && result.data != null) {
      _summary    = result.data;
      _errorMessage = '';
      _loadStatus = WalletLoadStatus.loaded;

      debugPrint('[WalletViewModel] _loadWalletData SUCCESS: '
          'balance=${_summary!.balance} '
          'transactions=${_summary!.transactions.length}');
    } else {
      debugPrint('[WalletViewModel] _loadWalletData FAILED: '
          'errorType=${result.errorType} msg=${result.message}');

      // Keep stale data visible if we already had a load — just show alert
      _errorMessage = result.message ?? 'Failed to load wallet.';
      _loadStatus   = _summary != null
          ? WalletLoadStatus.loaded   // stale but usable
          : WalletLoadStatus.error;

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: result.errorType,
          message:   result.message,
          onRetry: result.errorType == ApiErrorType.noInternet ||
              result.errorType == ApiErrorType.timeout
              ? () => _loadWalletData(context: context)
              : null,
        );
      }
    }

    notifyListeners();
    debugPrint('[WalletViewModel] _loadWalletData END status=$_loadStatus');
  }

  Future<void> refresh({BuildContext? context}) {
    debugPrint('[WalletViewModel] refresh triggered');
    return _loadWalletData(context: context);
  }

  // ── Tab switching ─────────────────────────────────────────────────────────

  void setTabIndex(int index) {
    debugPrint('[WalletViewModel] setTabIndex: $index');
    _currentTabIndex = index;
    notifyListeners();
  }

  // ── Top-up option selection ───────────────────────────────────────────────

  void selectTopUpOption(TopUpOptionModel option) {
    debugPrint('[WalletViewModel] selectTopUpOption: '
        'id=${option.id} amount=${option.amount} isCustom=${option.isCustom}');
    _selectedTopUpOption = option;
    if (!option.isCustom) _customAmount = null;
    notifyListeners();
  }

  void setCustomAmount(String value) {
    _customAmount = double.tryParse(value);
    debugPrint('[WalletViewModel] setCustomAmount: raw=$value parsed=$_customAmount');
    notifyListeners();
  }

  void clearCustomAmount() {
    debugPrint('[WalletViewModel] clearCustomAmount');
    _customAmount = null;
    notifyListeners();
  }

  // ── Top-up processing ──────────────────────── POST /corporate/wallet/topup
  // Called from the BankTransferSheet after user confirms payment.
  // amount is passed explicitly (not read from _selectedTopUpOption) so the
  // sheet fully controls the value.

  Future<bool> processTopUp({
    required double           amount,
    required PaymentMethodModel paymentMethod,
    required BuildContext     context,
  }) async {
    debugPrint('[WalletViewModel] processTopUp START '
        'amount=$amount method=${paymentMethod.id}');

    _topUpStatus  = TopUpStatus.processing;
    _errorMessage = '';
    notifyListeners();

    final result = await WalletRepository.topUp(
      amount:          amount,
      paymentMethodId: paymentMethod.id,
    );

    if (result.success && result.data != null) {
      final newBalance = result.data!;
      debugPrint('[WalletViewModel] processTopUp SUCCESS: newBalance=$newBalance');

      // Build a local transaction to show immediately in the history list.
      // The real transaction will appear on next refresh from the server.
      final newTx = WalletTransactionModel(
        id:          'tx_${DateTime.now().millisecondsSinceEpoch}',
        date:        DateTime.now(),
        description: 'Wallet Top-up via ${paymentMethod.name}',
        amount:      amount,
        type:        TransactionType.credit,
        status:      'completed',
      );

      // Replace balance with server-confirmed value, prepend transaction
      _summary = _summary != null
          ? WalletSummaryModel(
        balance:      newBalance,
        totalTopups:  (_summary!.totalTopups) + amount,
        totalSpent:   _summary!.totalSpent,
        currency:     _summary!.currency,
        transactions: [newTx, ..._summary!.transactions],
      )
          : WalletSummaryModel(
        balance:      newBalance,
        totalTopups:  amount,
        totalSpent:   0,
        currency:     'SAR',
        transactions: [newTx],
      );

      _topUpStatus         = TopUpStatus.success;
      _selectedTopUpOption = null;
      _customAmount        = null;
      notifyListeners();

      // Auto-reset after animation
      await Future.delayed(const Duration(seconds: 2));
      _topUpStatus = TopUpStatus.idle;
      notifyListeners();

      return true;
    } else {
      debugPrint('[WalletViewModel] processTopUp FAILED: '
          'errorType=${result.errorType} msg=${result.message}');

      _errorMessage = result.message ?? 'Top-up failed. Please try again.';
      _topUpStatus  = TopUpStatus.error;
      notifyListeners();

      if (context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: result.errorType,
          message:   result.message,
          onRetry: result.errorType == ApiErrorType.noInternet ||
              result.errorType == ApiErrorType.timeout
              ? () => processTopUp(
            amount:        amount,
            paymentMethod: paymentMethod,
            context:       context,
          )
              : null,
        );
      }

      _topUpStatus = TopUpStatus.idle;
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  WalletTransactionModel? getTransactionById(String id) =>
      _summary?.transactions
          .cast<WalletTransactionModel?>()
          .firstWhere((t) => t?.id == id, orElse: () => null);

  List<WalletTransactionModel> getTransactionsByType(TransactionType type) =>
      transactions.where((t) => t.type == type).toList();

  List<WalletTransactionModel> getRecentTransactions(int count) =>
      transactions.take(count).toList();
}