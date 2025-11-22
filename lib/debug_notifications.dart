// Script de diagnostic pour les notifications push
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationDebugger {
  static Future<void> debugNotifications() async {
    debugPrint('🔍 [DEBUG] Début du diagnostic des notifications...\n');

    // 1. Vérifier Firebase Messaging
    debugPrint('1️⃣ Vérification Firebase Messaging...');
    try {
      final messaging = FirebaseMessaging.instance;
      debugPrint('✅ Firebase Messaging instance créée');

      // Vérifier les permissions
      final settings = await messaging.getNotificationSettings();
      debugPrint('📱 Permissions de notification:');
      debugPrint('   - Alert: ${settings.alert}');
      debugPrint('   - Badge: ${settings.badge}');
      debugPrint('   - Sound: ${settings.sound}');
      debugPrint('   - Authorization status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint(
            '✅ Permissions accordées - Les notifications push devraient fonctionner');
      } else {
        debugPrint('❌ Permissions refusées - Demander les permissions');
        final newSettings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint(
            '📱 Nouvelles permissions: ${newSettings.authorizationStatus}');
      }
    } catch (e) {
      debugPrint('❌ Erreur Firebase Messaging: $e');
    }

    // 2. Vérifier le token FCM
    debugPrint('\n2️⃣ Vérification du token FCM...');
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('✅ Token FCM obtenu: ${token.substring(0, 30)}...');
      } else {
        debugPrint('❌ Token FCM non obtenu');
      }
    } catch (e) {
      debugPrint('❌ Erreur token FCM: $e');
    }

    // 3. Vérifier les notifications locales
    debugPrint('\n3️⃣ Vérification des notifications locales...');
    try {
      final localNotifications = FlutterLocalNotificationsPlugin();

      // Configuration Android
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await localNotifications.initialize(initSettings);
      debugPrint('✅ Notifications locales initialisées');

      // Créer le canal Android
      const channel = AndroidNotificationChannel(
        'art_luxury_bus_channel',
        'Art Luxury Bus Notifications',
        description: 'Notifications de l\'application Art Luxury Bus',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      final androidPlugin =
          localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        debugPrint('✅ Canal Android créé: ${channel.id}');
      }

      // Tester une notification locale
      debugPrint('\n4️⃣ Test d\'une notification locale...');
      await localNotifications.show(
        999,
        '🧪 Test Notification Locale',
        'Ceci est un test de notification locale',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'art_luxury_bus_channel',
            'Art Luxury Bus Notifications',
            channelDescription:
                'Notifications de l\'application Art Luxury Bus',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            sound: RawResourceAndroidNotificationSound(
                'notification'), // Son personnalisé
            enableVibration: true,
            enableLights: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound:
                'notification.caf', // Son personnalisé iOS (format CAF requis)
          ),
        ),
      );
      debugPrint(
          '✅ Notification locale envoyée - Vérifiez votre écran de notification');
    } catch (e) {
      debugPrint('❌ Erreur notifications locales: $e');
    }

    // 5. Configurer les listeners Firebase
    debugPrint('\n5️⃣ Configuration des listeners Firebase...');
    try {
      // Listener pour les messages en premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📱 [DEBUG] Message reçu en premier plan:');
        debugPrint('   - Titre: ${message.notification?.title}');
        debugPrint('   - Corps: ${message.notification?.body}');
        debugPrint('   - Données: ${message.data}');
      });

      // Listener pour les messages en arrière-plan
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📱 [DEBUG] App ouverte via notification:');
        debugPrint('   - Titre: ${message.notification?.title}');
        debugPrint('   - Corps: ${message.notification?.body}');
        debugPrint('   - Données: ${message.data}');
      });

      debugPrint('✅ Listeners Firebase configurés');
    } catch (e) {
      debugPrint('❌ Erreur configuration listeners: $e');
    }

    debugPrint('\n🎯 [DEBUG] Diagnostic terminé !');
    debugPrint('📋 Résumé:');
    debugPrint(
        '   - Si vous voyez une notification locale → Les notifications locales fonctionnent');
    debugPrint(
        '   - Si vous ne voyez pas de notification → Vérifiez les paramètres de notification de votre téléphone');
    debugPrint(
        '   - Pour tester les notifications push → Envoyez une notification depuis le serveur');
  }
}
