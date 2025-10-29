import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/video_advertisement_model.dart';
import '../utils/api_config.dart';

class VideoAdvertisementService {
  static String? _token;

  /// Définir le token d'authentification
  static void setToken(String token) {
    _token = token;
    debugPrint('🔑 [VideoAdvertisementService] Token défini');
  }

  /// Supprimer le token
  static void clearToken() {
    _token = null;
    debugPrint('🔑 [VideoAdvertisementService] Token supprimé');
  }

  /// Headers communs pour les requêtes
  Map<String, String> _getHeaders({bool isMultipart = false}) {
    final headers = <String, String>{
      if (!isMultipart) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    return headers;
  }

  // ========== ROUTES PUBLIQUES ==========

  /// Récupérer toutes les vidéos actives (Public)
  Future<List<VideoAdvertisement>> getActiveVideos() async {
    try {
      debugPrint('📹 [VideoAdvertisementService] Récupération des vidéos actives');
      
      final url = Uri.parse('${ApiConfig.baseUrl}/video-advertisements');
      final response = await http.get(url, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> videosData = data['data'] as List;
          final videos = videosData.map((json) => VideoAdvertisement.fromJson(json)).toList();
          
          debugPrint('✅ [VideoAdvertisementService] ${videos.length} vidéos récupérées');
          return videos;
        }
      }
      throw Exception('Erreur lors de la récupération des vidéos');
    } catch (e) {
      debugPrint('❌ [VideoAdvertisementService] Erreur: $e');
      rethrow;
    }
  }

  /// Récupérer une vidéo spécifique par son ID
  Future<VideoAdvertisement> getVideoById(int id) async {
    try {
      debugPrint('📹 [VideoAdvertisementService] Récupération de la vidéo $id');
      
      final url = Uri.parse('${ApiConfig.baseUrl}/video-advertisements/$id');
      final response = await http.get(url, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return VideoAdvertisement.fromJson(data['data']);
        }
      }
      throw Exception('Vidéo non trouvée');
    } catch (e) {
      debugPrint('❌ [VideoAdvertisementService] Erreur: $e');
      rethrow;
    }
  }

  /// Enregistrer une vue pour une vidéo
  Future<void> recordView(int videoId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/video-advertisements/$videoId/view');
      await http.post(url, headers: _getHeaders());
      debugPrint('✅ [VideoAdvertisementService] Vue enregistrée pour vidéo $videoId');
    } catch (e) {
      debugPrint('⚠️ [VideoAdvertisementService] Erreur enregistrement vue: $e');
    }
  }

  /// Rechercher des vidéos
  Future<List<VideoAdvertisement>> searchVideos(String query) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/video-advertisements/search/query?q=$query');
      final response = await http.get(url, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> videosData = data['data'] as List;
          return videosData.map((json) => VideoAdvertisement.fromJson(json)).toList();
        }
      }
      throw Exception('Erreur lors de la recherche');
    } catch (e) {
      debugPrint('❌ [VideoAdvertisementService] Erreur recherche: $e');
      rethrow;
    }
  }

  // ========== ROUTES ADMIN (PROTÉGÉES) ==========

  /// Récupérer toutes les vidéos (actives et inactives) - Admin
  Future<List<VideoAdvertisement>> getAllVideos() async {
    try {
      debugPrint('📹 [VideoAdvertisementService] Récupération de toutes les vidéos (Admin)');
      
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/video-advertisements');
      final response = await http.get(url, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> videosData = data['data'] as List;
          final videos = videosData.map((json) => VideoAdvertisement.fromJson(json)).toList();
          
          debugPrint('✅ [VideoAdvertisementService] ${videos.length} vidéos récupérées (Admin)');
          return videos;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      }
      throw Exception('Erreur lors de la récupération des vidéos');
    } catch (e) {
      debugPrint('❌ [VideoAdvertisementService] Erreur: $e');
      rethrow;
    }
  }

  /// Créer une nouvelle publicité vidéo - Admin
  Future<VideoAdvertisement> createVideo({
    required String title,
    String? description,
    required File videoFile,
    int? displayOrder,
    bool isActive = true,
  }) async {
    try {
      debugPrint('📹 [VideoAdvertisementService] Création d\'une vidéo');
      
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/video-advertisements');
      
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(_getHeaders(isMultipart: true));
      
      request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (displayOrder != null) request.fields['display_order'] = displayOrder.toString();
      request.fields['is_active'] = isActive ? '1' : '0';
      
      request.files.add(await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ [VideoAdvertisementService] Vidéo créée avec succès');
          return VideoAdvertisement.fromJson(data['data']);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception('Erreur de validation: ${data['errors']}');
      }
      throw Exception('Erreur lors de la création');
    } catch (e) {
      debugPrint('❌ [VideoAdvertisementService] Erreur création: $e');
      rethrow;
    }
  }

  /// Mettre à jour une publicité vidéo - Admin
  Future<VideoAdvertisement> updateVideo({
    required int id,
    String? title,
    String? description,
    File? videoFile,
    int? displayOrder,
    bool? isActive,
  }) async {
    try {
      debugPrint('📹 [VideoAdvertisementService] Mise à jour de la vidéo $id');
      
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/video-advertisements/$id');
      
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(_getHeaders(isMultipart: true));
      
      if (title != null) request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (displayOrder != null) request.fields['display_order'] = displayOrder.toString();
      if (isActive != null) request.fields['is_active'] = isActive ? '1' : '0';
      
      if (videoFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ [VideoAdvertisementService] Vidéo mise à jour avec succès');
          return VideoAdvertisement.fromJson(data['data']);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else if (response.statusCode == 404) {
        throw Exception('Vidéo non trouvée');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception('Erreur de validation: ${data['errors']}');
      }
      throw Exception('Erreur lors de la mise à jour');
    } catch (e) {
      debugPrint('❌ [VideoAdvertisementService] Erreur mise à jour: $e');
      rethrow;
    }
  }

  /// Supprimer une publicité vidéo - Admin
  Future<bool> deleteVideo(int id) async {
    try {
      debugPrint('📹 [VideoAdvertisementService] Suppression de la vidéo $id');
      
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/video-advertisements/$id');
      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ [VideoAdvertisementService] Vidéo supprimée avec succès');
          return true;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else if (response.statusCode == 404) {
        throw Exception('Vidéo non trouvée');
      }
      return false;
    } catch (e) {
      debugPrint('❌ [VideoAdvertisementService] Erreur suppression: $e');
      return false;
    }
  }

  /// Activer/Désactiver une vidéo - Admin
  Future<bool> toggleVideoStatus(int id) async {
    try {
      debugPrint('📹 [VideoAdvertisementService] Toggle statut vidéo $id');
      
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/video-advertisements/$id/toggle-status');
      final response = await http.patch(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ [VideoAdvertisementService] Statut mis à jour');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('❌ [VideoAdvertisementService] Erreur toggle: $e');
      return false;
    }
  }

  /// Suppression multiple de vidéos - Admin
  Future<bool> deleteMultipleVideos(List<int> ids) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/video-advertisements/bulk-delete');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'ids': ids}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [VideoAdvertisementService] Erreur suppression multiple: $e');
      return false;
    }
  }
}
