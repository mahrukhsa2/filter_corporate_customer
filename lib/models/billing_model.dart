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
  final String monthLabel;         // e.g. "February 2026"
  final double totalDue;
  final DateTime dueDate;
  final double walletBalance;
  final BillingPaymentStatus status;
  final List<InvoiceModel> invoices;

  const MonthlyBillingSummary({
    required this.monthLabel,
    required this.totalDue,
    required this.dueDate,
    required this.walletBalance,
    required this.status,
    required this.invoices,
  });

  double get totalPaid => invoices
      .where((i) => i.status == InvoiceStatus.paid)
      .fold(0, (sum, i) => sum + i.amount);

  double get totalPending => invoices
      .where((i) => i.status == InvoiceStatus.pending ||
          i.status == InvoiceStatus.overdue)
      .fold(0, (sum, i) => sum + i.amount);

  int get paidCount =>
      invoices.where((i) => i.status == InvoiceStatus.paid).length;

  int get pendingCount => invoices
      .where((i) => i.status == InvoiceStatus.pending ||
          i.status == InvoiceStatus.overdue)
      .length;
}

class PartialPaymentModel {
  final double amount;
  final String note;

  const PartialPaymentModel({required this.amount, required this.note});
}
