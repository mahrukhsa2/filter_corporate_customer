import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// booking_service_report_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum BookingStatus { completed, inProgress, cancelled, pending }

extension BookingStatusInfo on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.completed:  return 'Completed';
      case BookingStatus.inProgress: return 'In Progress';
      case BookingStatus.cancelled:  return 'Cancelled';
      case BookingStatus.pending:    return 'Pending';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.completed:  return const Color(0xFF2E7D32);
      case BookingStatus.inProgress: return const Color(0xFF1565C0);
      case BookingStatus.cancelled:  return const Color(0xFFC62828);
      case BookingStatus.pending:    return const Color(0xFFE65100);
    }
  }

  Color get bgColor {
    switch (this) {
      case BookingStatus.completed:  return const Color(0xFFE8F5E9);
      case BookingStatus.inProgress: return const Color(0xFFE3F2FD);
      case BookingStatus.cancelled:  return const Color(0xFFFFEBEE);
      case BookingStatus.pending:    return const Color(0xFFFFF3E0);
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.completed:  return Icons.check_circle_outline_rounded;
      case BookingStatus.inProgress: return Icons.autorenew_rounded;
      case BookingStatus.cancelled:  return Icons.cancel_outlined;
      case BookingStatus.pending:    return Icons.schedule_rounded;
    }
  }
}

enum ServiceType { oilChange, fullService, tireService, carWash, inspection, brakes, ac }

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
    }
  }
}

class BookingServiceItem {
  final String id;
  final String bookingId;       // BK-9876
  final DateTime date;
  final String vehiclePlate;
  final String department;
  final ServiceType serviceType;
  final String branch;
  final BookingStatus status;
  final double? amount;         // null if in-progress / cancelled

  const BookingServiceItem({
    required this.id,
    required this.bookingId,
    required this.date,
    required this.vehiclePlate,
    required this.department,
    required this.serviceType,
    required this.branch,
    required this.status,
    this.amount,
  });

  String get formattedAmount =>
      amount != null ? 'SAR ${_fmtAmt(amount!)}' : '—';
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

class BookingServiceSummary {
  final int totalBookings;
  final int completed;
  final int inProgress;
  final int cancelled;
  final int pending;
  final double totalSpend;

  const BookingServiceSummary({
    required this.totalBookings,
    required this.completed,
    required this.inProgress,
    required this.cancelled,
    required this.pending,
    required this.totalSpend,
  });
}

class BookingServiceFilters {
  final DateTime?      fromDate;
  final DateTime?      toDate;
  final BookingStatus? status;
  final String?        branch;

  const BookingServiceFilters({
    this.fromDate,
    this.toDate,
    this.status,
    this.branch,
  });

  BookingServiceFilters copyWith({
    DateTime?      fromDate,
    DateTime?      toDate,
    BookingStatus? status,
    String?        branch,
    bool clearFromDate = false,
    bool clearToDate   = false,
    bool clearStatus   = false,
    bool clearBranch   = false,
  }) {
    return BookingServiceFilters(
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate:   clearToDate   ? null : (toDate   ?? this.toDate),
      status:   clearStatus   ? null : (status   ?? this.status),
      branch:   clearBranch   ? null : (branch   ?? this.branch),
    );
  }

  bool get hasAny =>
      fromDate != null || toDate != null ||
      status   != null || branch != null;
}
