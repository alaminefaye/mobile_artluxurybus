import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/client_registration_models.dart';
import '../utils/api_config.dart';

class ClientRegistrationService {
  // Headers par défaut
  Map<String, String> get _headers => ApiConfig.defaultHeaders;

  /// Rechercher un client par numéro de téléphone
  Future<ClientSearchResponse> searchClient(String telephone) async {
    try {
      final url = '${ApiConfig.baseUrl}/clients/search';
      final body = json.encode({'telephone': telephone});
      
      debugPrint('🔍 [ClientRegistrationService] Recherche client avec numéro: $telephone');
      debugPrint('🔍 [ClientRegistrationService] URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body,
      );

      debugPrint('🔍 [ClientRegistrationService] Status: ${response.statusCode}');
      debugPrint('🔍 [ClientRegistrationService] Body: ${response.body}');

      final data = json.decode(response.body);
      final result = ClientSearchResponse.fromJson(data);
      
      if (result.success && result.found) {
        debugPrint('✅ [ClientRegistrationService] Client trouvé: ${result.client?.nomComplet}');
      } else {
        debugPrint('❌ [ClientRegistrationService] Client non trouvé: ${result.message}');
      }
      
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ [ClientRegistrationService] Erreur: $e');
      debugPrint('❌ [ClientRegistrationService] StackTrace: $stackTrace');
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

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/clients/create-account'),
        headers: _headers,
        body: json.encode(request.toJson()),
      );


      final data = json.decode(response.body);
      return ClientRegistrationResponse.fromJson(data);
    } catch (e) {
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

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/clients/register'),
        headers: _headers,
        body: json.encode(request.toJson()),
      );


      final data = json.decode(response.body);
      return ClientRegistrationResponse.fromJson(data);
    } catch (e) {
      return ClientRegistrationResponse(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }
}
