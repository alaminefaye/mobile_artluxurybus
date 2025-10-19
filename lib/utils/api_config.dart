class ApiConfig {
  // Configuration pour le serveur en ligne - PRODUCTION ✅ RÉPARÉ !
  static const String baseUrl = 'https://gestion-compagny.universaltechnologiesafrica.com/api';
  
  // Serveur Laravel local (désactivé)
  // static const String baseUrl = 'http://localhost:8000/api';
  
  // Serveur de test temporaire (désactivé - serveur principal fonctionne!)
  // static const String baseUrl = 'http://10.0.2.2:8001/api';
  
  // Headers par défaut
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Timeout pour les requêtes
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String userProfileEndpoint = '/user';
  static const String pingEndpoint = '/ping';
}

// Extension pour faciliter la construction des URLs complètes
extension ApiEndpoints on String {
  String get fullUrl => '${ApiConfig.baseUrl}$this';
}
