import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parametrlər: tema, bildiriş UI, dil (persist).
class AppSettingsController extends ChangeNotifier {
  AppSettingsController._();
  static final AppSettingsController instance = AppSettingsController._();

  static const _kDark = 'settings_dark_mode';
  static const _kNotif = 'settings_notifications_enabled';
  static const _kLang = 'settings_language_code';

  ThemeMode _themeMode = ThemeMode.light;
  bool _notificationsEnabled = true;
  String _languageCode = 'az';

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get languageCode => _languageCode;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _themeMode =
        p.getBool(_kDark) == true ? ThemeMode.dark : ThemeMode.light;
    _notificationsEnabled = p.getBool(_kNotif) ?? true;
    _languageCode = p.getString(_kLang) ?? 'az';
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDark, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotif, value);
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    if (code.isEmpty) return;
    _languageCode = code;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, code);
    notifyListeners();
  }
}
