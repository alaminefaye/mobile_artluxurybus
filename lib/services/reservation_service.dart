import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class ReservationService {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  /// Récupérer le profil client de l'utilisateur connecté
  static Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/loyalty/my-profile');
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'client': data['client'],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'exists': false,
          'message': 'Profil client non trouvé',
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération du profil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Récupérer les sièges disponibles pour un départ
  static Future<Map<String, dynamic>> getAvailableSeats(
    int departId, {
    int? stopEmbarkId,
    int? stopDisembarkId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/departs/$departId/available-seats').replace(
        queryParameters: {
          if (stopEmbarkId != null) 'stop_embark_id': stopEmbarkId.toString(),
          if (stopDisembarkId != null) 'stop_disembark_id': stopDisembarkId.toString(),
        },
      );

      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération des sièges',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Rechercher ou créer un ClientProfile par téléphone
  static Future<Map<String, dynamic>> searchOrCreateClientProfile(String telephone) async {
    try {
      // D'abord, rechercher le client existant
      final searchUri = Uri.parse('${ApiConfig.baseUrl}/clients/search');
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final searchResponse = await http.post(
        searchUri,
        headers: headers,
        body: json.encode({'telephone': telephone}),
      ).timeout(ApiConfig.requestTimeout);

      if (searchResponse.statusCode == 200) {
        final data = json.decode(searchResponse.body);
        if (data['found'] == true) {
          return {
            'success': true,
            'client': data['client'],
            'exists': true,
          };
        }
      }

      // Si le client n'existe pas, créer un nouveau profil
      // Note: Pour l'instant, on retourne une erreur car la création nécessite plus d'infos
      // L'utilisateur devra créer le profil via l'écran approprié
      return {
        'success': false,
        'exists': false,
        'message': 'Client non trouvé. Veuillez vous inscrire d\'abord.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Créer une réservation temporaire
  static Future<Map<String, dynamic>> createReservation({
    required int departId,
    required int seatNumber,
    required int clientProfileId,
    int? stopEmbarkId,
    int? stopDisembarkId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/reservations');
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final body = json.encode({
        'depart_id': departId,
        'seat_number': seatNumber,
        'client_profile_id': clientProfileId,
        if (stopEmbarkId != null) 'stop_embark_id': stopEmbarkId,
        if (stopDisembarkId != null) 'stop_disembark_id': stopDisembarkId,
      });

      final response = await http.post(uri, headers: headers, body: body)
          .timeout(ApiConfig.requestTimeout);

      final data = json.decode(response.body);

      // Vérifier si c'est une erreur 429 (Rate Limiting)
      if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Too Many Attempts. Veuillez patienter quelques instants.',
          'status_code': 429,
          'details': data,
        };
      }

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
          'warning': data['warning'], // Message d'avertissement sur l'expiration
          'details': data['data'], // Contient expires_at, countdown_seconds, etc.
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la création de la réservation',
          'status_code': response.statusCode,
          'details': data['details'], // Détails supplémentaires (reason, expires_at, info, etc.)
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Confirmer une réservation et créer le ticket (mode test)
  static Future<Map<String, dynamic>> confirmReservation(int reservationId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/reservations/$reservationId/confirm');
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await http.post(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      final data = json.decode(response.body);

      // Vérifier si c'est une erreur 429 (Rate Limiting)
      if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Too Many Attempts. Veuillez patienter quelques instants.',
          'status_code': 429,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Ticket créé avec succès',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la confirmation de la réservation',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Initier un paiement Wave pour une réservation
  static Future<Map<String, dynamic>> initiateWavePayment(int reservationId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/reservations/$reservationId/payment/wave');
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await http.post(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      final data = json.decode(response.body);

      // Vérifier si c'est une erreur 429 (Rate Limiting)
      if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Too Many Attempts. Veuillez patienter quelques instants.',
          'status_code': 429,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Paiement Wave initié avec succès',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'initiation du paiement Wave',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Vérifier un code promotionnel
  static Future<Map<String, dynamic>> verifyPromoCode(String code) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/promo-codes/verify');
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({'code': code}),
      ).timeout(ApiConfig.requestTimeout);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Code valide',
          'code': data['code'],
          'customer_name': data['customer_name'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Code invalide',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }
}

