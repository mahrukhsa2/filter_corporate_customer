import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// wallet_transaction_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum WalletTransactionType { credit, debit, topUp }

extension WalletTransactionTypeInfo on WalletTransactionType {
  String get label {
    switch (this) {
      case WalletTransactionType.credit: return 'Credit';
      case WalletTransactionType.debit:  return 'Debit';
      case WalletTransactionType.topUp:  return 'Top-up';
    }
  }

  Color get color {
    switch (this) {
      case WalletTransactionType.credit: return const Color(0xFF2E7D32);
      case WalletTransactionType.debit:  return const Color(0xFFC62828);
      case WalletTransactionType.topUp:  return const Color(0xFF1565C0);
    }
  }

  Color get bgColor {
    switch (this) {
      case WalletTransactionType.credit: return const Color(0xFFE8F5E9);
      case WalletTransactionType.debit:  return const Color(0xFFFFEBEE);
      case WalletTransactionType.topUp:  return const Color(0xFFE3F2FD);
    }
  }

  IconData get icon {
    switch (this) {
      case WalletTransactionType.credit: return Icons.arrow_downward_rounded;
      case WalletTransactionType.debit:  return Icons.arrow_upward_rounded;
      case WalletTransactionType.topUp:  return Icons.add_card_rounded;
    }
  }

  String get amountPrefix {
    switch (this) {
      case WalletTransactionType.credit: return '+';
      case WalletTransactionType.debit:  return '-';
      case WalletTransactionType.topUp:  return '+';
    }
  }
}

class WalletTransaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final WalletTransactionType type;
  final double balanceAfter;
  final String? referenceNumber; // invoice or receipt ref

  const WalletTransaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.balanceAfter,
    this.referenceNumber,
  });

  String get formattedAmount =>
      '${type.amountPrefix}SAR ${_fmtAmt(amount)}';

  String get formattedBalance => 'SAR ${_fmtAmt(balanceAfter)}';
}

String _fmtAmt(double v) {
  final parts = v.toStringAsFixed(0).split('');
  final buf   = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
    buf.write(parts[i]);
  }
  return buf.toString();
}

class WalletSummary {
  final double currentBalance;
  final double totalTopUps;
  final double totalSpent;
  final double netMovement;

  const WalletSummary({
    required this.currentBalance,
    required this.totalTopUps,
    required this.totalSpent,
    required this.netMovement,
  });
}

class WalletTransactionFilters {
  final DateTime? fromDate;
  final DateTime? toDate;
  final WalletTransactionType? type;
  final double? minAmount;
  final double? maxAmount;

  const WalletTransactionFilters({
    this.fromDate,
    this.toDate,
    this.type,
    this.minAmount,
    this.maxAmount,
  });

  WalletTransactionFilters copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    WalletTransactionType? type,
    double? minAmount,
    double? maxAmount,
    bool clearFromDate = false,
    bool clearToDate   = false,
    bool clearType     = false,
    bool clearMin      = false,
    bool clearMax      = false,
  }) {
    return WalletTransactionFilters(
      fromDate:  clearFromDate ? null : (fromDate  ?? this.fromDate),
      toDate:    clearToDate   ? null : (toDate    ?? this.toDate),
      type:      clearType     ? null : (type      ?? this.type),
      minAmount: clearMin      ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMax      ? null : (maxAmount ?? this.maxAmount),
    );
  }

  bool get hasAny =>
      fromDate  != null ||
      toDate    != null ||
      type      != null ||
      minAmount != null ||
      maxAmount != null;
}
