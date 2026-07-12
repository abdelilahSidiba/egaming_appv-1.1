import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مزوّد إعدادات التطبيق العامة — يُحمَّل مرة واحدة عند بدء التطبيق ويُحفظ
/// كل تغيير مباشرة (بدون زر "حفظ") تماشيًا مع فلسفة التطبيق (الفصل 1.8 / 10).
class SettingsProvider extends ChangeNotifier {
  static const _keyThemeMode = 'theme_mode';
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keyIntroScreenEnabled = 'intro_screen_enabled';

  ThemeMode themeMode = ThemeMode.system;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool introScreenEnabled = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyThemeMode);
    if (themeIndex != null) themeMode = ThemeMode.values[themeIndex];
    soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
    vibrationEnabled = prefs.getBool(_keyVibrationEnabled) ?? true;
    introScreenEnabled = prefs.getBool(_keyIntroScreenEnabled) ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    vibrationEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibrationEnabled, value);
  }

  Future<void> setIntroScreenEnabled(bool value) async {
    introScreenEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIntroScreenEnabled, value);
  }
}
