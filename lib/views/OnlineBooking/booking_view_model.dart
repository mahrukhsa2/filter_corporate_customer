import 'package:flutter/material.dart';
import '../../data/app_cache.dart';
import '../../data/repositories/VehicleRepository.dart';
import '../../data/repositories/lookup_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/time_slots_repository.dart';
import '../../data/network/api_response.dart';
import '../../widgets/app_alert.dart';
import '../../models/booking_model.dart';
import '../../models/branch_model.dart';
import '../../models/department_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Booking/booking_view_model.dart
//
// IMPORTANT: Booking is for LOGGED-IN users only.
// Branches come from AppCache.allowedBranches (user's profile).
// ─────────────────────────────────────────────────────────────────────────────

enum BookingLoadStatus   { idle, loading, loaded, error }
enum BookingSubmitStatus { idle, submitting, success, error }

class BookingViewModel extends ChangeNotifier {

  // ── State ─────────────────────────────────────────────────────────────────
  BookingLoadStatus   _loadStatus   = BookingLoadStatus.idle;
  BookingSubmitStatus _submitStatus = BookingSubmitStatus.idle;
  String              _errorMessage = '';

  // ── Data lists ────────────────────────────────────────────────────────────
  List<BranchModel>         _branches    = [];
  List<DepartmentModel>     _departments = [];
  List<BookingVehicleModel> _vehicles    = [];
  List<TimeSlotModel>       _timeSlots   = [];
  double                    _walletBalance = 0;

  // ── Loading states for individual fetches ─────────────────────────────────
  bool _isDepartmentsLoading = false;
  bool _isVehiclesLoading    = false;
  bool _isBranchesLoading    = false;

  // ── Form selections ───────────────────────────────────────────────────────
  BranchModel?         _selectedBranch;
  DepartmentModel?     _selectedDepartment;
  BookingVehicleModel? _selectedVehicle;
  DateTime?            _selectedDate;
  TimeSlotModel?       _selectedSlot;
  String               _notes         = '';
  bool                 _payFromWallet = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  BookingLoadStatus   get loadStatus   => _loadStatus;
  BookingSubmitStatus get submitStatus => _submitStatus;
  String              get errorMessage => _errorMessage;
  bool get isLoading    => _loadStatus == BookingLoadStatus.loading || _isBranchesLoading;
  bool get isSubmitting => _submitStatus == BookingSubmitStatus.submitting;
  bool get isDepartmentsLoading => _isDepartmentsLoading;
  bool get isVehiclesLoading    => _isVehiclesLoading;

  List<BranchModel>         get branches    => _branches;
  List<DepartmentModel>     get departments => _departments;
  List<BookingVehicleModel> get vehicles    => _vehicles;
  List<TimeSlotModel>       get timeSlots   => _timeSlots;
  double                    get walletBalance => _walletBalance;

  BranchModel?         get selectedBranch     => _selectedBranch;
  DepartmentModel?     get selectedDepartment => _selectedDepartment;
  BookingVehicleModel? get selectedVehicle    => _selectedVehicle;
  DateTime?            get selectedDate       => _selectedDate;
  TimeSlotModel?       get selectedSlot       => _selectedSlot;
  String               get notes              => _notes;
  bool                 get payFromWallet      => _payFromWallet;

  bool get canSubmit =>
      _selectedBranch     != null &&
          _selectedDepartment != null &&
          _selectedVehicle    != null &&
          _selectedDate       != null;

  // ── Constructor ───────────────────────────────────────────────────────────

  BookingViewModel() {
    _loadInitialData();
  }

  // ── Load initial data ─────────────────────────────────────────────────────
  // Branches: from AppCache.allowedBranches (user's profile)
  // If empty, reload profile to get branches

  Future<void> _loadInitialData() async {
    _loadStatus = BookingLoadStatus.loading;
    notifyListeners();

    // 1. Load allowed branches from AppCache
    await _loadBranches();

    // 2. Pre-select first branch if available
    if (_branches.isNotEmpty) {
      _selectedBranch = _branches.first;
    }

    // 3. Load vehicles and departments in parallel
    await Future.wait([
      _loadVehicles(),
      if (_selectedBranch != null) _loadDepartments(_selectedBranch!.id),
    ]);

    // 4. Pre-select default vehicle if available
    if (_vehicles.isNotEmpty) {
      _selectedVehicle = _vehicles.firstWhere(
            (v) => v.isDefault,
        orElse: () => _vehicles.first,
      );
    }

    // 5. Load wallet balance
    await _loadWalletBalance();

    _loadStatus = BookingLoadStatus.loaded;
    notifyListeners();
  }

  // ── Load branches ─────────────────────────────────────────────────────────
  // ✅ FIXED: Reload profile if branches are empty

  Future<void> _loadBranches() async {
    debugPrint('[BookingViewModel] _loadBranches() START');

    // Check if allowedBranches is empty
    if (AppCache.allowedBranches.isEmpty) {
      debugPrint('[BookingViewModel] allowedBranches is empty, reloading profile...');

      _isBranchesLoading = true;
      notifyListeners();

      // Reload profile to get allowed branches
      await AppCache.refreshProfile();

      _isBranchesLoading = false;
    }

    // Load from cache
    _branches = List.of(AppCache.allowedBranches);

    debugPrint('[BookingViewModel] loaded ${_branches.length} allowed branches');
    for (final b in _branches) {
      debugPrint('[BookingViewModel]   → Branch: id=${b.id}, name=${b.name}');
    }

    notifyListeners();
  }

