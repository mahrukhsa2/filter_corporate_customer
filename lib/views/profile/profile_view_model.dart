import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/lookup_repository.dart';
import '../../data/app_cache.dart';
import '../../data/network/api_constants.dart';
import '../../data/network/api_response.dart';
import '../../data/network/base_api_service.dart';
import '../../models/branch_model.dart';
import '../../models/profile_model.dart';
import '../../widgets/app_alert.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Profile/profile_view_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum ProfileSaveStatus { idle, saving, success, error }

class ProfileViewModel extends ChangeNotifier {

  // ── State ─────────────────────────────────────────────────────────────────
  bool              _isLoading    = false;
  ProfileSaveStatus _saveStatus   = ProfileSaveStatus.idle;
  String            _errorMessage = '';
  ProfileModel?     _profile;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool              get isLoading    => _isLoading;
  ProfileSaveStatus get saveStatus   => _saveStatus;
  String            get errorMessage => _errorMessage;
  ProfileModel?     get profile      => _profile;
  bool              get isSaving     => _saveStatus == ProfileSaveStatus.saving;

  ProfileViewModel() {
    debugPrint('[ProfileViewModel] created → loading profile');
    _loadProfile();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _loadProfile({BuildContext? context}) async {
    debugPrint('[ProfileViewModel] _loadProfile START');

    _isLoading = true;
    notifyListeners();

    final result = await ProfileRepository.fetchProfile();

    if (result.success && result.data != null) {
      _profile = result.data;
      debugPrint('[ProfileViewModel] _loadProfile SUCCESS: '
          'name=${_profile!.name} '
          'company=${_profile!.companyName} '
          'workshops=${_profile!.branches.length}');
    } else {
      debugPrint('[ProfileViewModel] _loadProfile FAILED: '
          'errorType=${result.errorType} message=${result.message}');

      if (_profile == null) {
        debugPrint('[ProfileViewModel] no stale data — profile will be null');
      }

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: result.errorType,
          message:   result.message,
          onRetry: result.errorType == ApiErrorType.noInternet ||
              result.errorType == ApiErrorType.timeout
              ? () => _loadProfile(context: context)
              : null,
        );
      }
    }

    _isLoading = false;
    notifyListeners();
    debugPrint('[ProfileViewModel] _loadProfile END '
        'isLoading=$_isLoading profile=${_profile != null}');
  }

  Future<void> refresh({BuildContext? context}) {
    debugPrint('[ProfileViewModel] refresh triggered');
    return _loadProfile(context: context);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<bool> saveProfile({
    BuildContext? context,
    required String billingAddress,
    required String contactPerson,
    required String mobile,
  }) async {
    debugPrint('[ProfileViewModel] saveProfile START');

    _saveStatus   = ProfileSaveStatus.saving;
    _errorMessage = '';
    notifyListeners();

    final result = await ProfileRepository.updateProfile(
      billingAddress: billingAddress.trim(),
      contactPerson:  contactPerson.trim(),
      mobile:         mobile.trim(),
    );

    if (result.success) {
      debugPrint('[ProfileViewModel] saveProfile SUCCESS');

      if (_profile != null) {
        _profile!.billingAddress = billingAddress.trim();
        _profile!.contactPerson  = contactPerson.trim();
        _profile!.mobile         = mobile.trim();
      }

      AppCache.refreshProfile();

      _saveStatus = ProfileSaveStatus.success;
      notifyListeners();
      return true;
    } else {
      debugPrint('[ProfileViewModel] saveProfile FAILED: '
          'errorType=${result.errorType} message=${result.message}');

      _errorMessage = result.message ?? 'Failed to save profile.';
      _saveStatus   = ProfileSaveStatus.error;
      notifyListeners();

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: result.errorType,
          message:   result.message,
          onRetry: (result.errorType == ApiErrorType.noInternet ||
              result.errorType == ApiErrorType.timeout) && context != null
              ? () => saveProfile(
            context:        context,
            billingAddress: billingAddress,
            contactPerson:  contactPerson,
            mobile:         mobile,
          )
              : null,
        );
      }

      _saveStatus = ProfileSaveStatus.idle;
      notifyListeners();
      return false;
    }
  }

  void resetSaveStatus() {
    debugPrint('[ProfileViewModel] resetSaveStatus');
    _saveStatus   = ProfileSaveStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }

  // ── Manage Branches ───────────────────────────────────────────────────────

  List<BranchModel> _allBranches      = [];
  bool              _isBranchesLoading = false;

  List<BranchModel> get allBranches       => _allBranches;
  bool              get isBranchesLoading => _isBranchesLoading;

  /// IDs of branches currently assigned to this profile.
  Set<String> get assignedBranchIds =>
      _profile?.branches.map((b) => b.id).toSet() ?? {};

  /// Loads all available branches — called when the popup opens.
  Future<void> loadAllBranches() async {
    if (_allBranches.isNotEmpty) return;
    _isBranchesLoading = true;
    notifyListeners();
    _allBranches = await LookupRepository.fetchBranches();
    _isBranchesLoading = false;
    notifyListeners();
    debugPrint('[ProfileViewModel] allBranches loaded: ${_allBranches.length}');
  }

  /// Add branch — POST /corporate/branches/{branchId}
  Future<bool> addBranch(String branchId) async {
    debugPrint('[ProfileViewModel] addBranch id=$branchId');
    final response = await BaseApiService.post(
      '${ApiConstants.branches}/$branchId',
      {},
    );
    if (response.success) {
      await AppCache.refreshProfile();
      await _loadProfile();
      debugPrint('[ProfileViewModel] addBranch SUCCESS');
      return true;
    }
    debugPrint('[ProfileViewModel] addBranch FAILED: ${response.message}');
    return false;
  }

  /// Remove branch — DELETE /corporate/branches/{branchId}
  Future<bool> removeBranch(String branchId) async {
    debugPrint('[ProfileViewModel] removeBranch id=$branchId');
    final response = await BaseApiService.delete(
      '${ApiConstants.branches}/$branchId',
    );
    if (response.success) {
      await AppCache.refreshProfile();
      await _loadProfile();
      debugPrint('[ProfileViewModel] removeBranch SUCCESS');
      return true;
    }
    debugPrint('[ProfileViewModel] removeBranch FAILED: ${response.message}');
    return false;
  }
}