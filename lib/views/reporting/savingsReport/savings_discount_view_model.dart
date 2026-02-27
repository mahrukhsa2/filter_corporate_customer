import 'package:flutter/material.dart';

import '../../../models/savings_discount_model.dart';

enum SDLoadStatus { idle, loading, loaded }

class SavingsDiscountViewModel extends ChangeNotifier {
  SDLoadStatus _loadStatus = SDLoadStatus.idle;
  bool _isExporting = false;

  List<VehicleSavingsRow>    _allVehicles    = [];
  List<VehicleSavingsRow>    _filteredVehicles = [];
  List<DepartmentSavingsRow> _allDepartments = [];
  List<DepartmentSavingsRow> _filteredDepartments = [];
  SavingsSummary?  _summary;
  SavingsFilters   _filters = const SavingsFilters();

  // dropdown options
  List<VehicleSavingsRow> get vehicleOptions => _allVehicles;
  List<String>            get departmentOptions =>
      _allDepartments.map((d) => d.department).toList();

  // Getters
  bool get isLoading   => _loadStatus == SDLoadStatus.loading;
  bool get isExporting => _isExporting;
  List<VehicleSavingsRow>    get vehicleRows    => _filteredVehicles;
  List<DepartmentSavingsRow> get departmentRows => _filteredDepartments;
  SavingsSummary?  get summary => _summary;
  SavingsFilters   get filters => _filters;

  SavingsDiscountViewModel() { _load(); }

  Future<void> _load() async {
    _loadStatus = SDLoadStatus.loading;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    // ── Dummy data ────────────────────────────────────────────────────────
    _allVehicles = const [
      VehicleSavingsRow(id: 'v1', vehicleName: 'Toyota Camry',   plateNumber: 'ABC-123', marketCost: 42500, corporateCost: 33300),
      VehicleSavingsRow(id: 'v2', vehicleName: 'BMW X5',         plateNumber: 'XYZ-789', marketCost: 38200, corporateCost: 31900),
      VehicleSavingsRow(id: 'v3', vehicleName: 'Honda Accord',   plateNumber: 'DEF-456', marketCost: 29800, corporateCost: 25100),
      VehicleSavingsRow(id: 'v4', vehicleName: 'Ford Explorer',  plateNumber: 'GHI-321', marketCost: 21500, corporateCost: 18800),
      VehicleSavingsRow(id: 'v5', vehicleName: 'Nissan Patrol',  plateNumber: 'JKL-654', marketCost: 15250, corporateCost: 13400),
    ];

    _allDepartments = const [
      DepartmentSavingsRow(department: 'Oil Change',    marketCost: 32000, corporateCost: 27200),
      DepartmentSavingsRow(department: 'Repair',        marketCost: 58000, corporateCost: 49500),
      DepartmentSavingsRow(department: 'Tire Service',  marketCost: 24500, corporateCost: 21300),
      DepartmentSavingsRow(department: 'Car Wash',      marketCost: 12800, corporateCost: 11100),
      DepartmentSavingsRow(department: 'Inspection',    marketCost: 19950, corporateCost: 17400),
    ];

    _filteredVehicles    = List.from(_allVehicles);
    _filteredDepartments = List.from(_allDepartments);
    _summary = _buildSummary();
    _loadStatus = SDLoadStatus.loaded;
    notifyListeners();
  }

  Future<void> refresh() => _load();

  // ── Filters ───────────────────────────────────────────────────────────────
  void updateFilters(SavingsFilters f) {
    _filters = f;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _filters             = const SavingsFilters();
    _filteredVehicles    = List.from(_allVehicles);
    _filteredDepartments = List.from(_allDepartments);
    _summary             = _buildSummary();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredVehicles = _filters.vehicleId != null
        ? _allVehicles.where((v) => v.id == _filters.vehicleId).toList()
        : List.from(_allVehicles);

    _filteredDepartments = _filters.department != null
        ? _allDepartments
            .where((d) => d.department == _filters.department)
            .toList()
        : List.from(_allDepartments);

    _summary = _buildSummary();
  }

  SavingsSummary _buildSummary() {
    final market    = _filteredVehicles.fold(0.0, (s, v) => s + v.marketCost);
    final corporate = _filteredVehicles.fold(0.0, (s, v) => s + v.corporateCost);
    return SavingsSummary(
      totalMarketCost:    market,
      totalCorporateCost: corporate,
      totalSavings:       market - corporate,
    );
  }

  // ── Export ────────────────────────────────────────────────────────────────
  Future<void> exportReport() async {
    _isExporting = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    // TODO: real API
    _isExporting = false;
    notifyListeners();
  }
}
