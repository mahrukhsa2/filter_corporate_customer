// ─────────────────────────────────────────────────────────────────────────────
// lib/models/booking_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class BookingHistoryModel {
  final String  id;
  final String  serviceName;   // workshopName from API
  final DateTime date;         // submittedAt from API
  final DateTime? bookedFor;   // bookedFor from API
  final String  branchName;
  final String  status;        // display status mapped from API status
  final String? bookingCode;
  final String? paymentMethod;
  final String? invoiceNumber;
  final double? amount;
  final bool    isPaid;
  final String? vehicleInfo;   // formatted from vehicle object

  const BookingHistoryModel({
    required this.id,
    required this.serviceName,
    required this.date,
    this.bookedFor,
    required this.branchName,
    required this.status,
    this.bookingCode,
    this.paymentMethod,
    this.invoiceNumber,
    this.amount,
    this.isPaid = false,
    this.vehicleInfo,
  });

  /// Factory from API order response.
  /// API shape:
  /// {
  ///   "id", "status", "submittedAt", "branchId", "branchName",
  ///   "workshopId", "workshopName",
  ///   "vehicle": { "id", "plateNo", "make", "model", "year" },
  ///   "departments": [],
  ///   "bookedFor", "bookingCode", "paymentMethod", "notes", "amount"
  /// }
  factory BookingHistoryModel.fromOrderMap(Map<String, dynamic> map) {
    final apiStatus    = map['status']?.toString().toLowerCase() ?? '';
    final displayStatus = _mapApiStatus(apiStatus);

    // submittedAt
    DateTime date;
    try {
      date = DateTime.parse(map['submittedAt']?.toString() ?? '');
    } catch (_) {
      date = DateTime.now();
    }

    // bookedFor
    DateTime? bookedFor;
    try {
      if (map['bookedFor'] != null) {
        bookedFor = DateTime.parse(map['bookedFor'].toString());
      }
    } catch (_) {}

    // vehicle → formatted string
    String? vehicleInfo;
    final vehicle = map['vehicle'];
    if (vehicle is Map<String, dynamic>) {
      final make  = vehicle['make']?.toString() ?? '';
      final model = vehicle['model']?.toString() ?? '';
      final plate = vehicle['plateNo']?.toString() ?? '';
      final year  = vehicle['year']?.toString() ?? '';
      vehicleInfo = '$make $model $year – $plate'.trim();
    }

    // amount
    double? amount;
    if (map['amount'] != null) {
      amount = (map['amount'] as num).toDouble();
    }

    return BookingHistoryModel(
      id:            map['id']?.toString() ?? '',
      serviceName:   map['workshopName']?.toString() ?? 'Service',
      date:          date,
      bookedFor:     bookedFor,
      branchName:    map['branchName']?.toString() ?? '',
      status:        displayStatus,
      bookingCode:   map['bookingCode']?.toString(),
      paymentMethod: map['paymentMethod']?.toString(),
      invoiceNumber: null,   // populated when order is completed
      amount:        amount,
      isPaid:        false,
      vehicleInfo:   vehicleInfo,
    );
  }

  static String _mapApiStatus(String s) => switch (s) {
    'submitted'                        => 'Submitted',
    'approved'                         => 'Approved',
    'in_progress'                      => 'In Progress',
    'completed' || 'invoiced'          => 'Completed',
    'cancelled'                        => 'Cancelled',
    'rejected'                         => 'Rejected',
        _    =>     '',
  };

  String get formattedDate {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day.toString().padLeft(2,'0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  String get formattedBookedFor {
    if (bookedFor == null) return '—';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = bookedFor!.hour.toString().padLeft(2,'0');
    final m = bookedFor!.minute.toString().padLeft(2,'0');
    return '${bookedFor!.day.toString().padLeft(2,'0')} '
        '${months[bookedFor!.month - 1]} ${bookedFor!.year}  $h:$m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /corporate/orders response
// ─────────────────────────────────────────────────────────────────────────────

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
    final list = map['orders'] as List<dynamic>? ?? [];
    return OrdersResponseModel(
      success: map['success'] as bool? ?? false,
      orders:  list.map((e) =>
          BookingHistoryModel.fromOrderMap(e as Map<String, dynamic>)).toList(),
      total:   map['total']  as int? ?? 0,
      limit:   map['limit']  as int? ?? 10,
      offset:  map['offset'] as int? ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /corporate/orders/:id detail
// ─────────────────────────────────────────────────────────────────────────────

class OrderDetailModel {
  final String   id;
  final String   status;
  final DateTime submittedAt;
  final String   branchId;
  final String   branchName;
  final String   workshopId;
  final String   workshopName;

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
    try { date = DateTime.parse(map['submittedAt']?.toString() ?? ''); }
    catch (_) { date = DateTime.now(); }
    return OrderDetailModel(
      id:           map['id']?.toString() ?? '',
      status:       map['status']?.toString() ?? '',
      submittedAt:  date,
      branchId:     map['branchId']?.toString() ?? '',
      branchName:   map['branchName']?.toString() ?? '',
      workshopId:   map['workshopId']?.toString() ?? '',
      workshopName: map['workshopName']?.toString() ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking vehicle (used in booking form)
// ─────────────────────────────────────────────────────────────────────────────

class BookingVehicleModel {
  final String id;
  final String make;
  final String model;
  final String plateNumber;
  final bool   isDefault;
  final int?   year;
  final String? color;

  const BookingVehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.plateNumber,
    this.isDefault = false,
    this.year,
    this.color,
  });

  factory BookingVehicleModel.fromMap(Map<String, dynamic> map) =>
      BookingVehicleModel(
        id:          map['id']?.toString() ?? '',
        make:        map['make']?.toString() ?? '',
        model:       map['model']?.toString() ?? '',
        plateNumber: map['plateNumber']?.toString() ?? '',
        isDefault:   map['isDefault'] as bool? ?? false,
        year:        map['year'] as int?,
        color:       map['color']?.toString(),
      );

  factory BookingVehicleModel.fromApiMap(Map<String, dynamic> map) =>
      BookingVehicleModel(
        id:          map['id']?.toString() ?? '',
        make:        map['make']?.toString() ?? '',
        model:       map['model']?.toString() ?? '',
        plateNumber: map['plateNo']?.toString() ?? '',
        isDefault:   false,
        year:        map['year'] as int?,
        color:       map['color']?.toString(),
      );

  String get displayName => year != null
      ? '$make $model $year – $plateNumber'
      : '$make $model – $plateNumber';

  @override
  bool operator ==(Object other) => other is BookingVehicleModel && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Time slot (used in booking form)
// ─────────────────────────────────────────────────────────────────────────────

class TimeSlotModel {
  final String id;
  final String label;
  final bool   available;
  final int?   hour;

  const TimeSlotModel({
    required this.id,
    required this.label,
    required this.available,
    this.hour,
  });

  factory TimeSlotModel.fromMap(Map<String, dynamic> map) => TimeSlotModel(
    id:        map['id']?.toString() ?? '',
    label:     map['label']?.toString() ?? '',
    available: map['available'] as bool? ?? true,
    hour:      map['hour'] as int?,
  );

  @override
  bool operator ==(Object other) => other is TimeSlotModel && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking submit payload
// ─────────────────────────────────────────────────────────────────────────────

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