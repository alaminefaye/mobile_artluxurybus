import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/slide_model.dart';
import '../utils/api_config.dart';

class SlideService {
  static String? _token;

  /// Définir le token d'authentification
  static void setToken(String token) {
    _token = token;
    debugPrint('🔑 [SlideService] Token défini');
  }

  /// Supprimer le token
  static void clearToken() {
    _token = null;
    debugPrint('🔑 [SlideService] Token supprimé');
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

  /// Récupérer toutes les slides actives (Public)
  Future<List<Slide>> getActiveSlides() async {
    try {
      debugPrint('🖼️ [SlideService] Récupération des slides actives');
      
      final url = Uri.parse('${ApiConfig.baseUrl}/slides');
      final response = await http.get(url, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> slidesData = data['data'] as List;
          final slides = slidesData.map((json) => Slide.fromJson(json)).toList();
          
          debugPrint('✅ [SlideService] ${slides.length} slides récupérées');
          return slides;
        }
      }
      throw Exception('Erreur lors de la récupération des slides');
    } on SocketException {
      debugPrint('❌ [SlideService] Erreur de connexion');
      rethrow;
    } catch (e) {
      debugPrint('❌ [SlideService] Erreur: $e');
      // Retourner une liste vide en cas d'erreur pour ne pas bloquer l'application
      return [];
    }
  }

  /// Récupérer une slide spécifique par son ID
  Future<Slide> getSlideById(int id) async {
    try {
      debugPrint('🖼️ [SlideService] Récupération de la slide $id');
      
      final url = Uri.parse('${ApiConfig.baseUrl}/slides/$id');
      final response = await http.get(url, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Slide.fromJson(data['data']);
        }
      }
      throw Exception('Slide non trouvée');
    } catch (e) {
      debugPrint('❌ [SlideService] Erreur: $e');
      rethrow;
    }
  }
}

