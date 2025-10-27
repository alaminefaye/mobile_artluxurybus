import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/bus_models.dart';
import '../utils/api_config.dart';
import '../utils/api_response_validator.dart';
import 'auth_service.dart';

class BusApiService {
  final AuthService _authService = AuthService();
  
  void _log(String message) => debugPrint('[BusApiService] $message');
  
  // Récupérer le token depuis le stockage sécurisé
  Future<String?> _getAuthToken() async {
    return await _authService.getToken();
  }
  
  // Construire les headers avec authentification
  Future<Map<String, String>> _getHeaders() async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    final token = await _getAuthToken();
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // Construire les headers pour multipart (sans Content-Type)
  Future<Map<String, String>> _getMultipartHeaders() async {
    final token = await _getAuthToken();
    final headers = <String, String>{};
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // Envoyer une requête multipart avec fichier
  Future<http.StreamedResponse> _sendMultipartRequest({
    required String method,
    required String url,
    required Map<String, dynamic> data,
    File? file,
    String? fileFieldName,
  }) async {
    final request = http.MultipartRequest(method, Uri.parse(url));
    
    // Ajouter les headers
    final headers = await _getMultipartHeaders();
    request.headers.addAll(headers);
    
    // Ajouter les champs
    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });
    
    // Ajouter le fichier si présent
    if (file != null && fileFieldName != null) {
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, file.path),
      );
    }
    
    return await request.send().timeout(ApiConfig.requestTimeout);
  }
  
  // ===== Dashboard =====
  
  /// Récupère le tableau de bord des bus avec statistiques
  Future<BusDashboard> getDashboard() async {
    try {
      _log('🚌 Récupération du dashboard des bus...');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/buses/dashboard'),
        headers: headers,
      ).timeout(
        ApiConfig.requestTimeout,
        onTimeout: () => throw Exception('Timeout: Le serveur ne répond pas. Vérifiez votre connexion.'),
      );
      
      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Valider la structure de la réponse en mode debug
        if (kDebugMode) {
          _log('Structure de la réponse:');
          ApiResponseValidator.logJsonStructure(data);
          
          if (!ApiResponseValidator.validateDashboardResponse(data)) {
            _log('⚠️ Avertissement: Structure de réponse invalide');
          }
        }
        
        _log('✅ Dashboard récupéré avec succès');
        return BusDashboard.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Non autorisé: Veuillez vous reconnecter.');
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé: Vous n\'avez pas les permissions nécessaires.');
      } else if (response.statusCode == 404) {
        throw Exception('Ressource non trouvée.');
      } else if (response.statusCode >= 500) {
        throw Exception('Erreur serveur: Veuillez réessayer plus tard.');
      } else {
        final error = 'Erreur ${response.statusCode}: ${response.body}';
        _log('❌ $error');
        throw Exception(error);
      }
    } on FormatException catch (e) {
      _log('❌ Erreur de format JSON: $e');
      throw Exception('Erreur de format de données. Contactez le support.');
    } catch (e) {
      _log('❌ Erreur lors de la récupération du dashboard: $e');
      rethrow;
    }
  }
  
  // ===== Liste et détails des bus =====
  
  /// Récupère la liste des bus avec pagination et filtres
  Future<PaginatedResponse<Bus>> getBuses({
    int page = 1,
    int perPage = 15,
    String? status,
    String? search,
    String? sortField,
    String? sortOrder,
  }) async {
    try {
      _log('🚌 Récupération de la liste des bus (page: $page)...');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (sortField != null) queryParams['sort_field'] = sortField;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/buses').replace(
        queryParameters: queryParams,
      );
      
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);
      
      _log('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('✅ Liste des bus récupérée avec succès');
        return PaginatedResponse<Bus>.fromJson(
          data,
          (json) => Bus.fromJson(json as Map<String, dynamic>),
        );
      } else {
        final error = 'Erreur ${response.statusCode}: ${response.body}';
        _log('❌ $error');
        throw Exception(error);
      }
    } catch (e) {
      _log('❌ Erreur lors de la récupération des bus: $e');
      rethrow;
    }
  }
  
  /// Récupère les détails d'un bus spécifique avec toutes ses relations
  Future<Bus> getBusDetails(int busId) async {
    try {
      _log('🚌 Récupération des détails du bus #$busId...');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      
      _log('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('Response body: ${response.body}');
        
        // Debug: Vérifier les assurances
        if (data['insurance_records'] != null) {
          _log('📋 Nombre d\'assurances: ${(data['insurance_records'] as List).length}');
          for (var insurance in data['insurance_records']) {
            _log('🔍 Assurance: company=${insurance['insurance_company']}, policy=${insurance['policy_number']}, coverage=${insurance['coverage_type']}, premium=${insurance['premium']}');
          }
        }
        
        _log('✅ Détails du bus récupérés avec succès');
        return Bus.fromJson(data);
      } else {
        final error = 'Erreur ${response.statusCode}: ${response.body}';
        _log('❌ $error');
        throw Exception(error);
      }
    } catch (e) {
      _log('❌ Erreur lors de la récupération des détails: $e');
      rethrow;
    }
  }
  
  // ===== Maintenance =====
  
  /// Récupère l'historique de maintenance d'un bus
  Future<PaginatedResponse<MaintenanceRecord>> getMaintenances(
    int busId, {
    int page = 1,
  }) async {
    try {
      _log('🔧 Récupération des maintenances du bus #$busId...');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/buses/$busId/maintenances')
          .replace(queryParameters: {'page': page.toString()});
      
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('✅ Maintenances récupérées avec succès');
        return PaginatedResponse<MaintenanceRecord>.fromJson(
          data,
          (json) => MaintenanceRecord.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la récupération des maintenances: $e');
      rethrow;
    }
  }
  
  // ===== Carburant =====
  
  /// Récupère l'historique du carburant d'un bus
  Future<PaginatedResponse<FuelRecord>> getFuelHistory(
    int busId, {
    int page = 1,
    String? period,
    String? year,
  }) async {
    try {
      _log('⛽ Récupération de l\'historique carburant du bus #$busId (period: $period, year: $year)...');
      
      final queryParams = {'page': page.toString()};
      if (period != null) queryParams['period'] = period;
      if (year != null) queryParams['year'] = year;
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/buses/$busId/fuel-history')
          .replace(queryParameters: queryParams);
      
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('Response body: ${response.body}');
        _log('Data items count: ${data['data']?.length ?? 0}');
        _log('✅ Historique carburant récupéré avec succès');
        return PaginatedResponse<FuelRecord>.fromJson(
          data,
          (json) => FuelRecord.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la récupération de l\'historique: $e');
      rethrow;
    }
  }
  
  /// Récupère les statistiques de consommation de carburant
  Future<FuelStats> getFuelStats(
    int busId, {
    String? period,
    String? year,
  }) async {
    try {
      _log('📊 Récupération des stats carburant du bus #$busId (period: $period, year: $year)...');
      
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (year != null) queryParams['year'] = year;
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/buses/$busId/fuel-stats')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      
      final headers = await _getHeaders();
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('Response body: ${response.body}');
        _log('✅ Stats carburant récupérées avec succès');
        return FuelStats.fromJson(data);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la récupération des stats: $e');
      rethrow;
    }
  }
  
  // ===== Visites techniques =====
  
  /// Récupère l'historique des visites techniques d'un bus
  Future<PaginatedResponse<TechnicalVisit>> getTechnicalVisits(
    int busId, {
    int page = 1,
  }) async {
    try {
      _log('🔍 Récupération des visites techniques du bus #$busId...');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/buses/$busId/technical-visits')
          .replace(queryParameters: {'page': page.toString()});
      
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('✅ Visites techniques récupérées avec succès');
        return PaginatedResponse<TechnicalVisit>.fromJson(
          data,
          (json) => TechnicalVisit.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la récupération des visites: $e');
      rethrow;
    }
  }
  
  /// Ajouter une visite technique
  Future<void> addTechnicalVisit(int busId, Map<String, dynamic> data, {File? photo}) async {
    try {
      _log('➕ Ajout d\'une visite technique pour le bus #$busId...');
      
      if (photo != null) {
        // Utiliser multipart si photo présente
        final streamedResponse = await _sendMultipartRequest(
          method: 'POST',
          url: '${ApiConfig.baseUrl}/buses/$busId/technical-visits',
          data: data,
          file: photo,
          fileFieldName: 'document_photo',
        );
        
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 201) {
          _log('✅ Visite technique ajoutée avec succès (avec photo)');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      } else {
        // Utiliser JSON si pas de photo
        final headers = await _getHeaders();
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/technical-visits'),
          headers: headers,
          body: json.encode(data),
        ).timeout(ApiConfig.requestTimeout);
        
        if (response.statusCode == 201) {
          _log('✅ Visite technique ajoutée avec succès');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      _log('❌ Erreur lors de l\'ajout de la visite: $e');
      rethrow;
    }
  }
  
  /// Modifier une visite technique
  Future<void> updateTechnicalVisit(int busId, int visitId, Map<String, dynamic> data, {File? photo}) async {
    try {
      _log('✏️ Modification de la visite technique #$visitId...');
      
      if (photo != null) {
        // Utiliser multipart si photo présente
        final streamedResponse = await _sendMultipartRequest(
          method: 'POST', // Laravel n'accepte pas PUT avec multipart, on utilise POST avec _method
          url: '${ApiConfig.baseUrl}/buses/$busId/technical-visits/$visitId',
          data: {...data, '_method': 'PUT'},
          file: photo,
          fileFieldName: 'document_photo',
        );
        
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          _log('✅ Visite technique modifiée avec succès (avec photo)');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      } else {
        // Utiliser JSON si pas de photo
        final headers = await _getHeaders();
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/technical-visits/$visitId'),
          headers: headers,
          body: json.encode(data),
        ).timeout(ApiConfig.requestTimeout);
        
        if (response.statusCode == 200) {
          _log('✅ Visite technique modifiée avec succès');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      _log('❌ Erreur lors de la modification de la visite: $e');
      rethrow;
    }
  }
  
  /// Supprimer une visite technique
  Future<void> deleteTechnicalVisit(int busId, int visitId) async {
    try {
      _log('🗑️ Suppression de la visite technique #$visitId...');
      
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId/technical-visits/$visitId'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('✅ Visite technique supprimée avec succès');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la suppression de la visite: $e');
      rethrow;
    }
  }
  
  // ===== Assurances =====
  
  /// Récupère l'historique des assurances d'un bus
  Future<PaginatedResponse<InsuranceRecord>> getInsuranceHistory(
    int busId, {
    int page = 1,
  }) async {
    try {
      _log('🛡️ Récupération de l\'historique assurance du bus #$busId...');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/buses/$busId/insurance-history')
          .replace(queryParameters: {'page': page.toString()});
      
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('✅ Historique assurance récupéré avec succès');
        return PaginatedResponse<InsuranceRecord>.fromJson(
          data,
          (json) => InsuranceRecord.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la récupération de l\'assurance: $e');
      rethrow;
    }
  }
  
  /// Ajouter une assurance
  Future<void> addInsurance(int busId, Map<String, dynamic> data, {File? photo}) async {
    try {
      _log('➕ Ajout d\'une assurance pour le bus #$busId...');
      
      if (photo != null) {
        final streamedResponse = await _sendMultipartRequest(
          method: 'POST',
          url: '${ApiConfig.baseUrl}/buses/$busId/insurance-records',
          data: data,
          file: photo,
          fileFieldName: 'document_photo',
        );
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 201) {
          _log('✅ Assurance ajoutée avec succès (avec photo)');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      } else {
        final headers = await _getHeaders();
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/insurance-records'),
          headers: headers,
          body: json.encode(data),
        ).timeout(ApiConfig.requestTimeout);
        if (response.statusCode == 201) {
          _log('✅ Assurance ajoutée avec succès');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      _log('❌ Erreur lors de l\'ajout de l\'assurance: $e');
      rethrow;
    }
  }
  
  /// Modifier une assurance
  Future<void> updateInsurance(int busId, int insuranceId, Map<String, dynamic> data, {File? photo}) async{
    try {
      _log('✏️ Modification de l\'assurance #$insuranceId...');
      
      if (photo != null) {
        final streamedResponse = await _sendMultipartRequest(
          method: 'POST',
          url: '${ApiConfig.baseUrl}/buses/$busId/insurance-records/$insuranceId',
          data: {...data, '_method': 'PUT'},
          file: photo,
          fileFieldName: 'document_photo',
        );
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200) {
          _log('✅ Assurance modifiée avec succès (avec photo)');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      } else {
        final headers = await _getHeaders();
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/insurance-records/$insuranceId'),
          headers: headers,
          body: json.encode(data),
        ).timeout(ApiConfig.requestTimeout);
        if (response.statusCode == 200) {
          _log('✅ Assurance modifiée avec succès');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      _log('❌ Erreur lors de la modification de l\'assurance: $e');
      rethrow;
    }
  }
  
  /// Supprimer une assurance
  Future<void> deleteInsurance(int busId, int insuranceId) async {
    try {
      _log('🗑️ Suppression de l\'assurance #$insuranceId...');
      
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId/insurance-records/$insuranceId'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('✅ Assurance supprimée avec succès');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la suppression de l\'assurance: $e');
      rethrow;
    }
  }
  
  // ===== Patentes =====
  
  /// Récupère l'historique des patentes d'un bus
  Future<PaginatedResponse<Patent>> getPatents(
    int busId, {
    int page = 1,
  }) async {
    try {
      _log('📄 Récupération des patentes du bus #$busId...');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/buses/$busId/patents')
          .replace(queryParameters: {'page': page.toString()});
      
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('✅ Patentes récupérées avec succès');
        return PaginatedResponse<Patent>.fromJson(
          data,
          (json) => Patent.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la récupération des patentes: $e');
      rethrow;
    }
  }
  
  // ===== Pannes =====
  
  /// Récupère le carnet de pannes d'un bus
  Future<PaginatedResponse<BusBreakdown>> getBreakdowns(
    int busId, {
    int page = 1,
  }) async {
    try {
      _log('⚠️ Récupération des pannes du bus #$busId...');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/buses/$busId/breakdowns')
          .replace(queryParameters: {'page': page.toString()});
      
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('✅ Pannes récupérées avec succès');
        return PaginatedResponse<BusBreakdown>.fromJson(
          data,
          (json) => BusBreakdown.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la récupération des pannes: $e');
      rethrow;
    }
  }
  
  /// Ajoute une nouvelle panne pour un bus
  Future<void> addBreakdown(int busId, Map<String, dynamic> data, {File? photo}) async {
    try {
      _log('➕ Ajout d\'une panne pour le bus #$busId...');
      
      if (photo != null) {
        final streamedResponse = await _sendMultipartRequest(
          method: 'POST',
          url: '${ApiConfig.baseUrl}/buses/$busId/breakdowns',
          data: data,
          file: photo,
          fileFieldName: 'facture_photo',
        );
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 201) {
          _log('✅ Panne ajoutée avec succès (avec photo)');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      } else {
        final headers = await _getHeaders();
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/breakdowns'),
          headers: headers,
          body: json.encode(data),
        ).timeout(ApiConfig.requestTimeout);
        if (response.statusCode == 201) {
          _log('✅ Panne ajoutée avec succès');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      _log('❌ Erreur lors de l\'ajout de la panne: $e');
      rethrow;
    }
  }
  
  /// Modifier une panne
  Future<void> updateBreakdown(int busId, int breakdownId, Map<String, dynamic> data, {File? photo}) async {
    try {
      _log('✏️ Modification de la panne #$breakdownId...');
      
      if (photo != null) {
        final streamedResponse = await _sendMultipartRequest(
          method: 'POST',
          url: '${ApiConfig.baseUrl}/buses/$busId/breakdowns/$breakdownId',
          data: {...data, '_method': 'PUT'},
          file: photo,
          fileFieldName: 'facture_photo',
        );
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200) {
          _log('✅ Panne modifiée avec succès (avec photo)');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      } else {
        final headers = await _getHeaders();
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/breakdowns/$breakdownId'),
          headers: headers,
          body: json.encode(data),
        ).timeout(ApiConfig.requestTimeout);
        if (response.statusCode == 200) {
          _log('✅ Panne modifiée avec succès');
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      _log('❌ Erreur lors de la modification de la panne: $e');
      rethrow;
    }
  }
  
  /// Supprimer une panne
  Future<void> deleteBreakdown(int busId, int breakdownId) async {
    try {
      _log('🗑️ Suppression de la panne #$breakdownId...');
      
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId/breakdowns/$breakdownId'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('✅ Panne supprimée avec succès');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la suppression de la panne: $e');
      rethrow;
    }
  }
  
  // ===== Vidanges =====
  
  /// Récupère l'historique des vidanges d'un bus
  Future<PaginatedResponse<BusVidange>> getVidanges(
    int busId, {
    int page = 1,
  }) async {
    try {
      _log('🛢️ Récupération des vidanges du bus #$busId...');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/buses/$busId/vidanges')
          .replace(queryParameters: {'page': page.toString()});
      
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('✅ Vidanges récupérées avec succès');
        return PaginatedResponse<BusVidange>.fromJson(
          data,
          (json) => BusVidange.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la récupération des vidanges: $e');
      rethrow;
    }
  }
  
  /// Planifie une nouvelle vidange pour un bus
  Future<void> scheduleVidange(int busId, Map<String, dynamic> data) async {
    try {
      _log('📅 Planification d\'une vidange pour le bus #$busId...');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId/vidanges'),
        headers: headers,
        body: json.encode(data),
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 201) {
        _log('✅ Vidange planifiée avec succès');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la planification de la vidange: $e');
      rethrow;
    }
  }
  
  /// Marque une vidange comme effectuée
  Future<BusVidange> completeVidange({
    required int busId,
    required int vidangeId,
    required DateTime completionDate,
    String? notes,
  }) async {
    try {
      _log('✅ Marquage de la vidange #$vidangeId comme effectuée...');
      
      final body = {
        'completion_date': completionDate.toIso8601String().split('T')[0],
        if (notes != null) 'notes': notes,
      };
      
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId/vidanges/$vidangeId/complete'),
        headers: headers,
        body: json.encode(body),
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('✅ Vidange marquée comme effectuée');
        return BusVidange.fromJson(data);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors du marquage de la vidange: $e');
      rethrow;
    }
  }
  
  /// Modifier une vidange
  Future<void> updateVidange(int busId, int vidangeId, Map<String, dynamic> data) async {
    try {
      _log('✏️ Modification de la vidange #$vidangeId...');
      
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId/vidanges/$vidangeId'),
        headers: headers,
        body: json.encode(data),
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        _log('✅ Vidange modifiée avec succès');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la modification de la vidange: $e');
      rethrow;
    }
  }
  
  /// Supprimer une vidange
  Future<void> deleteVidange(int busId, int vidangeId) async {
    try {
      _log('🗑️ Suppression de la vidange #$vidangeId...');
      
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId/vidanges/$vidangeId'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('✅ Vidange supprimée avec succès');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la suppression de la vidange: $e');
      rethrow;
    }
  }
  
  // ===== CRUD Carburant =====
  
  /// Ajouter un enregistrement de carburant
  Future<FuelRecord> addFuelRecord({
    required int busId,
    required double cost,
    required DateTime fueledAt,
    String? notes,
    File? invoiceImage,
  }) async {
    try {
      _log('➡️ Ajout d\'un enregistrement de carburant...');
      
      final token = await _getAuthToken();
      
      // Si image, utiliser multipart
      if (invoiceImage != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/fuel-records'),
        );
        
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.headers['Accept'] = 'application/json';
        
        request.fields['cost'] = cost.toString();
        request.fields['fueled_at'] = fueledAt.toIso8601String().split('T')[0];
        if (notes != null) request.fields['notes'] = notes;
        
        request.files.add(await http.MultipartFile.fromPath(
          'invoice_photo',
          invoiceImage.path,
        ));
        
        final streamedResponse = await request.send().timeout(ApiConfig.requestTimeout);
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          _log('✅ Enregistrement ajouté avec succès');
          return FuelRecord.fromJson(data);
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      } else {
        // Sans image, utiliser JSON normal
        final body = {
          'cost': cost,
          'fueled_at': fueledAt.toIso8601String().split('T')[0],
          if (notes != null) 'notes': notes,
        };
        
        final headers = await _getHeaders();
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/fuel-records'),
          headers: headers,
          body: json.encode(body),
        ).timeout(ApiConfig.requestTimeout);
        
        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          _log('✅ Enregistrement ajouté avec succès');
          return FuelRecord.fromJson(data);
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      _log('❌ Erreur lors de l\'ajout: $e');
      rethrow;
    }
  }
  
  /// Modifier un enregistrement de carburant
  Future<FuelRecord> updateFuelRecord({
    required int busId,
    required int recordId,
    required double cost,
    required DateTime fueledAt,
    String? notes,
    File? invoiceImage,
  }) async {
    try {
      _log('✏️ Modification du carburant #$recordId...');
      
      final token = await _getAuthToken();
      
      // Si image, utiliser multipart avec _method=PUT
      if (invoiceImage != null) {
        var request = http.MultipartRequest(
          'POST', // Laravel utilise POST avec _method=PUT pour multipart
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/fuel-records/$recordId'),
        );
        
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.headers['Accept'] = 'application/json';
        
        request.fields['_method'] = 'PUT';
        request.fields['cost'] = cost.toString();
        request.fields['fueled_at'] = fueledAt.toIso8601String().split('T')[0];
        if (notes != null) request.fields['notes'] = notes;
        
        request.files.add(await http.MultipartFile.fromPath(
          'invoice_photo',
          invoiceImage.path,
        ));
        
        final streamedResponse = await request.send().timeout(ApiConfig.requestTimeout);
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _log('✅ Enregistrement modifié avec succès');
          return FuelRecord.fromJson(data);
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      } else {
        // Sans image, utiliser PUT normal
        final body = {
          'cost': cost,
          'fueled_at': fueledAt.toIso8601String().split('T')[0],
          if (notes != null) 'notes': notes,
        };
        
        final headers = await _getHeaders();
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/fuel-records/$recordId'),
          headers: headers,
          body: json.encode(body),
        ).timeout(ApiConfig.requestTimeout);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _log('✅ Enregistrement modifié avec succès');
          return FuelRecord.fromJson(data);
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      _log('❌ Erreur lors de la modification: $e');
      rethrow;
    }
  }
  
  /// Supprimer un enregistrement de carburant
  Future<void> deleteFuelRecord(int busId, int recordId) async {
    try {
      _log('🗑️ Suppression du carburant #$recordId...');
      
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId/fuel-records/$recordId'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('✅ Carburant supprimé avec succès');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  // ============================================================================
  // PATENTES - CRUD
  // ============================================================================

  /// Ajouter une patente
  Future<Patent> addPatent(int busId, Patent patent, {File? documentFile}) async {
    try {
      _log('➕ Ajout d\'une patente pour le bus #$busId...');
      
      final token = await _getAuthToken();
      
      // Si document, utiliser multipart
      if (documentFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/patents'),
        );
        
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.headers['Accept'] = 'application/json';
        
        request.fields['patent_number'] = patent.patentNumber;
        request.fields['issue_date'] = patent.issueDate.toIso8601String().split('T')[0];
        request.fields['expiry_date'] = patent.expiryDate.toIso8601String().split('T')[0];
        request.fields['cost'] = patent.cost.toString();
        if (patent.notes != null) request.fields['notes'] = patent.notes!;
        
        request.files.add(await http.MultipartFile.fromPath(
          'document',
          documentFile.path,
        ));
        
        final streamedResponse = await request.send().timeout(ApiConfig.requestTimeout);
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 201) {
          final responseData = json.decode(response.body);
          _log('✅ Patente ajoutée avec succès');
          final patentData = responseData['data'] ?? responseData['patent'] ?? responseData;
          return Patent.fromJson(patentData);
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      } else {
        // Sans document, utiliser JSON normal
        final headers = await _getHeaders();
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/patents'),
          headers: headers,
          body: json.encode(patent.toJson()),
        ).timeout(ApiConfig.requestTimeout);
        
        if (response.statusCode == 201) {
          final responseData = json.decode(response.body);
          _log('✅ Patente ajoutée avec succès');
          _log('📦 Response data: $responseData');
          
          final patentData = responseData['data'] ?? responseData['patent'] ?? responseData;
          _log('📋 Patent data: $patentData');
          
          return Patent.fromJson(patentData);
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      _log('❌ Erreur lors de l\'ajout de la patente: $e');
      rethrow;
    }
  }

  /// Mettre à jour une patente
  Future<Patent> updatePatent(int busId, int patentId, Patent patent, {File? documentFile}) async {
    try {
      _log('✏️ Modification de la patente #$patentId...');
      
      final token = await _getAuthToken();
      
      // Si document, utiliser multipart avec _method=PUT
      if (documentFile != null) {
        var request = http.MultipartRequest(
          'POST', // Laravel utilise POST avec _method=PUT pour multipart
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/patents/$patentId'),
        );
        
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.headers['Accept'] = 'application/json';
        
        request.fields['_method'] = 'PUT';
        request.fields['patent_number'] = patent.patentNumber;
        request.fields['issue_date'] = patent.issueDate.toIso8601String().split('T')[0];
        request.fields['expiry_date'] = patent.expiryDate.toIso8601String().split('T')[0];
        request.fields['cost'] = patent.cost.toString();
        if (patent.notes != null) request.fields['notes'] = patent.notes!;
        
        request.files.add(await http.MultipartFile.fromPath(
          'document',
          documentFile.path,
        ));
        
        final streamedResponse = await request.send().timeout(ApiConfig.requestTimeout);
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          _log('✅ Patente modifiée avec succès');
          final patentData = responseData['data'] ?? responseData['patent'] ?? responseData;
          return Patent.fromJson(patentData);
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      } else {
        // Sans document, utiliser PUT normal
        final headers = await _getHeaders();
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/buses/$busId/patents/$patentId'),
          headers: headers,
          body: json.encode(patent.toJson()),
        ).timeout(ApiConfig.requestTimeout);
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          _log('✅ Patente modifiée avec succès');
          
          final patentData = responseData['data'] ?? responseData['patent'] ?? responseData;
          
          return Patent.fromJson(patentData);
        } else {
          throw Exception('Erreur ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      _log('❌ Erreur lors de la modification de la patente: $e');
      rethrow;
    }
  }

  /// Supprimer une patente
  Future<void> deletePatent(int busId, int patentId) async {
    try {
      _log('🗑️ Suppression de la patente #$patentId...');
      
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId/patents/$patentId'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('✅ Patente supprimée avec succès');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _log('❌ Erreur lors de la suppression de la patente: $e');
      rethrow;
    }
  }
}
