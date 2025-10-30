import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/horaire_model.dart';

class HoraireService {
  // URL de base de votre API
  static const String baseUrl = 'https://skf-artluxurybus.com/api';
  
  // Timeout pour les requêtes
  static const Duration timeoutDuration = Duration(seconds: 10);
  
  // Token d'authentification
  static String? _token;
  
  // Méthode pour définir le token
  static void setToken(String? token) {
    _token = token;
    debugPrint('🔑 HoraireService - Token défini: ${token != null ? "✅" : "❌"}');
  }
  
  // Headers pour les requêtes authentifiées
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
  
  // Headers pour les requêtes publiques
  Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

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
      debugPrint('Erreur fetchAllHoraires: $e');
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
      debugPrint('Erreur fetchHorairesByGare: $e');
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
      debugPrint('Erreur fetchHorairesByAppareil: $e');
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
        headers: _publicHeaders, // Endpoint public
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Gérer les deux formats de réponse
        if (jsonData is List) {
          // Nouveau format : liste directe
          Map<String, List<Horaire>> groupedHoraires = {};
          final List<dynamic> horairesJson = jsonData;
          
          // Grouper par gare ou créer une gare par défaut
          groupedHoraires['Horaires'] = horairesJson.map((horaireJson) {
            return Horaire.fromJson(horaireJson);
          }).toList();
          
          return groupedHoraires;
        } else if (jsonData['success'] == true) {
          // Ancien format : structure avec success et data
          final dynamic data = jsonData['data'];
          Map<String, List<Horaire>> groupedHoraires = {};

          if (data is Map<String, dynamic>) {
            // Format ancien serveur
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
          } else if (data is List) {
            // Format liste dans data
            groupedHoraires['Horaires'] = data.map((horaireJson) {
              return Horaire.fromJson(horaireJson);
            }).toList();
          }

          return groupedHoraires;
        }
      }
      throw Exception('Échec du chargement des horaires');
    } catch (e) {
      debugPrint('Erreur fetchTodayHoraires: $e');
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
      debugPrint('Erreur fetchHoraireById: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Créer un nouvel horaire
  Future<Horaire> createHoraire({
    required int gareId,
    required int trajetId,
    int? busId,
    required String heure,
    String? date,
    String? statut,
    bool actif = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/horaires'),
        headers: _authHeaders, // Nécessite authentification
        body: json.encode({
          'gare_id': gareId,
          'trajet_id': trajetId,
          'bus_id': busId,
          'heure': heure,
          'date': date,
          'statut': statut,
          'actif': actif ? 1 : 0,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return Horaire.fromJson(jsonData['data']);
        }
      }
      throw Exception('Échec de la création de l\'horaire');
    } catch (e) {
      debugPrint('Erreur createHoraire: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Modifier un horaire existant
  Future<Horaire> updateHoraire({
    required int id,
    int? gareId,
    int? trajetId,
    int? busId,
    String? heure,
    String? date,
    String? statut,
    bool? actif,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (gareId != null) body['gare_id'] = gareId;
      if (trajetId != null) body['trajet_id'] = trajetId;
      if (busId != null) body['bus_id'] = busId;
      if (heure != null) body['heure'] = heure;
      if (date != null) body['date'] = date;
      if (statut != null) body['statut'] = statut;
      if (actif != null) body['actif'] = actif ? 1 : 0;

      final response = await http.put(
        Uri.parse('$baseUrl/horaires/$id'),
        headers: _authHeaders, // Nécessite authentification
        body: json.encode(body),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return Horaire.fromJson(jsonData['data']);
        }
      }
      throw Exception('Échec de la modification de l\'horaire');
    } catch (e) {
      debugPrint('Erreur updateHoraire: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Supprimer un horaire
  Future<bool> deleteHoraire(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/horaires/$id'),
        headers: _authHeaders, // Nécessite authentification
      ).timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      throw Exception('Échec de la suppression de l\'horaire');
    } catch (e) {
      debugPrint('Erreur deleteHoraire: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer toutes les gares
  Future<List<Gare>> fetchGares() async {
    try {
      debugPrint('🔑 Token présent: ${_token != null}');
      debugPrint('📍 Requête vers: $baseUrl/gares');
      
      final response = await http.get(
        Uri.parse('$baseUrl/gares'),
        headers: _authHeaders, // Nécessite authentification
      ).timeout(timeoutDuration);

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          debugPrint('✅ ${data.length} gares récupérées');
          return data.map((json) => Gare.fromJson(json)).toList();
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié - Token manquant ou invalide');
      }
      throw Exception('Échec du chargement des gares (Status: ${response.statusCode})');
    } catch (e) {
      debugPrint('❌ Erreur fetchGares: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer tous les trajets
  Future<List<Trajet>> fetchTrajets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trajets'),
        headers: _authHeaders, // Nécessite authentification
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          return data.map((json) => Trajet.fromJson(json)).toList();
        }
      }
      throw Exception('Échec du chargement des trajets');
    } catch (e) {
      debugPrint('Erreur fetchTrajets: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer tous les bus
  Future<List<Bus>> fetchBuses() async {
    try {
      debugPrint('🚌 Requête vers: $baseUrl/buses?simple=true');
      
      final response = await http.get(
        Uri.parse('$baseUrl/buses?simple=true'),
        headers: _authHeaders, // Nécessite authentification
      ).timeout(timeoutDuration);

      debugPrint('📡 Bus Response status: ${response.statusCode}');
      debugPrint('📡 Bus Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data'];
          debugPrint('✅ ${data.length} bus récupérés');
          return data.map((json) => Bus.fromJson(json)).toList();
        }
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié - Token manquant ou invalide');
      }
      throw Exception('Échec du chargement des bus (Status: ${response.statusCode})');
    } catch (e) {
      debugPrint('❌ Erreur fetchBuses: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }
}
