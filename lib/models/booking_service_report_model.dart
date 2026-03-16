import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/models/booking_service_report_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum BookingStatus { completed, inProgress, cancelled, pending, submitted, draft }

extension BookingStatusInfo on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.completed:  return 'Completed';
      case BookingStatus.inProgress: return 'In Progress';
      case BookingStatus.cancelled:  return 'Cancelled';
      case BookingStatus.pending:    return 'Pending';
      case BookingStatus.submitted:  return 'Submitted';
      case BookingStatus.draft:      return 'Draft';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.completed:  return const Color(0xFF2E7D32);
      case BookingStatus.inProgress: return const Color(0xFF1565C0);
      case BookingStatus.cancelled:  return const Color(0xFFC62828);
      case BookingStatus.pending:    return const Color(0xFFE65100);
      case BookingStatus.submitted:  return const Color(0xFF0277BD);
      case BookingStatus.draft:      return const Color(0xFF6D4C41);
    }
  }

  Color get bgColor {
    switch (this) {
      case BookingStatus.completed:  return const Color(0xFFE8F5E9);
      case BookingStatus.inProgress: return const Color(0xFFE3F2FD);
      case BookingStatus.cancelled:  return const Color(0xFFFFEBEE);
      case BookingStatus.pending:    return const Color(0xFFFFF3E0);
      case BookingStatus.submitted:  return const Color(0xFFE1F5FE);
      case BookingStatus.draft:      return const Color(0xFFEFEBE9);
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.completed:  return Icons.check_circle_outline_rounded;
      case BookingStatus.inProgress: return Icons.autorenew_rounded;
      case BookingStatus.cancelled:  return Icons.cancel_outlined;
      case BookingStatus.pending:    return Icons.schedule_rounded;
      case BookingStatus.submitted:  return Icons.send_rounded;
      case BookingStatus.draft:      return Icons.edit_outlined;
    }
  }

  /// Maps API status strings → enum value.
  static BookingStatus fromString(String raw) {
    switch (raw.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
      case 'completed':  return BookingStatus.completed;
      case 'inprogress': return BookingStatus.inProgress;
      case 'cancelled':
      case 'canceled':   return BookingStatus.cancelled;
      case 'pending':    return BookingStatus.pending;
      case 'submitted':  return BookingStatus.submitted;
      case 'draft':      return BookingStatus.draft;
      default:           return BookingStatus.pending;
    }
  }
}

enum ServiceType { oilChange, fullService, tireService, carWash, inspection, brakes, ac, general }

extension ServiceTypeInfo on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.oilChange:   return 'Oil Change';
      case ServiceType.fullService: return 'Full Service';
      case ServiceType.tireService: return 'Tire Service';
      case ServiceType.carWash:     return 'Car Wash';
      case ServiceType.inspection:  return 'Inspection';
      case ServiceType.brakes:      return 'Brake Service';
      case ServiceType.ac:          return 'A/C Service';
      case ServiceType.general:     return 'Service';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceType.oilChange:   return Icons.opacity_rounded;
      case ServiceType.fullService: return Icons.build_circle_outlined;
      case ServiceType.tireService: return Icons.tire_repair_rounded;
      case ServiceType.carWash:     return Icons.local_car_wash_rounded;
      case ServiceType.inspection:  return Icons.search_rounded;
      case ServiceType.brakes:      return Icons.disc_full_rounded;
      case ServiceType.ac:          return Icons.ac_unit_rounded;
      case ServiceType.general:     return Icons.build_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class BookingServiceItem {
  final String id;
  final String? invoiceNo;

  final String bookingId;
  final DateTime date;
  final String vehiclePlate;
  final String department;
  final ServiceType serviceType;
  final String branch;
  final BookingStatus status;
  final double? amount;

  const BookingServiceItem({
    required this.id,
    required this.bookingId,
    required this.date,
    required this.vehiclePlate,
    required this.department,
    required this.serviceType,
    required this.branch,
    required this.status,
    required this.invoiceNo,
    this.amount,
  });

  String get formattedAmount =>
      amount != null && amount! > 0 ? 'SAR ${_fmtAmt(amount!)}' : '—';

  // ── Parse from GET /corporate/reports/history item ────────────────────────
  // API shape: { id, date, vehicle, branch, amount, status }
  factory BookingServiceItem.fromApiMap(Map<String, dynamic> map) {
    // Date
    DateTime date;
    try {
      date = DateTime.parse(map['date']?.toString() ?? '');
    } catch (_) {
      date = DateTime.now();
    }

    // Amount (treat 0 as "no amount")
    final rawAmount = (map['amount'] as num?)?.toDouble() ?? 0.0;

    return BookingServiceItem(
      id:           map['id']?.toString() ?? '',
      invoiceNo:           map['invoice_no']?.toString() ?? '',
      bookingId:    '#${map['id']?.toString() ?? ''}',
      date:         date,
      vehiclePlate: map['vehicle']?.toString() ?? '—',
      department:   map['department']?.toString() ?? '—',
      serviceType:  ServiceType.general,    // API doesn't return serviceType
      branch:       map['branch']?.toString() ?? '—',
      status:       BookingStatusInfo.fromString(map['status']?.toString() ?? ''),
      amount:       rawAmount > 0 ? rawAmount : null,
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

// ─────────────────────────────────────────────────────────────────────────────

class BookingServiceSummary {
  final int totalBookings;
  final int completed;
  final int inProgress;
  final int cancelled;
  final int pending;
  final int submitted;
  final double totalSpend;

  const BookingServiceSummary({
    required this.totalBookings,
    required this.completed,
    required this.inProgress,
    required this.cancelled,
    required this.pending,
    required this.submitted,
    required this.totalSpend,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class BookingServiceFilters {
  final DateTime?      fromDate;
  final DateTime?      toDate;
  final BookingStatus? status;
  final String?        branchId;   // stored as id for API, display name shown in dropdown
  final String?        branchName; // shown in dropdown

  const BookingServiceFilters({
    this.fromDate,
    this.toDate,
    this.status,
    this.branchId,
    this.branchName,
  });

  BookingServiceFilters copyWith({
    DateTime?      fromDate,
    DateTime?      toDate,
    BookingStatus? status,
    String?        branchId,
    String?        branchName,
    bool clearFromDate  = false,
    bool clearToDate    = false,
    bool clearStatus    = false,
    bool clearBranch    = false,
  }) {
    return BookingServiceFilters(
      fromDate:   clearFromDate ? null : (fromDate   ?? this.fromDate),
      toDate:     clearToDate   ? null : (toDate     ?? this.toDate),
      status:     clearStatus   ? null : (status     ?? this.status),
      branchId:   clearBranch   ? null : (branchId   ?? this.branchId),
      branchName: clearBranch   ? null : (branchName ?? this.branchName),
    );
  }

  bool get hasAny =>
      fromDate != null || toDate   != null ||
          status   != null || branchId != null;
}