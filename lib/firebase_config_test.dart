import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseConfigTest {
  static Future<void> testFirebaseConfig() async {
    try {
      // 1. Initialiser Firebase
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialisé avec succès');

      // 2. Obtenir l'instance FCM
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      debugPrint('✅ FirebaseMessaging instance créée');

      // 3. Demander les permissions
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 Permissions de notification:');
      debugPrint('  - Alert: ${settings.alert}');
      debugPrint('  - Badge: ${settings.badge}');
      debugPrint('  - Sound: ${settings.sound}');
      debugPrint('  - Authorization status: ${settings.authorizationStatus}');
      
      // Vérifier spécifiquement les permissions Android
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permissions accordées - Les notifications push devraient fonctionner');
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('❌ Permissions refusées - Les notifications ne fonctionneront pas');
        debugPrint('💡 Vérifiez les paramètres de notification dans les paramètres de l\'appareil');
      } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        debugPrint('⚠️ Permissions non déterminées - Demandez à l\'utilisateur d\'autoriser');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permissions accordées');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ Permissions provisoires');
      } else {
        debugPrint('❌ Permissions refusées');
      }

      // 4. Obtenir le token FCM
      String? token = await messaging.getToken();
      if (token != null) {
        debugPrint('🔑 Token FCM obtenu: ${token.substring(0, 30)}...');
      } else {
        debugPrint('❌ Impossible d\'obtenir le token FCM');
      }

      // 5. Configurer les handlers de messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 Message reçu en foreground:');
        debugPrint('  - Titre: ${message.notification?.title}');
        debugPrint('  - Corps: ${message.notification?.body}');
        debugPrint('  - Données: ${message.data}');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 Message ouvert depuis notification:');
        debugPrint('  - Titre: ${message.notification?.title}');
        debugPrint('  - Corps: ${message.notification?.body}');
      });

      // 6. Vérifier le message initial
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 Message initial trouvé:');
        debugPrint('  - Titre: ${initialMessage.notification?.title}');
        debugPrint('  - Corps: ${initialMessage.notification?.body}');
      } else {
        debugPrint('ℹ️ Aucun message initial');
      }

      debugPrint('🎉 Test de configuration Firebase terminé avec succès');

    } catch (e) {
      debugPrint('❌ Erreur lors du test Firebase: $e');
    }
  }
}
