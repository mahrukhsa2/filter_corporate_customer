// ─────────────────────────────────────────────────────────────────────────────
// booking_model.dart (Extended)
// Additional model for My Bookings / Orders history
// ─────────────────────────────────────────────────────────────────────────────

class BookingHistoryModel {
  final String id;
  final String serviceName;
  final DateTime date;
  final String branchName;
  final String status; // Completed, In Progress, Upcoming, Cancelled
  final String? invoiceNumber;
  final double? amount;
  final bool isPaid;
  final String? vehicleInfo;

  const BookingHistoryModel({
    required this.id,
    required this.serviceName,
    required this.date,
    required this.branchName,
    required this.status,
    this.invoiceNumber,
    this.amount,
    this.isPaid = false,
    this.vehicleInfo,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Original booking models (from your existing file)
// ─────────────────────────────────────────────────────────────────────────────

class DepartmentModel {
  final String id;
  final String name;
  final String icon; // emoji for quick visual

  const DepartmentModel({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class BookingVehicleModel {
  final String id;
  final String make;
  final String model;
  final String plateNumber;
  final bool isDefault;

  const BookingVehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.plateNumber,
    this.isDefault = false,
  });

  String get displayName => '$make $model – $plateNumber';
}

class BranchModel {
  final String id;
  final String name;
  final String city;

  const BranchModel({
    required this.id,
    required this.name,
    required this.city,
  });

  String get displayName => '$name, $city';
}

class TimeSlotModel {
  final String id;
  final String label;   // e.g. "09:00 AM"
  final bool available;

  const TimeSlotModel({
    required this.id,
    required this.label,
    required this.available,
  });
}

class BookingSubmitPayload {
  final String departmentId;
  final String vehicleId;
  final String branchId;
  final DateTime date;
  final String timeSlotId;
  final String notes;
  final bool payFromWallet;

  const BookingSubmitPayload({
    required this.departmentId,
    required this.vehicleId,
    required this.branchId,
    required this.date,
    required this.timeSlotId,
    required this.notes,
    required this.payFromWallet,
  });
}
