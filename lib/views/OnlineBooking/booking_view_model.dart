import 'package:flutter/material.dart';
import '../../data/app_cache.dart';
import '../../models/booking_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Booking/booking_view_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum BookingLoadStatus   { idle, loading, loaded, error }
enum BookingSubmitStatus { idle, submitting, success, error }

class BookingViewModel extends ChangeNotifier {

  // ── State ─────────────────────────────────────────────────────────────────
  BookingLoadStatus   _loadStatus   = BookingLoadStatus.idle;
  BookingSubmitStatus _submitStatus = BookingSubmitStatus.idle;
  String              _errorMessage = '';

  // ── Lookup data (read from AppCache — never fetched here) ─────────────────
  List<DepartmentModel>    _departments = [];
  List<BranchModel>        _branches    = [];

  // ── Per-user data (still dummy until vehicles API is integrated) ──────────
  List<BookingVehicleModel> _vehicles   = [];
  List<TimeSlotModel>       _timeSlots  = [];
  double                    _walletBalance = 0;

  // ── Form selections ───────────────────────────────────────────────────────
  DepartmentModel?    _selectedDepartment;
  BookingVehicleModel? _selectedVehicle;
  BranchModel?        _selectedBranch;
  DateTime?           _selectedDate;
  TimeSlotModel?      _selectedSlot;
  String              _notes         = '';
  bool                _payFromWallet = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  BookingLoadStatus   get loadStatus   => _loadStatus;
  BookingSubmitStatus get submitStatus => _submitStatus;
  String              get errorMessage => _errorMessage;
  bool get isLoading    => _loadStatus   == BookingLoadStatus.loading;
  bool get isSubmitting => _submitStatus == BookingSubmitStatus.submitting;

  List<DepartmentModel>    get departments => _departments;
  List<BookingVehicleModel> get vehicles   => _vehicles;
  List<BranchModel>        get branches    => _branches;
  List<TimeSlotModel>      get timeSlots   => _timeSlots;
  double                   get walletBalance => _walletBalance;

  DepartmentModel?    get selectedDepartment => _selectedDepartment;
  BookingVehicleModel? get selectedVehicle   => _selectedVehicle;
  BranchModel?        get selectedBranch     => _selectedBranch;
  DateTime?           get selectedDate       => _selectedDate;
  TimeSlotModel?      get selectedSlot       => _selectedSlot;
  String              get notes              => _notes;
  bool                get payFromWallet      => _payFromWallet;

  bool get canSubmit =>
      _selectedDepartment != null &&
      _selectedVehicle    != null &&
      _selectedBranch     != null &&
      _selectedDate       != null &&
      _selectedSlot       != null;

  // ── Constructor ───────────────────────────────────────────────────────────

  BookingViewModel() {
    _loadData();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    _loadStatus = BookingLoadStatus.loading;
    notifyListeners();

    // ── 1. Read branches + departments from AppCache (instant) ────────────
    // AppCache was populated during the splash. No network call here.
    // If cache is empty for any reason (first launch, logout/login edge case),
    // we refresh it now — the screen shows a spinner during that time only.
    if (!AppCache.isReady) {
      await AppCache.init();
    }

    _departments = List.of(AppCache.departments);
    _branches    = List.of(AppCache.branches);

    // ── 2. Load vehicles + wallet (user-specific — cannot be cached globally)
    // Still dummy data until the vehicles API is integrated.
    await _loadUserData();

    // ── 3. Pre-select defaults ─────────────────────────────────────────────
    if (_vehicles.isNotEmpty) {
      _selectedVehicle = _vehicles.firstWhere(
        (v) => v.isDefault,
        orElse: () => _vehicles.first,
      );
    }
    if (_branches.isNotEmpty) {
      _selectedBranch = _branches.first;
    }

    _loadStatus = BookingLoadStatus.loaded;
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    // TODO: replace with real vehicles + wallet API calls when ready.
    // Pattern: final r = await BaseApiService.get(ApiConstants.vehicles);
    await Future.delayed(const Duration(milliseconds: 300));

    _vehicles = const [
      BookingVehicleModel(
          id: 'v1', make: 'Toyota',  model: 'Camry',  plateNumber: 'ABC-123', isDefault: true),
      BookingVehicleModel(
          id: 'v2', make: 'Hyundai', model: 'Sonata', plateNumber: 'XYZ-456'),
      BookingVehicleModel(
          id: 'v3', make: 'Ford',    model: 'F-150',  plateNumber: 'DEF-789'),
    ];
    _walletBalance = 12450;
  }

  Future<void> refresh() => _loadData();

  // ── Time slot loading (triggered when date changes) ───────────────────────

  Future<void> _loadSlotsForDate(DateTime date) async {
    _timeSlots   = [];
    _selectedSlot = null;
    notifyListeners();

    // TODO: replace with real time-slot API call.
    await Future.delayed(const Duration(milliseconds: 400));

    final seed = date.day;
    _timeSlots = [
      TimeSlotModel(id: 's1',  label: '08:00 AM', available: seed % 2 == 0),
      TimeSlotModel(id: 's2',  label: '09:00 AM', available: true),
      TimeSlotModel(id: 's3',  label: '10:00 AM', available: seed % 3 != 0),
      TimeSlotModel(id: 's4',  label: '11:00 AM', available: true),
      TimeSlotModel(id: 's5',  label: '12:00 PM', available: false),
      TimeSlotModel(id: 's6',  label: '01:00 PM', available: seed % 2 != 0),
      TimeSlotModel(id: 's7',  label: '02:00 PM', available: true),
      TimeSlotModel(id: 's8',  label: '03:00 PM', available: seed % 4 != 0),
      TimeSlotModel(id: 's9',  label: '04:00 PM', available: true),
      TimeSlotModel(id: 's10', label: '05:00 PM', available: seed % 3 == 0),
    ];
    notifyListeners();
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  void selectDepartment(DepartmentModel dept) {
    _selectedDepartment = dept;
    notifyListeners();
  }

  void selectVehicle(BookingVehicleModel v) {
    _selectedVehicle = v;
    notifyListeners();
  }

  void selectBranch(BranchModel b) {
    _selectedBranch = b;
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

    _submitStatus = BookingSubmitStatus.submitting;
    _errorMessage = '';
    notifyListeners();

    // TODO: replace with real booking API call.
    await Future.delayed(const Duration(milliseconds: 1200));

    final payload = BookingSubmitPayload(
      departmentId:  _selectedDepartment!.id,
      vehicleId:     _selectedVehicle!.id,
      branchId:      _selectedBranch!.id,
      date:          _selectedDate!,
      timeSlotId:    _selectedSlot!.id,
      notes:         _notes,
      payFromWallet: _payFromWallet,
    );

    debugPrint('Booking payload: ${payload.toMap()}');

    _submitStatus = BookingSubmitStatus.success;
    notifyListeners();
    return true;
  }
}
