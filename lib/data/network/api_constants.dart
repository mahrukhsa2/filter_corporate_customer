// ─────────────────────────────────────────────────────────────────────────────
// lib/data/api_constants.dart
// ─────────────────────────────────────────────────────────────────────────────

class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'https://filterbackend-production.up.railway.app';

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String login    = '/auth/corporate/login';
  static const String logout   = '/auth/corporate/logout';
  static const String register = '/auth/corporate/register';

  // ── Dashboard ──────────────────────────────────────────────────────────────
  static const String dashboard = '/corporate/dashboard';

  // ── Lookup / dropdowns ────────────────────────────────────────────────────
  static const String branches    = '/corporate/branches';
  static const String departments = '/corporate/departments';

  // ── Vehicles ───────────────────────────────────────────────────────────────
  static const String vehicles = '/corporate/vehicles';

  // ── Bookings ───────────────────────────────────────────────────────────────
  static const String bookings = '/corporate/bookings';
  static const String orders = '/corporate/orders';

  // ── Billing ────────────────────────────────────────────────────────────────
  static const String billing  = '/corporate/billing';
  static const String invoices = '/corporate/invoices';

  // ── Wallet ─────────────────────────────────────────────────────────────────
  static const String wallet      = '/corporate/wallet';
  static const String walletTopup = '/corporate/wallet/topup';

  // ── Reports ────────────────────────────────────────────────────────────────
  static const String reports         = '/corporate/reports';
  static const String reportsBookings = '/corporate/reports/bookings';
  static const String reportsWallet   = '/corporate/reports/wallet';
  static const String reportsSavings  = '/corporate/reports/savings';

  // ── Quotations ─────────────────────────────────────────────────────────────
  static const String quotations = '/corporate/quotations';

  // ── Timeouts ───────────────────────────────────────────────────────────────
  static const Duration requestTimeout = Duration(seconds: 30);
}