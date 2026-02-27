import 'package:filter_corporate_customer/data/repositories/lookup_repository.dart';

import '../../models/booking_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/app_cache.dart
//
// In-memory singleton cache for all lookup / dropdown data.
//
// LIFECYCLE
// ─────────
//   1. SplashScreen calls AppCache.init() once while the logo animates.
//   2. After login (if splash ran before login), call AppCache.init() again
//      so authenticated endpoints can be reached.
//   3. ViewModels read AppCache.branches / AppCache.departments synchronously
//      — no await, no loading state, instant dropdowns.
//   4. AppCache.refresh() can be called silently in the background (e.g. on
//      home screen load) to keep data fresh without blocking the UI.
//   5. AppCache.clear() is called on logout.
//
// ADDING A NEW LOOKUP
// ───────────────────
//   1. Add a static list field here.
//   2. Add the fetch call inside _fetchAll().
//   3. Add to clear().
//   That's it. The ViewModel just reads AppCache.yourNewList.
// ─────────────────────────────────────────────────────────────────────────────

class AppCache {
  AppCache._();

  // ── Cached lists ──────────────────────────────────────────────────────────
  static List<BranchModel>     branches    = [];
  static List<DepartmentModel> departments = [];
  // Add more here:  static List<ServiceType> serviceTypes = [];

  // ── State ─────────────────────────────────────────────────────────────────
  static bool _initialized = false;
  static bool _isLoading   = false;

  /// True once init() has completed at least once successfully.
  static bool get isReady => _initialized;

  // ── Init (called once from SplashRepository / post-login) ─────────────────

  static Future<void> init() async {
    if (_isLoading) return; // prevent concurrent duplicate calls
    _isLoading = true;

    try {
      await _fetchAll();
      _initialized = true;
    } catch (_) {
      // Never crash the app due to a cache failure.
      // Screens that need data will show empty dropdowns and can retry.
    } finally {
      _isLoading = false;
    }
  }

  /// Silent background refresh — call this from HomeViewModel.loadDashboard()
  /// or any post-login screen to keep data fresh without showing a loader.
  static Future<void> refresh() async {
    if (_isLoading) return;
    await init();
  }

  /// Clear on logout so stale data from the previous session never bleeds
  /// into the next user's session.
  static void clear() {
    branches    = [];
    departments = [];
    _initialized = false;
  }

  // ── Private: fetch everything in parallel ─────────────────────────────────

  static Future<void> _fetchAll() async {
    final results = await Future.wait([
      LookupRepository.fetchBranches(),
      LookupRepository.fetchDepartments(),
      // Add more: LookupRepository.fetchServiceTypes(),
    ]);

    branches    = results[0] as List<BranchModel>;
    departments = results[1] as List<DepartmentModel>;
  }
}
