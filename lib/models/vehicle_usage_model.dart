import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// vehicle_usage_model.dart
//
// API response shape (GET /corporate/reports/vehicle-usage):
// {
//   "success": true,
//   "summary": { "noOfVehicles": 1, "totalServices": 0 },
//   "vehicles": [
//     { "id": "3", "vehicleName": "Honda City", "plateNo": "MH-123",
//       "totalServices": 0, "totalSpend": 0, "averagePerService": 0 }
//   ]
// }
// NOTE: serviceHistory is not returned by the API — kept as empty list.
// ─────────────────────────────────────────────────────────────────────────────

class VehicleServiceRecord {
  final String serviceType;
  final DateTime date;
  final double amount;
  final String branch;

  const VehicleServiceRecord({
    required this.serviceType,
    required this.date,
    required this.amount,
    required this.branch,
  });
}

class VehicleUsageItem {
  final String id;
  final String vehicleName;
  final String plateNumber;
  final String make;
  final String model;
  final int year;
  final int totalServices;
  final double totalSpend;
  final double averagePerService;
  final DateTime? lastServiceDate;
  final String lastServiceType;
  final List<VehicleServiceRecord> serviceHistory;

  const VehicleUsageItem({
    required this.id,
    required this.vehicleName,
    required this.plateNumber,
    this.make             = '',
    this.model            = '',
    this.year             = 0,
    required this.totalServices,
    required this.totalSpend,
    required this.averagePerService,
    this.lastServiceDate,
    this.lastServiceType  = '',
    this.serviceHistory   = const [],
  });

  factory VehicleUsageItem.fromApiMap(Map<String, dynamic> map) {
    return VehicleUsageItem(
      id:                map['id']?.toString()             ?? '',
      vehicleName:       map['vehicleName']?.toString()    ?? '',
      plateNumber:       map['plateNo']?.toString()        ?? '',
      totalServices:     (map['totalServices'] as num?)?.toInt()    ?? 0,
      totalSpend:        (map['totalSpend']    as num?)?.toDouble() ?? 0,
      averagePerService: (map['averagePerService'] as num?)?.toDouble() ?? 0,
      // Not in API response — will be populated if API adds it later
      serviceHistory:    const [],
    );
  }
}

class VehicleUsageSummary {
  final int totalVehicles;
  final int totalServices;
  final double totalSpend;
  final double averagePerVehicle;

  const VehicleUsageSummary({
    required this.totalVehicles,
    required this.totalServices,
    required this.totalSpend,
    required this.averagePerVehicle,
  });

  factory VehicleUsageSummary.fromApiMap(
      Map<String, dynamic> map, List<VehicleUsageItem> vehicles) {
    final totalSpend = vehicles.fold(0.0, (s, v) => s + v.totalSpend);
    final count      = (map['noOfVehicles'] as num?)?.toInt() ?? vehicles.length;
    return VehicleUsageSummary(
      totalVehicles:     count,
      totalServices:     (map['totalServices'] as num?)?.toInt() ?? 0,
      totalSpend:        totalSpend,
      averagePerVehicle: count > 0 ? totalSpend / count : 0,
    );
  }
}

class VehicleUsageFilters {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String?   vehicleId;

  const VehicleUsageFilters({
    this.fromDate,
    this.toDate,
    this.vehicleId,
  });

  VehicleUsageFilters copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String?   vehicleId,
    bool clearFromDate = false,
    bool clearToDate   = false,
    bool clearVehicle  = false,
  }) {
    return VehicleUsageFilters(
      fromDate:  clearFromDate ? null : (fromDate  ?? this.fromDate),
      toDate:    clearToDate   ? null : (toDate    ?? this.toDate),
      vehicleId: clearVehicle  ? null : (vehicleId ?? this.vehicleId),
    );
  }

  bool get hasAny =>
      fromDate  != null ||
          toDate    != null ||
          vehicleId != null;

  Map<String, String> toQueryParams() {
    final p = <String, String>{};
    if (fromDate  != null) p['startDate'] = _fmt(fromDate!);
    if (toDate    != null) p['endDate']   = _fmt(toDate!);
    if (vehicleId != null) p['vehicleId'] = vehicleId!;
    return p;
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle detail — GET /corporate/reports/vehicle-usage/{id}
// history items are plain strings for now; will be reshaped once API is final.
// ─────────────────────────────────────────────────────────────────────────────

class VehicleDetail {
  final int    totalServices;
  final double totalSpend;
  final double averagePerService;
  final List<String> history;

  const VehicleDetail({
    required this.totalServices,
    required this.totalSpend,
    required this.averagePerService,
    required this.history,
  });

  factory VehicleDetail.fromMap(Map<String, dynamic> map) {
    final stats = map['stats'] as Map<String, dynamic>? ?? {};
    final hist  = (map['history'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return VehicleDetail(
      totalServices:     (stats['totalServices']     as num?)?.toInt()    ?? 0,
      totalSpend:        (stats['totalSpend']        as num?)?.toDouble() ?? 0,
      averagePerService: (stats['averagePerService'] as num?)?.toDouble() ?? 0,
      history:           hist,
    );
  }
}