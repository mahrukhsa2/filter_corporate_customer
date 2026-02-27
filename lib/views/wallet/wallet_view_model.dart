import 'package:flutter/material.dart';
import '../../models/wallet_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum WalletLoadStatus { idle, loading, loaded, error }
enum TopUpStatus { idle, processing, success, error }

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class WalletViewModel extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────
  WalletLoadStatus _loadStatus = WalletLoadStatus.idle;
  TopUpStatus _topUpStatus = TopUpStatus.idle;
  
  double _balance = 0.0;
  List<WalletTransactionModel> _transactions = [];
  List<TopUpOptionModel> _topUpOptions = [];
  List<PaymentMethodModel> _paymentMethods = [];
  
  TopUpOptionModel? _selectedTopUpOption;
  double? _customAmount;
  String _errorMessage = '';
  
  // Tab index for switching between top-up and transaction history
  int _currentTabIndex = 0;

  // ── Getters ───────────────────────────────────────────────────────────────
  WalletLoadStatus get loadStatus => _loadStatus;
  TopUpStatus get topUpStatus => _topUpStatus;
  
  double get balance => _balance;
  List<WalletTransactionModel> get transactions => _transactions;
  List<TopUpOptionModel> get topUpOptions => _topUpOptions;
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  
  TopUpOptionModel? get selectedTopUpOption => _selectedTopUpOption;
  double? get customAmount => _customAmount;
  String get errorMessage => _errorMessage;
  int get currentTabIndex => _currentTabIndex;
  
  bool get isLoading => _loadStatus == WalletLoadStatus.loading;
  bool get isProcessingTopUp => _topUpStatus == TopUpStatus.processing;
  
  bool get canProceedWithTopUp {
    if (_selectedTopUpOption == null) return false;
    if (_selectedTopUpOption!.isCustom) {
      return _customAmount != null && _customAmount! > 0;
    }
    return true;
  }

  WalletViewModel() {
    _loadWalletData();
  }

  // ── Load wallet data ──────────────────────────────────────────────────────
  Future<void> _loadWalletData() async {
    _loadStatus = WalletLoadStatus.loading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // ── Dummy data – replace with real API call ────────────────────────
      _balance = 12450.0;
      
      _transactions = [
        WalletTransactionModel(
          id: 't1',
          date: DateTime(2026, 2, 12),
          description: 'Oil Change Invoice',
          amount: 285.0,
          type: TransactionType.debit,
          invoiceNumber: 'INV-7845',
        ),
        WalletTransactionModel(
          id: 't2',
          date: DateTime(2026, 2, 10),
          description: 'Wallet Top-up',
          amount: 10000.0,
          type: TransactionType.credit,
        ),
        WalletTransactionModel(
          id: 't3',
          date: DateTime(2026, 2, 5),
          description: 'Full Service',
          amount: 2450.0,
          type: TransactionType.debit,
          invoiceNumber: 'INV-7820',
        ),
        WalletTransactionModel(
          id: 't4',
          date: DateTime(2026, 1, 28),
          description: 'Wallet Top-up',
          amount: 5000.0,
          type: TransactionType.credit,
        ),
        WalletTransactionModel(
          id: 't5',
          date: DateTime(2026, 1, 20),
          description: 'Tire Rotation',
          amount: 150.0,
          type: TransactionType.debit,
          invoiceNumber: 'INV-7720',
        ),
        WalletTransactionModel(
          id: 't6',
          date: DateTime(2026, 1, 15),
          description: 'AC Service',
          amount: 420.0,
          type: TransactionType.debit,
          invoiceNumber: 'INV-7650',
        ),
        WalletTransactionModel(
          id: 't7',
          date: DateTime(2026, 1, 10),
          description: 'Wallet Top-up',
          amount: 3000.0,
          type: TransactionType.credit,
        ),
      ];

      // Sort by date descending (newest first)
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      _topUpOptions = const [
        TopUpOptionModel(id: 'o1', amount: 5000),
        TopUpOptionModel(id: 'o2', amount: 10000),
        TopUpOptionModel(id: 'o3', amount: 25000),
        TopUpOptionModel(id: 'o4', amount: 0, isCustom: true),
      ];

      _paymentMethods = const [
        PaymentMethodModel(
          id: 'pm1',
          name: 'Bank Transfer',
          icon: '🏦',
          isAvailable: true,
        ),
        PaymentMethodModel(
          id: 'pm2',
          name: 'Credit/Debit Card',
          icon: '💳',
          isAvailable: true,
        ),
        PaymentMethodModel(
          id: 'pm3',
          name: 'Apple Pay / Google Pay',
          icon: '📱',
          isAvailable: true,
        ),
      ];

      _loadStatus = WalletLoadStatus.loaded;
      _errorMessage = '';
    } catch (e) {
      _loadStatus = WalletLoadStatus.error;
      _errorMessage = 'Failed to load wallet data: ${e.toString()}';
    }

    notifyListeners();
  }

  // ── Refresh ───────────────────────────────────────────────────────────────
  Future<void> refresh() async {
    await _loadWalletData();
  }

  // ── Tab switching ─────────────────────────────────────────────────────────
  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // ── Top-up option selection ───────────────────────────────────────────────
  void selectTopUpOption(TopUpOptionModel option) {
    _selectedTopUpOption = option;
    if (!option.isCustom) {
      _customAmount = null;
    }
    notifyListeners();
  }

  void setCustomAmount(String value) {
    final parsed = double.tryParse(value);
    _customAmount = parsed;
    notifyListeners();
  }

  void clearCustomAmount() {
    _customAmount = null;
    notifyListeners();
  }

  // ── Top-up processing ─────────────────────────────────────────────────────
  Future<bool> processTopUp(PaymentMethodModel paymentMethod) async {
    if (!canProceedWithTopUp) return false;

    _topUpStatus = TopUpStatus.processing;
    _errorMessage = '';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      // ── Dummy top-up – replace with real API call ──────────────────────
      final amount = _selectedTopUpOption!.isCustom 
          ? _customAmount! 
          : _selectedTopUpOption!.amount;

      // Add transaction
      final newTransaction = WalletTransactionModel(
        id: 't${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        description: 'Wallet Top-up',
        amount: amount,
        type: TransactionType.credit,
      );

      _transactions.insert(0, newTransaction);
      _balance += amount;

      _topUpStatus = TopUpStatus.success;
      
      // Reset selections
      _selectedTopUpOption = null;
      _customAmount = null;
      
      notifyListeners();

      // Auto-reset status after delay
      await Future.delayed(const Duration(seconds: 2));
      _topUpStatus = TopUpStatus.idle;
      notifyListeners();

      return true;
    } catch (e) {
      _topUpStatus = TopUpStatus.error;
      _errorMessage = 'Top-up failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ── Get transaction by ID ─────────────────────────────────────────────────
  WalletTransactionModel? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // ── Filter transactions ───────────────────────────────────────────────────
  List<WalletTransactionModel> getTransactionsByType(TransactionType type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  List<WalletTransactionModel> getRecentTransactions(int count) {
    return _transactions.take(count).toList();
  }
}
