import 'package:flutter/foundation.dart';

import '../../../data/app_cache.dart';
import '../../../data/network/api_constants.dart';
import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/lookup_repository.dart';
import '../../../data/repositories/VehicleRepository.dart';
import '../../../models/department_model.dart';
import '../../../models/savings_discount_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../services/excel_export_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// savings_discount_view_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum SDLoadStatus { idle, loading, loaded }

class SavingsDiscountViewModel extends ChangeNotifier {

  SDLoadStatus _loadStatus    = SDLoadStatus.idle;
  bool         _isTableLoading = false;
  bool         _isExporting    = false;
  String?      _exportError;

  SavingsSummary?            _summary;
  List<VehicleSavingsRow>    _vehicleRows    = [];
  List<DepartmentSavingsRow> _departmentRows = [];
  SavingsFilters             _filters        = const SavingsFilters();

  // ── Dropdown options (loaded once at init) ────────────────────────────────
  List<VehicleModel>    _dropdownVehicles    = [];
  List<DepartmentModel> _dropdownDepartments = [];

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading      => _loadStatus == SDLoadStatus.loading;
  bool get isTableLoading => _isTableLoading;
  bool get isExporting    => _isExporting;
  String? get exportError  => _exportError;

  SavingsSummary?            get summary            => _summary;
  List<VehicleSavingsRow>    get vehicleRows        => _vehicleRows;
  List<DepartmentSavingsRow> get departmentRows     => _departmentRows;
  SavingsFilters             get filters            => _filters;
  List<VehicleModel>         get dropdownVehicles   => _dropdownVehicles;
  List<DepartmentModel>      get dropdownDepartments => _dropdownDepartments;

  SavingsDiscountViewModel() {
    debugPrint('[SavingsDiscountViewModel] created');
    _loadDropdowns();
    _load();
  }

  // ── Load dropdown options — vehicles + departments ────────────────────────
  // Both run in parallel. Neither blocks the main data load.

  Future<void> _loadDropdowns() async {
    await Future.wait([
      _loadVehicleDropdown(),
      _loadDepartmentDropdown(),
    ]);
  }

  Future<void> _loadVehicleDropdown() async {
    if (AppCache.vehicles.isNotEmpty) {
      _dropdownVehicles = AppCache.vehicles;
      debugPrint('[SavingsDiscountViewModel] vehicles from cache: ${_dropdownVehicles.length}');
      notifyListeners();
      return;
    }
    debugPrint('[SavingsDiscountViewModel] fetching vehicles from API');
    final res = await VehicleRepository.fetchVehicles();
    if (res.success && res.data != null) {
      _dropdownVehicles    = res.data!;
      AppCache.vehicles    = List.of(_dropdownVehicles);
      debugPrint('[SavingsDiscountViewModel] vehicles from API: ${_dropdownVehicles.length}');
      notifyListeners();
    }
  }

  Future<void> _loadDepartmentDropdown() async {
    // Departments are per-branch. Collect all branch IDs from allowedBranches,
    // fetch departments for each, deduplicate by id.
    final branchIds = AppCache.allowedBranches.map((b) => b.id).toList();
    if (branchIds.isEmpty) {
      debugPrint('[SavingsDiscountViewModel] no allowed branches — skipping department load');
      return;
    }

    debugPrint('[SavingsDiscountViewModel] fetching departments for ${branchIds.length} branches');

    final results = await Future.wait(
      branchIds.map((id) => LookupRepository.fetchDepartmentsByBranch(id)),
    );

    // Flatten + deduplicate by id
    final seen  = <String>{};
    final depts = <DepartmentModel>[];
    for (final list in results) {
      for (final d in list) {
        if (seen.add(d.id)) depts.add(d);
      }
    }

    _dropdownDepartments = depts;
    debugPrint('[SavingsDiscountViewModel] departments loaded: ${_dropdownDepartments.length}');
    notifyListeners();
  }

  // ── Initial full-screen load ──────────────────────────────────────────────

  Future<void> _load() async {
    debugPrint('[SavingsDiscountViewModel] _load START');
    _loadStatus = SDLoadStatus.loading;
    notifyListeners();
    await _fetch(_filters);
    _loadStatus = SDLoadStatus.loaded;
    notifyListeners();
    debugPrint('[SavingsDiscountViewModel] _load END');
  }

