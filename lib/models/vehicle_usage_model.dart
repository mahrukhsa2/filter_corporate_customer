import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// vehicle_usage_model.dart
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
  final DateTime lastServiceDate;
  final String lastServiceType;
  final List<VehicleServiceRecord> serviceHistory;

  const VehicleUsageItem({
    required this.id,
    required this.vehicleName,
    required this.plateNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.totalServices,
    required this.totalSpend,
    required this.averagePerService,
    required this.lastServiceDate,
    required this.lastServiceType,
    required this.serviceHistory,
  });
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
}
