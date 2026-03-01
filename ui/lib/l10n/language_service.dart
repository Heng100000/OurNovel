import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

class LanguageService extends ChangeNotifier {
  // Singleton instance
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  // Current language code ('km' or 'en')
  String _currentLanguage = 'km';
  String get currentLanguageCode => _currentLanguage;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language_code') ?? 'km';
    notifyListeners();
  }

  // Change language
  Future<void> switchLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);
      notifyListeners();
    }
  }

  // Get translated string
  String translate(String key) {
    return AppTranslations.translations[_currentLanguage]?[key] ?? key;
  }
  
  // Backward compatibility helper for SettingsPage ValueListenableBuilder if still needed
  // but we should ideally move to Consumer
  ValueNotifier<String> get currentLanguage => ValueNotifier<String>(_currentLanguage);
}
