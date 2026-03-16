import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// quotation_history_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum QuotationStatus { approved, rejected, pending }

extension QuotationStatusInfo on QuotationStatus {
  String get label {
    switch (this) {
      case QuotationStatus.approved: return 'Approved';
      case QuotationStatus.rejected: return 'Rejected';
      case QuotationStatus.pending:  return 'Pending';
    }
  }

  Color get color {
    switch (this) {
      case QuotationStatus.approved: return const Color(0xFF2E7D32); // green
      case QuotationStatus.rejected: return const Color(0xFFC62828); // red
      case QuotationStatus.pending:  return const Color(0xFFE65100); // orange
    }
  }

  Color get bgColor {
    switch (this) {
      case QuotationStatus.approved: return const Color(0xFFE8F5E9);
      case QuotationStatus.rejected: return const Color(0xFFFFEBEE);
      case QuotationStatus.pending:  return const Color(0xFFFFF3E0);
    }
  }
}

class QuotationHistoryItem {
  final String id;  // ✅ Added for API
  final String quotationNumber;
  final DateTime date;
  final String productService;
  final String qty;
  final double quotedPrice;
  final String unit;
  final QuotationStatus status;
  final String? rejectionReason;
  final String submittedBy;

  const QuotationHistoryItem({
    required this.id,  // ✅ Added
    required this.quotationNumber,
    required this.date,
    required this.productService,
    required this.qty,
    required this.quotedPrice,
    required this.unit,
    required this.status,
    this.rejectionReason,
    required this.submittedBy,
  });

  String get formattedPrice => 'SAR ${quotedPrice.toStringAsFixed(2)}$unit';
}

class QuotationHistorySummary {
  final int total;
  final int approved;
  final int rejected;
  final int pending;
  final double totalQuotedValue;

  const QuotationHistorySummary({
    required this.total,
    required this.approved,
    required this.rejected,
    required this.pending,
    required this.totalQuotedValue,
  });
}

class QuotationHistoryFilters {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? productQuery;
  final QuotationStatus? status;
  final String? submittedBy;

  const QuotationHistoryFilters({
    this.fromDate,
    this.toDate,
    this.productQuery,
    this.status,
    this.submittedBy,
  });

  QuotationHistoryFilters copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? productQuery,
    QuotationStatus? status,
    String? submittedBy,
    bool clearFromDate = false,
    bool clearToDate   = false,
    bool clearStatus   = false,
    bool clearSubmittedBy = false,
  }) {
    return QuotationHistoryFilters(
      fromDate:    clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate:      clearToDate   ? null : (toDate   ?? this.toDate),
      productQuery: productQuery ?? this.productQuery,
      status:      clearStatus   ? null : (status   ?? this.status),
      submittedBy: clearSubmittedBy ? null : (submittedBy ?? this.submittedBy),
    );
  }

  bool get hasAny =>
      fromDate != null ||
          toDate   != null ||
          (productQuery != null && productQuery!.isNotEmpty) ||
          status   != null ||
          submittedBy != null;
}