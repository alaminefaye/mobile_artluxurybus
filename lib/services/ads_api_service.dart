import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ad_model.dart';

class AdsApiService {
  static const String baseUrl = 'https://gestion-compagny.universaltechnologiesafrica.com/api';
  static String? _token;

  static void setToken(String? token) { _token = token; }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Fetch active video ads from backend.
  static Future<List<AdModel>> fetchActiveAds() async {
    try {
      // Primary endpoint defined in backend
      final uri = Uri.parse('$baseUrl/video-advertisements');
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = AdModel.listFromJson(data);
        final videos = list
            .where((a) => (a.videoUrl != null && a.videoUrl!.isNotEmpty) && a.isActive)
            .toList();
        if (videos.isNotEmpty) return videos;
      }

      // Fallback to a single random video if list empty
      final randomUri = Uri.parse('$baseUrl/video-advertisements/random/video');
      final r = await http.get(randomUri, headers: _headers);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final item = (data['data'] as Map<String, dynamic>?);
        if (item != null) {
          final ad = AdModel.fromJson(item);
          if (ad.videoUrl != null && ad.videoUrl!.isNotEmpty) {
            return [ad];
          }
        }
      }
    } on SocketException {
      rethrow;
    } catch (_) {
      // swallow and return empty
    }
    return [];
  }
}