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
  
  // Endpoints - Auth
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String userProfileEndpoint = '/user';
  static const String pingEndpoint = '/ping';
  
  // Endpoints - Bus Management
  static const String busDashboardEndpoint = '/buses/dashboard';
  static const String busesEndpoint = '/buses';
  static String busDetailsEndpoint(int busId) => '/buses/$busId';
  static String busMaintenancesEndpoint(int busId) => '/buses/$busId/maintenances';
  static String busFuelHistoryEndpoint(int busId) => '/buses/$busId/fuel-history';
  static String busFuelStatsEndpoint(int busId) => '/buses/$busId/fuel-stats';
  static String busTechnicalVisitsEndpoint(int busId) => '/buses/$busId/technical-visits';
  static String busInsuranceHistoryEndpoint(int busId) => '/buses/$busId/insurance-history';
  static String busPatentsEndpoint(int busId) => '/buses/$busId/patents';
  static String busBreakdownsEndpoint(int busId) => '/buses/$busId/breakdowns';
  static String busVidangesEndpoint(int busId) => '/buses/$busId/vidanges';
  static String busVidangeCompleteEndpoint(int busId, int vidangeId) => '/buses/$busId/vidanges/$vidangeId/complete';
}

// Extension pour faciliter la construction des URLs complètes
extension ApiEndpoints on String {
  String get fullUrl => '${ApiConfig.baseUrl}$this';
}
