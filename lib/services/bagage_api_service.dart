import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bagage_model.dart';

class BagageApiService {
  static const String baseUrl = 'https://skf-artluxurybus.com/api';
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  /// Récupérer le dashboard des bagages
  static Future<BagageDashboard> getDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bagages/dashboard'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return BagageDashboard.fromJson(data['data']);
        } else {
          throw Exception(
              data['message'] ?? 'Erreur lors du chargement du dashboard');
        }
      } else {
        final errorData =
            response.body.isNotEmpty ? json.decode(response.body) : null;
        final errorMessage =
            errorData?['message'] ?? 'Erreur HTTP ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur lors du chargement du dashboard: $e');
    }
  }

  /// Récupérer la liste des bagages avec filtres
  static Future<Map<String, dynamic>> getBagages({
    int page = 1,
    int perPage = 15,
    String? destination,
    bool? hasTicket,
    String? telephone,
    String? search,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
        if (destination != null) 'destination': destination,
        if (hasTicket != null) 'has_ticket': hasTicket.toString(),
        if (telephone != null) 'telephone': telephone,
        if (search != null) 'search': search,
      };

      final uri =
          Uri.parse('$baseUrl/bagages').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Erreur lors du chargement des bagages');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupérer les détails d'un bagage
  static Future<BagageModel> getBagageDetails(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bagages/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BagageModel.fromJson(data['data']);
      } else {
        throw Exception('Bagage non trouvé');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Créer un nouveau bagage
  static Future<BagageModel> createBagage({
    required String nom,
    required String prenom,
    required String telephone,
    required String destination,
    double? valeur,
    double? poids,
    double? montant,
    String? contenu,
    required bool hasTicket,
    String? ticketNumber,
  }) async {
    try {
      final body = {
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'destination': destination,
        'has_ticket': hasTicket,
        if (valeur != null) 'valeur': valeur.toString(),
        if (poids != null) 'poids': poids.toString(),
        if (montant != null) 'montant': montant.toString(),
        if (contenu != null) 'contenu': contenu,
        if (ticketNumber != null) 'ticket_number': ticketNumber,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/bagages'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return BagageModel.fromJson(data['data']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Mettre à jour un bagage
  static Future<BagageModel> updateBagage({
    required int id,
    String? nom,
    String? prenom,
    String? telephone,
    String? destination,
    double? valeur,
    double? poids,
    double? montant,
    String? contenu,
    bool? hasTicket,
    String? ticketNumber,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nom != null) body['nom'] = nom;
      if (prenom != null) body['prenom'] = prenom;
      if (telephone != null) body['telephone'] = telephone;
      if (destination != null) body['destination'] = destination;
      if (valeur != null) body['valeur'] = valeur.toString();
      if (poids != null) body['poids'] = poids.toString();
      if (montant != null) body['montant'] = montant.toString();
      if (contenu != null) body['contenu'] = contenu;
      if (hasTicket != null) body['has_ticket'] = hasTicket;
      if (ticketNumber != null) body['ticket_number'] = ticketNumber;

      final response = await http.put(
        Uri.parse('$baseUrl/bagages/$id'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BagageModel.fromJson(data['data']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Supprimer un bagage
  static Future<void> deleteBagage(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/bagages/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Rechercher par téléphone
  static Future<List<BagageModel>> searchByPhone(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bagages/search-by-phone'),
        headers: _getHeaders(),
        body: json.encode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List bagagesData = data['data']['data'] ?? [];
        return bagagesData.map((e) => BagageModel.fromJson(e)).toList();
      } else {
        throw Exception('Erreur lors de la recherche');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupérer les statistiques
  static Future<Map<String, dynamic>> getStatistics(
      {String period = 'week'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bagages/stats?period=$period'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Erreur lors du chargement des statistiques');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Destinations disponibles (même liste que pour les courriers)
  static List<String> getDestinations() {
    return [
      'Bouaké',
      'Yamoussoukro',
      'Abidjan Adjamé',
      'Abidjan Yopougon',
      'Daloa',
      'Bouafle Toumori',
      'Korhogo',
    ];
  }
}
