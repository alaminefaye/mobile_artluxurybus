import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Test de connexion avec le nouveau domaine...');
  
  const baseUrl = 'https://gestion-compagny.universaltechnologiesafrica.com/api';
  
  // Test 1: Ping
  await testEndpoint('$baseUrl/ping', 'Test Ping');
  
  // Test 2: Messages actifs
  await testEndpoint('$baseUrl/messages/active?appareil=mobile&current=true', 'Messages actifs');
  
  // Test 3: User endpoint (nécessite auth)
  await testEndpoint('$baseUrl/user', 'User profile (auth requis)');
  
  print('\n✅ Tests terminés !');
}

Future<void> testEndpoint(String url, String name) async {
  try {
    print('\n📡 Test: $name');
    print('URL: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ).timeout(Duration(seconds: 10));
    
    print('Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(response.body);
        print('✅ Réponse JSON reçue: ${jsonData.toString().substring(0, 100)}...');
      } catch (e) {
        print('✅ Réponse reçue (non-JSON): ${response.body.substring(0, 100)}...');
      }
    } else if (response.statusCode == 401) {
      print('🔐 Authentification requise (normal pour certains endpoints)');
    } else {
      print('⚠️  Status Code: ${response.statusCode}');
      print('Body: ${response.body.substring(0, 200)}...');
    }
    
  } catch (e) {
    if (e is SocketException) {
      print('❌ Erreur de connexion: ${e.message}');
    } else {
      print('❌ Erreur: $e');
    }
  }
}