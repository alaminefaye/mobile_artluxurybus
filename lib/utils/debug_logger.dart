import 'package:flutter/foundation.dart';

class DebugLogger {
  static const bool _isDebugMode = kDebugMode;
  
  static void log(String message) {
    if (_isDebugMode) {
      debugPrint('[AUTH] $message');
    }
  }
  
  static void error(String message, [dynamic error]) {
    if (_isDebugMode) {
      debugPrint('[AUTH ERROR] $message${error != null ? ': $error' : ''}');
    }
  }
  
  static void response(int statusCode, String body) {
    if (_isDebugMode) {
      debugPrint('[AUTH RESPONSE] Status: $statusCode');
      debugPrint('[AUTH RESPONSE] Body: ${body.length > 500 ? '${body.substring(0, 500)}...' : body}');
    }
  }
}
