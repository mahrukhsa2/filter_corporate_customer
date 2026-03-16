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
  final String               id;             // raw API id — used by InvoiceService
  final String               invoiceNumber;
  final DateTime             date;
  final String               vehiclePlate;
  final String               department;
  final double               amount;
  final BillingInvoiceStatus status;

  const BillingInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.vehiclePlate,
    required this.department,
    required this.amount,
    required this.status,
  });

  String get formattedAmount => 'SAR ${_fmt(amount)}';

  factory BillingInvoice.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['status'] ?? '').toString().toLowerCase();
    BillingInvoiceStatus status;
    switch (rawStatus) {
      case 'paid':    status = BillingInvoiceStatus.paid;    break;
      case 'overdue': status = BillingInvoiceStatus.overdue; break;
      default:        status = BillingInvoiceStatus.pending;
    }

    // API returns 'date' as YYYY-MM-DD string
    final rawDate = map['date'] ?? map['created_at'] ?? map['invoice_date'];
    DateTime date;
    try {
      date = rawDate != null ? DateTime.parse(rawDate.toString()) : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    // API uses 'invoiceNo' as the identifier
    final rawId       = (map['id'] ?? map['invoiceNo'] ?? '').toString();
    final invoiceNo   = (map['invoiceNo'] ?? map['invoice_number'] ?? rawId).toString();

    return BillingInvoice(
      id:            rawId,
      invoiceNumber: invoiceNo,
      date:          date,
      // API does not return vehicle — show dash
      vehiclePlate:  (map['vehicle_plate'] ?? map['plateNo'] ?? '—').toString(),
      department:    (map['department'] ?? map['service'] ?? map['description'] ?? '-').toString(),
      amount:        _toDouble(map['amount']),
      status:        status,
    );
  }
}

class MonthlyBillingOverview {
  final String   monthLabel;
  final double   totalBilled;
  final double   totalPaid;
  final double   outstanding;
  final DateTime dueDate;
  final double   walletUsed;

  const MonthlyBillingOverview({
    required this.monthLabel,
    required this.totalBilled,
    required this.totalPaid,
    required this.outstanding,
    required this.dueDate,
    required this.walletUsed,
  });

  factory MonthlyBillingOverview.fromApiMap(
      Map<String, dynamic> summary, String monthLabel) {
    DateTime dueDate;
    try {
      final raw = summary['dueDate']?.toString() ?? '';
      dueDate = raw.isNotEmpty
          ? DateTime.parse(raw)
          : DateTime.now().add(const Duration(days: 15));
    } catch (_) {
      dueDate = DateTime.now().add(const Duration(days: 15));
    }

    return MonthlyBillingOverview(
      monthLabel:  monthLabel,
      totalBilled: _toDouble(summary['totalBilled']),
      totalPaid:   _toDouble(summary['totalPaid']),
      outstanding: _toDouble(summary['outstandingBalance']),
      dueDate:     dueDate,
      walletUsed:  _toDouble(summary['walletUsed']),
    );
  }
}

/// One bar in the monthly trend chart
class BillingTrendPoint {
  final String monthLabel;
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
  final int?                  month;
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

  Map<String, String> toQueryParams() {
    final now = DateTime.now();
    final p   = <String, String>{
      'month': (month ?? now.month).toString(),
      'year':  (year  ?? now.year).toString(),
    };
    if (status != null) p['status'] = status!.label.toLowerCase();
    return p;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num)  return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
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