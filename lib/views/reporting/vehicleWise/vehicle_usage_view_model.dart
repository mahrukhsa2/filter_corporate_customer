import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/app_cache.dart';
import '../../../data/network/api_constants.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/VehicleRepository.dart';
import '../../../models/vehicle_model.dart';
import '../../../models/vehicle_usage_model.dart';
import '../../../services/excel_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/reporting/vehicleUsage/vehicle_usage_view_model.dart
//
// Load strategy:
//   _load()         → initial full-screen spinner (isLoading = true)
//   _fetchForFilter → called on every filter change; only _isTableLoading = true
//                     so the summary cards + filter bar stay visible during refresh.
//
// Vehicle dropdown:
//   Reads AppCache.vehicles first (populated by VehicleScreen).
//   If cache is empty, falls back to VehicleRepository.fetchVehicles().
// ─────────────────────────────────────────────────────────────────────────────

enum VULoadStatus { idle, loading, loaded, error }

class VehicleUsageViewModel extends ChangeNotifier {

  VULoadStatus _loadStatus    = VULoadStatus.idle;
  bool         _isTableLoading = false;
  bool         _isExporting    = false;
  String?      _exportError;

  final Set<String> _expandedIds = {};

  List<VehicleUsageItem>  _items   = [];
  VehicleUsageSummary?    _summary;
  VehicleUsageFilters     _filters = const VehicleUsageFilters();

  // Vehicle list for the dropdown filter
  List<VehicleModel> _dropdownVehicles = [];

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading       => _loadStatus == VULoadStatus.loading;
  bool get isTableLoading  => _isTableLoading;
  bool get isExporting     => _isExporting;
  String? get exportError  => _exportError;
  bool get hasError        => _loadStatus == VULoadStatus.error;

  List<VehicleUsageItem>  get items             => _items;
  VehicleUsageSummary?    get summary           => _summary;
  VehicleUsageFilters     get filters           => _filters;
  List<VehicleModel>      get dropdownVehicles  => _dropdownVehicles;

  bool isExpanded(String id) => _expandedIds.contains(id);

  void toggleExpand(String id) {
    _expandedIds.contains(id)
        ? _expandedIds.remove(id)
        : _expandedIds.add(id);
    notifyListeners();
  }

  VehicleUsageViewModel() {
    debugPrint('[VehicleUsageViewModel] created');
    _loadDropdownVehicles();
    _load();
  }

  // ── Vehicle dropdown — cache first, API fallback ──────────────────────────

  Future<void> _loadDropdownVehicles() async {
    if (AppCache.vehicles.isNotEmpty) {
      _dropdownVehicles = AppCache.vehicles;
      debugPrint('[VehicleUsageViewModel] dropdown: '
          '${_dropdownVehicles.length} vehicles from cache');
      notifyListeners();
      return;
    }

    debugPrint('[VehicleUsageViewModel] cache empty — fetching vehicles from API');
    final res = await VehicleRepository.fetchVehicles();
    if (res.success && res.data != null) {
      _dropdownVehicles  = res.data!;
      AppCache.vehicles  = List.of(_dropdownVehicles); // warm the cache
      debugPrint('[VehicleUsageViewModel] dropdown: '
          '${_dropdownVehicles.length} vehicles from API');
      notifyListeners();
    }
  }

  // ── Initial load (full-screen spinner) ────────────────────────────────────

  Future<void> _load() async {
    debugPrint('[VehicleUsageViewModel] _load START');
    _loadStatus = VULoadStatus.loading;
    notifyListeners();

    await _fetch(_filters);

    _loadStatus = VULoadStatus.loaded;
    notifyListeners();
    debugPrint('[VehicleUsageViewModel] _load END '
        'items=${_items.length}');
  }

  Future<void> refresh() => _load();

  // ── Filter change — table-only spinner, no full-screen reload ─────────────

  void updateFilters(VehicleUsageFilters f) {
    _filters = f;
    notifyListeners(); // update chip UI immediately
    _fetchForFilter();
  }

  void clearFilters() {
    _filters = const VehicleUsageFilters();
    notifyListeners();
    _fetchForFilter();
  }

  Future<void> _fetchForFilter() async {
    _isTableLoading = true;
    notifyListeners();

    await _fetch(_filters);

    _isTableLoading = false;
    notifyListeners();
  }

  // ── Core API fetch — reused by both _load and _fetchForFilter ─────────────

  Future<void> _fetch(VehicleUsageFilters f) async {
    final params = f.toQueryParams();
    debugPrint('[VehicleUsageViewModel] _fetch → '
        'GET ${ApiConstants.reportsVehicleUsage} params=$params');

    final response = await BaseApiService.get(
      ApiConstants.reportsVehicleUsage,
      queryParams: params,
    );

    debugPrint('[VehicleUsageViewModel] _fetch ← '
        'statusCode=${response.statusCode} success=${response.success}');

    if (!response.success || response.data == null) {
      debugPrint('[VehicleUsageViewModel] _fetch FAILED: ${response.message}');
      _items   = [];
      _summary = null;
      return;
    }

    try {
      final raw      = response.data!;
      final rawList  = raw['vehicles'] as List? ?? [];
      _items         = rawList
          .map((m) => VehicleUsageItem.fromApiMap(m as Map<String, dynamic>))
          .toList();

      final rawSum   = raw['summary'] as Map<String, dynamic>? ?? {};
      _summary       = VehicleUsageSummary.fromApiMap(rawSum, _items);

      debugPrint('[VehicleUsageViewModel] _fetch SUCCESS '
          'vehicles=${_items.length} '
          'totalServices=${_summary!.totalServices} '
          'totalSpend=${_summary!.totalSpend}');
    } catch (e, stack) {
      debugPrint('[VehicleUsageViewModel] _fetch PARSE ERROR: $e\n$stack');
      _items   = [];
      _summary = null;
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> exportReport() async {
    if (_items.isEmpty) {
      _exportError = 'No data available to export.';
      notifyListeners();
      return;
    }
    _isExporting = true;
    notifyListeners();

    try {
      final rows = _items.map((v) => {
        'Vehicle':             v.vehicleName,
        'Plate No':            v.plateNumber,
        'Total Services':      v.totalServices,
        'Total Spend (SAR)':   v.totalSpend,
        'Avg per Service (SAR)': v.averagePerService,
        'Last Service':        v.lastServiceDate != null
            ? v.lastServiceDate!.toIso8601String()
            : '—',
      }).toList();

      final summary = _summary == null ? null : {
        'Total Vehicles': _summary!.totalVehicles,
        'Total Services': _summary!.totalServices,
        'Total Spend':    _summary!.totalSpend,
        'Avg / Vehicle':  _summary!.averagePerVehicle,
      };

      _exportError = null;
      await ExcelExportService.exportFromList(
        title:    'Vehicle-wise Usage Report',
        rows:     rows,
        fromDate: _filters.fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
        toDate:   _filters.toDate   ?? DateTime.now(),
        summary:  summary,
      );

      debugPrint('[VehicleUsageViewModel] export done');
    } on ExcelExportException catch (e) {
      _exportError = e.message;
      debugPrint('[VehicleUsageViewModel] no data: ${e.message}');
    } catch (e) {
      _exportError = 'Export failed. Please try again.';
      debugPrint('[VehicleUsageViewModel] export error: $e');
    }

    _isExporting = false;
    notifyListeners();
  }
}