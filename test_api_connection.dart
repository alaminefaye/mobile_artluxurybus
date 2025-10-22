import 'dart:convert';
import 'package:http/http.dart' as http;

/// Script simple pour tester la connexion à l'API
/// Usage: dart run test_api_connection.dart YOUR_TOKEN
void main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Usage: dart run test_api_connection.dart YOUR_TOKEN');
    return;
  }

  final token = args[0];
  const baseUrl = 'https://gestion-compagny.universaltechnologiesafrica.com/api';

  print('🔍 Test de connexion à l\'API...\n');
  print('Base URL: $baseUrl');
  print('Token: ${token.substring(0, 10)}...\n');

  // Test 1: Ping
  await testEndpoint(
    'Ping',
    '$baseUrl/ping',
    token,
    authenticated: false,
  );

  // Test 2: User profile
  await testEndpoint(
    'User Profile',
    '$baseUrl/user',
    token,
  );

  // Test 3: Bus Dashboard
  await testEndpoint(
    'Bus Dashboard',
    '$baseUrl/buses/dashboard',
    token,
    validateStructure: (data) {
      if (data is! Map) return false;
      final map = data as Map<String, dynamic>;
      return map.containsKey('stats') && map.containsKey('recent_breakdowns');
    },
  );

  // Test 4: Bus List
  await testEndpoint(
    'Bus List',
    '$baseUrl/buses?per_page=5',
    token,
    validateStructure: (data) {
      if (data is! Map) return false;
      final map = data as Map<String, dynamic>;
      return map.containsKey('data') &&
          map.containsKey('current_page') &&
          map.containsKey('last_page');
    },
  );

  print('\n✅ Tests terminés!');
}

Future<void> testEndpoint(
  String name,
  String url,
  String token, {
  bool authenticated = true,
  bool Function(dynamic)? validateStructure,
}) async {
  print('📡 Test: $name');
  print('   URL: $url');

  try {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    print('   Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Afficher un aperçu des données
      if (data is Map) {
        print('   Clés: ${(data as Map<String, dynamic>).keys.join(', ')}');
      } else if (data is List) {
        print('   Type: Liste (${data.length} éléments)');
      }

      // Valider la structure si demandé
      if (validateStructure != null) {
        final isValid = validateStructure(data);
        if (isValid) {
          print('   ✅ Structure valide');
        } else {
          print('   ⚠️ Structure invalide');
          print('   Données reçues: ${json.encode(data).substring(0, 200)}...');
        }
      } else {
        print('   ✅ Succès');
      }
    } else {
      print('   ❌ Erreur HTTP');
      print('   Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
    }
  } catch (e) {
    print('   ❌ Exception: $e');
  }

  print('');
}
