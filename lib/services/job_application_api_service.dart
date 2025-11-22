import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/api_config.dart';
import 'auth_service.dart';

class JobApplicationApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  // Récupérer le token dynamiquement depuis AuthService
  static Future<String?> _getAuthToken() async {
    final authService = AuthService();
    return await authService.getToken();
  }

  static Future<Map<String, String>> _getHeaders(
      {bool withAuth = false}) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (withAuth) {
      final token = await _getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // Informations sur le formulaire de demande d'emploi
  static Future<Map<String, dynamic>> getInfo() async {
    try {
      final uri = Uri.parse('$baseUrl/demande-emploi/info');
      final response = await http.get(uri, headers: await _getHeaders());
      final data = json.decode(response.body);

      if (response.statusCode == 200 && (data['success'] == true)) {
        return data['data'] ?? {};
      }
      throw Exception(data['message'] ?? 'Service indisponible');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Soumettre une demande d'emploi (multipart/form-data)
  static Future<Map<String, dynamic>> submit({
    required String fullName,
    required String phoneNumber,
    required File motivationLetterPdf,
    required File cvPdf,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/demande-emploi');
      var request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers['Accept'] = 'application/json';

      // Champs
      request.fields['full_name'] = fullName;
      request.fields['phone_number'] = phoneNumber;

      // Fichiers PDF (max 5MB côté serveur)
      request.files.add(await http.MultipartFile.fromPath(
        'motivation_letter',
        motivationLetterPdf.path,
        contentType: MediaType('application', 'pdf'),
      ));
      request.files.add(await http.MultipartFile.fromPath(
        'cv',
        cvPdf.path,
        contentType: MediaType('application', 'pdf'),
      ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = json.decode(response.body);

      if (response.statusCode == 201 && (data['success'] == true)) {
        return data['data'] ?? {};
      }
      throw Exception(
          data['message'] ?? 'Impossible d\'enregistrer la demande');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Lister les candidatures (Super Admin, Admin, RH)
  static Future<Map<String, dynamic>> list({
    int page = 1,
    String? status,
    String? search,
  }) async {
    try {
      final query = {
        'page': page.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri.parse('$baseUrl/job-applications')
          .replace(queryParameters: query);
      final response =
          await http.get(uri, headers: await _getHeaders(withAuth: true));
      final data = json.decode(response.body);

      if (response.statusCode == 200 && (data['success'] == true)) {
        return data;
      }
      throw Exception(data['message'] ?? 'Accès non autorisé');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Détails d'une candidature
  static Future<Map<String, dynamic>> details(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/job-applications/$id');
      final response =
          await http.get(uri, headers: await _getHeaders(withAuth: true));
      final data = json.decode(response.body);

      if (response.statusCode == 200 && (data['success'] == true)) {
        return data['data'] ?? {};
      }
      throw Exception(data['message'] ?? 'Candidature non trouvée');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Supprimer une candidature
  static Future<bool> delete(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/job-applications/$id');
      final response = await http.delete(
        uri,
        headers: await _getHeaders(withAuth: true),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && (data['success'] == true)) {
        return true;
      }
      throw Exception(data['message'] ?? 'Suppression impossible');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }
}
