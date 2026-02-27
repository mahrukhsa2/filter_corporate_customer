import 'package:flutter/material.dart';

import '../../models/home_model.dart';
import '../../services/session_service.dart';




// ── ViewModel ─────────────────────────────────────────────────────────────────

class HomeViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String _companyName = '';
  HomeKpiData? _kpi;
  List<PromoBanner> _banners = [];

  bool get isLoading => _isLoading;

  String get companyName => _companyName;

  HomeKpiData? get kpi => _kpi;

  List<PromoBanner> get banners => _banners;

  HomeViewModel() {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // ── Dummy data (replace with real API calls when backend is ready) ─────────
    _companyName = 'Acme Trading Co.';

    _kpi = const HomeKpiData(
      totalBookingsThisYear: 87,
      thisMonthSpent: 45200,
      thisMonthBookings: 12,
      totalSpent: 128500,
      savingsPercent: 12,
      walletBalance: 12450,
    );

    _banners = const [
      PromoBanner(
        title: '20% off on Full Service',
        subtitle: 'Valid till 28 Feb',
        color: Color(0xFFFCC247),
      ),
      PromoBanner(
        title: 'Free Car Wash on Oil Change',
        subtitle: 'Acme Corp Special',
        color: Color(0xFF23262D),
      ),
      PromoBanner(
        title: 'Fleet Inspection Package',
        subtitle: 'Book 5+ vehicles and save 15%',
        color: Color(0xFF2E7D32),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => loadDashboard();

  void logout(BuildContext context) {
    // TODO: clear session via SessionService, then navigate to login
    //  SessionService.clearSession();
    SessionService.clearAll();

    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void topUpWallet(BuildContext context) {
    Navigator.pushNamed(context, '/wallet');
  }
  void myBookings(BuildContext context) {
    Navigator.pushNamed(context, '/my-bookings');
  }


  void goToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }
}