import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/models/home_model.dart
// ─────────────────────────────────────────────────────────────────────────────

// ── Dashboard KPI data ────────────────────────────────────────────────────────
// Maps 1-to-1 with GET /corporate/dashboard response.
//
// API response keys use snake_case:
//   total_bookings_year, this_month_spend, total_spend,
//   wallet_balance, savings_percent
//
// Note: API does not return thisMonthBookings — kept as 0 until backend adds it.

class HomeKpiData {
  final int    totalBookingsThisYear;
  final double thisMonthSpent;
  final int    thisMonthBookings;   // not in API yet — defaults to 0
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

  factory HomeKpiData.fromMap(Map<String, dynamic> map) {
    return HomeKpiData(
      totalBookingsThisYear: (map['total_bookings_year']  as num?)?.toInt()    ?? 0,
      thisMonthSpent:        (map['this_month_spend']     as num?)?.toDouble() ?? 0.0,
      thisMonthBookings:     (map['this_month_bookings']  as num?)?.toInt()    ?? 0,
      totalSpent:            (map['total_spend']          as num?)?.toDouble() ?? 0.0,
      savingsPercent:        (map['savings_percent']      as num?)?.toDouble() ?? 0.0,
      walletBalance:         (map['wallet_balance']       as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ── Promo banner ──────────────────────────────────────────────────────────────
// Fetched from GET /corporate/banners.
// Falls back to a cycling color palette when no imageUrl is provided.

// Fallback colors cycled by banner index
const _kBannerColors = [
  Color(0xFFFCC247),
  Color(0xFF23262D),
  Color(0xFF2E7D32),
  Color(0xFF1565C0),
  Color(0xFF6A1B9A),
];

class PromoBanner {
  final String  id;
  final String  title;
  final String  subtitle;   // maps from API "description"
  final Color   color;      // fallback palette — used when imageUrl is null
  final String? imageUrl;   // from API; if present, shown as network image

  const PromoBanner({
    this.id      = '',
    required this.title,
    required this.subtitle,
    required this.color,
    this.imageUrl,
  });

  factory PromoBanner.fromApiMap(Map<String, dynamic> map, int index) {
    return PromoBanner(
      id:       (map['id']          ?? '').toString(),
      title:    (map['title']       ?? '').toString(),
      subtitle: (map['description'] ?? '').toString(),
      color:    _kBannerColors[index % _kBannerColors.length],
      imageUrl: map['imageUrl']?.toString(),
    );
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}