import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/app_cache.dart';
import '../../data/network/api_constants.dart';
import '../../data/network/api_response.dart';
import '../../data/network/base_api_service.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../models/home_model.dart';
import '../../services/session_service.dart';
import '../../widgets/app_alert.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Home/home_view_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class HomeViewModel extends ChangeNotifier {

  bool         _isLoading   = false;
  bool         _hasError    = false;
  ApiErrorType _errorType   = ApiErrorType.none;
  String       _errorMessage = '';
  String       _companyName = '';
  HomeKpiData? _kpi;

  List<PromoBanner> _banners = const [];

  bool              get isLoading    => _isLoading;
  bool              get hasError     => _hasError;
  ApiErrorType      get errorType    => _errorType;
  String            get errorMessage => _errorMessage;
  String            get companyName  => _companyName;
  HomeKpiData?      get kpi          => _kpi;
  List<PromoBanner> get banners      => _banners;

  HomeViewModel() {
    loadDashboard();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadDashboard({BuildContext? context}) async {
    _isLoading = true;
    notifyListeners();

    // Run all concurrently
    final results = await Future.wait([
      SessionService.getCompanyName(),
      DashboardRepository.fetchKpis(),
      _fetchBanners(),
      // Silently refresh lookups in background so dropdowns stay current
      AppCache.refresh(),
    ]);

    // ── Company name from session ──────────────────────────────────────────
    _companyName = (results[0] as String?) ?? '';

    // ── KPI data from API ──────────────────────────────────────────────────
    final kpiResponse = results[1] as ApiResponse<HomeKpiData>;

    if (kpiResponse.success && kpiResponse.data != null) {
      _kpi          = kpiResponse.data;
      _hasError     = false;
      _errorType    = ApiErrorType.none;
      _errorMessage = '';
    } else {
      // Do NOT fall back to zeros — show a proper error state
      _hasError     = true;
      _errorType    = kpiResponse.errorType;
      _errorMessage = kpiResponse.message ?? 'Failed to load dashboard data.';
      // Keep stale _kpi if we had it from a previous successful load
      // On first load _kpi stays null — screen shows full error state
    }

    _isLoading = false;
    notifyListeners();
  }

  // Pull-to-refresh — context available from the screen
  Future<void> refresh({BuildContext? context}) =>
      loadDashboard(context: context);

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> logout(BuildContext context) async {
    AppCache.clear();
    await SessionService.clearAll();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  void topUpWallet(BuildContext context) =>
      Navigator.pushNamed(context, '/wallet');

  void myBookings(BuildContext context) =>
      Navigator.pushNamed(context, '/my-bookings');

  void goToProfile(BuildContext context) =>
      Navigator.pushNamed(context, '/profile');

// ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _fetchBanners() async {
    try {
      final response = await BaseApiService.get(ApiConstants.banners);
      if (response.success && response.data != null) {
        final raw = response.data!['banners'] as List? ?? [];
        _banners = raw
            .whereType<Map<String, dynamic>>()
            .toList()
            .asMap()
            .entries
            .map((e) => PromoBanner.fromApiMap(e.value, e.key))
            .toList();
        debugPrint('[HomeViewModel] banners loaded:  ' + banners.length.toString());
      }
    } catch (e) {
      debugPrint('[HomeViewModel] banners fetch error: \$e');
      // Non-fatal — keep empty list, screen handles it gracefully
    }
  }

}