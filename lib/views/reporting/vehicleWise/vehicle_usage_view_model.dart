import 'package:flutter/material.dart';

import '../../../models/vehicle_usage_model.dart';

enum VULoadStatus { idle, loading, loaded }

class VehicleUsageViewModel extends ChangeNotifier {
  VULoadStatus _loadStatus = VULoadStatus.idle;
  bool _isExporting = false;
  final Set<String> _expandedIds = {};

  List<VehicleUsageItem> _all      = [];
  List<VehicleUsageItem> _filtered = [];
  VehicleUsageSummary?   _summary;
  VehicleUsageFilters    _filters  = const VehicleUsageFilters();

  bool get isLoading   => _loadStatus == VULoadStatus.loading;
  bool get isExporting => _isExporting;
  List<VehicleUsageItem> get items    => _filtered;
  VehicleUsageSummary?   get summary  => _summary;
  VehicleUsageFilters    get filters  => _filters;
  List<VehicleUsageItem> get allVehiclesForFilter => _all;

  bool isExpanded(String id) => _expandedIds.contains(id);

  void toggleExpand(String id) {
    if (_expandedIds.contains(id)) {
      _expandedIds.remove(id);
    } else {
      _expandedIds.add(id);
    }
    notifyListeners();
  }

  VehicleUsageViewModel() { _load(); }

  Future<void> _load() async {
    _loadStatus = VULoadStatus.loading;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    _all = [
      VehicleUsageItem(
        id: 'v1', vehicleName: 'Toyota Camry', plateNumber: 'ABC-123',
        make: 'Toyota', model: 'Camry', year: 2022,
        totalServices: 18, totalSpend: 32400, averagePerService: 1800,
        lastServiceDate: DateTime(2026, 2, 12), lastServiceType: 'Oil Change',
        serviceHistory: [
          VehicleServiceRecord(serviceType: 'Oil Change',       date: DateTime(2026, 2, 12), amount: 285,  branch: 'Riyadh HQ'),
          VehicleServiceRecord(serviceType: 'Tyre Rotation',    date: DateTime(2026, 1, 20), amount: 180,  branch: 'Riyadh HQ'),
          VehicleServiceRecord(serviceType: 'Full Service',     date: DateTime(2025, 12, 5), amount: 2450, branch: 'Jeddah Branch'),
          VehicleServiceRecord(serviceType: 'Air Filter',       date: DateTime(2025, 11, 8), amount: 432,  branch: 'Riyadh HQ'),
          VehicleServiceRecord(serviceType: 'Brake Inspection', date: DateTime(2025, 10, 2), amount: 150,  branch: 'Dammam Branch'),
        ],
      ),
      VehicleUsageItem(
        id: 'v2', vehicleName: 'BMW X5', plateNumber: 'XYZ-789',
        make: 'BMW', model: 'X5', year: 2021,
        totalServices: 9, totalSpend: 45600, averagePerService: 5067,
        lastServiceDate: DateTime(2026, 2, 5), lastServiceType: 'Full Service',
        serviceHistory: [
          VehicleServiceRecord(serviceType: 'Full Service',  date: DateTime(2026, 2, 5),  amount: 5200, branch: 'Riyadh HQ'),
          VehicleServiceRecord(serviceType: 'Brake Pads',    date: DateTime(2026, 1, 10), amount: 880,  branch: 'Riyadh HQ'),
          VehicleServiceRecord(serviceType: 'Oil Change',    date: DateTime(2025, 12, 1), amount: 420,  branch: 'Jeddah Branch'),
          VehicleServiceRecord(serviceType: 'Tyre Replace',  date: DateTime(2025, 10, 15),amount: 3200, branch: 'Riyadh HQ'),
        ],
      ),
      VehicleUsageItem(
        id: 'v3', vehicleName: 'Honda Accord', plateNumber: 'DEF-456',
        make: 'Honda', model: 'Accord', year: 2023,
        totalServices: 12, totalSpend: 18750, averagePerService: 1563,
        lastServiceDate: DateTime(2026, 1, 28), lastServiceType: 'Oil Change',
        serviceHistory: [
          VehicleServiceRecord(serviceType: 'Oil Change',     date: DateTime(2026, 1, 28), amount: 260,  branch: 'Dammam Branch'),
          VehicleServiceRecord(serviceType: 'Wiper Blades',   date: DateTime(2025, 12, 20),amount: 132,  branch: 'Dammam Branch'),
          VehicleServiceRecord(serviceType: 'Coolant Flush',  date: DateTime(2025, 11, 10),amount: 580,  branch: 'Riyadh HQ'),
        ],
      ),
      VehicleUsageItem(
        id: 'v4', vehicleName: 'Ford Explorer', plateNumber: 'GHI-321',
        make: 'Ford', model: 'Explorer', year: 2020,
        totalServices: 22, totalSpend: 51200, averagePerService: 2327,
        lastServiceDate: DateTime(2026, 2, 18), lastServiceType: 'Brake Service',
        serviceHistory: [
          VehicleServiceRecord(serviceType: 'Brake Service',  date: DateTime(2026, 2, 18), amount: 1560, branch: 'Riyadh HQ'),
          VehicleServiceRecord(serviceType: 'Oil Change',     date: DateTime(2026, 1, 5),  amount: 310,  branch: 'Riyadh HQ'),
          VehicleServiceRecord(serviceType: 'Suspension',     date: DateTime(2025, 11, 22),amount: 2800, branch: 'Jeddah Branch'),
          VehicleServiceRecord(serviceType: 'AC Service',     date: DateTime(2025, 10, 8), amount: 950,  branch: 'Riyadh HQ'),
        ],
      ),
      VehicleUsageItem(
        id: 'v5', vehicleName: 'Nissan Patrol', plateNumber: 'JKL-654',
        make: 'Nissan', model: 'Patrol', year: 2019,
        totalServices: 7, totalSpend: 14800, averagePerService: 2114,
        lastServiceDate: DateTime(2026, 1, 15), lastServiceType: 'Oil Change',
        serviceHistory: [
          VehicleServiceRecord(serviceType: 'Oil Change',    date: DateTime(2026, 1, 15), amount: 350,  branch: 'Dammam Branch'),
          VehicleServiceRecord(serviceType: 'Tyre Check',    date: DateTime(2025, 12, 8), amount: 120,  branch: 'Dammam Branch'),
        ],
      ),
    ];

    _filtered = List.from(_all);
    _summary  = _buildSummary(_all);
    _loadStatus = VULoadStatus.loaded;
    notifyListeners();
  }

  Future<void> refresh() => _load();

  void updateFilters(VehicleUsageFilters f) {
    _filters  = f;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _filters  = const VehicleUsageFilters();
    _filtered = List.from(_all);
    _summary  = _buildSummary(_all);
    notifyListeners();
  }

  void _applyFilters() {
    _filtered = _all.where((v) {
      if (_filters.vehicleId != null && v.id != _filters.vehicleId) return false;
      return true;
    }).toList();
    _summary = _buildSummary(_filtered);
  }

  VehicleUsageSummary _buildSummary(List<VehicleUsageItem> list) {
    final totalSpend    = list.fold(0.0, (s, v) => s + v.totalSpend);
    final totalServices = list.fold(0, (s, v) => s + v.totalServices);
    return VehicleUsageSummary(
      totalVehicles:      list.length,
      totalServices:      totalServices,
      totalSpend:         totalSpend,
      averagePerVehicle:  list.isEmpty ? 0 : totalSpend / list.length,
    );
  }

  Future<void> exportReport() async {
    _isExporting = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _isExporting = false;
    notifyListeners();
  }
}
