import 'package:flutter/material.dart';

import '../../models/billing_model.dart';

enum BillingLoadStatus { idle, loading, loaded, error }
enum PaymentActionStatus { idle, processing, success, error }

class MonthlyBillingViewModel extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────
  BillingLoadStatus _loadStatus = BillingLoadStatus.idle;
  PaymentActionStatus _paymentStatus = PaymentActionStatus.idle;
  String _errorMessage = '';
  MonthlyBillingSummary? _summary;

  // ── Available months for navigation ───────────────────────────────────────
  final List<String> _availableMonths = [
    'February 2026',
    'January 2026',
    'December 2025',
    'November 2025',
  ];
  int _selectedMonthIndex = 0;

  // ── Getters ───────────────────────────────────────────────────────────────
  BillingLoadStatus get loadStatus => _loadStatus;
  PaymentActionStatus get paymentStatus => _paymentStatus;
  String get errorMessage => _errorMessage;
  MonthlyBillingSummary? get summary => _summary;
  List<String> get availableMonths => _availableMonths;
  int get selectedMonthIndex => _selectedMonthIndex;
  String get selectedMonth => _availableMonths[_selectedMonthIndex];
  bool get isLoading => _loadStatus == BillingLoadStatus.loading;
  bool get isProcessing => _paymentStatus == PaymentActionStatus.processing;
  bool get hasPrev => _selectedMonthIndex < _availableMonths.length - 1;
  bool get hasNext => _selectedMonthIndex > 0;

  MonthlyBillingViewModel() {
    _loadBilling();
  }

  // ── Load billing data ─────────────────────────────────────────────────────
  Future<void> _loadBilling() async {
    _loadStatus = BillingLoadStatus.loading;
    _summary = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    // ── Dummy data per selected month – replace with real API call ─────────
    _summary = _dummySummaryFor(_selectedMonthIndex);

    _loadStatus = BillingLoadStatus.loaded;
    notifyListeners();
  }

  Future<void> refresh() => _loadBilling();

  void goToPrevMonth() {
    if (!hasPrev) return;
    _selectedMonthIndex++;
    _loadBilling();
  }

  void goToNextMonth() {
    if (!hasNext) return;
    _selectedMonthIndex--;
    _loadBilling();
  }

  void selectMonth(int index) {
    if (index == _selectedMonthIndex) return;
    _selectedMonthIndex = index;
    _loadBilling();
  }

  // ── Payment actions ───────────────────────────────────────────────────────

  Future<bool> payWithWallet() async {
    return _processPayment('wallet_full');
  }

  Future<bool> payWithBank() async {
    return _processPayment('bank_full');
  }

  Future<bool> payPartial(double amount) async {
    return _processPayment('partial', amount: amount);
  }

  Future<bool> _processPayment(String method, {double? amount}) async {
    _paymentStatus = PaymentActionStatus.processing;
    _errorMessage = '';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1300));

    // ── Dummy success – replace with real payment API call ─────────────────
    _paymentStatus = PaymentActionStatus.success;
    notifyListeners();

    // Reload billing to reflect updated status
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadBilling();

    _paymentStatus = PaymentActionStatus.idle;
    notifyListeners();
    return true;
  }

  void resetPaymentStatus() {
    _paymentStatus = PaymentActionStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }

  // ── Dummy data factory ────────────────────────────────────────────────────
  static MonthlyBillingSummary _dummySummaryFor(int monthIndex) {
    switch (monthIndex) {
      case 0: // February 2026
        return MonthlyBillingSummary(
          monthLabel: 'February 2026',
          totalDue: 48750,
          dueDate: DateTime(2026, 3, 15),
          walletBalance: 12450,
          status: BillingPaymentStatus.pending,
          invoices: [
            InvoiceModel(
              invoiceNumber: 'INV-7845',
              date: DateTime(2026, 2, 12),
              vehiclePlate: 'ABC-123',
              department: 'Oil Change',
              amount: 285,
              status: InvoiceStatus.paid,
            ),
            InvoiceModel(
              invoiceNumber: 'INV-7846',
              date: DateTime(2026, 2, 20),
              vehiclePlate: 'XYZ-789',
              department: 'Engine Repair',
              amount: 12450,
              status: InvoiceStatus.pending,
            ),
            InvoiceModel(
              invoiceNumber: 'INV-7847',
              date: DateTime(2026, 2, 22),
              vehiclePlate: 'ABC-123',
              department: 'Brake Service',
              amount: 18500,
              status: InvoiceStatus.pending,
            ),
            InvoiceModel(
              invoiceNumber: 'INV-7848',
              date: DateTime(2026, 2, 25),
              vehiclePlate: 'DEF-456',
              department: 'Tire Rotation',
              amount: 17515,
              status: InvoiceStatus.pending,
            ),
          ],
        );
      case 1: // January 2026
        return MonthlyBillingSummary(
          monthLabel: 'January 2026',
          totalDue: 32100,
          dueDate: DateTime(2026, 2, 15),
          walletBalance: 12450,
          status: BillingPaymentStatus.paid,
          invoices: [
            InvoiceModel(
              invoiceNumber: 'INV-7801',
              date: DateTime(2026, 1, 5),
              vehiclePlate: 'ABC-123',
              department: 'Full Inspection',
              amount: 1800,
              status: InvoiceStatus.paid,
            ),
            InvoiceModel(
              invoiceNumber: 'INV-7802',
              date: DateTime(2026, 1, 18),
              vehiclePlate: 'XYZ-789',
              department: 'AC Service',
              amount: 12300,
              status: InvoiceStatus.paid,
            ),
            InvoiceModel(
              invoiceNumber: 'INV-7803',
              date: DateTime(2026, 1, 29),
              vehiclePlate: 'DEF-456',
              department: 'Oil Change',
              amount: 18000,
              status: InvoiceStatus.paid,
            ),
          ],
        );
      default: // Older months
        return MonthlyBillingSummary(
          monthLabel: monthIndex == 2 ? 'December 2025' : 'November 2025',
          totalDue: 22500,
          dueDate: DateTime(2026, monthIndex == 2 ? 1 : 12, 15),
          walletBalance: 12450,
          status: BillingPaymentStatus.paid,
          invoices: [
            InvoiceModel(
              invoiceNumber: 'INV-${7700 + monthIndex}',
              date: DateTime(2025, monthIndex == 2 ? 12 : 11, 10),
              vehiclePlate: 'ABC-123',
              department: 'Car Wash',
              amount: 9500,
              status: InvoiceStatus.paid,
            ),
            InvoiceModel(
              invoiceNumber: 'INV-${7701 + monthIndex}',
              date: DateTime(2025, monthIndex == 2 ? 12 : 11, 22),
              vehiclePlate: 'XYZ-789',
              department: 'Battery',
              amount: 13000,
              status: InvoiceStatus.paid,
            ),
          ],
        );
    }
  }
}
