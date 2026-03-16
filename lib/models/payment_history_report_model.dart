import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// payment_history_report_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum PaymentMethod { wallet, creditCard, bankTransfer, cash }

extension PaymentMethodInfo on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.wallet:       return 'Wallet';
      case PaymentMethod.creditCard:   return 'Credit Card';
      case PaymentMethod.bankTransfer: return 'Bank Transfer';
      case PaymentMethod.cash:         return 'Cash';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentMethod.wallet:       return 'Wallet';
      case PaymentMethod.creditCard:   return 'Credit Card';
      case PaymentMethod.bankTransfer: return 'Bank Transfer';
      case PaymentMethod.cash:         return 'Cash';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.wallet:       return Icons.account_balance_wallet_outlined;
      case PaymentMethod.creditCard:   return Icons.credit_card_outlined;
      case PaymentMethod.bankTransfer: return Icons.account_balance_outlined;
      case PaymentMethod.cash:         return Icons.payments_outlined;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.wallet:       return const Color(0xFF1565C0);
      case PaymentMethod.creditCard:   return const Color(0xFF6A1B9A);
      case PaymentMethod.bankTransfer: return const Color(0xFF2E7D32);
      case PaymentMethod.cash:         return const Color(0xFFE65100);
    }
  }

  Color get bgColor {
    switch (this) {
      case PaymentMethod.wallet:       return const Color(0xFFE3F2FD);
      case PaymentMethod.creditCard:   return const Color(0xFFF3E5F5);
      case PaymentMethod.bankTransfer: return const Color(0xFFE8F5E9);
      case PaymentMethod.cash:         return const Color(0xFFFFF3E0);
    }
  }
}

enum PaymentStatus { paid, success, pending, failed }

extension PaymentStatusInfo on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.paid:    return 'Paid';
      case PaymentStatus.success: return 'Success';
      case PaymentStatus.pending: return 'Pending';
      case PaymentStatus.failed:  return 'Failed';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentStatus.paid:    return 'Paid';
      case PaymentStatus.success: return 'Success';
      case PaymentStatus.pending: return 'Pending';
      case PaymentStatus.failed:  return 'Failed';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.paid:    return const Color(0xFF2E7D32);
      case PaymentStatus.success: return const Color(0xFF1565C0);
      case PaymentStatus.pending: return const Color(0xFFE65100);
      case PaymentStatus.failed:  return const Color(0xFFC62828);
    }
  }

  Color get bgColor {
    switch (this) {
      case PaymentStatus.paid:    return const Color(0xFFE8F5E9);
      case PaymentStatus.success: return const Color(0xFFE3F2FD);
      case PaymentStatus.pending: return const Color(0xFFFFF3E0);
      case PaymentStatus.failed:  return const Color(0xFFFFEBEE);
    }
  }
}

enum PaymentActionType { viewReceipt, viewProof, viewInvoice }

extension PaymentActionLabel on PaymentActionType {
  String get label {
    switch (this) {
      case PaymentActionType.viewReceipt: return 'View Receipt';
      case PaymentActionType.viewProof:   return 'View Proof';
      case PaymentActionType.viewInvoice: return 'View Invoice';
    }
  }
}

class PaymentHistoryItem {
  final String             id;
  final DateTime           date;
  final double             amount;
  final PaymentMethod      method;
  final String             invoiceRef;
  final PaymentStatus      status;
  final String             reference;
  final PaymentActionType  actionType;

  const PaymentHistoryItem({
    required this.id,
    required this.date,
    required this.amount,
    required this.method,
    required this.invoiceRef,
    required this.status,
    required this.reference,
    required this.actionType,
  });

  String get formattedAmount => 'SAR ${_fmtAmt(amount)}';

