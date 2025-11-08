import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service pour gérer les traductions de l'application
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  Map<String, dynamic> _translations = {};
  Locale _currentLocale = const Locale('fr', 'FR');
  bool _isLoaded = false;
  
  bool get isLoaded => _isLoaded;

  /// Charger les traductions pour une locale donnée
  Future<void> loadTranslations(Locale locale) async {
    try {
      _currentLocale = locale;
      final languageCode = locale.languageCode;
      // Le chemin doit correspondre exactement à celui dans pubspec.yaml
      final jsonString = await rootBundle.loadString('lib/l10n/$languageCode.json');
      _translations = json.decode(jsonString) as Map<String, dynamic>;
      _isLoaded = true;
      debugPrint('✅ Traductions chargées pour: $languageCode (${_translations.length} sections)');
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des traductions: $e');
      // En cas d'erreur, essayer de charger le français par défaut
      if (locale.languageCode != 'fr') {
        try {
          final jsonString = await rootBundle.loadString('lib/l10n/fr.json');
          _translations = json.decode(jsonString) as Map<String, dynamic>;
          _isLoaded = true;
          debugPrint('✅ Traductions françaises chargées par défaut');
        } catch (e2) {
          debugPrint('❌ Impossible de charger même les traductions françaises: $e2');
          // Initialiser avec un dictionnaire vide pour éviter les crashes
          _translations = {};
          _isLoaded = false;
        }
      } else {
        // Si on était déjà en train de charger le français et que ça échoue
        _translations = {};
        _isLoaded = false;
      }
    }
  }
  
  /// Forcer le rechargement des traductions
  Future<void> reloadTranslations(Locale locale) async {
    _isLoaded = false;
    await loadTranslations(locale);
  }

  /// Obtenir une traduction par clé
  String translate(String key, {Map<String, String>? params}) {
    try {
      // Si les traductions ne sont pas chargées, utiliser un fallback
      if (!_isLoaded || _translations.isEmpty) {
        return _getFrenchFallback(key);
      }
      
      final keys = key.split('.');
      dynamic value = _translations;

      for (final k in keys) {
        if (value is Map<String, dynamic>) {
          value = value[k];
        } else {
          return _getFrenchFallback(key);
        }
      }

      if (value is String) {
        String translation = value;
        // Remplacer les paramètres si fournis
        if (params != null) {
          params.forEach((key, value) {
            translation = translation.replaceAll('{{$key}}', value);
          });
        }
        return translation;
      }

      return _getFrenchFallback(key);
    } catch (e) {
      debugPrint('❌ Erreur lors de la traduction de "$key": $e');
      return _getFrenchFallback(key);
    }
  }
  
  /// Obtenir un texte par défaut en français si les traductions ne sont pas chargées
  String _getFrenchFallback(String key) {
    // Mapping de fallback pour les clés les plus utilisées
    final fallbacks = {
      'profile.my_account': 'Mon Compte',
      'profile.personal_info': 'Informations personnelles',
      'profile.edit_data': 'Modifier vos données',
      'profile.security': 'Sécurité',
      'profile.password_security': 'Mot de passe et sécurité',
      'profile.preferences': 'Préférences',
      'profile.notifications': 'Notifications',
      'profile.manage_alerts': 'Gérer vos alertes',
      'profile.voice_announcements': 'Annonces Vocales',
      'profile.announcement_config': 'Configuration des annonces',
      'profile.appearance': 'Apparence',
      'profile.theme_description': 'Thème clair, sombre ou système',
      'profile.language': 'Langue',
      'profile.support': 'Support',
      'profile.help_support': 'Aide et support',
      'profile.contact_team': 'Contactez notre équipe',
      'profile.about': 'À propos',
      'profile.about_info': 'Infos appareil & version',
      'profile.debug_tools': 'Outils de débogage',
      'profile.test_notifications': 'Tester les notifications et annonces',
      'navigation.home': 'Accueil',
      'navigation.notifications': 'Notifications',
      'navigation.services': 'Services',
      'navigation.profile': 'Profil',
      'home.search_placeholder': 'Rechercher un trajet, une ville...',
      'services.loyalty_program': 'Programme Fidélité',
      'services.loyalty_subtitle': 'Cumulez des points et avantages',
      'services.suggestions': 'Suggestions',
      'services.suggestions_subtitle': 'Partagez vos idées',
      'services.qr_scanner': 'Scanner QR',
      'services.qr_scanner_subtitle': 'Pointage rapide',
      'services.history': 'Historique',
      'services.attendance_history': 'Vos pointages',
      'services.bus_management': 'Gestion Bus',
      'services.bus_fleet': 'Flotte et maintenance',
      'services.schedules': 'Horaires',
      'services.view_schedules': 'Consulter les horaires',
      'services.mail': 'Courrier',
      'services.my_mails': 'Mes courriers',
      'services.videos': 'Mes Vidéos',
      'services.manage_videos': 'Gérer les vidéos publicitaires',
      'services.reservation': 'Réservation',
      'services.book_trip': 'Réserver un trajet',
      'services.my_trips': 'Mes Trajets',
      'services.view_trips': 'Voir mes réservations',
      'services.payment': 'Paiement',
      'services.payment_subtitle': 'Effectuer un paiement',
      'services.payment_development': 'Paiement - En développement',
      'services.help': 'Aide',
      'services.help_center': 'Centre d\'aide',
      'language.select_language': 'Sélectionnez votre langue préférée',
      'about.title': 'À propos',
      'about.app_name': 'Art Luxury Bus',
      'about.version': 'Version {{version}}',
      'about.device_info': 'Informations de l\'appareil',
      'about.unique_id': 'Identifiant unique',
      'about.device_name': 'Nom de l\'appareil',
      'about.type': 'Type',
      'about.model': 'Modèle',
      'about.brand': 'Marque',
      'about.manufacturer': 'Fabricant',
      'about.android_version': 'Version Android',
      'about.ios_version': 'Version iOS',
      'about.app_about': 'À propos de l\'application',
      'about.app_description': 'Art Luxury Bus est votre compagnon de voyage pour un service de transport de classe nationale. Gérez vos points de fidélité, partagez vos suggestions et restez informé de nos services.',
      'about.copyright': '© 2025 Art Luxury Bus\nTous droits réservés',
      'about.copy': 'Copier',
      'about.copied_to_clipboard': '{{label}} copié dans le presse-papiers',
      'about.loading_error': 'Impossible de charger les informations',
      'trips.title': 'Mes Trajets',
      'trips.trip': 'Trajet',
      'trips.trips': 'Trajets',
      'trips.refresh': 'Actualiser',
      'trips.no_trips': 'Aucun trajet',
      'trips.no_trips_registered': 'Vous n\'avez pas encore de trajets enregistrés',
      'trips.date': 'Date',
      'trips.departure': 'Départ',
      'trips.seat': 'Siège',
      'trips.total_price': 'Prix total',
      'trips.embarkment_label': 'Embarquement',
      'trips.disembarkment_label': 'Débarquement',
      'security.name': 'Nom',
      'security.email_address': 'Adresse email',
      'security.save_changes': 'Enregistrer les modifications',
      'security.change_password': 'Changer le mot de passe',
      'security.tap_to_change': 'Toucher l\'icône pour changer',
      'security.upload_in_progress': 'Upload en cours...',
      'security.name_required': 'Le nom est obligatoire',
      'security.name_min_length': 'Le nom doit contenir au moins 3 caractères',
      'security.email_required': 'L\'email est obligatoire',
      'security.invalid_email': 'Email invalide',
      'security.feature_coming': 'Fonctionnalité à venir',
      'common.save': 'Enregistrer',
      'common.cancel': 'Annuler',
      'common.confirm': 'Confirmer',
      'common.loading': 'Chargement...',
      'common.error': 'Erreur',
      'common.success': 'Succès',
      'common.yes': 'Oui',
      'common.no': 'Non',
      'common.ok': 'OK',
      'common.close': 'Fermer',
      'common.back': 'Retour',
      'common.search': 'Rechercher',
      'common.filter': 'Filtrer',
      'common.refresh': 'Actualiser',
      'client_info.title': 'Informations client',
      'client_info.continue_with_success': 'Continuer avec succès',
      'client_info.try_again': 'Réessayer',
      'seats.title': 'Sélection des sièges',
      'seats.continue': 'Continuer',
      'seats.free': 'Libre',
      'seats.occupied': 'Occupé',
      'seats.selected_seat': 'Sélectionné',
      'seats.reserved': 'Réservé',
      'seats.selected': 'sélectionné',
      'seats.select_your_stops': 'Sélectionnez vos arrêts',
    };
    
    return fallbacks[key] ?? key;
  }

  /// Obtenir la locale actuelle
  Locale get currentLocale => _currentLocale;
}

/// Provider pour le service de traduction
final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});

/// Provider pour vérifier si les traductions sont chargées
final translationsLoadedProvider = Provider<bool>((ref) {
  return TranslationService().isLoaded;
});

/// Provider pour obtenir une traduction
final translationProvider = Provider.family<String, String>((ref, key) {
  final translationService = ref.watch(translationServiceProvider);
  return translationService.translate(key);
});

/// Helper pour obtenir une traduction facilement
String t(String key, {Map<String, String>? params}) {
  return TranslationService().translate(key, params: params);
}

/// Extension pour faciliter l'utilisation des traductions dans les widgets
extension TranslationExtension on BuildContext {
  String t(String key, {Map<String, String>? params}) {
    return TranslationService().translate(key, params: params);
  }
}

