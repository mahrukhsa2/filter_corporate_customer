// ─────────────────────────────────────────────────────────────────────────────
// reports_model.dart
// All data models for the Reports & Analytics feature
// ─────────────────────────────────────────────────────────────────────────────

enum ReportCategory {
  monthlyBilling,
  bookingHistory,
  quotationHistory,
  walletTransactions,
  savingsDiscount,
  vehicleUsage,
  paymentHistory,
}

extension ReportCategoryInfo on ReportCategory {
  String get title {
    switch (this) {
      case ReportCategory.monthlyBilling:     return 'Monthly Billing Summary';
      case ReportCategory.bookingHistory:     return 'Booking & Service History';
      case ReportCategory.quotationHistory:   return 'Quotation History';
      case ReportCategory.walletTransactions: return 'Wallet Transaction History';
      case ReportCategory.savingsDiscount:    return 'Savings & Discount Report';
      case ReportCategory.vehicleUsage:       return 'Vehicle-wise Usage Report';
      case ReportCategory.paymentHistory:     return 'Payment History';
    }
  }

  String get subtitle {
    switch (this) {
      case ReportCategory.monthlyBilling:     return 'Invoices & billing per month';
      case ReportCategory.bookingHistory:     return 'All service appointments';
      case ReportCategory.quotationHistory:   return 'Submitted price quotations';
      case ReportCategory.walletTransactions: return 'Top-ups & deductions';
      case ReportCategory.savingsDiscount:    return 'Corporate savings breakdown';
      case ReportCategory.vehicleUsage:       return 'Spend per registered vehicle';
      case ReportCategory.paymentHistory:     return 'All payment transactions';
    }
  }

  /// Exact string the /corporate/reports/custom API expects for the `type` param.
  String get apiType {
    switch (this) {
      case ReportCategory.monthlyBilling:     return 'Monthly billing Summary';
      case ReportCategory.bookingHistory:     return 'Booking and service history';
      case ReportCategory.quotationHistory:   return 'Quotation History';
      case ReportCategory.walletTransactions: return 'Wallet Transaction History';
      case ReportCategory.savingsDiscount:    return 'Savings and discount report';
      case ReportCategory.vehicleUsage:       return 'Vehicle-wise usage Report';
      case ReportCategory.paymentHistory:     return 'Payment history';
    }
  }

  String get iconAsset {
    switch (this) {
      case ReportCategory.monthlyBilling:     return 'receipt_long';
      case ReportCategory.bookingHistory:     return 'calendar_month';
      case ReportCategory.quotationHistory:   return 'request_quote';
      case ReportCategory.walletTransactions: return 'account_balance_wallet';
      case ReportCategory.savingsDiscount:    return 'savings';
      case ReportCategory.vehicleUsage:       return 'directions_car';
      case ReportCategory.paymentHistory:     return 'payments';
    }
  }

  String get route {
    switch (this) {
      case ReportCategory.monthlyBilling:     return '/reports/monthly-billing';
      case ReportCategory.bookingHistory:     return '/reports/booking-service-history';
      case ReportCategory.quotationHistory:   return '/reports/quotation-history';
      case ReportCategory.walletTransactions: return '/reports/wallet-transactions';
      case ReportCategory.savingsDiscount:    return '/reports/savings';
      case ReportCategory.vehicleUsage:       return '/reports/vehicle-usage';
      case ReportCategory.paymentHistory:     return '/reports/payment-history';
    }
  }
}

class ReportsSummary {
  final double totalSpentThisYear;
  final double thisMonthAmount;
  final int    thisMonthInvoices;
  final double totalSavings;
  final double savingsPercent;
  final double walletUsed;
  final double walletUsedPercent;

  const ReportsSummary({
    required this.totalSpentThisYear,
    required this.thisMonthAmount,
    this.thisMonthInvoices  = 0,
    required this.totalSavings,
    this.savingsPercent     = 0,
    required this.walletUsed,
    this.walletUsedPercent  = 0,
  });

  factory ReportsSummary.fromMap(Map<String, dynamic> map) {
    return ReportsSummary(
      totalSpentThisYear: (map["totalSpentThisYear"] as num?)?.toDouble() ?? 0.0,
      thisMonthAmount:    (map["thisMonthAmount"]    as num?)?.toDouble() ?? 0.0,
      thisMonthInvoices:  (map["thisMonthInvoices"]  as num?)?.toInt()    ?? 0,
      totalSavings:       (map["totalSavings"]       as num?)?.toDouble() ?? 0.0,
      savingsPercent:     (map["savingsPercent"]     as num?)?.toDouble() ?? 0.0,
      walletUsed:         (map["walletUsed"]         as num?)?.toDouble() ?? 0.0,
      walletUsedPercent:  (map["walletUsedPercent"]  as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CustomReportRequest {
  final DateTime fromDate;
  final DateTime toDate;
  final ReportCategory category;

  const CustomReportRequest({
    required this.fromDate,
    required this.toDate,
    required this.category,
  });
}