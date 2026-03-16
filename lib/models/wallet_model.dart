// ─────────────────────────────────────────────────────────────────────────────
// lib/models/wallet_model.dart
//
// API shape (GET /corporate/wallet):
// {
//   "success": true,
//   "balance": 0,
//   "total_topups": 0,
//   "total_spent": 0,
//   "currency": "SAR",
//   "transactions": []
// }
//
// TopUpOptionModel and PaymentMethodModel are local config — not from API.
// WalletTransactionModel.fromMap() handles whatever the server sends per item.
// ─────────────────────────────────────────────────────────────────────────────

// ── Wallet summary (top-level API response) ───────────────────────────────────

class WalletSummaryModel {
  final double balance;
  final double totalTopups;
  final double totalSpent;
  final String currency;
  final List<WalletTransactionModel> transactions;

  const WalletSummaryModel({
    required this.balance,
    required this.totalTopups,
    required this.totalSpent,
    required this.currency,
    required this.transactions,
  });

  factory WalletSummaryModel.fromMap(Map<String, dynamic> map) {
    // Parse transactions array — defensive: handles null or non-list
    final rawTransactions = map['transactions'];
    final List<WalletTransactionModel> transactions = [];

    if (rawTransactions is List) {
      for (int i = 0; i < rawTransactions.length; i++) {
        final item = rawTransactions[i];
        if (item is Map<String, dynamic>) {
          try {
            transactions.add(WalletTransactionModel.fromMap(item));
          } catch (e) {
            // Skip malformed items — never crash the screen
          }
        }
      }
    }

    // Sort newest first (in case server doesn't guarantee order)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return WalletSummaryModel(
      balance:      (map['balance']      as num?)?.toDouble() ?? 0.0,
      totalTopups:  (map['total_topups'] as num?)?.toDouble() ?? 0.0,
      totalSpent:   (map['total_spent']  as num?)?.toDouble() ?? 0.0,
      currency:     map['currency']?.toString() ?? 'SAR',
      transactions: transactions,
    );
  }

  /// Creates a copy with an updated balance and prepended transaction.
  /// Used for optimistic local top-up updates.
  WalletSummaryModel withTopUp(WalletTransactionModel tx) {
    return WalletSummaryModel(
      balance:      balance + tx.amount,
      totalTopups:  totalTopups + tx.amount,
      totalSpent:   totalSpent,
      currency:     currency,
      transactions: [tx, ...transactions],
    );
  }
}

// ── Wallet summary stats (GET /corporate/wallet/summary) ─────────────────────
// { success, totalTopups, totalSpent, netMovement, currentBalance }

class WalletSummaryStatsModel {
  final double currentBalance;
  final double totalTopups;
  final double totalSpent;
  final double netMovement;

  const WalletSummaryStatsModel({
    required this.currentBalance,
    required this.totalTopups,
    required this.totalSpent,
    required this.netMovement,
  });
}

// ── Transaction ───────────────────────────────────────────────────────────────

class WalletTransactionModel {
  final String          id;
  final DateTime        date;
  final String          description;
  final double          amount;
  final TransactionType type;
  final String?         invoiceNumber;
  final String?         referenceNumber;
  final String?         status;   // e.g. "completed", "pending", "failed"

  const WalletTransactionModel({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    this.invoiceNumber,
    this.referenceNumber,
    this.status,
  });

  // ── Parse from API transaction item ────────────────────────────────────────
  // Defensive field mapping — covers common backend naming conventions.
  // Update field names here when the server shape is confirmed.
  factory WalletTransactionModel.fromMap(Map<String, dynamic> map) {
    // Type: look for "type", "transaction_type", "transactionType"
    // Treat "credit", "topup", "top_up" as credit; everything else as debit
    final rawType = (map['type'] ??
        map['transaction_type'] ??
        map['transactionType'] ??
        '')
        .toString()
        .toLowerCase();
    final type = (rawType == 'credit' ||
        rawType == 'topup' ||
        rawType == 'top_up' ||
        rawType == 'top-up')
        ? TransactionType.credit
        : TransactionType.debit;

    // Date: look for "date", "created_at", "createdAt", "transaction_date"
    final rawDate = map['date'] ??
        map['created_at'] ??
        map['createdAt'] ??
        map['transaction_date'];
    DateTime date;
    try {
      date = rawDate != null
          ? DateTime.parse(rawDate.toString())
          : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    // Description: look for "description", "note", "remarks", "narration"
    final description = (map['description'] ??
        map['note'] ??
        map['remarks'] ??
        map['narration'] ??
        'Transaction')
        .toString();

    // Amount: always positive — sign is conveyed by type
    final amount =
    ((map['amount'] as num?)?.toDouble() ?? 0.0).abs();

    return WalletTransactionModel(
      id:              map['id']?.toString() ?? '',
      date:            date,
      description:     description,
      amount:          amount,
      type:            type,
      invoiceNumber:   (map['invoice_number'] ?? map['invoiceNumber'])
          ?.toString(),
      referenceNumber: (map['reference_number'] ??
          map['referenceNumber'] ??
          map['ref'])
          ?.toString(),
      status:          map['status']?.toString(),
    );
  }

  // ── Display helpers ────────────────────────────────────────────────────────

  String get formattedDate {
    final day    = date.day.toString().padLeft(2, '0');
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May',
      'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '$day ${months[date.month - 1]} ${date.year}';
  }

  String get formattedAmount {
    final formatted = _fmtAmount(amount);
    return type == TransactionType.credit
        ? '+ SAR $formatted'
        : '- SAR $formatted';
  }

  String _fmtAmount(double value) {
    final parts = value.toStringAsFixed(0).split('');
    final buf   = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }
}

enum TransactionType { debit, credit }

// ── Top-up options — local config, NOT from API ───────────────────────────────

class TopUpOptionModel {
  final String id;
  final double amount;
  final bool   isCustom;

  const TopUpOptionModel({
    required this.id,
    required this.amount,
    this.isCustom = false,
  });

  String get displayAmount {
    if (isCustom) return 'Custom Amount';
    return 'SAR ${_fmt(amount)}';
  }

  String _fmt(double value) {
    final parts = value.toStringAsFixed(0).split('');
    final buf   = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }
}

// ── Payment methods — local config, NOT from API ──────────────────────────────

class PaymentMethodModel {
  final String id;
  final String name;
  final String icon;
  final bool   isAvailable;

  const PaymentMethodModel({
    required this.id,
    required this.name,
    required this.icon,
    this.isAvailable = true,
  });
}