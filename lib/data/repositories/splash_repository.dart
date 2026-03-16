import '../../services/session_service.dart';
import '../app_cache.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/splash_repository.dart
//
// Orchestrates everything loaded before the user sees any screen.
// SplashScreen calls loadSessionState() first, then loadDropdowns().
// They must NOT run in parallel — loadDropdowns needs cachedIsLoggedIn.
//
// FETCH LOGIC:
// - Branches: Fetched for ALL users (logged in or not)
// - Referrals: Fetched ONLY for non-logged-in users (registration flow)
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
  // MUST be called after loadSessionState() so cachedIsLoggedIn is correct.
  // Logged-in  → fetches profile (allowed branches) + public branches
  // Logged-out → fetches public branches + referrals (registration flow)

  static Future<void> loadDropdowns() async {
    // cachedIsLoggedIn is set by loadSessionState() — call that first.
    await AppCache.init(isLoggedIn: cachedIsLoggedIn);
  }
}