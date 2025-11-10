/// Helper pour convertir les erreurs techniques en messages user-friendly
class ErrorMessageHelper {
  /// Convertir une erreur en message compréhensible pour l'utilisateur
  static String getUserFriendlyError(dynamic error, {String? defaultMessage}) {
    if (error == null) {
      return defaultMessage ?? 'Une erreur est survenue. Veuillez réessayer.';
    }

    String errorString = error.toString();

    // Si c'est déjà un message user-friendly (pas de détails techniques)
    if (_isUserFriendly(errorString)) {
      // Nettoyer les préfixes techniques
      errorString = errorString
          .replaceAll('Exception: ', '')
          .replaceAll('Error: ', '')
          .replaceAll('Exception', '')
          .trim();
      
      // Si le message est vide après nettoyage, utiliser le message par défaut
      if (errorString.isEmpty) {
        return defaultMessage ?? 'Une erreur est survenue. Veuillez réessayer.';
      }
      
      return errorString;
    }

    // Extraire le message depuis une réponse API
    if (error is Map<String, dynamic>) {
      return _extractFromApiResponse(error, defaultMessage);
    }

    // IMPORTANT: Vérifier d'abord les erreurs spécifiques (ClientException + SocketException)
    // avant les erreurs génériques (SocketException seul)
    
    // Erreur ClientException avec SocketException (erreur HTTP + réseau) - Plus spécifique
    if (errorString.contains('ClientException') && 
        (errorString.contains('SocketException') || 
         errorString.contains('Failed host lookup') ||
         errorString.contains('No address associated with hostname'))) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet et réessayez.';
    }
    
    // Messages d'erreur communs - Connexion réseau (générique)
    if (errorString.contains('SocketException') || 
        errorString.contains('Failed host lookup') ||
        errorString.contains('Network is unreachable') ||
        errorString.contains('No address associated with hostname') ||
        errorString.contains('Connection refused') ||
        errorString.contains('Connection timed out') ||
        errorString.contains('No route to host')) {
      return 'Pas de connexion internet. Vérifiez votre connexion WiFi ou données mobiles et réessayez.';
    }

    if (errorString.contains('TimeoutException') || errorString.contains('timeout')) {
      return 'La requête a pris trop de temps. Veuillez réessayer.';
    }

    if (errorString.contains('401') || errorString.contains('Unauthorized')) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }

    if (errorString.contains('403') || errorString.contains('Forbidden')) {
      return 'Vous n\'avez pas la permission d\'effectuer cette action.';
    }

    if (errorString.contains('404') || errorString.contains('Not Found')) {
      return 'Ressource introuvable.';
    }

    if (errorString.contains('422') || errorString.contains('Unprocessable')) {
      return 'Données invalides. Veuillez vérifier les informations saisies.';
    }

    if (errorString.contains('500') || errorString.contains('Internal Server Error')) {
      return 'Erreur serveur. Veuillez réessayer dans quelques instants.';
    }

    if (errorString.contains('503') || errorString.contains('Service Unavailable')) {
      return 'Service temporairement indisponible. Veuillez réessayer plus tard.';
    }

    // Erreurs SQL - ne jamais afficher les détails SQL
    if (errorString.contains('SQLSTATE') || 
        errorString.contains('SQL') ||
        errorString.contains('database') && errorString.contains('error')) {
      return defaultMessage ?? 'Erreur lors de la sauvegarde des données. Veuillez réessayer.';
    }

    // Erreurs de validation Laravel
    if (errorString.contains('The given data was invalid') ||
        errorString.contains('validation failed')) {
      return 'Les données saisies sont invalides. Veuillez vérifier tous les champs.';
    }

    // Stack traces - ne jamais afficher
    if (errorString.contains('#0') || errorString.contains('at ') || errorString.contains('Stack trace')) {
      return defaultMessage ?? 'Une erreur inattendue est survenue. Veuillez réessayer.';
    }

    // Si on ne peut pas déterminer le type d'erreur, utiliser le message par défaut
    return defaultMessage ?? 'Une erreur est survenue. Veuillez réessayer.';
  }

  /// Vérifier si un message est déjà user-friendly
  static bool _isUserFriendly(String message) {
    // Messages qui ne sont PAS user-friendly
    final technicalPatterns = [
      'Exception:',
      'Error:',
      'SQLSTATE',
      'SQL',
      'Stack trace',
      '#0',
      'at ',
      'file:',
      'line:',
      'Connection:',
      'Connection refused',
      'SocketException',
      'TimeoutException',
      'Failed host lookup',
    ];

    final lowerMessage = message.toLowerCase();
    for (final pattern in technicalPatterns) {
      if (lowerMessage.contains(pattern.toLowerCase())) {
        return false;
      }
    }

    return true;
  }

  /// Extraire un message depuis une réponse API
  static String _extractFromApiResponse(Map<String, dynamic> data, String? defaultMessage) {
    // 1. Vérifier le message direct (sans détails techniques)
    if (data['message'] != null) {
      final message = data['message'].toString();
      if (!message.contains('SQLSTATE') && 
          !message.contains('SQL') && 
          !message.contains('Stack trace') &&
          !message.contains('#0')) {
        return message;
      }
    }

    // 2. Vérifier les erreurs de validation Laravel
    if (data['errors'] != null && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      if (errors.isNotEmpty) {
        // Prendre le premier message d'erreur
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        } else if (firstError is String) {
          return firstError;
        }
      }
    }

    // 3. Messages par code de statut
    final statusCode = data['status_code'] ?? data['status'];
    if (statusCode != null) {
      switch (statusCode.toString()) {
        case '401':
          return 'Session expirée. Veuillez vous reconnecter.';
        case '403':
          return 'Vous n\'avez pas la permission d\'effectuer cette action.';
        case '404':
          return 'Ressource introuvable.';
        case '422':
          return 'Données invalides. Veuillez vérifier les informations saisies.';
        case '500':
          return 'Erreur serveur. Veuillez réessayer dans quelques instants.';
        case '503':
          return 'Service temporairement indisponible. Veuillez réessayer plus tard.';
      }
    }

    return defaultMessage ?? 'Une erreur est survenue. Veuillez réessayer.';
  }

  /// Obtenir un message d'erreur selon le type d'opération
  static String getOperationError(String operation, {dynamic error, String? customMessage}) {
    if (customMessage != null) {
      return customMessage;
    }

    if (error != null) {
      return getUserFriendlyError(error);
    }

    // Messages par défaut selon l'opération
    switch (operation.toLowerCase()) {
      case 'create':
      case 'créer':
      case 'ajouter':
        return 'Impossible de créer l\'élément. Veuillez réessayer.';
      case 'update':
      case 'mettre à jour':
      case 'modifier':
        return 'Impossible de modifier l\'élément. Veuillez réessayer.';
      case 'delete':
      case 'supprimer':
        return 'Impossible de supprimer l\'élément. Veuillez réessayer.';
      case 'load':
      case 'charger':
      case 'récupérer':
        return 'Impossible de charger les données. Veuillez réessayer.';
      case 'save':
      case 'sauvegarder':
        return 'Impossible de sauvegarder. Veuillez réessayer.';
      case 'send':
      case 'envoyer':
        return 'Impossible d\'envoyer. Veuillez réessayer.';
      case 'upload':
      case 'télécharger':
        return 'Impossible de télécharger le fichier. Veuillez réessayer.';
      default:
        return 'Une erreur est survenue lors de l\'opération. Veuillez réessayer.';
    }
  }
}




