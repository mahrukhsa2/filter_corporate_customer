import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/app_cache.dart';
import '../../../data/network/api_response.dart';
import '../../../models/registration_model.dart';
import '../../../models/referral_model.dart';
import '../../../widgets/app_alert.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Registration/registration_view_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum RegistrationStatus { idle, loading, success, error }

class RegistrationViewModel extends ChangeNotifier {

  // ── State ─────────────────────────────────────────────────────────────────
  RegistrationStatus _status       = RegistrationStatus.idle;
  String             _errorMessage  = '';
  String             _successMessage = '';
  bool               _isLoadingData = false;

  // ── Stores (branches the user can select during registration) ─────────────
  // Sourced from AppCache.branches (public endpoint, loaded on splash)
  List<StoreModel> _stores = [];

  // ── Referrals ─────────────────────────────────────────────────────────────
  // Sourced from AppCache.referrals (public endpoint, loaded on splash for
  // logged-out users). User picks one optionally.
  List<ReferralModel> _referrals       = [];
  ReferralModel?      _selectedReferral;

  // ── Getters ───────────────────────────────────────────────────────────────
  RegistrationStatus  get status          => _status;
  String              get errorMessage    => _errorMessage;
  String              get successMessage  => _successMessage;
  bool                get isLoading       => _status == RegistrationStatus.loading || _isLoadingData;
  List<StoreModel>    get stores          => _stores;
  List<ReferralModel> get referrals       => _referrals;
  ReferralModel?      get selectedReferral => _selectedReferral;

  List<String> get selectedStoreIds =>
      _stores.where((s) => s.isSelected).map((s) => s.id).toList();

  bool get hasSelectedStores => selectedStoreIds.isNotEmpty;

  bool get allStoresSelected =>
      _stores.isNotEmpty && _stores.every((s) => s.isSelected);

  // ── Constructor ───────────────────────────────────────────────────────────

  RegistrationViewModel() {
    _loadFromCache();
  }

  // ── Load from AppCache (data already fetched on splash) ───────────────────
  // ✅ FIXED: Added fallback to reload data if cache is empty

  Future<void> _loadFromCache() async {
    debugPrint('[RegistrationViewModel] _loadFromCache() START');

    // Check if AppCache has data
    if (AppCache.branches.isEmpty && AppCache.referrals.isEmpty) {
      debugPrint('[RegistrationViewModel] AppCache is empty, reloading data...');

      _isLoadingData = true;
      notifyListeners();

      // Reload data (this happens if user navigated too fast or splash failed)
      await AppCache.init(isLoggedIn: false);

      _isLoadingData = false;
    }

    // Load from cache
    _stores = AppCache.branches.map((b) =>
        StoreModel(id: b.id, name: b.name)).toList();

    _referrals = List.of(AppCache.referrals);

    debugPrint('[RegistrationViewModel] loaded from cache: '
        'stores=${_stores.length} referrals=${_referrals.length}');

    notifyListeners();
  }

  // ── Store selection ───────────────────────────────────────────────────────

  void toggleStore(String storeId) {
    final index = _stores.indexWhere((s) => s.id == storeId);
    if (index != -1) {
      _stores[index] = _stores[index].copyWith(isSelected: !_stores[index].isSelected);
      notifyListeners();
    }
  }

  void toggleAllStores(bool selectAll) {
    for (int i = 0; i < _stores.length; i++) {
      _stores[i] = _stores[i].copyWith(isSelected: selectAll);
    }
    notifyListeners();
  }

  // ── Referral selection ────────────────────────────────────────────────────

  void selectReferral(ReferralModel? referral) {
    _selectedReferral = referral;
    debugPrint('[RegistrationViewModel] referral selected: '
        '${referral?.id} ${referral?.fullName}');
    notifyListeners();
  }

  // ── Retry loading data (called from UI if stores are empty) ───────────────

  Future<void> retryLoadData() async {
    debugPrint('[RegistrationViewModel] retryLoadData() - forcing reload');

    _isLoadingData = true;
    notifyListeners();

    await AppCache.init(isLoggedIn: false);
    await _loadFromCache();

    _isLoadingData = false;
    notifyListeners();
  }

  // ── Register ──────────────────────────────────── POST /auth/corporate/register

  Future<bool> register({
    required BuildContext context,
    required String companyName,
    required String vatNumber,
    required String contactPerson,
    required String email,
    required String password,
   // required String mobile,
  }) async {
    if (!hasSelectedStores) {
      _status       = RegistrationStatus.error;
      _errorMessage = 'Please select at least one store.';
      notifyListeners();
      return false;
    }

    debugPrint('[RegistrationViewModel] register START');
    debugPrint('[RegistrationViewModel]   companyName=$companyName '
        'vatNumber=$vatNumber contactPerson=$contactPerson');
    //debugPrint('[RegistrationViewModel]   email=$email mobile=$mobile');
    debugPrint('[RegistrationViewModel]   selectedStoreIds=$selectedStoreIds');
    debugPrint('[RegistrationViewModel]   referralId=${_selectedReferral?.id}');

    _status        = RegistrationStatus.loading;
    _errorMessage  = '';
    _successMessage = '';
    notifyListeners();

    final payload = RegistrationPayload(
      companyName:      companyName.trim(),
      vatNumber:        vatNumber.trim(),
      contactPerson:    contactPerson.trim(),
      email:            email.trim(),
      password:         password,
      selectedStoreIds: selectedStoreIds,
    //  mobile:           mobile.trim(),
      referralId:       _selectedReferral?.id,
    );

    final result = await AuthRepository.register(payload);

    debugPrint('[RegistrationViewModel] register result: '
        'success=${result.success} '
        'errorType=${result.errorType} '
        'msg=${result.message}');

    if (result.success && result.data != null) {
      _successMessage = result.data!.message;
      _status         = RegistrationStatus.success;
      notifyListeners();
      debugPrint('[RegistrationViewModel] register SUCCESS ✅');
      return true;
    }

    // ── Failure ────────────────────────────────────────────────────────────
    _errorMessage = result.message ?? 'Registration failed.';
    _status       = RegistrationStatus.error;
    notifyListeners();

    debugPrint('[RegistrationViewModel] register FAILED ❌ '
        'errorType=${result.errorType} msg=$_errorMessage');

    if (context.mounted) {
      await AppAlert.apiError(
        context,
        errorType: result.errorType,
        message:   result.message,
        onRetry: result.errorType == ApiErrorType.noInternet ||
            result.errorType == ApiErrorType.timeout
            ? () => register(
          context:       context,
          companyName:   companyName,
          vatNumber:     vatNumber,
          contactPerson: contactPerson,
          email:         email,
          password:      password,
        //  mobile:        mobile,
        )
            : null,
      );
    }

    return false;
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void resetStatus() {
    _status         = RegistrationStatus.idle;
    _errorMessage   = '';
    _successMessage = '';
    notifyListeners();
  }

  void clearSelections() {
    for (int i = 0; i < _stores.length; i++) {
      _stores[i] = _stores[i].copyWith(isSelected: false);
    }
    _selectedReferral = null;
    notifyListeners();
  }
}