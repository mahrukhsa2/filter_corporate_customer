import 'package:flutter/material.dart';

import '../../models/profile_model.dart';


// ── ViewModel ─────────────────────────────────────────────────────────────────

enum ProfileSaveStatus { idle, saving, success, error }

class ProfileViewModel extends ChangeNotifier {
  bool _isLoading = false;
  ProfileSaveStatus _saveStatus = ProfileSaveStatus.idle;
  String _errorMessage = '';
  ProfileModel? _profile;

  bool get isLoading => _isLoading;
  ProfileSaveStatus get saveStatus => _saveStatus;
  String get errorMessage => _errorMessage;
  ProfileModel? get profile => _profile;
  bool get isSaving => _saveStatus == ProfileSaveStatus.saving;

  ProfileViewModel() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network fetch
    await Future.delayed(const Duration(milliseconds: 700));

    // ── Dummy data (replace with real API call when ready) ─────────────────
    _profile = ProfileModel(
      companyName: 'Acme Trading Co.',
      vatNumber: '300123456789',
      billingAddress: 'King Fahd Road, Riyadh 12271, Saudi Arabia',
      contactPerson: 'Mohammed Al-Rashidi',
      mobile: '+966 50 123 4567',
      walletBalance: 12450,
      branches: const [
        BranchModel(name: 'Riyadh Main', isActive: true),
        BranchModel(name: 'Jeddah', isActive: true),
        BranchModel(name: 'Dammam', isActive: false),
      ],
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => _loadProfile();

  /// Save editable fields (billingAddress, contactPerson, mobile)
  Future<bool> saveProfile({
    required String billingAddress,
    required String contactPerson,
    required String mobile,
  }) async {
    _saveStatus = ProfileSaveStatus.saving;
    _errorMessage = '';
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1000));

    // ── Dummy success (replace with real API call) ──────────────────────────
    _profile!.billingAddress = billingAddress.trim();
    _profile!.contactPerson = contactPerson.trim();
    _profile!.mobile = mobile.trim();

    _saveStatus = ProfileSaveStatus.success;
    notifyListeners();

    // Reset status after a moment
    await Future.delayed(const Duration(seconds: 2));
    _saveStatus = ProfileSaveStatus.idle;
    notifyListeners();

    return true;
  }

  void resetSaveStatus() {
    _saveStatus = ProfileSaveStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
