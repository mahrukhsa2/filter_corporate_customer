// ─────────────────────────────────────────────────────────────────────────────
// wallet_model.dart
// All data models for the Wallet feature
// ─────────────────────────────────────────────────────────────────────────────

class WalletTransactionModel {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final TransactionType type; // debit or credit
  final String? invoiceNumber;

  const WalletTransactionModel({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    this.invoiceNumber,
  });

  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  String get formattedAmount {
    final formatted = _formatAmount(amount);
    return type == TransactionType.credit ? '+ SAR $formatted' : '- SAR $formatted';
  }

  String _formatAmount(double value) {
    final parts = value.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }
}

enum TransactionType {
  debit,  // money spent (negative)
  credit, // money added (positive)
}

class TopUpOptionModel {
  final String id;
  final double amount;
  final bool isCustom;

  const TopUpOptionModel({
    required this.id,
    required this.amount,
    this.isCustom = false,
  });

  String get displayAmount {
    if (isCustom) return 'Custom Amount';
    return 'SAR ${_formatAmount(amount)}';
  }

  String _formatAmount(double value) {
    final parts = value.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }
}

class PaymentMethodModel {
  final String id;
  final String name;
  final String icon; // emoji or icon name
  final bool isAvailable;

  const PaymentMethodModel({
    required this.id,
    required this.name,
    required this.icon,
    this.isAvailable = true,
  });
}
