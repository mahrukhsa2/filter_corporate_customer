import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/network/api_response.dart';
import '../../data/app_cache.dart';
import '../../data/repositories/VehicleRepository.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/app_alert.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Vehicles/vehicle_view_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum VehicleLoadStatus   { idle, loading, loaded, error }
enum VehicleActionStatus { idle, saving, deleting, success, error }

class VehicleViewModel extends ChangeNotifier {

  VehicleLoadStatus   _loadStatus   = VehicleLoadStatus.idle;
  VehicleActionStatus _actionStatus = VehicleActionStatus.idle;
  String              _errorMessage = '';
  ApiErrorType        _errorType    = ApiErrorType.none;
  List<VehicleModel>  _vehicles     = [];

  // Getters
  VehicleLoadStatus   get loadStatus   => _loadStatus;
  VehicleActionStatus get actionStatus => _actionStatus;
  String              get errorMessage => _errorMessage;
  ApiErrorType        get errorType    => _errorType;
  List<VehicleModel>  get vehicles     => List.unmodifiable(_vehicles);
  bool get isLoading  => _loadStatus   == VehicleLoadStatus.loading;
  bool get hasError   => _loadStatus   == VehicleLoadStatus.error;
  bool get isSaving   => _actionStatus == VehicleActionStatus.saving;
  bool get isDeleting => _actionStatus == VehicleActionStatus.deleting;

  VehicleViewModel() {
    debugPrint('[VehicleViewModel] created');
    loadVehicles();
  }

  // ── Load ─────────────────────────────────────────── GET /corporate/vehicles

