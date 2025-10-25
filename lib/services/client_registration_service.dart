import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client_registration_models.dart';
import '../utils/api_config.dart';
import '../utils/debug_logger.dart';

class ClientRegistrationService {
  // Headers par défaut
  Map<String, String> get _headers => ApiConfig.defaultHeaders;

  /// Rechercher un client par numéro de téléphone
  Future<ClientSearchResponse> searchClient(String telephone) async {
    try {
      DebugLogger.log('🔍 Recherche client: $telephone');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/clients/search'),
        headers: _headers,
        body: json.encode({'telephone': telephone}),
      );

      DebugLogger.response(response.statusCode, response.body);

      final data = json.decode(response.body);
      return ClientSearchResponse.fromJson(data);
    } catch (e) {
      DebugLogger.error('Erreur recherche client', e);
      return ClientSearchResponse(
        success: false,
        found: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// Créer un compte pour un client existant
  Future<ClientRegistrationResponse> createAccountForExistingClient(
    CreateAccountRequest request,
  ) async {
    try {
      DebugLogger.log('👤 Création compte pour client ID: ${request.clientId}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/clients/create-account'),
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      DebugLogger.response(response.statusCode, response.body);

      final data = json.decode(response.body);
      return ClientRegistrationResponse.fromJson(data);
    } catch (e) {
      DebugLogger.error('Erreur création compte', e);
      return ClientRegistrationResponse(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// Inscription complète (nouveau client + nouveau compte)
  Future<ClientRegistrationResponse> registerNewClient(
    RegisterClientRequest request,
  ) async {
    try {
      DebugLogger.log('📝 Inscription nouveau client: ${request.telephone}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/clients/register'),
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      DebugLogger.response(response.statusCode, response.body);

      final data = json.decode(response.body);
      return ClientRegistrationResponse.fromJson(data);
    } catch (e) {
      DebugLogger.error('Erreur inscription', e);
      return ClientRegistrationResponse(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }
}
