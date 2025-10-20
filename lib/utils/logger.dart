import 'dart:developer' as developer;

/// Utilitaire de logging pour l'application Art Luxury Bus
class AppLogger {
  static const String _appName = 'ArtLuxuryBus';

  /// Log d'information
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: _appName,
      level: 800, // INFO level
      time: DateTime.now(),
    );
  }

  /// Log d'erreur
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    developer.log(
      message,
      name: _appName,
      level: 1000, // ERROR level
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  /// Log de debug (seulement en mode debug)
  static void debug(String message, {String? tag}) {
    assert(() {
      developer.log(
        message,
        name: _appName,
        level: 500, // DEBUG level
        time: DateTime.now(),
      );
      return true;
    }());
  }

  /// Log d'avertissement
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: _appName,
      level: 900, // WARNING level
      time: DateTime.now(),
    );
  }
}
