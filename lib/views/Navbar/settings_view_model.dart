import 'package:flutter/material.dart';
import '../../services/session_service.dart';

class SettingsViewModel extends ChangeNotifier {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.light;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  SettingsViewModel() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final saved = await SessionService.getLocale();
    _locale = Locale(saved);
    notifyListeners();
  }

  Future<void> updateLocale(Locale locale) async {
    _locale = locale;
    await SessionService.saveLocale(locale.languageCode);
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  bool get isRtl => _locale.languageCode == 'ar';
}
