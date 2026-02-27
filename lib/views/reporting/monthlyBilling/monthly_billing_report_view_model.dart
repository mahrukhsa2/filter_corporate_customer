import 'package:flutter/material.dart';

import '../../../models/monthly_billing_report_model.dart';

enum MBLoadStatus { idle, loading, loaded }

class MonthlyBillingReportViewModel extends ChangeNotifier {
  MBLoadStatus _status     = MBLoadStatus.idle;
  bool _isExporting        = false;
  bool _isPayingOutstanding = false;

  List<BillingInvoice>     _all      = [];
  List<BillingInvoice>     _filtered = [];
  MonthlyBillingOverview?  _overview;
  List<BillingTrendPoint>  _trend    = [];
  BillingFilters           _filters  = const BillingFilters(month: 2, year: 2026);

  bool get isLoading           => _status == MBLoadStatus.loading;
  bool get isExporting         => _isExporting;
  bool get isPayingOutstanding => _isPayingOutstanding;

  List<BillingInvoice>    get items    => _filtered;
  MonthlyBillingOverview? get overview => _overview;
  List<BillingTrendPoint> get trend    => _trend;
  BillingFilters          get filters  => _filters;

  // Available months/years for the dropdowns
  final List<int> availableYears  = [2024, 2025, 2026];
  final List<int> availableMonths = List.generate(12, (i) => i + 1);

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  String monthName(int m) => _monthNames[m - 1];

  MonthlyBillingReportViewModel() { _load(); }

  Future<void> _load() async {
    _status = MBLoadStatus.loading;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    // ── Dummy invoices (February 2026) ────────────────────────────────
    _all = [
      BillingInvoice(invoiceNumber: 'INV-7845', date: DateTime(2026, 2, 12),
          vehiclePlate: 'ABC-123', department: 'Oil Change',
          amount: 285, status: BillingInvoiceStatus.paid),
      BillingInvoice(invoiceNumber: 'INV-7846', date: DateTime(2026, 2, 20),
          vehiclePlate: 'XYZ-789', department: 'Repair',
          amount: 12450, status: BillingInvoiceStatus.pending),
      BillingInvoice(invoiceNumber: 'INV-7847', date: DateTime(2026, 2, 25),
          vehiclePlate: 'DEF-456', department: 'Tire Service',
          amount: 8200, status: BillingInvoiceStatus.paid),
      BillingInvoice(invoiceNumber: 'INV-7848', date: DateTime(2026, 2, 18),
          vehiclePlate: 'GHI-321', department: 'Full Service',
          amount: 15650, status: BillingInvoiceStatus.overdue),
      BillingInvoice(invoiceNumber: 'INV-7849', date: DateTime(2026, 2, 5),
          vehiclePlate: 'JKL-654', department: 'AC Service',
          amount: 950, status: BillingInvoiceStatus.paid),
      BillingInvoice(invoiceNumber: 'INV-7850', date: DateTime(2026, 2, 8),
          vehiclePlate: 'ABC-123', department: 'Brake Pads',
          amount: 1200, status: BillingInvoiceStatus.paid),
      BillingInvoice(invoiceNumber: 'INV-7851', date: DateTime(2026, 2, 22),
          vehiclePlate: 'XYZ-789', department: 'Wheel Alignment',
          amount: 480, status: BillingInvoiceStatus.pending),
      BillingInvoice(invoiceNumber: 'INV-7852', date: DateTime(2026, 2, 28),
          vehiclePlate: 'DEF-456', department: 'Battery Replace',
          amount: 650, status: BillingInvoiceStatus.paid),
    ];

    _filtered = List.from(_all);

    _overview = MonthlyBillingOverview(
      monthLabel:   'February 2026',
      totalBilled:  48765,
      totalPaid:    35200,
      outstanding:  13565,
      dueDate:      DateTime(2026, 3, 15),
      walletUsed:   8450,
    );

    // ── Monthly trend (last 6 months) ─────────────────────────────────
    _trend = const [
      BillingTrendPoint(monthLabel: 'Sep', paid: 22000, pending: 5000),
      BillingTrendPoint(monthLabel: 'Oct', paid: 31000, pending: 8000),
      BillingTrendPoint(monthLabel: 'Nov', paid: 28500, pending: 6500),
      BillingTrendPoint(monthLabel: 'Dec', paid: 41200, pending: 11000),
      BillingTrendPoint(monthLabel: 'Jan', paid: 38000, pending: 9200),
      BillingTrendPoint(monthLabel: 'Feb', paid: 35200, pending: 13565),
    ];

    _status = MBLoadStatus.loaded;
    notifyListeners();
  }

  Future<void> refresh() => _load();

  void updateFilters(BillingFilters f) {
    _filters = f;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filtered = _all.where((inv) {
      if (_filters.status != null && inv.status != _filters.status)
        return false;
      return true;
    }).toList();
  }

  Future<void> exportReport(String format) async {
    _isExporting = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _isExporting = false;
    notifyListeners();
  }

  Future<void> payOutstanding() async {
    _isPayingOutstanding = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1500));
    // TODO: real payment API
    _isPayingOutstanding = false;
    notifyListeners();
  }
}
