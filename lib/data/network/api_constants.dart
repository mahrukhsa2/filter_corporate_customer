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
  static const String banners   = '/corporate/banners';

  // ── Dashboard ──────────────────────────────────────────────────────────────
  static const String profile = '/corporate/profile';

  // ── Lookup / dropdowns ────────────────────────────────────────────────────
  static const String branches    = '/corporate/branches';
  static const String departments = '/corporate/departments';
  static const String referrals   = '/corporate/referrals';

  // ── Vehicles ───────────────────────────────────────────────────────────────
  static const String vehicles = '/corporate/vehicles';

  static const String timeSlots = '/corporate/time-slots';


  // ── Bookings ───────────────────────────────────────────────────────────────
  static const String bookings = '/corporate/bookings';
  static const String orders = '/corporate/orders';
  static const String orderSubmit = '/corporate/order';   // POST — submit new order

  static const String makePayment   = '/corporate/make_payment';   // POST — confirm payment


  static const String billingMonthly = '/corporate/billing/monthly';
  static const String billingSummary  = '/corporate/billing/summary';  static const String invoices = '/corporate/invoices';

  // ── Wallet ─────────────────────────────────────────────────────────────────
  static const String wallet        = '/corporate/wallet';
  static const String walletTopup   = '/corporate/wallet/topup';
  static const String walletSummary = '/corporate/wallet/summary';
  static const String walletHistory = '/corporate/wallet/history';

  // ── Reports ────────────────────────────────────────────────────────────────
  static const String reports         = '/corporate/reports';
  static const String reportsSummary  = '/corporate/reports/summary';
  static const String reportsBookings = '/corporate/reports/bookings';
  static const String reportsWallet   = '/corporate/reports/wallet';
  static const String reportsSavings  = '/corporate/reports/savings';
  static const String reportsBookingServiceHistory  = '/corporate/reports/history';
  static const String reportsCustom                 = '/corporate/reports/custom';
  static const String reportsVehicleUsage            = '/corporate/reports/vehicle-usage';
  static const String reportsPayments                = '/corporate/reports/payments';


  // ── Quotations ─────────────────────────────────────────────────────────────
  // ── Quotations ✅ NEW ──────────────────────────────────────────────────────
  static const String quotations       = '/corporate/quotations';
  static const String quotationsSubmit = '/corporate/quotations/submit';
  static const String productsSearch   = '/corporate/products/search';
  static const String quotationsSummary = '/corporate/quotations/summary';

  // ── Timeouts ───────────────────────────────────────────────────────────────
  static const Duration requestTimeout = Duration(seconds: 40);
}
