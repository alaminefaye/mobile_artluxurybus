import 'package:flutter/material.dart';

/// Helper class pour les traductions de l'application
/// Cette classe peut être étendue pour ajouter plus de traductions
class Translations {
  final Locale locale;

  Translations(this.locale);

  static Translations of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Translations(locale);
  }

  // Navigation
  String get home => locale.languageCode == 'en' ? 'Home' : 'Accueil';
  String get notifications => locale.languageCode == 'en' ? 'Notifications' : 'Notifications';
  String get services => locale.languageCode == 'en' ? 'Services' : 'Services';
  String get profile => locale.languageCode == 'en' ? 'Profile' : 'Profil';

  // Profile
  String get preferences => locale.languageCode == 'en' ? 'Preferences' : 'Préférences';
  String get language => locale.languageCode == 'en' ? 'Language' : 'Langue';
  String get appearance => locale.languageCode == 'en' ? 'Appearance' : 'Apparence';
  String get security => locale.languageCode == 'en' ? 'Security' : 'Sécurité';
  String get support => locale.languageCode == 'en' ? 'Support' : 'Support';
  String get about => locale.languageCode == 'en' ? 'About' : 'À propos';

  // Language selection
  String get selectLanguage => locale.languageCode == 'en' 
      ? 'Select your preferred language' 
      : 'Sélectionnez votre langue préférée';
  String get french => locale.languageCode == 'en' ? 'French' : 'Français';
  String get english => locale.languageCode == 'en' ? 'English' : 'Anglais';

  // Common
  String get save => locale.languageCode == 'en' ? 'Save' : 'Enregistrer';
  String get cancel => locale.languageCode == 'en' ? 'Cancel' : 'Annuler';
  String get confirm => locale.languageCode == 'en' ? 'Confirm' : 'Confirmer';
  String get loading => locale.languageCode == 'en' ? 'Loading...' : 'Chargement...';
  String get error => locale.languageCode == 'en' ? 'Error' : 'Erreur';
  String get success => locale.languageCode == 'en' ? 'Success' : 'Succès';
}

