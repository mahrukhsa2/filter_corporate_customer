import 'package:filter_corporate_customer/splash_screen.dart';
import 'package:filter_corporate_customer/views/OnlineBooking/MyBookings/my_bookings_screen.dart';
import 'package:filter_corporate_customer/views/OnlineBooking/booking_screen.dart';
import 'package:filter_corporate_customer/views/billingMonthly/billing_screen.dart';
import 'package:filter_corporate_customer/views/homescreen/home_screen.dart';
import 'package:filter_corporate_customer/views/makePayment/payment_screen.dart';
import 'package:filter_corporate_customer/views/myVehicle/vehicle_screen.dart';
import 'package:filter_corporate_customer/views/reporting/bookingServiceReport/booking_service_report_screen.dart';
import 'package:filter_corporate_customer/views/reporting/landingReport/reports_screen.dart';
import 'package:filter_corporate_customer/views/reporting/monthlyBilling/monthly_billing_report_screen.dart';
import 'package:filter_corporate_customer/views/reporting/paymentHistory/payment_history_report_screen.dart';
import 'package:filter_corporate_customer/views/reporting/quotationHistory/quotation_history_screen.dart';
import 'package:filter_corporate_customer/views/reporting/savingsReport/savings_discount_screen.dart';
import 'package:filter_corporate_customer/views/reporting/vehicleWise/vehicle_usage_screen.dart';
import 'package:filter_corporate_customer/views/reporting/walletHistory/wallet_transaction_screen.dart';
import 'package:filter_corporate_customer/views/wallet/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'services/session_service.dart';
import 'utils/app_theme.dart';
import 'views/Navbar/settings_view_model.dart';
import 'views/Navbar/navbar_view_model.dart';
import 'views/Login/onboarding_view.dart';
import 'views/Login/login_view.dart';
import 'views/Profile/profile_screen.dart';
import 'views/PriceQuotation/price_quotation_screen.dart';

import 'views/Navbar/pos_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Keeps status bar and system navigation bar visible but transparent,
  // so Flutter's SafeArea / MediaQuery.padding automatically pushes
  // all app content above the device navigation buttons — no overlap.
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:              Colors.transparent,
    systemNavigationBarColor:    Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  final isOnboardDone = await SessionService.isOnboardDone();
  final isLoggedIn = await SessionService.isLoggedIn();
  final savedLocale = await SessionService.getLocale();

  runApp(
    FilterCorporateApp(
      initialLocale: Locale(savedLocale),
      showOnboarding: !isOnboardDone,
      isLoggedIn: isLoggedIn,
    ),
  );
}

class FilterCorporateApp extends StatelessWidget {
  final Locale initialLocale;
  final bool showOnboarding;
  final bool isLoggedIn;

  const FilterCorporateApp({
    super.key,
    required this.initialLocale,
    required this.showOnboarding,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel()..updateLocale(initialLocale),
        ),
        ChangeNotifierProvider(create: (_) => NavbarViewModel()),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Filter Corporate',
            debugShowCheckedModeBanner: false,

            // ── Theme ──────────────────────────────────────────────────────
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,

            // ── Localisation ───────────────────────────────────────────────
            locale: settings.locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // ── Initial screen ─────────────────────────────────────────────
            home: _RtlWrapper(child: const SplashScreen()),

            // ── Named routes ───────────────────────────────────────────────
            // Every route is wrapped in _RtlWrapper so RTL switching works
            // across all screens automatically.
            onGenerateRoute: (routeSettings) {
              Widget page;

              switch (routeSettings.name) {
                case '/login':
                  page = const LoginScreen();
                  break;

                case '/register':
                  page = const OnboardingView();
                  break;

                case '/home':
                // HomeViewModel is provided inside HomeScreen itself via
                // ChangeNotifierProvider — no extra provider needed here.
                  page = const HomeScreen();
                  break;

                case '/vehicle_mng':
                // HomeViewModel is provided inside HomeScreen itself via
                // ChangeNotifierProvider — no extra provider needed here.
                  page = const VehicleScreen();
                  break;

                case '/price_quotation':
                // HomeViewModel is provided inside HomeScreen itself via
                // ChangeNotifierProvider — no extra provider needed here.
                  page = const PriceQuotationScreen();
                  break;



                case '/reports/quotation-history':
                  page = const QuotationHistoryScreen();
                  break;

                case '/reports/monthly-billing':
                  page = const MonthlyBillingReportScreen();
                  break;

                case '/reports/wallet-transactions':
                  page = const WalletTransactionScreen();
                  break;

                 case '/reports/savings':
                  page = const SavingsDiscountScreen();
                  break;

                 case '/reports/vehicle-usage':
                  page = const VehicleUsageScreen();
                  break;

                  case '/reports/payment-history':
                    page = const PaymentHistoryReportScreen();
                    break;

                case '/reports/booking-service-history':
                  page = const BookingServiceReportScreen();
                  break;


              case '/pos':
                  page = const PosShell();
                  break;

              // ── Placeholder routes – swap with real screens when ready ─
                case '/forgot-password':
                  page = const _PlaceholderScreen(title: 'Forgot Password');
                  break;

                case '/wallet':
                  page = const WalletScreen();
                  break;

                case '/new-booking':
                  page = const BookingScreen();
                  break;

                case '/my-bookings':
                  page = const MyBookingsScreen();
                  break;

                case '/price-quotation':
                  page = const PriceQuotationScreen();
                  break;

                case '/my-vehicles':
                  page = const VehicleScreen();
                  break;

                case '/monthly-billing':
                  page = const MonthlyBillingScreen();
                  break;

                case '/profile':
                  page = const ProfileScreen();
                  break;

                case '/make_payment':
                  page = const MakePaymentScreen();
                  break;

                case '/reports-landing':
                  page = const ReportsScreen();
                  break;

                case '/manage-branches':
                  page = const _PlaceholderScreen(title: 'Manage Branches');
                  break;

                default:
                // Unknown route → fall back to home
                  page = const LoginScreen();
              }

              return MaterialPageRoute(
                builder: (_) => _RtlWrapper(child: page),
                settings: routeSettings,
              );
            },

          );
        },
      ),
    );
  }

  /// Decides the very first screen shown based on persisted session state.
  Widget _resolveHome() {
    if (isLoggedIn) return const HomeScreen();
    if (showOnboarding) return const OnboardingView();
    return const LoginScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RTL wrapper – must live inside MaterialApp so localization context exists
// ─────────────────────────────────────────────────────────────────────────────

class _RtlWrapper extends StatelessWidget {
  final Widget child;
  const _RtlWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final isRtl = context.watch<SettingsViewModel>().isRtl;
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Temporary placeholder – replace each one with the real screen when ready
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFFCC247),
        foregroundColor: const Color(0xFF23262D),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded,
                size: 64, color: Color(0xFFFCC247)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF23262D)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}