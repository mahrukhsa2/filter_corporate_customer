import 'package:flutter/material.dart';
import '../../data/network/api_response.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/app_cache.dart';
import '../../services/session_service.dart';
import '../../widgets/app_alert.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Login/login_view_model.dart
// ─────────────────────────────────────────────────────────────────────────────

enum LoginStatus { idle, loading, success, error }

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  LoginStatus _status          = LoginStatus.idle;
  bool        _obscurePassword = true;
  bool        _rememberMe      = false;

  LoginStatus get status          => _status;
  bool        get obscurePassword => _obscurePassword;
  bool        get rememberMe      => _rememberMe;
  bool        get isLoading       => _status == LoginStatus.loading;

  LoginViewModel() {
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    _rememberMe = await SessionService.getRememberMe();
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void resetStatus() {
    _status = LoginStatus.idle;
    notifyListeners();
  }

  Future<bool> login(
      BuildContext context, {
        required String email,
        required String password,
      }) async {
    _status = LoginStatus.loading;
    notifyListeners();

    final result = await _authRepository.login(
      email:    email,
      password: password,
    );

    if (result.success && result.data != null) {
      final model = result.data!;

      // ── Persist session ────────────────────────────────────────────────
      await SessionService.saveToken(model.token!);
      await SessionService.saveUser(model.user!);
      await SessionService.setRememberMe(_rememberMe);
      await SessionService.setLoggedIn(true);

      // ── ✅ Refresh cache for logged-in user ───────────────────────────
      // User just logged in, so we need to switch from public data
      // (branches + referrals) to user-specific data (profile with allowed branches).
      // This ensures BookingScreen shows the correct allowed branches.
      debugPrint('[LoginViewModel] User logged in, calling AppCache.onLogin()');
      await AppCache.onLogin();
      debugPrint('[LoginViewModel] AppCache.onLogin() complete');

      _status = LoginStatus.success;
      notifyListeners();
      return true;
    }

    _status = LoginStatus.error;
    notifyListeners();

    if (context.mounted) {
      await AppAlert.apiError(
        context,
        errorType: result.errorType,
        message:   result.message,
        onRetry: result.errorType == ApiErrorType.noInternet ||
            result.errorType == ApiErrorType.timeout
            ? () => login(context, email: email, password: password)
            : null,
      );
    }

    return false;
  }
}