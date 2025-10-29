import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/feedback_api_service.dart';
import '../services/device_info_service.dart';
import '../services/announcement_manager.dart';
import '../firebase_options.dart';

// Handler pour les notifications en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Vérifier si Firebase est déjà initialisé pour éviter l'erreur duplicate-app
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('ℹ️ [Background Handler] Firebase déjà initialisé');
    } else {
      debugPrint('⚠️ [Background Handler] Erreur Firebase: $e');
    }
  }
  
  // Traiter la notification en arrière-plan
  await NotificationService._handleBackgroundMessage(message);
}

class NotificationService {
  static FirebaseMessaging? _messaging;
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static StreamController<Map<String, dynamic>>? _notificationStreamController;
  static bool _bgHandlerRegistered = false;
  static String? _deviceId;

  // Stream pour écouter les notifications
  static Stream<Map<String, dynamic>>? get notificationStream =>
      _notificationStreamController?.stream;

  /// Initialiser Firebase et les notifications
  static Future<void> initialize() async {
    try {
      debugPrint('🔔 [NotificationService] Début initialisation...');

      // Vérifier si Firebase est déjà initialisé
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ [NotificationService] Firebase initialisé');
      } catch (e) {
        if (e.toString().contains('duplicate-app')) {
          debugPrint(
            'ℹ️ [NotificationService] Firebase déjà initialisé, on continue...',
          );
        } else {
          debugPrint(
            '⚠️ [NotificationService] Erreur Firebase (non bloquante): $e',
          );
          // Ne pas bloquer l'app si Firebase échoue
        }
      }

      // Récupérer l'ID unique de l'appareil
      try {
        _deviceId = await DeviceInfoService().getDeviceId();
        debugPrint('📱 [NotificationService] Device ID: $_deviceId');
      } catch (e) {
        debugPrint(
          '⚠️ [NotificationService] Erreur récupération Device ID: $e',
        );
      }

      // Initialiser Firebase Messaging avec gestion d'erreur
      try {
        _messaging = FirebaseMessaging.instance;
        debugPrint('✅ [NotificationService] Firebase Messaging initialisé');
      } catch (e) {
        debugPrint(
          '⚠️ [NotificationService] Firebase Messaging non disponible: $e',
        );
        // Continuer sans notifications push
      }

      // Initialiser les notifications locales
      try {
        await _initializeLocalNotifications();
        debugPrint(
          '✅ [NotificationService] Notifications locales initialisées',
        );
      } catch (e) {
        debugPrint(
          '⚠️ [NotificationService] Notifications locales non disponibles: $e',
        );
      }

      // Configurer le handler pour les notifications en arrière-plan (une seule fois)
      if (!_bgHandlerRegistered && _messaging != null) {
        try {
          FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler,
          );
          _bgHandlerRegistered = true;
          debugPrint('✅ [NotificationService] Handler arrière-plan configuré');
        } catch (e) {
          debugPrint(
            '⚠️ [NotificationService] Handler arrière-plan non configuré: $e',
          );
        }
      }

      // Demander les permissions
      if (_messaging != null) {
        try {
          await _requestPermissions();
          debugPrint('✅ [NotificationService] Permissions demandées');
        } catch (e) {
          debugPrint('⚠️ [NotificationService] Permissions non obtenues: $e');
        }
      }

      // Obtenir et enregistrer le token FCM
      if (_messaging != null) {
        try {
          await _getAndRegisterToken();
          debugPrint('✅ [NotificationService] Token FCM obtenu');
        } catch (e) {
          debugPrint('⚠️ [NotificationService] Token FCM non obtenu: $e');
        }
      }

      // Configurer les listeners
      if (_messaging != null) {
        try {
          await _setupMessageHandlers();
          debugPrint('✅ [NotificationService] Listeners configurés');
        } catch (e) {
          debugPrint('⚠️ [NotificationService] Listeners non configurés: $e');
        }
      }

      // Initialiser le stream controller
      _notificationStreamController =
          StreamController<Map<String, dynamic>>.broadcast();

