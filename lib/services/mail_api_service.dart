import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/mail_model.dart';
import 'package:http_parser/http_parser.dart';

class MailApiService {
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

  /// Récupérer le dashboard de l'agent courrier
  static Future<MailDashboard> getDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mails/dashboard'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MailDashboard.fromJson(data['data']);
      } else {
        throw Exception('Erreur lors du chargement du dashboard');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupérer la liste des courriers avec filtres
  static Future<Map<String, dynamic>> getMails({
    int page = 1,
    int perPage = 15,
    bool? isCollected,
    String? destination,
    String? mailNumber,
    String? senderPhone,
    String? recipientPhone,
    String? receivingAgency,
    String? packageType,
    String? dateFrom,
    String? dateTo,
    double? amountMin,
    double? amountMax,
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
        if (isCollected != null) 'is_collected': isCollected.toString(),
        if (destination != null) 'destination': destination,
        if (mailNumber != null) 'mail_number': mailNumber,
        if (senderPhone != null) 'sender_phone': senderPhone,
        if (recipientPhone != null) 'recipient_phone': recipientPhone,
        if (receivingAgency != null) 'receiving_agency': receivingAgency,
        if (packageType != null) 'package_type': packageType,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        if (amountMin != null) 'amount_min': amountMin.toString(),
        if (amountMax != null) 'amount_max': amountMax.toString(),
        if (search != null) 'search': search,
      };

      final uri = Uri.parse('$baseUrl/mails').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Erreur lors du chargement des courriers');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupérer les détails d'un courrier
  static Future<MailModel> getMailDetails(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mails/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MailModel.fromJson(data['data']);
      } else {
        throw Exception('Courrier non trouvé');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Créer un nouveau courrier
  static Future<MailModel> createMail({
    required String destination,
    required String senderName,
    required String senderPhone,
    required String recipientName,
    required String recipientPhone,
    required double amount,
    required String packageValue,
    required String packageType,
    required String receivingAgency,
    String? description,
    File? photo,
    bool isLoyaltyMail = false,
    String? loyaltyNotes,
    int? clientProfileId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/mails'),
      );

      // Ajouter les headers
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.headers['Accept'] = 'application/json';

      // Ajouter les champs
      request.fields['destination'] = destination;
      request.fields['sender_name'] = senderName;
      request.fields['sender_phone'] = senderPhone;
      request.fields['recipient_name'] = recipientName;
      request.fields['recipient_phone'] = recipientPhone;
      request.fields['amount'] = amount.toString();
      request.fields['package_value'] = packageValue;
      request.fields['package_type'] = packageType;
      request.fields['receiving_agency'] = receivingAgency;
      if (description != null) request.fields['description'] = description;
      request.fields['is_loyalty_mail'] = isLoyaltyMail ? '1' : '0';
      if (loyaltyNotes != null) request.fields['loyalty_notes'] = loyaltyNotes;
      if (clientProfileId != null) request.fields['client_profile_id'] = clientProfileId.toString();

      // Ajouter la photo si présente
      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return MailModel.fromJson(data['data']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Mettre à jour un courrier
  static Future<MailModel> updateMail({
    required int id,
    String? destination,
    String? senderName,
    String? senderPhone,
    String? recipientName,
    String? recipientPhone,
    double? amount,
    String? packageValue,
    String? packageType,
    String? receivingAgency,
    String? description,
    File? photo,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/mails/$id/update'),
      );

      // Ajouter les headers
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.headers['Accept'] = 'application/json';

      // Ajouter les champs modifiés
      if (destination != null) request.fields['destination'] = destination;
      if (senderName != null) request.fields['sender_name'] = senderName;
      if (senderPhone != null) request.fields['sender_phone'] = senderPhone;
      if (recipientName != null) request.fields['recipient_name'] = recipientName;
      if (recipientPhone != null) request.fields['recipient_phone'] = recipientPhone;
      if (amount != null) request.fields['amount'] = amount.toString();
      if (packageValue != null) request.fields['package_value'] = packageValue;
      if (packageType != null) request.fields['package_type'] = packageType;
      if (receivingAgency != null) request.fields['receiving_agency'] = receivingAgency;
      if (description != null) request.fields['description'] = description;

      // Ajouter la nouvelle photo si présente
      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MailModel.fromJson(data['data']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Supprimer un courrier
  static Future<void> deleteMail(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/mails/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Marquer un courrier comme collecté
  static Future<MailModel> markAsCollected(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mails/$id/collect'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MailModel.fromJson(data['data']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors du marquage');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Annuler la collection d'un courrier
  static Future<MailModel> markAsUncollected(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mails/$id/uncollect'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MailModel.fromJson(data['data']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Vérifier les points de fidélité d'un client par téléphone
  static Future<Map<String, dynamic>> checkLoyaltyPoints(String telephone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mails/check-loyalty-points'),
        headers: _getHeaders(),
        body: json.encode({'telephone': telephone}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Erreur lors de la vérification des points');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Rechercher par téléphone
  static Future<List<MailModel>> searchByPhone(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mails/search-by-phone'),
        headers: _getHeaders(),
        body: json.encode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List mailsData = data['data']['data'] ?? [];
        return mailsData.map((e) => MailModel.fromJson(e)).toList();
      } else {
        throw Exception('Erreur lors de la recherche');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupérer les statistiques
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mails/stats'),
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

  /// Destinations disponibles
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

  /// Types de colis disponibles
  static List<String> getPackageTypes() {
    return [
      'pli/enveloppe',
      'carton',
      'paquet',
      'sac',
      'sachet',
      'colis',
      'déménagement',
      'déménagement complet',
      'bazard',
      'salon complet',
    ];
  }
}