  Future<void> loadVehicles({BuildContext? context}) async {
    debugPrint('[VehicleViewModel] loadVehicles START');
    _loadStatus = VehicleLoadStatus.loading;
    notifyListeners();

    final result = await VehicleRepository.fetchVehicles();

    if (result.success && result.data != null) {
      _vehicles = result.data!;

      if (_vehicles.isNotEmpty && !_vehicles.any((v) => v.isDefault)) {
        _vehicles[0] = _vehicles[0].copyWith(isDefault: true);
        debugPrint('[VehicleViewModel] auto-default assigned to id=${_vehicles[0].id}');
      }

      _errorMessage = '';
      _errorType    = ApiErrorType.none;
      _loadStatus   = VehicleLoadStatus.loaded;
      AppCache.vehicles = List.of(_vehicles); // cache for other screens
      debugPrint('[VehicleViewModel] loadVehicles SUCCESS: ${_vehicles.length} vehicles (cached)');
    } else {
      debugPrint('[VehicleViewModel] loadVehicles FAILED: '
          'errorType=${result.errorType} msg=${result.message}');
      _errorMessage = result.message ?? 'Failed to load vehicles.';
      _errorType    = result.errorType;
      _loadStatus   = VehicleLoadStatus.error;

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: result.errorType,
          message:   result.message,
          onRetry: result.errorType == ApiErrorType.noInternet ||
              result.errorType == ApiErrorType.timeout
              ? () => loadVehicles(context: context)
              : null,
        );
      }
    }

    notifyListeners();
    debugPrint('[VehicleViewModel] loadVehicles END status=$_loadStatus');
  }

  Future<void> refresh({BuildContext? context}) {
    debugPrint('[VehicleViewModel] refresh');
    return loadVehicles(context: context);
  }

  // ── Add ──────────────────────────────────────────── POST /corporate/vehicles

  Future<bool> addVehicle({
    required BuildContext context,
    required String make,
    required String model,
    required String plateNumber,
    required int    odometer,
    required int    year,
    required String color,
  }) async {
    debugPrint('[VehicleViewModel] addVehicle START '
        'make=$make model=$model plate=$plateNumber year=$year odo=$odometer color=$color');

    _actionStatus = VehicleActionStatus.saving;
    _errorMessage = '';
    notifyListeners();

    final result = await VehicleRepository.createVehicle(
      make:        make.trim(),
      model:       model.trim(),
      plateNumber: plateNumber.trim().toUpperCase(),
      year:        year,
      color:       color.trim(),
      odometer:    odometer,
    );

    if (result.success && result.data != null) {
      final created = result.data!;
      final isFirst = _vehicles.isEmpty;
      _vehicles.add(created.copyWith(isDefault: isFirst));

      debugPrint('[VehicleViewModel] addVehicle SUCCESS id=${created.id} '
          'plate=${created.plateNumber} isDefault=$isFirst');

      AppCache.vehicles = List.of(_vehicles); // keep cache in sync
      _actionStatus = VehicleActionStatus.success;
      notifyListeners();
      await _resetActionStatus();
      return true;
    } else {
      debugPrint('[VehicleViewModel] addVehicle FAILED '
          'errorType=${result.errorType} msg=${result.message}');

      _errorMessage = result.message ?? 'Failed to add vehicle.';
      _actionStatus = VehicleActionStatus.error;
      notifyListeners();

      if (context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: result.errorType,
          message:   result.message,
          onRetry: result.errorType == ApiErrorType.noInternet ||
              result.errorType == ApiErrorType.timeout
              ? () => addVehicle(
            context:     context,
            make:        make,
            model:       model,
            plateNumber: plateNumber,
            odometer:    odometer,
            year:        year,
            color:       color,
          )
              : null,
        );
      }

      _actionStatus = VehicleActionStatus.idle;
      notifyListeners();
      return false;
    }
  }

  // ── Edit ─────────────────────────────────────────── PUT /corporate/vehicles/:id

  Future<bool> editVehicle({
    required String id,
    required String make,
    required String model,
    required String plateNumber,
    required int    odometer,
    required int    year,
    required String color,
    BuildContext?   context,
  }) async {
    debugPrint('[VehicleViewModel] editVehicle START id=$id plate=$plateNumber');

    _actionStatus = VehicleActionStatus.saving;
    _errorMessage = '';
    notifyListeners();

    final result = await VehicleRepository.updateVehicle(
      id:          id,
      make:        make.trim(),
      model:       model.trim(),
      plateNumber: plateNumber.trim().toUpperCase(),
      year:        year,
      color:       color.trim(),
      odometer:    odometer,
    );

    if (result.success && result.data != null) {
      final updated = result.data!;
      final index   = _vehicles.indexWhere((v) => v.id == id);
      if (index != -1) {
        _vehicles[index] = updated.copyWith(isDefault: _vehicles[index].isDefault);
        debugPrint('[VehicleViewModel] editVehicle SUCCESS: '
            'updated index=$index plate=${updated.plateNumber}');
      }

      _actionStatus = VehicleActionStatus.success;
      notifyListeners();
      await _resetActionStatus();
      return true;
    } else {
      debugPrint('[VehicleViewModel] editVehicle FAILED: '
          'errorType=${result.errorType} msg=${result.message}');

      _errorMessage = result.message ?? 'Failed to update vehicle.';
      _actionStatus = VehicleActionStatus.error;
      notifyListeners();

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: result.errorType,
          message:   result.message,
          onRetry: result.errorType == ApiErrorType.noInternet ||
              result.errorType == ApiErrorType.timeout
              ? () => editVehicle(
            context:     context,
            id:          id,
            make:        make,
            model:       model,
            plateNumber: plateNumber,
            odometer:    odometer,
            year:        year,
            color:       color,
          )
              : null,
        );
      }

      _actionStatus = VehicleActionStatus.idle;
      notifyListeners();
      return false;
    }
  }

  // ── Delete ───────────────────────────────────── DELETE /corporate/vehicles/:id

  Future<bool> deleteVehicle(String id, {BuildContext? context}) async {
    debugPrint('[VehicleViewModel] deleteVehicle START id=$id');

    _actionStatus = VehicleActionStatus.deleting;
    _errorMessage = '';
    notifyListeners();

    final result = await VehicleRepository.deleteVehicle(id);

    if (result.success) {
      final wasDefault = _vehicles.any((v) => v.id == id && v.isDefault);
      _vehicles.removeWhere((v) => v.id == id);

      if (wasDefault && _vehicles.isNotEmpty) {
        _vehicles[0] = _vehicles[0].copyWith(isDefault: true);
        debugPrint('[VehicleViewModel] deleteVehicle: '
            're-assigned default to id=${_vehicles[0].id}');
      }

      debugPrint('[VehicleViewModel] deleteVehicle SUCCESS: '
          '${_vehicles.length} vehicles remain');

      _actionStatus = VehicleActionStatus.success;
      notifyListeners();
      await _resetActionStatus();
      return true;
    } else {
      debugPrint('[VehicleViewModel] deleteVehicle FAILED: '
          'errorType=${result.errorType} msg=${result.message}');

      _errorMessage = result.message ?? 'Failed to delete vehicle.';
      _actionStatus = VehicleActionStatus.error;
      notifyListeners();

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: result.errorType,
          message:   result.message,
          // No retry for delete — user should confirm again
        );
      }

      _actionStatus = VehicleActionStatus.idle;
      notifyListeners();
      return false;
    }
  }

  // ── Set Default ─────────────────────────────── local only (no API yet)

  Future<void> setDefault(String id) async {
    debugPrint('[VehicleViewModel] setDefault LOCAL id=$id');
    _actionStatus = VehicleActionStatus.saving;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    for (int i = 0; i < _vehicles.length; i++) {
      _vehicles[i] = _vehicles[i].copyWith(isDefault: _vehicles[i].id == id);
    }

    debugPrint('[VehicleViewModel] setDefault done');
    _actionStatus = VehicleActionStatus.success;
    notifyListeners();
    await _resetActionStatus();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void resetActionStatus() {
    _actionStatus = VehicleActionStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _resetActionStatus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _actionStatus = VehicleActionStatus.idle;
    notifyListeners();
  }
}