      debugPrint(
        '🎉 [NotificationService] Initialisation complète avec succès !',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ [NotificationService] ERREUR lors de l\'initialisation: $e',
      );
      debugPrint('Stack trace: $stackTrace');
      // NE PAS faire crasher l'app - initialiser quand même le stream
      _notificationStreamController =
          StreamController<Map<String, dynamic>>.broadcast();
    }
  }

  /// Initialiser les notifications locales
  static Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Créer le canal de notification Android (requis pour Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'art_luxury_bus_channel', // ID du canal
      'Art Luxury Bus Notifications', // Nom du canal
      description: 'Notifications de l\'application Art Luxury Bus',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Créer le canal sur l'appareil Android
    final androidPlugin = _localNotifications!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      debugPrint('✅ [NotificationService] Canal Android créé: ${channel.id}');
    } else {
      debugPrint(
        '❌ [NotificationService] Impossible de créer le canal Android',
      );
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Demander les permissions de notification
  static Future<void> _requestPermissions() async {
    if (_messaging == null) return;

    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Permissions accordées pour les notifications
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      // Permissions provisoires accordées
    } else {
      // Permissions refusées par l'utilisateur
    }
  }

  /// Obtenir et enregistrer le token FCM
  static Future<String?> _getAndRegisterToken() async {
    if (_messaging == null) return null;

    try {
      String? token = await _messaging!.getToken();
      if (token != null) {
        // Token FCM obtenu avec succès

        // Sauvegarder localement
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);

        // Enregistrer sur le serveur
        await _registerTokenWithServer(token);

        // Écouter les changements de token
        _messaging!.onTokenRefresh.listen((newToken) {
          // Nouveau token FCM reçu - mise à jour automatique
          _registerTokenWithServer(newToken);
        });

        return token;
      }
    } catch (e) {
      // Erreur lors de l'obtention du token FCM
    }
    return null;
  }

  /// Enregistrer le token sur le serveur
  static Future<void> _registerTokenWithServer(String token) async {
    try {
      final deviceInfoService = DeviceInfoService();

      // Obtenir les informations réelles de l'appareil
      final deviceType = await deviceInfoService.getDeviceType();
      final deviceId = await deviceInfoService.getDeviceId();

      debugPrint('📱 Enregistrement FCM Token avec device_id: $deviceId');
      debugPrint('📱 Type d\'appareil: $deviceType');

      final result = await FeedbackApiService.registerFcmToken(
        token,
        deviceType: deviceType,
        deviceId: deviceId,
      );

      if (result['success'] == true) {
        debugPrint('✅ Token FCM enregistré avec succès sur le serveur');
      } else {
        debugPrint(
          '❌ Erreur lors de l\'enregistrement du token: ${result['message']}',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ Exception lors de l\'enregistrement du token sur le serveur: $e',
      );
    }
  }

  /// Configurer les handlers de messages
  static Future<void> _setupMessageHandlers() async {
    if (_messaging == null) return;

    // Messages reçus quand l'app est en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Notification reçue en premier plan
      _handleForegroundMessage(message);
    });

    // Messages reçus quand l'app est ouverte via une notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // App ouverte via notification
      _handleNotificationTap(message);
    });

    // Vérifier si l'app a été lancée via une notification
    RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      // App lancée via notification
      _handleNotificationTap(initialMessage);
    }
  }

  /// Gérer les messages en premier plan
  static void _handleForegroundMessage(RemoteMessage message) {
    // 🔊 Vérifier si c'est une annonce vocale UNIQUEMENT
    if (message.data['msg_type'] == 'annonce') {
      _handleAnnouncementMessage(message);
    }

    // Afficher une notification locale pour TOUTES les notifications
    _showLocalNotification(
      title: message.notification?.title ?? 'Art Luxury Bus',
      body: message.notification?.body ?? 'Nouvelle notification',
      data: message.data,
    );

    // Envoyer via le stream pour TOUTES les notifications
    _notificationStreamController?.add({
      'type': 'foreground',
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
    });
  }

  /// 🔊 Gérer les annonces vocales
  static Future<void> _handleAnnouncementMessage(RemoteMessage message) async {
    try {
      debugPrint('🔊 [NotificationService] Annonce vocale reçue');

      // Vérifier si l'annonce est destinée à cet appareil
      final appareil = message.data['appareil']?.toString().trim();

      // Si pas d'appareil spécifié ou 'tous', traiter l'annonce
      if (appareil == null ||
          appareil.isEmpty ||
          appareil.toLowerCase() == 'tous') {
        debugPrint('✅ [NotificationService] Annonce pour tous les appareils');
      }
      // Si c'est la catégorie 'mobile', traiter l'annonce
      else if (appareil.toLowerCase() == 'mobile') {
        debugPrint('✅ [NotificationService] Annonce pour catégorie mobile');
      }
      // Vérifier si c'est l'identifiant unique de CET appareil
      else if (_deviceId != null && appareil == _deviceId) {
        debugPrint(
          '✅ [NotificationService] Annonce pour cet appareil spécifique',
        );
      }
      // Vérifier si l'identifiant est dans une liste séparée par des virgules
      else if (appareil.contains(',')) {
        final deviceIds = appareil.split(',').map((e) => e.trim()).toList();
        if (_deviceId != null && deviceIds.contains(_deviceId)) {
          debugPrint(
            '✅ [NotificationService] Annonce pour cet appareil (liste multiple)',
          );
        } else {
          debugPrint(
            '⚠️ [NotificationService] Annonce non destinée à cet appareil (liste: $appareil, device_id: $_deviceId)',
          );
          return;
        }
      }
      // Sinon, ne pas traiter (autre catégorie ou autre device_id)
      else {
        debugPrint(
          '⚠️ [NotificationService] Annonce non destinée à cet appareil (appareil: $appareil, device_id: $_deviceId)',
        );
        return;
      }

      // Déclencher immédiatement une vérification de l'AnnouncementManager
      final messageId = message.data['message_id'];
      if (messageId != null) {
        debugPrint(
          '📢 [NotificationService] Déclenchement immédiat annonce #$messageId',
        );
        
        // Déclencher le rafraîchissement immédiat de l'AnnouncementManager
        try {
          await AnnouncementManager().refresh();
          debugPrint('✅ [NotificationService] AnnouncementManager rafraîchi immédiatement');
        } catch (e) {
          debugPrint('⚠️ [NotificationService] Impossible de rafraîchir AnnouncementManager: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur traitement annonce: $e');
    }
  }

  /// Gérer les notifications en arrière-plan
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Message en arrière-plan reçu et traité

    // Traitement spécifique en arrière-plan si nécessaire
    // Par exemple, sauvegarder en local, mettre à jour un compteur, etc.
  }

  /// Gérer le tap sur une notification
  static void _handleNotificationTap(RemoteMessage message) {
    // Notification cliquée par l'utilisateur

    // Navigation selon le type de notification
    String type = message.data['type'] ?? '';

    // Envoyer via le stream pour navigation
    _notificationStreamController?.add({
      'type': 'tap',
      'notification_type': type,
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
    });
  }

  /// Callback pour les notifications locales
  static void _onNotificationTap(NotificationResponse details) {
    // Notification locale cliquée par l'utilisateur

    // Envoyer via le stream
    _notificationStreamController?.add({
      'type': 'local_tap',
      'payload': details.payload,
    });
  }

  /// Afficher une notification locale
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (_localNotifications == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'art_luxury_bus_channel',
          'Art Luxury Bus Notifications',
          channelDescription: 'Notifications de l\'application Art Luxury Bus',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          enableLights: true,
          // color: Color(0xFF1976D2), // Bleu Art Luxury Bus
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications!.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: data?.toString(),
    );
  }

  /// Obtenir le token FCM actuel
  static Future<String?> getCurrentToken() async {
    if (_messaging == null) return null;
    return await _messaging!.getToken();
  }

  /// Souscrire à un topic
  static Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.subscribeToTopic(topic);
      // Souscrit au topic avec succès
    } catch (e) {
      // Erreur lors de la souscription au topic
    }
  }

  /// Se désabonner d'un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      // Désabonné du topic avec succès
    } catch (e) {
      // Erreur lors du désabonnement du topic
    }
  }

  /// Tester les notifications
  static Future<void> testNotification() async {
    debugPrint(
      '🔔 [NotificationService] TEST - Début du test de notification...',
    );

    if (_localNotifications == null) {
      debugPrint(
        '❌ [NotificationService] TEST - Plugin de notifications locales non initialisé !',
      );
      return;
    }

    debugPrint(
      '✅ [NotificationService] TEST - Plugin OK, envoi de la notification...',
    );

    try {
      await _showLocalNotification(
        title: 'Test Notification',
        body: 'Ceci est un test des notifications push Art Luxury Bus 🔔',
        data: {'type': 'test'},
      );
      
      debugPrint('✅ [NotificationService] TEST - Notification locale envoyée');
    } catch (e) {
      debugPrint('❌ [NotificationService] TEST - Erreur: $e');
    }
  }

  /// Tester les annonces vocales
  static Future<void> testAnnouncementPush() async {
    debugPrint('🎤 [NotificationService] TEST - Simulation notification d\'annonce...');
    
    try {
      // Simuler une notification d'annonce reçue
      final fakeMessage = RemoteMessage(
        data: {
          'msg_type': 'annonce',
          'type': 'message_notification',
          'message_id': '999',
          'appareil': 'mobile',
          'titre': 'Test Annonce',
          'contenu': 'Ceci est un test d\'annonce vocale pour vérifier le fonctionnement',
        },
        notification: const RemoteNotification(
          title: 'Test Annonce',
          body: 'Ceci est un test d\'annonce vocale',
        ),
      );
      
      // Déclencher le traitement comme si c'était une vraie notification
      await _handleAnnouncementMessage(fakeMessage);
      
      debugPrint('✅ [NotificationService] TEST - Notification d\'annonce simulée');
    } catch (e) {
      debugPrint('❌ [NotificationService] TEST - Erreur simulation: $e');
    }
  }

  /// Nettoyer les ressources
  static Future<void> dispose() async {
    await _notificationStreamController?.close();
    _notificationStreamController = null;
  }
}
