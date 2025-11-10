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
      
      debugPrint('🔄 [LanguageNotifier] Chargement depuis SharedPreferences: $languageCode-$countryCode');
      
      final locale = Locale(languageCode, countryCode);
      state = locale;
      
      // Charger les traductions pour la langue chargée
      final translationService = TranslationService();
      // Toujours recharger pour s'assurer que la bonne langue est chargée
      await translationService.loadTranslations(locale);
      
      debugPrint('✅ [LanguageNotifier] Langue chargée: $languageCode-$countryCode');
      debugPrint('✅ [LanguageNotifier] Traductions chargées: ${translationService.isLoaded}');
      debugPrint('✅ [LanguageNotifier] Locale service: ${translationService.currentLocale.languageCode}');
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de la langue: $e');
    }
  }

  /// Changer la langue
  Future<void> setLanguage(Locale locale) async {
    try {
      debugPrint('🔄 [LanguageNotifier] setLanguage appelé: ${locale.languageCode}-${locale.countryCode}');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, locale.languageCode);
      await prefs.setString(_countryCodeKey, locale.countryCode ?? '');
      
      debugPrint('✅ [LanguageNotifier] Langue sauvegardée dans SharedPreferences');
      
      // Charger les traductions pour la nouvelle langue AVANT de changer le state
      final translationService = TranslationService();
      debugPrint('🔄 [LanguageNotifier] Chargement des traductions...');
      await translationService.loadTranslations(locale);
      
      debugPrint('✅ [LanguageNotifier] Traductions chargées: ${translationService.isLoaded}');
      debugPrint('✅ [LanguageNotifier] Locale service: ${translationService.currentLocale.languageCode}');
      
      // Attendre un petit délai pour s'assurer que les traductions sont chargées
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Maintenant changer le state (cela notifie les listeners)
      state = locale;
      
      debugPrint('✅ [LanguageNotifier] State mis à jour: ${locale.languageCode}-${locale.countryCode}');
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