  // ── Load departments for selected branch ──────────────────────────────────

  Future<void> _loadDepartments(String branchId) async {
    _isDepartmentsLoading = true;
    _departments = [];
    _selectedDepartment = null;
    notifyListeners();

    try {
      final depts = await LookupRepository.fetchDepartmentsByBranch(branchId);
      _departments = depts;
      debugPrint('[BookingViewModel] Loaded ${_departments.length} departments for branch $branchId');
    } catch (e) {
      debugPrint('[BookingViewModel] Failed to load departments: $e');
      _departments = [];
    }

    _isDepartmentsLoading = false;
    notifyListeners();
  }

  // ── Load vehicles from API ────────────────────────────────────────────────

  Future<void> _loadVehicles() async {
    _isVehiclesLoading = true;
    notifyListeners();

    try {
      final response = await VehicleRepository.fetchVehicles();

      if (response.success && response.data != null) {
        _vehicles = response.data!.map((vehicleModel) {
          return BookingVehicleModel(
            id: vehicleModel.id,
            make: vehicleModel.make,
            model: vehicleModel.model,
            plateNumber: vehicleModel.plateNumber,
            isDefault: vehicleModel.isDefault,
            year: vehicleModel.year,
            color: vehicleModel.color,
          );
        }).toList();

        debugPrint('[BookingViewModel] Loaded ${_vehicles.length} vehicles');
      } else {
        debugPrint('[BookingViewModel] Failed to load vehicles: ${response.message}');
        _vehicles = [];
      }
    } catch (e) {
      debugPrint('[BookingViewModel] Error loading vehicles: $e');
      _vehicles = [];
    }

    _isVehiclesLoading = false;
    notifyListeners();
  }

  // ── Load wallet balance ───────────────────────────────────────────────────

  Future<void> _loadWalletBalance() async {
    // TODO: Replace with real wallet API call
    await Future.delayed(const Duration(milliseconds: 200));
    _walletBalance = 12450;
  }

  // ── Load time slots for selected date ─────────────────────────────────────

  Future<void> _loadSlotsForDate(DateTime date) async {
    _timeSlots    = [];
    _selectedSlot = null;
    notifyListeners();

    if (_selectedBranch == null) {
      debugPrint('[BookingViewModel] Cannot load time slots: no branch selected');
      return;
    }

    try {
      final slots = await TimeSlotsRepository.fetchTimeSlots(
        branchId: _selectedBranch!.id,
        date: date,
      );

      _timeSlots = slots;
      debugPrint('[BookingViewModel] Loaded ${_timeSlots.length} time slots');
    } catch (e) {
      debugPrint('[BookingViewModel] Error loading time slots: $e');
      _timeSlots = [];
    }

    notifyListeners();
  }

  Future<void> refresh() => _loadInitialData();

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> selectBranch(BranchModel branch) async {
    if (_selectedBranch?.id == branch.id) return;

    _selectedBranch = branch;
    _selectedDepartment = null;
    notifyListeners();

    await _loadDepartments(branch.id);
  }

  void selectDepartment(DepartmentModel dept) {
    _selectedDepartment = dept;
    notifyListeners();
  }

  void selectVehicle(BookingVehicleModel v) {
    _selectedVehicle = v;
    notifyListeners();
  }

  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    notifyListeners();
    await _loadSlotsForDate(date);
  }

  void selectSlot(TimeSlotModel slot) {
    if (!slot.available) return;
    _selectedSlot = slot;
    notifyListeners();
  }

  void setNotes(String value) => _notes = value;

  void togglePayFromWallet() {
    _payFromWallet = !_payFromWallet;
    notifyListeners();
  }

  void resetSubmitStatus() {
    _submitStatus = BookingSubmitStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<bool> submitBooking(BuildContext context) async {
    if (!canSubmit) return false;

    debugPrint('[BookingViewModel] submitBooking START');

    _submitStatus = BookingSubmitStatus.submitting;
    _errorMessage = '';
    notifyListeners();

    final slotHour = _selectedSlot?.hour ?? 9;
    final bookedFor = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
     // slotHour, 0, 0,
    );

    final result = await OrdersRepository.submitOrder(
      branchId:      _selectedBranch!.id,
      vehicleId:     _selectedVehicle!.id,
      departmentId:  _selectedDepartment!.id,
      bookedFor:     bookedFor,
      payFromWallet: _payFromWallet,
      notes:         _notes,
    );

    if (result.success && result.data != null) {
      _submitStatus = BookingSubmitStatus.success;
      notifyListeners();
      debugPrint('[BookingViewModel] submitBooking SUCCESS ✅');
      return true;
    }

    _errorMessage = result.message ?? 'Failed to submit booking.';
    _submitStatus = BookingSubmitStatus.error;
    notifyListeners();

    if (context.mounted) {
      await AppAlert.apiError(
        context,
        errorType: result.errorType,
        message:   result.message,
        onRetry: result.errorType == ApiErrorType.noInternet ||
            result.errorType == ApiErrorType.timeout
            ? () => submitBooking(context)
            : null,
      );
    }

    return false;
  }
}