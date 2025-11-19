import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import '../models/horaire_model.dart';
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
        debugPrint(
            '⚠️ [MessageAPI] Pas de token - Mode public (device_id uniquement)');
      } else {
        debugPrint('✅ [MessageAPI] Token disponible - Mode authentifié');
      }

      List<MessageModel> allMessages = [];

      // 1. Récupérer les messages génériques pour 'mobile'
      final mobileMessages =
          await _fetchMessagesForDevice('mobile', gareId, token);
      allMessages.addAll(mobileMessages);

      // 2. Récupérer les messages spécifiques à ce device ID ET UUID
      try {
        final deviceInfoService = DeviceInfoService();
        final deviceId = await deviceInfoService.getDeviceId();
        final uuid = await deviceInfoService.getUuid();
        debugPrint('📱 [MessageAPI] Device ID: $deviceId');
        debugPrint('🔑 [MessageAPI] UUID: $uuid');

        // Récupérer les messages par device_id (avec UUID en paramètre pour logique OR backend)
        if (deviceId.isNotEmpty && deviceId != 'mobile') {
          final deviceSpecificMessages = await _fetchMessagesForDevice(
              deviceId, gareId, token,
              uuid: uuid);
          allMessages.addAll(deviceSpecificMessages);
        }

        // Récupérer aussi les messages par UUID uniquement (pour les cas où seul UUID est défini)
        if (uuid.isNotEmpty) {
          final uuidSpecificMessages =
              await _fetchMessagesForUuid(uuid, gareId, token);
          allMessages.addAll(uuidSpecificMessages);
        }
      } catch (e) {
        debugPrint('⚠️ Erreur récupération device ID/UUID: $e');
      }

      // Supprimer les doublons basés sur l'ID
      final uniqueMessages = <int, MessageModel>{};
      for (final message in allMessages) {
        uniqueMessages[message.id] = message;
      }

      final finalMessages = uniqueMessages.values.toList();
      debugPrint(
          '✅ ${finalMessages.length} messages uniques récupérés (${mobileMessages.length} génériques + ${allMessages.length - mobileMessages.length} spécifiques)');

      return finalMessages;
    } catch (e) {
      debugPrint('❌ Exception lors de la récupération des messages: $e');
      return [];
    }
  }

  /// Méthode privée pour récupérer les messages d'un appareil spécifique
  /// Fonctionne avec ou sans token d'authentification
  Future<List<MessageModel>> _fetchMessagesForDevice(
      String appareil, int? gareId, String? token,
      {String? uuid}) async {
    try {
      // Construire l'URL avec les filtres
      final queryParams = <String, String>{
        'appareil': appareil,
        'current': 'true', // Uniquement les messages actifs et non expirés
      };

      if (gareId != null) {
        queryParams['gare_id'] = gareId.toString();
      }

      // Ajouter UUID si fourni (le backend utilisera logique OR)
      if (uuid != null && uuid.isNotEmpty) {
        queryParams['uuid'] = uuid;
      }

      final uri = Uri.parse('$baseUrl/messages/active')
          .replace(queryParameters: queryParams);

      debugPrint(
          '🔍 Récupération des messages pour appareil "$appareil" (UUID: ${uuid ?? "N/A"}): $uri');

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
        debugPrint(
            '🔓 [MessageAPI] Requête SANS authentification (mode public)');
      }

      final response = await http.get(uri, headers: headers);

      debugPrint('📡 Status Code pour "$appareil": ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // L'API retourne soit {data: [...]} soit directement [...]
        final List<dynamic> messagesJson = jsonData is Map
            ? (jsonData['data'] as List<dynamic>? ?? [])
            : (jsonData as List<dynamic>? ?? []);

        final messages =
            messagesJson.map((json) => MessageModel.fromJson(json)).toList();

        debugPrint(
            '✅ ${messages.length} messages récupérés pour appareil "$appareil"');
        return messages;
      } else if (response.statusCode == 401 && token == null) {
        debugPrint(
            '⚠️ [MessageAPI] API nécessite authentification pour appareil "$appareil"');
        return [];
      } else {
        debugPrint(
            '❌ Erreur API pour "$appareil": ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint(
          '❌ Exception lors de la récupération des messages pour appareil "$appareil": $e');
      return [];
    }
  }

  /// Méthode privée pour récupérer les messages par UUID uniquement
  /// Fonctionne avec ou sans token d'authentification
  Future<List<MessageModel>> _fetchMessagesForUuid(
      String uuid, int? gareId, String? token) async {
    try {
      // Construire l'URL avec les filtres
      final queryParams = <String, String>{
        'uuid': uuid,
        'current': 'true', // Uniquement les messages actifs et non expirés
      };

      if (gareId != null) {
        queryParams['gare_id'] = gareId.toString();
      }

      final uri = Uri.parse('$baseUrl/messages/active')
          .replace(queryParameters: queryParams);

      debugPrint('🔍 Récupération des messages pour UUID "$uuid": $uri');

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
        debugPrint(
            '🔓 [MessageAPI] Requête SANS authentification (mode public)');
      }

      final response = await http.get(uri, headers: headers);

      debugPrint('📡 Status Code pour UUID "$uuid": ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // L'API retourne soit {data: [...]} soit directement [...]
        final List<dynamic> messagesJson = jsonData is Map
            ? (jsonData['data'] as List<dynamic>? ?? [])
            : (jsonData as List<dynamic>? ?? []);

        final messages =
            messagesJson.map((json) => MessageModel.fromJson(json)).toList();

        debugPrint('✅ ${messages.length} messages récupérés pour UUID "$uuid"');
        return messages;
      } else if (response.statusCode == 401 && token == null) {
        debugPrint(
            '⚠️ [MessageAPI] API nécessite authentification pour UUID "$uuid"');
        return [];
      } else {
        debugPrint(
            '❌ Erreur API pour UUID "$uuid": ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint(
          '❌ Exception lors de la récupération des messages pour UUID "$uuid": $e');
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

      final uri =
          Uri.parse('$baseUrl/messages').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Le backend retourne soit {data: [...], meta: {...}} soit directement [...]
        List<dynamic> messagesJson = [];
        if (jsonData is Map<String, dynamic>) {
          messagesJson = jsonData['data'] ?? [];
        } else if (jsonData is List) {
          messagesJson = jsonData;
        }

        final messages = messagesJson
            .whereType<Map<String, dynamic>>()
            .map((json) => MessageModel.fromJson(json))
            .toList();

        return {
          'data': messages,
          'total': (jsonData is Map)
              ? (jsonData['meta']?['total'] ?? messages.length)
              : messages.length,
          'current_page': (jsonData is Map)
              ? (jsonData['meta']?['current_page'] ?? page)
              : page,
          'last_page':
              (jsonData is Map) ? (jsonData['meta']?['last_page'] ?? 1) : 1,
        };
      } else {
        debugPrint('❌ Erreur API getMessages: ${response.statusCode}');
        return {
          'data': <MessageModel>[],
          'total': 0,
          'current_page': page,
          'last_page': 1,
        };
      }
    } catch (e) {
      debugPrint('❌ Exception getMessages: $e');
      return {
        'data': <MessageModel>[],
        'total': 0,
        'current_page': 1,
        'last_page': 1,
      };
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

  /// Créer un nouveau message
  Future<Map<String, dynamic>> createMessage({
    required String titre,
    required String contenu,
    required String type, // 'notification' ou 'annonce'
    File? imageFile, // Fichier image à uploader
    int? gareId,
    String? appareil, // 'mobile', 'ecran_tv', 'ecran_led', 'tous'
    String? uuid,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool active = true,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentification requise',
        };
      }

      // Si une image est fournie, utiliser multipart/form-data
      if (imageFile != null && type == 'notification') {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/messages'),
        );

        // Headers
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        // Champs du formulaire
        request.fields['titre'] = titre;
        request.fields['contenu'] = contenu;
        request.fields['type'] = type;
        request.fields['active'] = active ? '1' : '0'; // Laravel attend '1' ou '0' pour les booléens en multipart

        if (gareId != null) {
          request.fields['gare_id'] = gareId.toString();
        }
        if (appareil != null && appareil.isNotEmpty) {
          request.fields['appareil'] = appareil;
        }
        if (uuid != null && uuid.isNotEmpty) {
          request.fields['uuid'] = uuid;
        }
        if (dateDebut != null) {
          request.fields['date_debut'] = dateDebut.toIso8601String();
        }
        if (dateFin != null) {
          request.fields['date_fin'] = dateFin.toIso8601String();
        }

        // Ajouter le fichier image
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201 || response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          final messageJson = jsonData['data'] ?? jsonData;
          return {
            'success': true,
            'message': jsonData['message'] ?? 'Message créé avec succès',
            'data': MessageModel.fromJson(messageJson),
          };
        } else {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message':
                errorData['message'] ?? 'Erreur lors de la création du message',
            'errors': errorData['errors'],
          };
        }
      } else {
        // Pas d'image, utiliser JSON classique
        final body = <String, dynamic>{
          'titre': titre,
          'contenu': contenu,
          'type': type,
          'active': active,
        };

        if (gareId != null) {
          body['gare_id'] = gareId;
        }
        if (appareil != null && appareil.isNotEmpty) {
          body['appareil'] = appareil;
        }
        if (uuid != null && uuid.isNotEmpty) {
          body['uuid'] = uuid;
        }
        if (dateDebut != null) {
          body['date_debut'] = dateDebut.toIso8601String();
        }
        if (dateFin != null) {
          body['date_fin'] = dateFin.toIso8601String();
        }

        final response = await http.post(
          Uri.parse('$baseUrl/messages'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          final messageJson = jsonData['data'] ?? jsonData;
          return {
            'success': true,
            'message': jsonData['message'] ?? 'Message créé avec succès',
            'data': MessageModel.fromJson(messageJson),
          };
        } else {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message':
                errorData['message'] ?? 'Erreur lors de la création du message',
            'errors': errorData['errors'],
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Exception createMessage: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la création du message: $e',
      };
    }
  }

  /// Mettre à jour un message existant
  Future<Map<String, dynamic>> updateMessage({
    required int id,
    String? titre,
    String? contenu,
    String? type,
    File? imageFile, // Fichier image à uploader
    bool shouldDeleteImage =
        false, // Indique si l'image existante doit être supprimée
    int? gareId,
    String? appareil,
    String? uuid,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? active,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentification requise',
        };
      }

      // Si une image est fournie et que c'est une notification, utiliser multipart/form-data
      if (imageFile != null && type == 'notification') {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/messages/$id'),
        );

        // Headers
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        // Utiliser _method pour Laravel (PUT via POST)
        request.fields['_method'] = 'PUT';

        // Champs du formulaire
        if (titre != null) request.fields['titre'] = titre;
        if (contenu != null) request.fields['contenu'] = contenu;
        if (type != null) request.fields['type'] = type;
        if (gareId != null) request.fields['gare_id'] = gareId.toString();
        if (appareil != null) request.fields['appareil'] = appareil;
        if (uuid != null) request.fields['uuid'] = uuid;
        if (dateDebut != null) {
          request.fields['date_debut'] = dateDebut.toIso8601String();
        }
        if (dateFin != null) {
          request.fields['date_fin'] = dateFin.toIso8601String();
        }
        if (active != null) request.fields['active'] = active ? '1' : '0'; // Laravel attend '1' ou '0' pour les booléens en multipart

        // Ajouter le fichier image
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          final messageJson = jsonData['data'] ?? jsonData;
          return {
            'success': true,
            'message': jsonData['message'] ?? 'Message mis à jour avec succès',
            'data': MessageModel.fromJson(messageJson),
          };
        } else {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ??
                'Erreur lors de la mise à jour du message',
            'errors': errorData['errors'],
          };
        }
      } else {
        // Pas d'image, utiliser JSON classique
        final body = <String, dynamic>{};

        if (titre != null) body['titre'] = titre;
        if (contenu != null) body['contenu'] = contenu;
        if (type != null) body['type'] = type;
        // Si on passe d'une notification à une annonce, envoyer image: null
        // Note: Si imageFile est null et qu'on met à jour une notification,
        // on n'envoie pas le champ image pour ne pas modifier l'image existante
        // Gérer la suppression d'image
        if (type == 'annonce' || shouldDeleteImage) {
          body['image'] = null;
        }
        if (gareId != null) body['gare_id'] = gareId;
        if (appareil != null) body['appareil'] = appareil;
        if (uuid != null) body['uuid'] = uuid;
        if (dateDebut != null) body['date_debut'] = dateDebut.toIso8601String();
        if (dateFin != null) body['date_fin'] = dateFin.toIso8601String();
        if (active != null) body['active'] = active;

        final response = await http.put(
          Uri.parse('$baseUrl/messages/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        );

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          final messageJson = jsonData['data'] ?? jsonData;
          return {
            'success': true,
            'message': jsonData['message'] ?? 'Message mis à jour avec succès',
            'data': MessageModel.fromJson(messageJson),
          };
        } else {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ??
                'Erreur lors de la mise à jour du message',
            'errors': errorData['errors'],
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Exception updateMessage: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la mise à jour du message: $e',
      };
    }
  }

  /// Récupérer toutes les gares
  Future<List<Gare>> getGares() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('⚠️ [MessageAPI] Pas de token pour récupérer les gares');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/gares'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'] ?? [];
          debugPrint('✅ [MessageAPI] ${data.length} gares récupérées');
          return data.map((json) => Gare.fromJson(json)).toList();
        }
      } else {
        debugPrint(
            '❌ [MessageAPI] Erreur récupération gares: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      debugPrint('❌ [MessageAPI] Exception getGares: $e');
      return [];
    }
  }

  /// Supprimer un message
  Future<Map<String, dynamic>> deleteMessage(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentification requise',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/messages/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final jsonData = response.body.isNotEmpty
            ? json.decode(response.body)
            : <String, dynamic>{};
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Message supprimé avec succès',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              'Erreur lors de la suppression du message',
        };
      }
    } catch (e) {
      debugPrint('❌ Exception deleteMessage: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la suppression du message: $e',
      };
    }
  }
}
