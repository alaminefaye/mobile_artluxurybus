import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client_registration_models.dart';
import '../utils/api_config.dart';

class ClientRegistrationService {
  // Headers par défaut
  Map<String, String> get _headers => ApiConfig.defaultHeaders;

  /// Rechercher un client par numéro de téléphone
  Future<ClientSearchResponse> searchClient(String telephone) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/clients/search'),
        headers: _headers,
        body: json.encode({'telephone': telephone}),
      );


      final data = json.decode(response.body);
      return ClientSearchResponse.fromJson(data);
    } catch (e) {
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
