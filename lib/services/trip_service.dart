import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/trip_model.dart';
import '../services/auth_service.dart';

class TripService {
  static const String baseUrl = 'https://skf-artluxurybus.com/api';
  
  // Timeout pour les requêtes
  static const Duration timeoutDuration = Duration(seconds: 30);
  
  // Token d'authentification
  static String? _token;
  
  // Méthode pour définir le token
  static void setToken(String? token) {
    _token = token;
    debugPrint('🔑 TripService - Token défini: ${token != null ? "✅" : "❌"}');
  }
  
  // Headers pour les requêtes authentifiées
  static Future<Map<String, String>> get _authHeaders async {
    // Si le token n'est pas défini, essayer de le récupérer depuis AuthService
    if (_token == null) {
      final authService = AuthService();
      _token = await authService.getToken();
    }
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }
  
  /// Récupère tous les anciens voyages du client connecté
  static Future<TripsResponse> getMyTrips() async {
    try {
      final headers = await _authHeaders;
      
      final response = await http.get(
        Uri.parse('$baseUrl/trips/my-trips'),
        headers: headers,
      ).timeout(timeoutDuration);

      debugPrint('📡 TripService - GET /trips/my-trips');
      debugPrint('📡 Status: ${response.statusCode}');
      debugPrint('📡 Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          return TripsResponse.fromJson(jsonData);
        } else {
          throw Exception(jsonData['message'] ?? 'Erreur lors de la récupération des trajets');
        }
      } else if (response.statusCode == 401) {
        // Token expiré ou invalide
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ TripService - Erreur getMyTrips: $e');
      if (e is http.ClientException || e.toString().contains('SocketException')) {
        throw Exception('Problème de connexion. Vérifiez votre connexion internet.');
      }
      rethrow;
    }
  }

  /// Récupère les anciens voyages avec le numéro de téléphone (version publique)
  static Future<TripsResponse> getTripsByPhone(String telephone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trips/by-phone'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'telephone': telephone,
        }),
      ).timeout(timeoutDuration);

      debugPrint('📡 TripService - POST /trips/by-phone');
      debugPrint('📡 Status: ${response.statusCode}');
      debugPrint('📡 Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          return TripsResponse.fromJson(jsonData);
        } else {
          throw Exception(jsonData['message'] ?? 'Erreur lors de la récupération des trajets');
        }
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ TripService - Erreur getTripsByPhone: $e');
      if (e is http.ClientException || e.toString().contains('SocketException')) {
        throw Exception('Problème de connexion. Vérifiez votre connexion internet.');
      }
      rethrow;
    }
  }

  /// Récupère les détails d'un voyage spécifique
  static Future<Trip> getTripDetails(int ticketId) async {
    try {
      final headers = await _authHeaders;
      
      final response = await http.get(
        Uri.parse('$baseUrl/trips/$ticketId'),
        headers: headers,
      ).timeout(timeoutDuration);

      debugPrint('📡 TripService - GET /trips/$ticketId');
      debugPrint('📡 Status: ${response.statusCode}');
      debugPrint('📡 Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true && jsonData['trip'] != null) {
          return Trip.fromJson(jsonData['trip']);
        } else {
          throw Exception(jsonData['message'] ?? 'Ticket introuvable');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 403) {
        throw Exception('Ce ticket ne vous appartient pas');
      } else if (response.statusCode == 404) {
        throw Exception('Ticket introuvable');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ TripService - Erreur getTripDetails: $e');
      if (e is http.ClientException || e.toString().contains('SocketException')) {
        throw Exception('Problème de connexion. Vérifiez votre connexion internet.');
      }
      rethrow;
    }
  }
}




