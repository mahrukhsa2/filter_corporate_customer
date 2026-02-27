// ─────────────────────────────────────────────────────────────────────────────
// lib/models/booking_model.dart
// ─────────────────────────────────────────────────────────────────────────────

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

  /// Factory constructor from API order response
  factory BookingHistoryModel.fromOrderMap(Map<String, dynamic> map) {
    // Map API status to display status
    final apiStatus = map['status']?.toString().toLowerCase() ?? '';
    final displayStatus = _mapApiStatus(apiStatus);

    // Parse date
    DateTime date;
    try {
      date = DateTime.parse(map['submittedAt']?.toString() ?? '');
    } catch (_) {
      date = DateTime.now();
    }

    return BookingHistoryModel(
      id: map['id']?.toString() ?? '',
      serviceName: map['workshopName']?.toString() ?? 'Service',
      date: date,
      branchName: map['branchName']?.toString() ?? '',
      status: displayStatus,
      invoiceNumber: null, // Will be populated when order is completed
      amount: null,
      isPaid: false,
      vehicleInfo: null, // API doesn't return vehicle info in list
    );
  }

  /// Maps API status to display-friendly status
  static String _mapApiStatus(String apiStatus) {
    switch (apiStatus) {
      case 'submitted':
      case 'pending':
        return 'Upcoming';
      case 'approved':
      case 'in_progress':
      case 'processing':
        return 'In Progress';
      case 'completed':
      case 'delivered':
        return 'Completed';
      case 'cancelled':
      case 'rejected':
        return 'Cancelled';
      default:
        return 'Upcoming';
    }
  }

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

/// Response model for GET /corporate/orders
class OrdersResponseModel {
  final bool success;
  final List<BookingHistoryModel> orders;
  final int total;
  final int limit;
  final int offset;

  const OrdersResponseModel({
    required this.success,
    required this.orders,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory OrdersResponseModel.fromMap(Map<String, dynamic> map) {
    final ordersList = map['orders'] as List<dynamic>? ?? [];

    return OrdersResponseModel(
      success: map['success'] as bool? ?? false,
      orders: ordersList
          .map((item) => BookingHistoryModel.fromOrderMap(
          item as Map<String, dynamic>))
          .toList(),
      total: map['total'] as int? ?? 0,
      limit: map['limit'] as int? ?? 20,
      offset: map['offset'] as int? ?? 0,
    );
  }
}

/// Detailed order model (for single order fetch if needed)
class OrderDetailModel {
  final String id;
  final String status;
  final DateTime submittedAt;
  final String branchId;
  final String branchName;
  final String workshopId;
  final String workshopName;

  const OrderDetailModel({
    required this.id,
    required this.status,
    required this.submittedAt,
    required this.branchId,
    required this.branchName,
    required this.workshopId,
    required this.workshopName,
  });

  factory OrderDetailModel.fromMap(Map<String, dynamic> map) {
    DateTime date;
    try {
      date = DateTime.parse(map['submittedAt']?.toString() ?? '');
    } catch (_) {
      date = DateTime.now();
    }

    return OrderDetailModel(
      id: map['id']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      submittedAt: date,
      branchId: map['branchId']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? '',
      workshopId: map['workshopId']?.toString() ?? '',
      workshopName: map['workshopName']?.toString() ?? '',
    );
  }
}

// ── Department ────────────────────────────────────────────────────────────────

class DepartmentModel {
  final String id;
  final String name;
  // API does not return an icon — we use a default emoji fallback.
  // If the backend adds an icon field later, just update fromMap().
  final String icon;

  const DepartmentModel({
    required this.id,
    required this.name,
    this.icon = '🔧',
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id:   map['id']?.toString()   ?? '',
      name: map['name']?.toString() ?? '',
      icon: map['icon']?.toString() ?? '🔧',
    );
  }

  // Equality by id — required so DropdownButton can match selected value
  @override
  bool operator ==(Object other) =>
      other is DepartmentModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ── Branch ────────────────────────────────────────────────────────────────────

class BranchModel {
  final String id;
  final String name;
  final String address; // real API returns address, not city

  const BranchModel({
    required this.id,
    required this.name,
    this.address = '',
  });

  factory BranchModel.fromMap(Map<String, dynamic> map) {
    return BranchModel(
      id:      map['id']?.toString()      ?? '',
      name:    map['name']?.toString()    ?? '',
      address: map['address']?.toString() ?? '',
    );
  }

  // Used by the dropdown label — shows name only to keep it compact
  String get displayName => name;

  @override
  bool operator ==(Object other) =>
      other is BranchModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ── Vehicle (booking-scoped — not the full vehicle module model) ──────────────

class BookingVehicleModel {
  final String id;
  final String make;
  final String model;
  final String plateNumber;
  final bool   isDefault;

  const BookingVehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.plateNumber,
    this.isDefault = false,
  });

  factory BookingVehicleModel.fromMap(Map<String, dynamic> map) {
    return BookingVehicleModel(
      id:          map['id']?.toString()          ?? '',
      make:        map['make']?.toString()        ?? '',
      model:       map['model']?.toString()       ?? '',
      plateNumber: map['plateNumber']?.toString() ?? '',
      isDefault:   map['isDefault'] as bool?      ?? false,
    );
  }

  String get displayName => '$make $model – $plateNumber';

  @override
  bool operator ==(Object other) =>
      other is BookingVehicleModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ── Time slot ─────────────────────────────────────────────────────────────────

class TimeSlotModel {
  final String id;
  final String label;
  final bool   available;

  const TimeSlotModel({
    required this.id,
    required this.label,
    required this.available,
  });

  factory TimeSlotModel.fromMap(Map<String, dynamic> map) {
    return TimeSlotModel(
      id:        map['id']?.toString()     ?? '',
      label:     map['label']?.toString()  ?? '',
      available: map['available'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TimeSlotModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ── Submit payload ────────────────────────────────────────────────────────────

class BookingSubmitPayload {
  final String   departmentId;
  final String   vehicleId;
  final String   branchId;
  final DateTime date;
  final String   timeSlotId;
  final String   notes;
  final bool     payFromWallet;

  const BookingSubmitPayload({
    required this.departmentId,
    required this.vehicleId,
    required this.branchId,
    required this.date,
    required this.timeSlotId,
    required this.notes,
    required this.payFromWallet,
  });

  Map<String, dynamic> toMap() => {
    'departmentId':  departmentId,
    'vehicleId':     vehicleId,
    'branchId':      branchId,
    'date':          date.toIso8601String(),
    'timeSlotId':    timeSlotId,
    'notes':         notes,
    'payFromWallet': payFromWallet,
  };
}