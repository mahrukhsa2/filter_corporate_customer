// ── Dummy data models ──────────────────────────────────────────────────────────

import 'dart:ui';

class HomeKpiData {
  final int totalBookingsThisYear;
  final double thisMonthSpent;
  final int thisMonthBookings;
  final double totalSpent;
  final double savingsPercent;
  final double walletBalance;

  const HomeKpiData({
    required this.totalBookingsThisYear,
    required this.thisMonthSpent,
    required this.thisMonthBookings,
    required this.totalSpent,
    required this.savingsPercent,
    required this.walletBalance,
  });
}

class PromoBanner {
  final String title;
  final String subtitle;
  final Color color;

  const PromoBanner({
    required this.title,
    required this.subtitle,
    required this.color,
  });
}