  factory PaymentHistoryItem.fromMap(Map<String, dynamic> map) {
    // Method
    final rawMethod = (map['method'] ?? map['paymentMethod'] ?? '').toString().toLowerCase();
    PaymentMethod method;
    if (rawMethod.contains('wallet'))        method = PaymentMethod.wallet;
    else if (rawMethod.contains('card'))     method = PaymentMethod.creditCard;
    else if (rawMethod.contains('bank') ||
        rawMethod.contains('transfer')) method = PaymentMethod.bankTransfer;
    else if (rawMethod.contains('cash'))     method = PaymentMethod.cash;
    else                                     method = PaymentMethod.wallet;

    // Status
    final rawStatus = (map['status'] ?? '').toString().toLowerCase();
    PaymentStatus status;
    switch (rawStatus) {
      case 'paid':    status = PaymentStatus.paid;    break;
      case 'success': status = PaymentStatus.success; break;
      case 'failed':  status = PaymentStatus.failed;  break;
      default:        status = PaymentStatus.pending;
    }

    // Action type — derive from method
    PaymentActionType actionType;
    switch (method) {
      case PaymentMethod.bankTransfer: actionType = PaymentActionType.viewProof;   break;
      case PaymentMethod.cash:         actionType = PaymentActionType.viewInvoice; break;
      default:                         actionType = PaymentActionType.viewReceipt;
    }

    // Date
    final rawDate = map['date'] ?? map['created_at'] ?? map['paymentDate'];
    DateTime date;
    try {
      date = rawDate != null ? DateTime.parse(rawDate.toString()) : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return PaymentHistoryItem(
      id:         (map['id'] ?? '').toString(),
      date:       date,
      amount:     _toDouble(map['amount']),
      method:     method,
      invoiceRef: (map['invoiceRef'] ?? map['invoice_number'] ?? map['invoiceNumber'] ?? '—').toString(),
      status:     status,
      reference:  (map['reference'] ?? map['transactionRef'] ?? map['ref'] ?? '—').toString(),
      actionType: actionType,
    );
  }
}

String _fmtAmt(double v) {
  final s = v.toStringAsFixed(0).split('');
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class PaymentHistorySummary {
  final double totalPaid;
  final double byWallet;
  final double byCard;
  final double byTransfer;
  final double byCash;          // not in API — computed client-side
  final int    totalTransactions; // not in API — computed client-side

  const PaymentHistorySummary({
    required this.totalPaid,
    required this.byWallet,
    required this.byCard,
    required this.byTransfer,
    required this.byCash,
    required this.totalTransactions,
  });

  factory PaymentHistorySummary.fromApiMap(
      Map<String, dynamic> map, List<PaymentHistoryItem> items) {
    // byCash and totalTransactions not in API — derive from parsed items
    final byCash = items
        .where((i) => i.method == PaymentMethod.cash)
        .fold(0.0, (s, i) => s + i.amount);

    return PaymentHistorySummary(
      totalPaid:          _toDouble(map['totalPaid']),
      byWallet:           _toDouble(map['byWallet']),
      byCard:             _toDouble(map['byCard']),
      byTransfer:         _toDouble(map['byTransfer']),
      byCash:             byCash,
      totalTransactions:  items.length,
    );
  }
}

class PaymentHistoryFilters {
  final DateTime?      fromDate;
  final DateTime?      toDate;
  final PaymentMethod? method;
  final PaymentStatus? status;

  const PaymentHistoryFilters({
    this.fromDate,
    this.toDate,
    this.method,
    this.status,
  });

  PaymentHistoryFilters copyWith({
    DateTime?      fromDate,
    DateTime?      toDate,
    PaymentMethod? method,
    PaymentStatus? status,
    bool clearFromDate = false,
    bool clearToDate   = false,
    bool clearMethod   = false,
    bool clearStatus   = false,
  }) {
    return PaymentHistoryFilters(
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate:   clearToDate   ? null : (toDate   ?? this.toDate),
      method:   clearMethod   ? null : (method   ?? this.method),
      status:   clearStatus   ? null : (status   ?? this.status),
    );
  }

  bool get hasAny =>
      fromDate != null || toDate != null ||
          method   != null || status != null;

  Map<String, String> toQueryParams() {
    final p = <String, String>{};
    if (fromDate != null) p['startDate'] = _fmtDate(fromDate!);
    if (toDate   != null) p['endDate']   = _fmtDate(toDate!);
    if (method   != null) p['method']    = method!.apiValue;
    if (status   != null) p['status']    = status!.apiValue;
    return p;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num)  return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';