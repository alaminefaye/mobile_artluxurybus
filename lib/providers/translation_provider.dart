import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/translation_service.dart';
import 'language_provider.dart';

/// StateNotifier pour gérer le chargement des traductions
class TranslationNotifier extends StateNotifier<bool> {
  final TranslationService _translationService = TranslationService();
  
  TranslationNotifier() : super(false) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Ne pas charger ici, attendre que la langue soit déterminée
    // Le chargement se fera dans loadTranslations()
  }

  Future<void> loadTranslations(Locale locale) async {
    try {
      await _translationService.loadTranslations(locale);
      final wasLoaded = state;
      state = _translationService.isLoaded;
      if (state != wasLoaded) {
        debugPrint('✅ [TranslationNotifier] État changé: $wasLoaded -> $state');
      }
    } catch (e) {
      debugPrint('❌ [TranslationNotifier] Erreur chargement: $e');
      state = false;
    }
  }
  
  TranslationService get translationService => _translationService;
}

/// Provider pour le StateNotifier des traductions
final translationLoadingProvider = StateNotifierProvider<TranslationNotifier, bool>((ref) {
  final notifier = TranslationNotifier();
  // Charger les traductions pour la langue actuelle
  final locale = ref.watch(languageProvider);
  notifier.loadTranslations(locale);
  return notifier;
});
