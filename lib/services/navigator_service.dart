import 'package:flutter/material.dart';

/// Service global pour accéder au Navigator depuis n'importe où dans l'application
/// Utile pour les totems qui ne sont pas connectés et n'ont pas accès à HomePage
class NavigatorService {
  static final NavigatorService _instance = NavigatorService._internal();
  factory NavigatorService() => _instance;
  NavigatorService._internal();

  GlobalKey<NavigatorState>? _navigatorKey;

  /// Définir le navigatorKey global (appelé depuis main.dart)
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Obtenir le contexte global du Navigator
  BuildContext? getGlobalContext() {
    if (_navigatorKey?.currentContext != null) {
      return _navigatorKey!.currentContext;
    }
    return null;
  }

  /// Vérifier si le Navigator est disponible
  bool get isAvailable => _navigatorKey?.currentContext != null;
}

