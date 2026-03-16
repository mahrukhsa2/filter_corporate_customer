import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/auth_response_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/services/session_service.dart
// All SharedPreferences access is centralised here.
// Existing method signatures are PRESERVED so no other screen breaks.
// ─────────────────────────────────────────────────────────────────────────────

class SessionService {
  SessionService._();

  // ── Keys ───────────────────────────────────────────────────────────────────
  static const _kToken      = 'session_token';
  static const _kUser       = 'auth_user_json'; // full AuthUser JSON
  static const _kLocale     = 'app_locale';
  static const _kOnboard    = 'onboard_done';
  static const _kRememberMe = 'remember_me';
  static const _kLoggedIn   = 'is_logged_in'; // ✅ NEW

  // ── Token ──────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
  }

  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kToken);
  }

  static Future<void> clearToken() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
  }

  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    // Check explicit flag first (more reliable)
    if (p.containsKey(_kLoggedIn)) {
      return p.getBool(_kLoggedIn) ?? false;
    }
    // Fallback to token check for backward compatibility
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── ✅ NEW: Explicit logged-in flag ───────────────────────────────────────
  // Set this to true after successful login, false on logout.
  // This is more reliable than just checking token existence.

  static Future<void> setLoggedIn(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, value);
  }

  // ── User object (new — stores full AuthUser JSON) ──────────────────────────

  static Future<void> saveUser(AuthUser user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUser, jsonEncode(user.toMap()));
  }

  static Future<AuthUser?> getUser() async {
    final p   = await SharedPreferences.getInstance();
    final raw = p.getString(_kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthUser.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Legacy helpers (kept so existing ViewModels don't break) ──────────────
  // Reads from the stored AuthUser JSON under the hood.

  static Future<void> saveUserInfo({
    required String companyName,
    required String email,
  }) async {
    // Patch only company name + email into the stored user map
    final p   = await SharedPreferences.getInstance();
    final raw = p.getString(_kUser);
    final map = raw != null
        ? jsonDecode(raw) as Map<String, dynamic>
        : <String, dynamic>{};

    map['email'] = email;
    final acc = (map['corporateAccount'] as Map<String, dynamic>?) ?? {};
    acc['companyName']       = companyName;
    map['corporateAccount']  = acc;

    await p.setString(_kUser, jsonEncode(map));
  }

  static Future<String?> getCompanyName() async {
    final user = await getUser();
    return user?.companyName;
  }

  static Future<String?> getUserEmail() async {
    final user = await getUser();
    return user?.email;
  }

  static Future<String?> getUserName() async {
    final user = await getUser();
    return user?.name;
  }

  static Future<String?> getWorkshopId() async {
    final user = await getUser();
    return user?.workshopId;
  }

  static Future<String> getCurrencyCode() async {
    final user = await getUser();
    return user?.currencyCode ?? 'SAR';
  }

  // ── Locale ─────────────────────────────────────────────────────────────────

  static Future<void> saveLocale(String languageCode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, languageCode);
  }

  static Future<String> getLocale() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLocale) ?? 'en';
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────

  static Future<void> setOnboardDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboard, true);
  }

  static Future<bool> isOnboardDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kOnboard) ?? false;
  }

  // ── Remember Me ────────────────────────────────────────────────────────────

  static Future<void> setRememberMe(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRememberMe, value);
  }

  static Future<bool> getRememberMe() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kRememberMe) ?? false;
  }

  // ── Clear session (logout) ─────────────────────────────────────────────────
  // Keeps locale + onboard flag so UX is unchanged after re-login.

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kUser);
    await p.remove(_kLoggedIn); // ✅ Clear logged-in flag on logout
    final remember = p.getBool(_kRememberMe) ?? false;
    if (!remember) await p.remove(_kRememberMe);
  }
}