import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';

/// Provider pour gérer la langue de l'application
class LanguageNotifier extends StateNotifier<Locale> {
  static const String _languageCodeKey = 'app_language_code';
  static const String _countryCodeKey = 'app_country_code';
  
  LanguageNotifier() : super(const Locale('fr', 'FR')) {
    _loadLanguage();
  }

  /// Charger la langue depuis SharedPreferences
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageCodeKey) ?? 'fr';
      final countryCode = prefs.getString(_countryCodeKey) ?? 'FR';
      
      final locale = Locale(languageCode, countryCode);
      state = locale;
      
      // Charger les traductions pour la langue chargée
      final translationService = TranslationService();
      if (!translationService.isLoaded) {
        await translationService.loadTranslations(locale);
      }
      
      debugPrint('✅ Langue chargée: $languageCode-$countryCode');
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de la langue: $e');
    }
  }

  /// Changer la langue
  Future<void> setLanguage(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, locale.languageCode);
      await prefs.setString(_countryCodeKey, locale.countryCode ?? '');
      state = locale;
      
      // Charger les traductions pour la nouvelle langue
      await TranslationService().loadTranslations(locale);
      
      debugPrint('✅ Langue changée: ${locale.languageCode}-${locale.countryCode}');
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde de la langue: $e');
    }
  }

  /// Obtenir le nom d'affichage de la langue
  String getDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return 'Français';
    }
  }

  /// Obtenir l'icône de la langue
  IconData getIcon(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return Icons.flag;
      case 'en':
        return Icons.flag_outlined;
      default:
        return Icons.language;
    }
  }

  /// Vérifier si la langue est le français
  bool get isFrench => state.languageCode == 'fr';

  /// Vérifier si la langue est l'anglais
  bool get isEnglish => state.languageCode == 'en';
}

/// Provider pour la langue
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>(
  (ref) => LanguageNotifier(),
);

