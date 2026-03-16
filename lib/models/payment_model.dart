// ─────────────────────────────────────────────────────────────────────────────
// payment_model.dart
// All data models for the Make Payment feature
// ─────────────────────────────────────────────────────────────────────────────

enum PaymentMethod { wallet, bankTransfer, onlineCard, cashAtBranch, payMonthly }

enum PaymentConfirmStatus { idle, processing, success, error, skipped }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.wallet:       return 'Wallet balance';
      case PaymentMethod.bankTransfer: return 'Bank Transfer (IBAN)';
      case PaymentMethod.onlineCard:   return 'Online Card Payment';
      case PaymentMethod.cashAtBranch: return 'Cash at Branch';
      case PaymentMethod.payMonthly:   return 'Monthly Billing';
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
      case PaymentMethod.payMonthly:
        return 'Order placed now, settled in monthly billing cycle';
    }
  }

  bool get isRecommended  => this == PaymentMethod.wallet;
  bool get isMonthly      => this == PaymentMethod.payMonthly;
}

class PaymentSummary {
  final String invoiceRef;
  final double totalAmount;
  final double walletBalance;

  const PaymentSummary({
    required this.invoiceRef,
    required this.totalAmount,
    required this.walletBalance,
  });

  double get maxWalletUsable =>
      walletBalance < totalAmount ? walletBalance : totalAmount;

  double remaining(double walletUsed) =>
      (totalAmount - walletUsed).clamp(0, totalAmount);
}

// ─────────────────────────────────────────────────────────────────────────────
// Receipt shown after a successful POST /corporate/make_payment
// ─────────────────────────────────────────────────────────────────────────────

class PaymentReceiptModel {
  final String   receiptNumber;
  final String   orderId;
  final String   method;
  final double   amountPaid;
  final double   walletUsed;
  final DateTime timestamp;
  final String   status;
  final String?  notes;

  const PaymentReceiptModel({
    required this.receiptNumber,
    required this.orderId,
    required this.method,
    required this.amountPaid,
    required this.walletUsed,
    required this.timestamp,
    required this.status,
    this.notes,
  });

  bool get isMonthlyBilling => method == 'Monthly Billing';
}

// ─────────────────────────────────────────────────────────────────────────────
// Parsed result of POST /corporate/make_payment
// ─────────────────────────────────────────────────────────────────────────────

class OrderPaymentResult {
  final String   message;
  final String   orderId;
  final String   bookingCode;
  final String   status;
  final DateTime submittedAt;
  final String   paymentMethod;
  final String?  notes;

  const OrderPaymentResult({
    required this.message,
    required this.orderId,
    required this.bookingCode,
    required this.status,
    required this.submittedAt,
    required this.paymentMethod,
    this.notes,
  });

  factory OrderPaymentResult.fromMap(Map<String, dynamic> map) {
    final order = map['order'] as Map<String, dynamic>? ?? {};

    DateTime submittedAt;
    try {
      submittedAt = DateTime.parse(order['submittedAt']?.toString() ?? '');
    } catch (_) {
      submittedAt = DateTime.now();
    }

    return OrderPaymentResult(
      message:       map['message']?.toString() ?? 'Order placed successfully.',
      orderId:       order['id']?.toString() ?? '',
      bookingCode:   order['bookingCode']?.toString() ?? '',
      status:        order['status']?.toString() ?? 'submitted',
      submittedAt:   submittedAt,
      paymentMethod: order['paymentMethod']?.toString() ?? '',
      notes:         order['notes']?.toString(),
    );
  }
}