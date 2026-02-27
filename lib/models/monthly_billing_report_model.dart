import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// monthly_billing_report_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum BillingInvoiceStatus { paid, pending, overdue }

extension BillingInvoiceStatusInfo on BillingInvoiceStatus {
  String get label {
    switch (this) {
      case BillingInvoiceStatus.paid:    return 'Paid';
      case BillingInvoiceStatus.pending: return 'Pending';
      case BillingInvoiceStatus.overdue: return 'Overdue';
    }
  }

  Color get color {
    switch (this) {
      case BillingInvoiceStatus.paid:    return const Color(0xFF2E7D32);
      case BillingInvoiceStatus.pending: return const Color(0xFFE65100);
      case BillingInvoiceStatus.overdue: return const Color(0xFFC62828);
    }
  }

  Color get bgColor {
    switch (this) {
      case BillingInvoiceStatus.paid:    return const Color(0xFFE8F5E9);
      case BillingInvoiceStatus.pending: return const Color(0xFFFFF3E0);
      case BillingInvoiceStatus.overdue: return const Color(0xFFFFEBEE);
    }
  }
}

class BillingInvoice {
  final String invoiceNumber;
  final DateTime date;
  final String vehiclePlate;
  final String department;
  final double amount;
  final BillingInvoiceStatus status;

  const BillingInvoice({
    required this.invoiceNumber,
    required this.date,
    required this.vehiclePlate,
    required this.department,
    required this.amount,
    required this.status,
  });

  String get formattedAmount => 'SAR ${_fmt(amount)}';
}

class MonthlyBillingOverview {
  final String monthLabel;      // e.g. "February 2026"
  final double totalBilled;
  final double totalPaid;
  final double outstanding;
  final DateTime dueDate;
  final double walletUsed;

  const MonthlyBillingOverview({
    required this.monthLabel,
    required this.totalBilled,
    required this.totalPaid,
    required this.outstanding,
    required this.dueDate,
    required this.walletUsed,
  });
}

/// One bar in the monthly trend chart
class BillingTrendPoint {
  final String monthLabel;   // e.g. "Oct"
  final double paid;
  final double pending;

  const BillingTrendPoint({
    required this.monthLabel,
    required this.paid,
    required this.pending,
  });

  double get total => paid + pending;
}

class BillingFilters {
  final int?                  month;   // 1-12, null = current
  final int?                  year;
  final BillingInvoiceStatus? status;

  const BillingFilters({this.month, this.year, this.status});

  BillingFilters copyWith({
    int?                  month,
    int?                  year,
    BillingInvoiceStatus? status,
    bool clearStatus = false,
  }) {
    return BillingFilters(
      month:  month  ?? this.month,
      year:   year   ?? this.year,
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  bool get hasStatusFilter => status != null;
}

String _fmt(double v) {
  final s = v.toStringAsFixed(0).split('');
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
