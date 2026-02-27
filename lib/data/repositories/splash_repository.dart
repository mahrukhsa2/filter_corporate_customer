import '../../services/session_service.dart';
import '../app_cache.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/splash_repository.dart
//
// Orchestrates everything loaded before the user sees any screen.
// SplashScreen calls loadSessionState() and loadDropdowns() in parallel.
// ─────────────────────────────────────────────────────────────────────────────

class SplashRepository {
  SplashRepository._();

  // ── Cached session state (read by SplashScreen to decide which route) ─────
  static bool   cachedIsLoggedIn    = false;
  static bool   cachedIsOnboardDone = false;
  static String cachedLocale        = 'en';

  // ── 1. Session state ──────────────────────────────────────────────────────

  static Future<void> loadSessionState() async {
    final results = await Future.wait([
      SessionService.isLoggedIn(),
      SessionService.isOnboardDone(),
      SessionService.getLocale(),
    ]);
    cachedIsLoggedIn    = results[0] as bool;
    cachedIsOnboardDone = results[1] as bool;
    cachedLocale        = results[2] as String;
  }

  // ── 2. Lookup / dropdown data ─────────────────────────────────────────────
  // AppCache.init() fetches branches + departments (and any future lookups)
  // concurrently. Results sit in memory — ViewModels read them instantly.
  //
  // Skipped when user is not logged in because the endpoints require auth.
  // AppCache.init() is called again from LoginViewModel after a successful
  // login so the cache is warm before the home screen loads.

  static Future<void> loadDropdowns() async {
    if (!cachedIsLoggedIn) return;
    await AppCache.init();
  }
}
