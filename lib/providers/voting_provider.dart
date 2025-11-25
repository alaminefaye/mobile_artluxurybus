import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voting_session.dart';
import '../services/voting_api_service.dart';

/// Provider pour récupérer toutes les sessions de vote actives
final votingSessionsProvider = FutureProvider<List<VotingSession>>((ref) async {
  final response = await VotingApiService.getSessions();

  if (response['success'] == true && response['data'] != null) {
    final sessions = (response['data'] as List<dynamic>)
        .map((json) => VotingSession.fromJson(json as Map<String, dynamic>))
        .toList();
    return sessions;
  } else {
    throw Exception(
        response['message'] ?? 'Erreur lors du chargement des sessions');
  }
});

/// Provider pour récupérer une session de vote spécifique
final votingSessionProvider =
    FutureProvider.family<VotingSession, int>((ref, sessionId) async {
  final response = await VotingApiService.getSession(sessionId);

  if (response['success'] == true && response['data'] != null) {
    return VotingSession.fromJson(response['data'] as Map<String, dynamic>);
  } else {
    throw Exception(
        response['message'] ?? 'Erreur lors du chargement de la session');
  }
});

/// Provider pour les résultats d'une session de vote
final votingResultsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, sessionId) async {
  final response = await VotingApiService.getResults(sessionId);

  if (response['success'] == true) {
    return response['data'] as Map<String, dynamic>;
  } else {
    throw Exception(
        response['message'] ?? 'Erreur lors du chargement des résultats');
  }
});

/// Provider pour récupérer les sessions groupées (en cours, programmées, terminées)
final votingSessionsGroupedProvider =
    FutureProvider<Map<String, List<VotingSession>>>((ref) async {
  final response = await VotingApiService.getSessionsAll();

  if (response['success'] == true && response['data'] != null) {
    final data = response['data'] as Map<String, dynamic>;
    List<VotingSession> parseList(dynamic list) {
      return (list as List<dynamic>)
          .map((json) => VotingSession.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return {
      'active': data['active'] != null ? parseList(data['active']) : [],
      'scheduled':
          data['scheduled'] != null ? parseList(data['scheduled']) : [],
      'finished': data['finished'] != null ? parseList(data['finished']) : [],
    };
  } else {
    throw Exception(
        response['message'] ?? 'Erreur lors du chargement des sessions');
  }
});
