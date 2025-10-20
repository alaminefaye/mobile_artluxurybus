import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feedback_model.dart';
import '../services/feedback_api_service.dart';
import '../utils/logger.dart';

// État pour les statistiques des feedbacks
final feedbackStatsProvider = FutureProvider<FeedbackStats?>((ref) async {
  try {
    final result = await FeedbackApiService.getFeedbackStats();
    if (result['success'] == true) {
      return FeedbackStats.fromJson(result);
    }
    return null;
  } catch (e) {
    // Retourner null si pas admin ou erreur
    return null;
  }
});

// État pour la liste des feedbacks (admin seulement)
final feedbackListProvider = FutureProvider.family<List<FeedbackModel>, Map<String, dynamic>>((ref, params) async {
  try {
    final result = await FeedbackApiService.getFeedbacks(
      page: params['page'] ?? 1,
      perPage: params['per_page'] ?? 15,
      status: params['status'],
      search: params['search'],
    );
    
    if (result['success'] == true && result['data'] != null) {
      final List<dynamic> feedbacksList = result['data'];
      return feedbacksList.map((json) => FeedbackModel.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    throw Exception('Erreur lors du chargement des feedbacks: $e');
  }
});

// Provider pour créer un feedback
class FeedbackNotifier extends StateNotifier<AsyncValue<String?>> {
  FeedbackNotifier() : super(const AsyncValue.data(null));

  Future<void> submitFeedback({
    required String name,
    required String phone,
    required String subject,
    required String message,
    String? email,
    String? station,
    String? route,
    String? seatNumber,
    String? departureNumber,
    String? photoBase64,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final result = await FeedbackApiService.createFeedback(
        name: name,
        phone: phone,
        subject: subject,
        message: message,
        email: email,
        station: station,
        route: route,
        seatNumber: seatNumber,
        departureNumber: departureNumber,
        photoBase64: photoBase64,
      );

      if (result['success'] == true) {
        state = AsyncValue.data(result['message'] ?? 'Suggestion envoyée avec succès');
      } else {
        state = AsyncValue.error(
          result['message'] ?? 'Erreur lors de l\'envoi',
          StackTrace.current,
        );
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final feedbackSubmissionProvider = StateNotifierProvider<FeedbackNotifier, AsyncValue<String?>>((ref) {
  return FeedbackNotifier();
});

// Provider pour les notifications FCM
class NotificationTokenNotifier extends StateNotifier<String?> {
  NotificationTokenNotifier() : super(null);

  Future<void> registerToken(String token, {String? deviceType, String? deviceId}) async {
    try {
      await FeedbackApiService.registerFcmToken(
        token,
        deviceType: deviceType,
        deviceId: deviceId,
      );
      state = token;
    } catch (e) {
      // Log error mais ne pas faire échouer l'app
      AppLogger.error('Erreur enregistrement FCM token', error: e);
    }
  }
}

final notificationTokenProvider = StateNotifierProvider<NotificationTokenNotifier, String?>((ref) {
  return NotificationTokenNotifier();
});
