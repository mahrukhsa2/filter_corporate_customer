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

/// The action label shown in the table row
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
  final String id;
  final DateTime date;
  final double amount;
  final PaymentMethod method;
  final String invoiceRef;   // "INV-7845" or "Top-up"
  final PaymentStatus status;
  final String reference;    // WAL-, TXN-, REF-
  final PaymentActionType actionType;

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
  final double byCash;
  final int totalTransactions;

  const PaymentHistorySummary({
    required this.totalPaid,
    required this.byWallet,
    required this.byCard,
    required this.byTransfer,
    required this.byCash,
    required this.totalTransactions,
  });
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
}
