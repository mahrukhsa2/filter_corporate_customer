// ─────────────────────────────────────────────────────────────────────────────
// lib/models/savings_discount_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class SavingsSummary {
  final double totalMarketCost;
  final double totalCorporateCost;
  final double totalSavings;
  final double savingsPercentage;

  double get savingsPercent => savingsPercentage;

  const SavingsSummary({
    required this.totalMarketCost,
    required this.totalCorporateCost,
    required this.totalSavings,
    required this.savingsPercentage,
  });

  factory SavingsSummary.fromApiMap(Map<String, dynamic> map) {
    return SavingsSummary(
      totalMarketCost:    _toDouble(map['totalNormalMarketCost']),
      totalCorporateCost: _toDouble(map['totalCorporateCost']),
      totalSavings:       _toDouble(map['totalSavings']),
      savingsPercentage:  _toDouble(map['savingsPercentage']),
    );
  }
}

class VehicleSavingsRow {
  final String vehicleName;
  final String plateNumber;
  final double savings;

  const VehicleSavingsRow({
    required this.vehicleName,
    required this.plateNumber,
    required this.savings,
  });

  factory VehicleSavingsRow.fromApiMap(Map<String, dynamic> map) {
    return VehicleSavingsRow(
      vehicleName: map['vehicleName']?.toString() ?? '—',
      plateNumber: map['plateNo']?.toString() ?? '—',
      savings:     _toDouble(map['savings']),
    );
  }
}

class DepartmentSavingsRow {
  final String department;
  final double savings;

  const DepartmentSavingsRow({
    required this.department,
    required this.savings,
  });

  factory DepartmentSavingsRow.fromApiMap(Map<String, dynamic> map) {
    return DepartmentSavingsRow(
      department: map['departmentName']?.toString() ?? '—',
      savings:    _toDouble(map['savings']),
    );
  }
}

class SavingsFilters {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String?   vehicleId;
  final String?   departmentId;

  const SavingsFilters({
    this.fromDate,
    this.toDate,
    this.vehicleId,
    this.departmentId,
  });

  SavingsFilters copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String?   vehicleId,
    String?   departmentId,
    bool clearFromDate    = false,
    bool clearToDate      = false,
    bool clearVehicle     = false,
    bool clearDepartment  = false,
  }) {
    return SavingsFilters(
      fromDate:     clearFromDate   ? null : (fromDate     ?? this.fromDate),
      toDate:       clearToDate     ? null : (toDate       ?? this.toDate),
      vehicleId:    clearVehicle    ? null : (vehicleId    ?? this.vehicleId),
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
    );
  }

  bool get hasAny =>
      fromDate     != null ||
          toDate       != null ||
          vehicleId    != null ||
          departmentId != null;

  Map<String, String> toQueryParams() {
    final p = <String, String>{};
    if (fromDate     != null) p['startDate']    = _fmtDate(fromDate!);
    if (toDate       != null) p['endDate']      = _fmtDate(toDate!);
    if (vehicleId    != null) p['vehicleId']    = vehicleId!;
    if (departmentId != null) p['departmentId'] = departmentId!;
    return p;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';