  Future<void> refresh() => _load();

  // ── Filter change — table-only spinner, summary stays visible ─────────────

  void updateFilters(SavingsFilters f) {
    _filters = f;
    notifyListeners();
    _fetchForFilter();
  }

  void clearFilters() {
    _filters = const SavingsFilters();
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

  // ── Core API fetch ────────────────────────────────────────────────────────

  Future<void> _fetch(SavingsFilters f) async {
    final params = f.toQueryParams();
    debugPrint('[SavingsDiscountViewModel] _fetch → GET ${ApiConstants.reportsSavings} params=$params');

    final response = await BaseApiService.get(
      ApiConstants.reportsSavings,
      queryParams: params,
    );

    debugPrint('[SavingsDiscountViewModel] _fetch ← '
        'statusCode=${response.statusCode} success=${response.success}');

    if (!response.success || response.data == null) {
      debugPrint('[SavingsDiscountViewModel] _fetch FAILED: ${response.message}');
      _summary        = null;
      _vehicleRows    = [];
      _departmentRows = [];
      return;
    }

    try {
      final raw = response.data!;

      _summary = SavingsSummary.fromApiMap(
        raw['summary'] as Map<String, dynamic>? ?? {},
      );

      _vehicleRows = (raw['savingsByVehicle'] as List? ?? [])
          .map((m) => VehicleSavingsRow.fromApiMap(m as Map<String, dynamic>))
          .toList();

      _departmentRows = (raw['savingsByDepartment'] as List? ?? [])
          .map((m) => DepartmentSavingsRow.fromApiMap(m as Map<String, dynamic>))
          .toList();

      debugPrint('[SavingsDiscountViewModel] _fetch SUCCESS '
          'vehicles=${_vehicleRows.length} '
          'departments=${_departmentRows.length} '
          'totalSavings=${_summary?.totalSavings}');
    } catch (e, stack) {
      debugPrint('[SavingsDiscountViewModel] _fetch PARSE ERROR: $e\n$stack');
      _summary        = null;
      _vehicleRows    = [];
      _departmentRows = [];
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────
  // Exports two sections in one file:
  //   Sheet 1 rows 0–N  → Savings by Vehicle
  //   Separator row     → "── Savings by Department ──"
  //   Remaining rows    → Savings by Department

  Future<void> exportReport() async {
    if (_vehicleRows.isEmpty && _departmentRows.isEmpty) {
      _exportError = 'No data available to export.';
      notifyListeners();
      return;
    }
    _isExporting = true;
    notifyListeners();

    try {
      // Combine both sections into one flat list with a separator row
      final rows = <Map<String, dynamic>>[];

      // Vehicle rows
      for (final v in _vehicleRows) {
        rows.add({
          'Section':      'By Vehicle',
          'Name':         '${v.vehicleName} (${v.plateNumber})',
          'Savings (SAR)': v.savings,
        });
      }

      // Separator
      if (_vehicleRows.isNotEmpty && _departmentRows.isNotEmpty) {
        rows.add({
          'Section':      '── By Department ──',
          'Name':         '',
          'Savings (SAR)': '',
        });
      }

      // Department rows
      for (final d in _departmentRows) {
        rows.add({
          'Section':      'By Department',
          'Name':         d.department,
          'Savings (SAR)': d.savings,
        });
      }

      final summary = _summary == null ? null : {
        'Total Market Cost':    _summary!.totalMarketCost,
        'Total Corporate Cost': _summary!.totalCorporateCost,
        'Total Savings':        _summary!.totalSavings,
        'Savings %':            '${_summary!.savingsPercent.toStringAsFixed(1)}%',
      };

      _exportError = null;
      await ExcelExportService.exportFromList(
        title:    'Savings & Discount Report',
        rows:     rows,
        fromDate: _filters.fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
        toDate:   _filters.toDate   ?? DateTime.now(),
        summary:  summary,
      );

      debugPrint('[SavingsDiscountViewModel] export done');
    } on ExcelExportException catch (e) {
      _exportError = e.message;
      debugPrint('[SavingsDiscountViewModel] no data: ${e.message}');
    } catch (e) {
      _exportError = 'Export failed. Please try again.';
      debugPrint('[SavingsDiscountViewModel] export error: $e');
    }

    _isExporting = false;
    notifyListeners();
  }
}