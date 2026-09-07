import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ValueNotifier<bool> {
  ThemeService._() : super(false);

  static final ThemeService instance = ThemeService._();

  static const String darkModeKey = 'darkMode';

  static Color surface(BuildContext context, Color lightColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surface
        : lightColor;
  }

  void initialize(bool isDarkMode) {
    value = isDarkMode;
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    value = isDarkMode;

    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setBool(darkModeKey, isDarkMode);
    if (!saved) {
      debugPrint('DARK MODE PREFERENCE SAVE FAILED');
    }
  }
}
