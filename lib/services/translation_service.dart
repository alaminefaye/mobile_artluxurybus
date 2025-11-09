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
      final sectionsCount = _translations.keys.length;
      debugPrint('✅ Traductions chargées pour: $languageCode ($sectionsCount sections)');
      // Debug: vérifier que les clés auth existent
      if (_translations.containsKey('auth')) {
        final authKeys = (_translations['auth'] as Map<String, dynamic>).keys.length;
        debugPrint('   - Clés auth trouvées: $authKeys');
      } else {
        debugPrint('   - ⚠️ Section "auth" non trouvée dans les traductions');
      }
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
      // Debug: vérifier l'état des traductions
      if (!_isLoaded) {
        debugPrint('⚠️ [TranslationService] Traductions non chargées pour "$key", utilisation du fallback');
        final fallback = _getFrenchFallback(key);
        return fallback;
      }
      
      if (_translations.isEmpty) {
        debugPrint('⚠️ [TranslationService] Dictionnaire de traductions vide pour "$key", utilisation du fallback');
        final fallback = _getFrenchFallback(key);
        return fallback;
      }
      
      // Toujours essayer d'abord avec les traductions chargées
      final keys = key.split('.');
      dynamic value = _translations;

      for (final k in keys) {
        if (value is Map<String, dynamic>) {
          value = value[k];
          if (value == null) {
            // Clé non trouvée, utiliser le fallback
            debugPrint('⚠️ [TranslationService] Clé "$key" non trouvée dans les traductions (locale: ${_currentLocale.languageCode})');
            break;
          }
        } else {
          // Structure invalide, utiliser le fallback
          value = null;
          break;
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
      
      // Si on arrive ici, utiliser le fallback
      final fallback = _getFrenchFallback(key);
      if (fallback != key) {
        debugPrint('⚠️ [TranslationService] Utilisation du fallback français pour "$key" (locale actuelle: ${_currentLocale.languageCode})');
        return fallback;
      }
      
      // Si le fallback retourne la clé elle-même
      debugPrint('⚠️ [TranslationService] Traduction manquante pour "$key" dans les fichiers JSON (locale: ${_currentLocale.languageCode})');
      return fallback;
    } catch (e) {
      debugPrint('❌ Erreur lors de la traduction de "$key": $e');
      final fallback = _getFrenchFallback(key);
      return fallback;
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
      'trips.already_used': 'DÉJÀ UTILISÉ',
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
      'onboarding.select_language': 'Choisissez votre langue',
      'onboarding.select_language_description': 'Sélectionnez la langue que vous préférez utiliser dans l\'application',
      'onboarding.select_theme': 'Choisissez votre thème',
      'onboarding.select_theme_description': 'Personnalisez l\'apparence de l\'application selon vos préférences',
      'onboarding.theme_light': 'Mode clair',
      'onboarding.theme_light_description': 'Interface claire et lumineuse',
      'onboarding.theme_dark': 'Mode sombre',
      'onboarding.theme_dark_description': 'Interface sombre pour vos yeux',
      'onboarding.theme_system': 'Mode système',
      'onboarding.theme_system_description': 'Suit les paramètres de votre appareil',
      'onboarding.welcome_title': 'Bienvenue !',
      'onboarding.welcome_description': 'Découvrez tous les services Art Luxury Bus. Réservez vos trajets, gérez vos points de fidélité et bien plus encore.',
      'onboarding.feature_transport': 'Réservation de trajets en ligne',
      'onboarding.feature_loyalty': 'Programme de fidélité avec points',
      'onboarding.feature_notifications': 'Notifications en temps réel',
      'onboarding.get_started': 'Commencer',
      'common.next': 'Suivant',
      // Traductions auth
      'auth.login': 'Connexion',
      'auth.logout': 'Déconnexion',
      'auth.email': 'Email',
      'auth.password': 'Mot de passe',
      'auth.forgot_password': 'Mot de passe oublié ?',
      'auth.remember_me': 'Se souvenir de moi',
      'auth.welcome': 'Bienvenue !',
      'auth.connect_to_account': 'Connectez-vous à votre compte',
      'auth.email_or_phone': 'Email ou Téléphone',
      'auth.email_or_phone_hint': 'exemple@email.com ou 0771234567',
      'auth.email_or_phone_required': 'Veuillez saisir votre email ou téléphone',
      'auth.password_required': 'Veuillez saisir votre mot de passe',
      'auth.password_min_length': 'Le mot de passe doit contenir au moins 6 caractères',
      'auth.password_hint': 'Votre mot de passe',
      'auth.login_button': 'Se connecter',
      'auth.login_success': 'Connexion réussie !',
      'auth.login_error': 'Erreur de connexion',
      'auth.no_account': 'Pas encore de compte ?',
      'auth.register': 'S\'inscrire',
      'auth.skip': 'Ignorer',
      'auth.appearance': 'Apparence',
      'auth.forgot_password_feature_disabled': 'Fonctionnalité temporairement désactivée',
      // Traductions register
      'register.title': 'Inscription',
      'register.register_client': 'Enregistrer un nouveau client',
      'register.create_account': 'Créer un compte',
      'register.create_account_description': 'Rejoignez Art Luxury Bus et profitez de nos avantages',
      'register.personal_info': 'Informations personnelles',
      'register.first_name': 'Prénom',
      'register.last_name': 'Nom',
      'register.first_name_label': 'Prénom *',
      'register.last_name_label': 'Nom *',
      'register.first_name_hint': 'Votre prénom',
      'register.last_name_hint': 'Votre nom',
      'register.first_name_required': 'Le prénom est requis',
      'register.last_name_required': 'Le nom est requis',
      'register.phone': 'Téléphone',
      'register.phone_label': 'Téléphone *',
      'register.phone_hint': '+221 77 123 45 67',
      'register.phone_required': 'Le numéro de téléphone est requis',
      'register.phone_invalid': 'Numéro de téléphone invalide',
      'register.email': 'Email',
      'register.email_label': 'Email (optionnel)',
      'register.email_hint': 'votre.email@exemple.com',
      'register.email_required': 'L\'email est requis',
      'register.email_invalid': 'Email invalide',
      'register.date_of_birth': 'Date de naissance',
      'register.date_of_birth_label': 'Date de naissance (optionnel)',
      'register.date_of_birth_hint': 'Pour recevoir un cadeau d\'anniversaire 🎂',
      'register.select_date_of_birth': 'Sélectionnez votre date de naissance',
      'register.select_date': 'Sélectionnez votre date',
      'register.security': 'Sécurité',
      'register.password': 'Mot de passe',
      'register.password_label': 'Mot de passe *',
      'register.password_hint': 'Minimum 8 caractères',
      'register.password_required': 'Le mot de passe est requis',
      'register.password_min_length': 'Le mot de passe doit contenir au moins 6 caractères',
      'register.confirm_password': 'Confirmer le mot de passe',
      'register.confirm_password_label': 'Confirmer le mot de passe *',
      'register.confirm_password_hint': 'Retapez votre mot de passe',
      'register.confirm_password_required': 'Veuillez confirmer le mot de passe',
      'register.passwords_not_match': 'Les mots de passe ne correspondent pas',
      'register.register_button': 'S\'inscrire',
      'register.registering': 'Inscription en cours...',
      'register.register_success': 'Inscription réussie !',
      'register.register_error': 'Erreur lors de l\'inscription',
      'register.account_created': 'Compte créé avec succès !',
      'register.login_to_continue': 'Connectez-vous pour continuer',
      'register.welcome_message': 'Bienvenue {{name}} ! 🎉',
      'register.register_error_connection': 'Inscription réussie mais erreur de connexion : {{error}}',
      // Traductions public screen
      'public.welcome': 'Bienvenue !',
      'public.welcome_description': 'Explorez nos fonctionnalités sans connexion',
      'public.loyalty_points': 'Points de fidélité',
      'public.loyalty_points_description': 'Consultez et gérez vos points',
      'public.suggestions': 'Suggestions et préoccupations',
      'public.suggestions_description': 'Partagez votre avis sur nos services',
      'public.votes': 'Votes',
      'public.votes_description': 'Participez aux sondages et votes',
      'public.votes_login_required': 'Connectez-vous pour participer aux votes',
      'public.more_features': 'Plus de fonctionnalités',
      'public.more_features_description': 'Connectez-vous pour tout débloquer',
      'public.device_identifier': 'Identifiant appareil',
      'public.device_id_copied': 'Identifiant copié dans le presse-papiers',
      'public.appearance': 'Apparence',
      'public.change_theme': 'Changer le thème',
      'public.copy': 'Copier',
      'public.login': 'Se connecter',
      // Traductions create_account
      'create_account.title': 'Créer votre compte',
      'create_account.create_password': 'Créez votre mot de passe',
      'create_account.create_password_description': 'Choisissez un mot de passe sécurisé pour protéger votre compte',
      'create_account.birth_date': 'Date de naissance (optionnel)',
      'create_account.birth_date_hint': 'Sélectionnez votre date',
      'create_account.birth_date_select': 'Sélectionnez votre date de naissance',
      'create_account.birth_date_not_selected': 'Aucune date sélectionnée',
      'create_account.password': 'Mot de passe',
      'create_account.password_hint': 'Minimum 8 caractères',
      'create_account.confirm_password': 'Confirmer le mot de passe',
      'create_account.confirm_password_hint': 'Retapez votre mot de passe',
      'create_account.password_required': 'Veuillez entrer un mot de passe',
      'create_account.password_min_length': 'Le mot de passe doit contenir au moins 8 caractères',
      'create_account.confirm_password_required': 'Veuillez confirmer votre mot de passe',
      'create_account.passwords_not_match': 'Les mots de passe ne correspondent pas',
      'create_account.create_button': 'Créer mon compte',
      'create_account.loyalty_points': 'points fidélité',
      'create_account.cancel': 'Annuler',
      'create_account.ok': 'OK',
      'create_account.select_date': 'Sélectionnez votre date',
      'create_account.welcome': 'Bienvenue',
      'create_account.account_created_success': 'Compte créé avec succès',
      'create_account.account_created_error': 'Compte créé mais erreur de connexion',
      'create_account.advantages_title': 'Vos avantages',
      'create_account.advantages_loyalty_title': 'Programme de fidélité',
      'create_account.advantages_loyalty_description': 'Gagnez des points à chaque voyage',
      'create_account.advantages_free_tickets_title': 'Tickets gratuits',
      'create_account.advantages_free_tickets_description': '10 points = 1 voyage gratuit',
      'create_account.advantages_birthday_title': 'Cadeau d\'anniversaire',
      'create_account.advantages_birthday_description': 'Surprise spéciale le jour J',
      'create_account.advantages_notifications_title': 'Notifications',
      'create_account.advantages_notifications_description': 'Restez informé de nos offres',
      'create_account.birthday_message': 'Nous vous enverrons un cadeau spécial pour votre anniversaire! 🎉',
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

