import 'package:flutter/material.dart';

import '../../models/vehicle_model.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum VehicleLoadStatus { idle, loading, loaded, error }

enum VehicleActionStatus { idle, saving, deleting, success, error }

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class VehicleViewModel extends ChangeNotifier {
  VehicleLoadStatus _loadStatus = VehicleLoadStatus.idle;
  VehicleActionStatus _actionStatus = VehicleActionStatus.idle;
  String _errorMessage = '';
  List<VehicleModel> _vehicles = [];

  VehicleLoadStatus get loadStatus => _loadStatus;
  VehicleActionStatus get actionStatus => _actionStatus;
  String get errorMessage => _errorMessage;
  List<VehicleModel> get vehicles => List.unmodifiable(_vehicles);
  bool get isLoading => _loadStatus == VehicleLoadStatus.loading;
  bool get isSaving => _actionStatus == VehicleActionStatus.saving;
  bool get isDeleting => _actionStatus == VehicleActionStatus.deleting;

  VehicleViewModel() {
    loadVehicles();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadVehicles() async {
    _loadStatus = VehicleLoadStatus.loading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    // ── Dummy data – replace with real API call when ready ─────────────────
    _vehicles = [
      VehicleModel(
        id: 'v1',
        make: 'Toyota',
        model: 'Camry',
        plateNumber: 'ABC-123',
        odometer: 45200,
        year: 2022,
        color: 'White',
        isDefault: true,
      ),
      VehicleModel(
        id: 'v2',
        make: 'Hyundai',
        model: 'Sonata',
        plateNumber: 'XYZ-456',
        odometer: 28750,
        year: 2021,
        color: 'Silver',
      ),
      VehicleModel(
        id: 'v3',
        make: 'Ford',
        model: 'F-150',
        plateNumber: 'DEF-789',
        odometer: 61000,
        year: 2020,
        color: 'Black',
      ),
    ];

    _loadStatus = VehicleLoadStatus.loaded;
    notifyListeners();
  }

  Future<void> refresh() => loadVehicles();

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<bool> addVehicle({
    required String make,
    required String model,
    required String plateNumber,
    required int odometer,
    required int year,
    required String color,
  }) async {
    _actionStatus = VehicleActionStatus.saving;
    _errorMessage = '';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    // ── Dummy add – replace with real API call ─────────────────────────────
    final newVehicle = VehicleModel(
      id: 'v${DateTime.now().millisecondsSinceEpoch}',
      make: make.trim(),
      model: model.trim(),
      plateNumber: plateNumber.trim().toUpperCase(),
      odometer: odometer,
      year: year,
      color: color.trim(),
      isDefault: _vehicles.isEmpty,
    );

    _vehicles.add(newVehicle);
    _actionStatus = VehicleActionStatus.success;
    notifyListeners();
    await _resetActionStatus();
    return true;
  }

  // ── Edit ──────────────────────────────────────────────────────────────────

  Future<bool> editVehicle({
    required String id,
    required String make,
    required String model,
    required String plateNumber,
    required int odometer,
    required int year,
    required String color,
  }) async {
    _actionStatus = VehicleActionStatus.saving;
    _errorMessage = '';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    // ── Dummy edit – replace with real API call ────────────────────────────
    final index = _vehicles.indexWhere((v) => v.id == id);
    if (index != -1) {
      _vehicles[index] = _vehicles[index].copyWith(
        make: make.trim(),
        model: model.trim(),
        plateNumber: plateNumber.trim().toUpperCase(),
        odometer: odometer,
        year: year,
        color: color.trim(),
      );
    }

    _actionStatus = VehicleActionStatus.success;
    notifyListeners();
    await _resetActionStatus();
    return true;
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<bool> deleteVehicle(String id) async {
    _actionStatus = VehicleActionStatus.deleting;
    _errorMessage = '';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    // ── Dummy delete – replace with real API call ──────────────────────────
    final wasDefault = _vehicles.firstWhere((v) => v.id == id).isDefault;
    _vehicles.removeWhere((v) => v.id == id);

    if (wasDefault && _vehicles.isNotEmpty) {
      _vehicles[0] = _vehicles[0].copyWith(isDefault: true);
    }

    _actionStatus = VehicleActionStatus.success;
    notifyListeners();
    await _resetActionStatus();
    return true;
  }

  // ── Set Default ───────────────────────────────────────────────────────────

  Future<void> setDefault(String id) async {
    _actionStatus = VehicleActionStatus.saving;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // ── Dummy set-default – replace with real API call ─────────────────────
    for (int i = 0; i < _vehicles.length; i++) {
      _vehicles[i] = _vehicles[i].copyWith(isDefault: _vehicles[i].id == id);
    }

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
