import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// savings_discount_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class SavingsSummary {
  final double totalMarketCost;
  final double totalCorporateCost;
  final double totalSavings;

  double get savingsPercent =>
      totalMarketCost > 0 ? (totalSavings / totalMarketCost) * 100 : 0;

  const SavingsSummary({
    required this.totalMarketCost,
    required this.totalCorporateCost,
    required this.totalSavings,
  });
}

class VehicleSavingsRow {
  final String id;
  final String vehicleName;
  final String plateNumber;
  final double marketCost;
  final double corporateCost;

  double get saved => marketCost - corporateCost;
  double get savedPercent => marketCost > 0 ? (saved / marketCost) * 100 : 0;

  const VehicleSavingsRow({
    required this.id,
    required this.vehicleName,
    required this.plateNumber,
    required this.marketCost,
    required this.corporateCost,
  });
}

class DepartmentSavingsRow {
  final String department;
  final double marketCost;
  final double corporateCost;

  double get saved => marketCost - corporateCost;
  double get savedPercent => marketCost > 0 ? (saved / marketCost) * 100 : 0;

  const DepartmentSavingsRow({
    required this.department,
    required this.marketCost,
    required this.corporateCost,
  });
}

class SavingsFilters {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String?   vehicleId;
  final String?   department;

  const SavingsFilters({
    this.fromDate,
    this.toDate,
    this.vehicleId,
    this.department,
  });

  SavingsFilters copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String?   vehicleId,
    String?   department,
    bool clearFromDate   = false,
    bool clearToDate     = false,
    bool clearVehicle    = false,
    bool clearDepartment = false,
  }) {
    return SavingsFilters(
      fromDate:   clearFromDate   ? null : (fromDate   ?? this.fromDate),
      toDate:     clearToDate     ? null : (toDate     ?? this.toDate),
      vehicleId:  clearVehicle    ? null : (vehicleId  ?? this.vehicleId),
      department: clearDepartment ? null : (department ?? this.department),
    );
  }

  bool get hasAny =>
      fromDate   != null ||
      toDate     != null ||
      vehicleId  != null ||
      department != null;
}
