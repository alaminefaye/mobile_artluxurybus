import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/horaire_model.dart';

class HoraireService {
  // URL de base de votre API
  static const String baseUrl = 'https://gestion-compagny.universaltechnologiesafrica.com/api';
  
  // Timeout pour les requêtes
  static const Duration timeoutDuration = Duration(seconds: 10);

  /// Récupère tous les horaires actifs
  Future<List<Horaire>> fetchAllHoraires() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/horaires'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          return data.map((json) => Horaire.fromJson(json)).toList();
        }
      }
      throw Exception('Échec du chargement des horaires');
    } catch (e) {
      print('Erreur fetchAllHoraires: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les horaires d'une gare spécifique
  Future<List<Horaire>> fetchHorairesByGare(int gareId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/horaires/gare/$gareId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          return data.map((json) => Horaire.fromJson(json)).toList();
        }
      }
      throw Exception('Échec du chargement des horaires');
    } catch (e) {
      print('Erreur fetchHorairesByGare: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les horaires par identifiant d'appareil
  Future<List<Horaire>> fetchHorairesByAppareil(String appareil) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/horaires/appareil/$appareil'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          return data.map((json) => Horaire.fromJson(json)).toList();
        }
      }
      throw Exception('Échec du chargement des horaires');
    } catch (e) {
      print('Erreur fetchHorairesByAppareil: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les horaires du jour
  /// Si deviceId est fourni, filtre les horaires par appareil
  Future<Map<String, List<Horaire>>> fetchTodayHoraires({String? deviceId}) async {
    try {
      // Construire l'URL avec le paramètre device_id si fourni
      String url = '$baseUrl/horaires/today';
      if (deviceId != null && deviceId.isNotEmpty) {
        url += '?device_id=$deviceId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final Map<String, dynamic> data = jsonData['data'];
          Map<String, List<Horaire>> groupedHoraires = {};

          data.forEach((gareName, gareData) {
            if (gareData is Map && gareData['horaires'] is List) {
              final List<dynamic> horairesJson = gareData['horaires'];
              
              // Convertir chaque horaire en ajoutant les infos de la gare
              groupedHoraires[gareName] = horairesJson.map((horaireJson) {
                // Créer une structure complète avec la gare
                final completeHoraire = Map<String, dynamic>.from(horaireJson);
                completeHoraire['gare'] = {
                  'id': gareData['id'] ?? 0,
                  'nom': gareName,
                  'appareil': gareData['appareil'],
                };
                return Horaire.fromJson(completeHoraire);
              }).toList();
            }
          });

          return groupedHoraires;
        }
      }
      throw Exception('Échec du chargement des horaires');
    } catch (e) {
      print('Erreur fetchTodayHoraires: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère un horaire spécifique
  Future<Horaire> fetchHoraireById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/horaires/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return Horaire.fromJson(jsonData['data']);
        }
      }
      throw Exception('Échec du chargement de l\'horaire');
    } catch (e) {
      print('Erreur fetchHoraireById: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }
}
