import 'package:flutter/foundation.dart';
import 'repositories/lookup_repository.dart';
import 'repositories/profile_repository.dart';
import '../models/branch_model.dart';
import '../models/referral_model.dart';
import '../models/profile_model.dart';
import '../models/vehicle_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/app_cache.dart
//
// LIFECYCLE
// ─────────
//   1. SplashScreen calls AppCache.init() once while the logo animates.
//   2. Logged-in  → fetches profile (contains allowed branches) + branches list
//   3. Logged-out → fetches public branches + referrals (for registration)
//   4. ViewModels read AppCache.allowedBranches synchronously — instant, no await.
//   5. IMPORTANT: After user logs in, call AppCache.onLogin() to switch from
//      public data to user profile data.
//   6. AppCache.refreshProfile() re-fetches profile silently — call this after
//      the user changes their allowed branches via the manage-branches screen.
//   7. AppCache.clear() is called on logout.
// ─────────────────────────────────────────────────────────────────────────────

class AppCache {
  AppCache._();

  // ── Cached data ───────────────────────────────────────────────────────────
  static List<BranchModel>   branches  = []; // all system branches (public)
  static List<VehicleModel>  vehicles  = []; // cached vehicle list for dropdowns
  static List<ReferralModel> referrals = [];
  static ProfileModel?       profile;        // logged-in user's profile

  /// The branches this corporate account is allowed to use.
  /// Sourced from profile.workshops[].branches[] — these are the only branches
  /// that should appear in booking dropdowns and the profile screen.
  /// Falls back to the public branches list if profile hasn't loaded yet.
  static List<BranchModel> get allowedBranches {
    if (profile != null && profile!.branches.isNotEmpty) {
      // Convert ProfileBranchModel → BranchModel (same fields: id, name, address)
      return profile!.branches
          .map((b) => BranchModel(id: b.id, name: b.name, address: b.address))
          .toList();
    }
    // Fallback: return public branches if profile not loaded
    return branches;
  }

  // ── State ─────────────────────────────────────────────────────────────────
  static bool _initialized      = false;
  static bool _isLoading        = false;
  static bool _isProfileLoading = false;

  static bool get isReady => _initialized;

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init({bool isLoggedIn = false}) async {
    if (_isLoading) {
      debugPrint('[AppCache] init() called while already loading, skipping');
      return;
    }

    _isLoading = true;
    debugPrint('[AppCache] init() START - isLoggedIn: $isLoggedIn');

    try {
      if (isLoggedIn) {
        // Logged-in: fetch profile (allowed branches live here) + public branches
        // in parallel. Public branches serve as fallback if profile fails.
        debugPrint('[AppCache] Fetching profile + public branches (logged in)');
        await Future.wait([
          _fetchProfile(),
          _fetchBranches(),
        ]);
      } else {
        // Logged-out: fetch public branches + referrals (for registration)
        debugPrint('[AppCache] Fetching branches + referrals (logged out)');
        await _fetchPublic();
      }

      _initialized = true;
      debugPrint('[AppCache] init() SUCCESS '
          'branches=${branches.length} '
          'allowedBranches=${allowedBranches.length} '
          'referrals=${referrals.length} '
          'profile=${profile?.name}');
    } catch (e, stack) {
      debugPrint('[AppCache] init() FAILED: $e');
      debugPrint('[AppCache] Stack trace: $stack');
    } finally {
      _isLoading = false;
    }
  }

  /// Silent background refresh of all data.
  static Future<void> refresh({bool isLoggedIn = false}) async {
    if (_isLoading) return;
    await init(isLoggedIn: isLoggedIn);
  }

  // ── ✅ NEW: Call this after successful login ──────────────────────────────
  /// When user logs in during the session, we need to switch from public
  /// branches to user's allowed branches (from profile).
  /// This clears old non-logged-in data and fetches profile.
  static Future<void> onLogin() async {
    debugPrint('[AppCache] onLogin() - switching to logged-in mode');

    // Clear old public data
    referrals = [];

    // Fetch profile to get allowed branches
    await _fetchProfile();

    debugPrint('[AppCache] onLogin() DONE - allowedBranches: ${allowedBranches.length}');
  }

  /// Re-fetches only the profile — call this after the user changes their
  /// allowed branches via the manage-branches screen. This is lightweight
  /// (one API call) and updates allowedBranches instantly for both the
  /// profile screen and the booking screen.
  static Future<void> refreshProfile() async {
    if (_isProfileLoading) {
      debugPrint('[AppCache] refreshProfile() already in progress, skipping');
      return;
    }
    debugPrint('[AppCache] refreshProfile() START');
    await _fetchProfile();
    debugPrint('[AppCache] refreshProfile() DONE '
        'allowedBranches=${allowedBranches.length}');
  }

  /// Clear on logout.
  static void clear() {
    debugPrint('[AppCache] clear()');
    branches     = [];
    referrals    = [];
    vehicles     = [];
    profile      = null;
    _initialized = false;
  }

  // ── Private fetchers ──────────────────────────────────────────────────────

  static Future<void> _fetchProfile() async {
    _isProfileLoading = true;
    debugPrint('[AppCache] _fetchProfile() START');
    try {
      final result = await ProfileRepository.fetchProfile();
      if (result.success && result.data != null) {
        profile = result.data;
        debugPrint('[AppCache] _fetchProfile() SUCCESS '
            'name=${profile!.name} '
            'allowedBranches=${profile!.branches.length}');
        for (final b in profile!.branches) {
          debugPrint('[AppCache]   → allowed branch: id=${b.id} name=${b.name}');
        }
      } else {
        debugPrint('[AppCache] _fetchProfile() FAILED: ${result.message}');
        // Don't crash — profile stays null, allowedBranches falls back to public list
      }
    } catch (e) {
      debugPrint('[AppCache] _fetchProfile() ERROR: $e');
    } finally {
      _isProfileLoading = false;
    }
  }

  static Future<void> _fetchBranches() async {
    debugPrint('[AppCache] _fetchBranches() START');
    try {
      branches = await LookupRepository.fetchBranches();
      debugPrint('[AppCache] _fetchBranches() SUCCESS - ${branches.length} branches');
    } catch (e) {
      debugPrint('[AppCache] _fetchBranches() ERROR: $e');
      branches = [];
      rethrow;
    }
  }

  static Future<void> _fetchPublic() async {
    debugPrint('[AppCache] _fetchPublic() START');
    try {
      final results = await Future.wait([
        LookupRepository.fetchBranches(),
        LookupRepository.fetchReferrals(),
      ]);
      branches  = results[0] as List<BranchModel>;
      referrals = results[1] as List<ReferralModel>;
      debugPrint('[AppCache] _fetchPublic() SUCCESS '
          'branches=${branches.length} referrals=${referrals.length}');
    } catch (e) {
      debugPrint('[AppCache] _fetchPublic() ERROR: $e');
      branches  = [];
      referrals = [];
      rethrow;
    }
  }
}