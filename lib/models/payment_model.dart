// ─────────────────────────────────────────────────────────────────────────────
// payment_model.dart
// All data models for the Make Payment feature
// ─────────────────────────────────────────────────────────────────────────────

enum PaymentMethod { wallet, bankTransfer, onlineCard, cashAtBranch }

enum PaymentConfirmStatus { idle, processing, success, error }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.wallet:
        return 'Wallet Balance';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer (IBAN)';
      case PaymentMethod.onlineCard:
        return 'Online Card Payment';
      case PaymentMethod.cashAtBranch:
        return 'Cash at Branch';
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentMethod.wallet:
        return 'Instant deduction from wallet';
      case PaymentMethod.bankTransfer:
        return 'Transfer to IBAN SA03 8000 0000 6080 1016 7519';
      case PaymentMethod.onlineCard:
        return 'Visa / Mastercard / Mada';
      case PaymentMethod.cashAtBranch:
        return 'Generate a reference code to pay at branch';
    }
  }

  bool get isRecommended => this == PaymentMethod.wallet;
}

class PaymentSummary {
  final String invoiceRef;      // e.g. "Monthly Billing – February 2026"
  final double totalAmount;
  final double walletBalance;

  const PaymentSummary({
    required this.invoiceRef,
    required this.totalAmount,
    required this.walletBalance,
  });

  /// Max wallet portion that can be used (cannot exceed total)
  double get maxWalletUsable =>
      walletBalance < totalAmount ? walletBalance : totalAmount;

  /// Remaining to be settled by secondary method
  double remaining(double walletUsed) =>
      (totalAmount - walletUsed).clamp(0, totalAmount);
}

class PaymentReceiptModel {
  final String receiptNumber;
  final String method;
  final double amountPaid;
  final double walletUsed;
  final DateTime timestamp;
  final String status;

  const PaymentReceiptModel({
    required this.receiptNumber,
    required this.method,
    required this.amountPaid,
    required this.walletUsed,
    required this.timestamp,
    required this.status,
  });
}
