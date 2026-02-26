import 'package:flutter/material.dart';
import 'app_translations.dart';

class LanguageService {
  // Singleton instance
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  // ValueNotifier to hold current language code ('km' or 'en')
  final ValueNotifier<String> currentLanguage = ValueNotifier<String>('km');

  // Change language
  void switchLanguage(String languageCode) {
    if (currentLanguage.value != languageCode) {
      currentLanguage.value = languageCode;
    }
  }

  // Get translated string
  String translate(String key) {
    return AppTranslations.translations[currentLanguage.value]?[key] ?? key;
  }
}
