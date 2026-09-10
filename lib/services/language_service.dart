import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._internal();

  static const String _languageKey = 'language';

  Locale _locale = const Locale('en');

  LanguageService._internal();

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    final savedLanguage = prefs.getString(_languageKey) ?? 'en';

    _locale = Locale(savedLanguage);

    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'ar') {
      return;
    }

    if (_locale.languageCode == languageCode) {
      return;
    }

    _locale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    notifyListeners();
  }
}
