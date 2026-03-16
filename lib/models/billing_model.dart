// ─────────────────────────────────────────────────────────────────────────────
// billing_model.dart
// All data models for the Monthly Billing feature
// ─────────────────────────────────────────────────────────────────────────────

enum InvoiceStatus { paid, pending, overdue, partial }

enum BillingPaymentStatus { pending, paid, partial, overdue }

class InvoiceModel {
  final String invoiceNumber;
  final DateTime date;
  final String vehiclePlate;
  final String department;
  final double amount;
  final InvoiceStatus status;

  const InvoiceModel({
    required this.invoiceNumber,
    required this.date,
    required this.vehiclePlate,
    required this.department,
    required this.amount,
    required this.status,
  });
}

class MonthlyBillingSummary {
  final String monthLabel;
  final double totalDue;
  final DateTime dueDate;
  final double walletBalance;
  final BillingPaymentStatus status;
  final List<InvoiceModel> invoices;

  // ── These come directly from the API (no client-side computation) ─────────
  final double _paidAmount;
  final double _pendingAmount;
  final int    _paidCount;
  final int    _pendingCount;

  const MonthlyBillingSummary({
    required this.monthLabel,
    required this.totalDue,
    required this.dueDate,
    required this.walletBalance,
    required this.status,
    required this.invoices,
    required double paidAmount,
    required double pendingAmount,
    required int    paidCount,
    required int    pendingCount,
  })  : _paidAmount    = paidAmount,
        _pendingAmount = pendingAmount,
        _paidCount     = paidCount,
        _pendingCount  = pendingCount;

  double get totalPaid    => _paidAmount;
  double get totalPending => _pendingAmount;
  int    get paidCount    => _paidCount;
  int    get pendingCount => _pendingCount;
}

class PartialPaymentModel {
  final double amount;
  final String note;

  const PartialPaymentModel({required this.amount, required this.note});
}