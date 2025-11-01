import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import 'auth_service.dart';
import 'device_info_service.dart';

class MessageApiService {
  static const String baseUrl = 'https://skf-artluxurybus.com/api';
  final AuthService _authService = AuthService();

  /// Récupérer tous les messages actifs pour l'application mobile
  /// Fonctionne SANS authentification - utilise juste le device_id
  Future<List<MessageModel>> getActiveMessages({int? gareId}) async {
    try {
      // ✅ Essayer d'obtenir le token, mais continuer même s'il n'y en a pas
      String? token = await _authService.getToken();
      
      // Si pas de token, on continue quand même avec device_id seulement
      if (token == null) {
        debugPrint('⚠️ [MessageAPI] Pas de token - Mode public (device_id uniquement)');
      } else {
        debugPrint('✅ [MessageAPI] Token disponible - Mode authentifié');
      }

      List<MessageModel> allMessages = [];

      // 1. Récupérer les messages génériques pour 'mobile'
      final mobileMessages = await _fetchMessagesForDevice('mobile', gareId, token);
      allMessages.addAll(mobileMessages);

      // 2. Récupérer les messages spécifiques à ce device ID
      try {
        final deviceInfoService = DeviceInfoService();
        final deviceId = await deviceInfoService.getDeviceId();
        debugPrint('📱 [MessageAPI] Device ID: $deviceId');
        
        if (deviceId.isNotEmpty && deviceId != 'mobile') {
          final deviceSpecificMessages = await _fetchMessagesForDevice(deviceId, gareId, token);
          allMessages.addAll(deviceSpecificMessages);
        }
      } catch (e) {
        debugPrint('⚠️ Erreur récupération device ID: $e');
      }

      // Supprimer les doublons basés sur l'ID
      final uniqueMessages = <int, MessageModel>{};
      for (final message in allMessages) {
        uniqueMessages[message.id] = message;
      }

      final finalMessages = uniqueMessages.values.toList();
      debugPrint('✅ ${finalMessages.length} messages uniques récupérés (${mobileMessages.length} génériques + ${allMessages.length - mobileMessages.length} spécifiques)');
      
      return finalMessages;
    } catch (e) {
      debugPrint('❌ Exception lors de la récupération des messages: $e');
      return [];
    }
  }

  /// Méthode privée pour récupérer les messages d'un appareil spécifique
  /// Fonctionne avec ou sans token d'authentification
  Future<List<MessageModel>> _fetchMessagesForDevice(String appareil, int? gareId, String? token) async {
    try {
      // Construire l'URL avec les filtres
      final queryParams = <String, String>{
        'appareil': appareil,
        'current': 'true', // Uniquement les messages actifs et non expirés
      };

      if (gareId != null) {
        queryParams['gare_id'] = gareId.toString();
      }

      final uri = Uri.parse('$baseUrl/messages/active')
          .replace(queryParameters: queryParams);

      debugPrint('🔍 Récupération des messages pour appareil "$appareil": $uri');

      // Construire les headers - avec ou sans token
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      
      // Ajouter le token seulement s'il existe
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('🔐 [MessageAPI] Requête avec authentification');
      } else {
        debugPrint('🔓 [MessageAPI] Requête SANS authentification (mode public)');
      }

      final response = await http.get(uri, headers: headers);

      debugPrint('📡 Status Code pour "$appareil": ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // L'API retourne soit {data: [...]} soit directement [...]
        final List<dynamic> messagesJson = jsonData is Map 
            ? (jsonData['data'] as List<dynamic>? ?? [])
            : (jsonData as List<dynamic>? ?? []);

        final messages = messagesJson
            .map((json) => MessageModel.fromJson(json))
            .toList();

        debugPrint('✅ ${messages.length} messages récupérés pour appareil "$appareil"');
        return messages;
      } else if (response.statusCode == 401 && token == null) {
        debugPrint('⚠️ [MessageAPI] API nécessite authentification pour appareil "$appareil"');
        return [];
      } else {
        debugPrint('❌ Erreur API pour "$appareil": ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Exception lors de la récupération des messages pour appareil "$appareil": $e');
      return [];
    }
  }

  /// Récupérer tous les messages (avec pagination et filtres)
  Future<Map<String, dynamic>> getMessages({
    String? type, // 'notification' ou 'annonce'
    bool? active,
    int? gareId,
    String? appareil,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'data': [], 'total': 0};
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (active != null) queryParams['active'] = active.toString();
      if (gareId != null) queryParams['gare_id'] = gareId.toString();
      if (appareil != null) queryParams['appareil'] = appareil;

      final uri = Uri.parse('$baseUrl/messages')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        final List<dynamic> messagesJson = jsonData['data'] ?? [];
        final messages = messagesJson
            .map((json) => MessageModel.fromJson(json))
            .toList();

        return {
          'data': messages,
          'total': jsonData['meta']?['total'] ?? messages.length,
          'current_page': jsonData['meta']?['current_page'] ?? page,
          'last_page': jsonData['meta']?['last_page'] ?? 1,
        };
      } else {
        debugPrint('❌ Erreur API getMessages: ${response.statusCode}');
        return {'data': [], 'total': 0};
      }
    } catch (e) {
      debugPrint('❌ Exception getMessages: $e');
      return {'data': [], 'total': 0};
    }
  }

  /// Récupérer un message spécifique par ID
  Future<MessageModel?> getMessage(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/messages/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final messageJson = jsonData['data'] ?? jsonData;
        return MessageModel.fromJson(messageJson);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Exception getMessage: $e');
      return null;
    }
  }

  /// Récupérer uniquement les notifications (pour tous les utilisateurs)
  Future<List<MessageModel>> getNotifications() async {
    try {
      final result = await getMessages(
        type: 'notification',
        active: true,
        appareil: 'mobile',
      );
      
      return result['data'] as List<MessageModel>;
    } catch (e) {
      debugPrint('❌ Exception getNotifications: $e');
      return [];
    }
  }

  /// Récupérer uniquement les annonces actives
  Future<List<MessageModel>> getAnnonces({int? gareId}) async {
    try {
      final result = await getMessages(
        type: 'annonce',
        active: true,
        appareil: 'mobile',
        gareId: gareId,
      );
      
      return result['data'] as List<MessageModel>;
    } catch (e) {
      debugPrint('❌ Exception getAnnonces: $e');
      return [];
    }
  }
}
