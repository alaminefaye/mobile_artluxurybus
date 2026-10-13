import 'dart:async';
import 'dart:convert';
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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
  // Créé dès le départ : MyApp s'abonne avant la fin de initialize().
  static StreamController<Map<String, dynamic>>? _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  static bool _bgHandlerRegistered = false;
  static String? _deviceId;
  static bool _isClientUser = false;

  // Types autorisés pour les clients
  static const Set<String> _clientAllowedTypes = {
    'new_ticket',
    'ticket_created',
    'new_mail_sender',
    'new_mail_recipient',
    'mail_created',
    'mail_received',
    'mail_collected',
    'loyalty_point',
    'loyalty',
    'points',
    'departure_time_changed',
    'departure_modified',
    'departure_updated',
    'message_notification',
    'message'
  };

  static void _updateUserRoleFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        final role = (userMap['role'] ?? '').toString().toLowerCase().trim();
        _isClientUser = role.contains('client');
        // Vérifier aussi dans roles listes
        if (!_isClientUser) {
          final roles = userMap['roles'];
          if (roles is List) {
            _isClientUser =
                roles.any((r) => r.toString().toLowerCase().contains('client'));
          }
        }
      }
    } catch (_) {}
  }

  static bool _isAllowedClientType(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().toLowerCase().trim();
    if (type.isEmpty) return true; // Si pas de type, ne pas bloquer
    return _clientAllowedTypes.contains(type);
  }

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

        // 💾 Sauvegarder le device_id pour réutilisation
        if (_deviceId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('device_id', _deviceId!);
          debugPrint(
            '💾 [NotificationService] Device ID sauvegardé localement',
          );
        }

        // Mettre à jour le rôle utilisateur local pour filtrage
        _updateUserRoleFromPrefs();
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

      // Obtenir le token FCM (SANS l'enregistrer automatiquement)
      if (_messaging != null) {
        try {
          await _getToken();
          debugPrint(
            '✅ [NotificationService] Token FCM obtenu (non enregistré)',
          );
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
      _notificationStreamController ??=
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
      _notificationStreamController ??=
          StreamController<Map<String, dynamic>>.broadcast();
    }
  }

  // Canal "vibreur uniquement" partagé (caisse, suggestions…).
  // L'identifiant doit rester identique à celui envoyé par le serveur (vibrate_only)
  static const AndroidNotificationChannel _caisseVibrationChannel =
      AndroidNotificationChannel(
    'caisse_vibration_channel',
    'Notifications en vibreur',
    description:
        'Caisse, suggestions et autres notifications sans son (vibreur uniquement)',
    importance: Importance.high,
    playSound: false,
    enableVibration: true,
    showBadge: true,
  );

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
      sound: RawResourceAndroidNotificationSound(
          'notification'), // Son personnalisé
      enableVibration: true,
      showBadge: true,
    );

    // Créer le canal sur l'appareil Android
    final androidPlugin = _localNotifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      await androidPlugin.createNotificationChannel(_caisseVibrationChannel);
      debugPrint('✅ [NotificationService] Canal Android créé: ${channel.id}');
      debugPrint('   - Importance: ${channel.importance}');
      debugPrint('   - Son activé: ${channel.playSound}');
      debugPrint('   - Vibration activée: ${channel.enableVibration}');
      debugPrint('   - Badge activé: ${channel.showBadge}');

      // Demander la permission pour Android 13+ (notifications locales)
      final bool? permissionGranted =
          await androidPlugin.requestNotificationsPermission();
      if (permissionGranted == true) {
        debugPrint(
          '✅ [NotificationService] Permission notifications locales accordée',
        );
      } else {
        debugPrint(
          '⚠️ [NotificationService] Permission notifications locales refusée ou non disponible',
        );
      }
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

  /// Obtenir le token FCM (SANS l'enregistrer)
  static Future<String?> _getToken() async {
    if (_messaging == null) return null;

    try {
      String? token = await _messaging!.getToken();
      if (token != null) {
        // Token FCM obtenu avec succès - Sauvegarder localement
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        debugPrint('💾 [NotificationService] Token FCM sauvegardé localement');

        // Écouter les changements de token
        _messaging!.onTokenRefresh.listen((newToken) async {
          // Nouveau token FCM reçu - Sauvegarder et enregistrer si connecté
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', newToken);

          // Tenter d'enregistrer sur le serveur (échouera si non connecté)
          await registerTokenOnServer(newToken);
        });

        return token;
      }
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur obtention token: $e');
    }
    return null;
  }

  /// Enregistrer le token sur le serveur (APPELÉE APRÈS CONNEXION)
  static Future<bool> registerTokenOnServer([String? token]) async {
    try {
      // Récupérer le token stocké si non fourni
      String? fcmToken = token;
      if (fcmToken == null) {
        final prefs = await SharedPreferences.getInstance();
        fcmToken = prefs.getString('fcm_token');
      }

      if (fcmToken == null) {
        debugPrint('⚠️ [NotificationService] Aucun token FCM à enregistrer');
        return false;
      }

      await _registerTokenWithServer(fcmToken);
      return true;
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur enregistrement token: $e');
      return false;
    }
  }

  /// Enregistrer le token sur le serveur
  static Future<void> _registerTokenWithServer(String token) async {
    try {
      // 🔑 IMPORTANT: Récupérer le token d'authentification et le définir dans FeedbackApiService
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken != null) {
        debugPrint(
          '🔑 [NotificationService] Token auth récupéré, configuration FeedbackApiService...',
        );
        FeedbackApiService.setToken(authToken);
      } else {
        debugPrint(
          '⚠️ [NotificationService] Aucun token d\'authentification trouvé',
        );
        // Ne pas continuer si pas authentifié
        return;
      }

      final deviceInfoService = DeviceInfoService();

      // Obtenir les informations réelles de l'appareil
      final deviceType = await deviceInfoService.getDeviceType();

      // 💾 Récupérer le device_id depuis SharedPreferences en priorité
      String? deviceId = prefs.getString('device_id');

      // Si pas dans SharedPreferences, récupérer via DeviceInfoService
      if (deviceId == null) {
        debugPrint(
          '📱 [NotificationService] Device ID non trouvé en cache, récupération...',
        );
        deviceId = await deviceInfoService.getDeviceId();
      } else {
        debugPrint(
          '💾 [NotificationService] Device ID récupéré du cache: $deviceId',
        );
      }

      // 🔑 Récupérer l'UUID unique de l'installation
      final uuid = await deviceInfoService.getUuid();

      debugPrint('📱 Enregistrement FCM Token avec device_id: $deviceId');
      debugPrint('🔑 Enregistrement FCM Token avec uuid: $uuid');
      debugPrint('📱 Type d\'appareil: $deviceType');

      final result = await FeedbackApiService.registerFcmToken(
        token,
        deviceType: deviceType,
        deviceId: deviceId,
        uuid: uuid,
      );

      // Mettre à jour le rôle utilisateur (au cas où l'utilisateur vient juste de se connecter)
      _updateUserRoleFromPrefs();

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
    debugPrint('📱 [NotificationService] Message reçu en premier plan:');
    debugPrint('   - Titre: ${message.notification?.title}');
    debugPrint('   - Corps: ${message.notification?.body}');
    debugPrint('   - Données: ${message.data}');
    debugPrint('   - Message ID: ${message.messageId}');
    debugPrint('   - Type: ${message.data['type']}');

    // Filtrer pour les clients: ignorer les types non autorisés
    if (_isClientUser && !_isAllowedClientType(message.data)) {
      debugPrint(
          '🚫 [NotificationService] Notification ignorée pour client. Type=${message.data['type']}');
      return;
    }

    // 🔊 Vérifier si c'est une annonce vocale UNIQUEMENT
    if (message.data['msg_type'] == 'annonce') {
      _handleAnnouncementMessage(message);
    }

    // Déterminer le titre et le corps de la notification
    String title = message.notification?.title ??
        message.data['titre'] ??
        message.data['title'] ??
        'Art Luxury Bus';

    String body = message.notification?.body ??
        message.data['contenu'] ??
        message.data['body'] ??
        message.data['message'] ??
        'Nouvelle notification';

    debugPrint('📱 [NotificationService] Affichage notification locale:');
    debugPrint('   - Titre: $title');
    debugPrint('   - Corps: $body');

    // Afficher une notification locale pour TOUTES les notifications
    _showLocalNotification(title: title, body: body, data: message.data);

    // Envoyer via le stream pour TOUTES les notifications
    _notificationStreamController?.add({
      'type': 'foreground',
      'title': title,
      'body': body,
      'data': message.data,
    });
  }

  /// Normaliser un device ID pour la comparaison (insensible à la casse)
  static String? _normalizeDeviceId(String? deviceId) {
    if (deviceId == null || deviceId.isEmpty) return null;
    return deviceId.trim().toUpperCase();
  }

  /// 🔊 Gérer les annonces vocales
  static Future<void> _handleAnnouncementMessage(RemoteMessage message) async {
    try {
      debugPrint('🔊 [NotificationService] Annonce vocale reçue');

      // Vérifier si l'annonce est destinée à cet appareil
      final appareil = message.data['appareil']?.toString().trim();

      debugPrint('🔍 [NotificationService] Vérification annonce:');
      debugPrint('   - appareil dans message: "$appareil"');
      debugPrint('   - device ID local: "$_deviceId"');

      // Si pas d'appareil spécifié ou 'tous', traiter l'annonce
      if (appareil == null ||
          appareil.isEmpty ||
          appareil.toLowerCase() == 'tous') {
        debugPrint('✅ [NotificationService] Annonce pour tous les appareils');
      }
      // Si c'est la catégorie 'mobile', vérifier le type de message
      else if (appareil.toLowerCase() == 'mobile') {
        // Vérifier si c'est une annonce vocale (type="annonce")
        final type = message.data['type']?.toString().trim();

        // Si c'est une annonce vocale, elle doit être spécifiquement pour cet appareil
        if (type?.toLowerCase() == 'annonce') {
          debugPrint(
            '⚠️ [NotificationService] Annonce vocale de type "mobile" - ignorée car doit cibler un appareil spécifique',
          );
          return;
        }
        // Si c'est une notification normale, on accepte la catégorie 'mobile'
        else {
          debugPrint(
            '✅ [NotificationService] Notification pour catégorie mobile',
          );
        }
      }
      // Vérifier si c'est l'identifiant unique de CET appareil (comparaison insensible à la casse)
      else if (_deviceId != null) {
        final normalizedAppareil = _normalizeDeviceId(appareil);
        final normalizedDeviceId = _normalizeDeviceId(_deviceId);

        if (normalizedAppareil == normalizedDeviceId) {
          debugPrint(
            '✅ [NotificationService] Annonce pour cet appareil spécifique',
          );
          debugPrint(
            '   - Match trouvé: "$normalizedAppareil" == "$normalizedDeviceId"',
          );
        } else {
          debugPrint(
            '⚠️ [NotificationService] Annonce non destinée à cet appareil',
          );
          debugPrint(
            '   - Pas de match: "$normalizedAppareil" != "$normalizedDeviceId"',
          );
          return;
        }
      }
      // Vérifier si l'identifiant est dans une liste séparée par des virgules (comparaison insensible à la casse)
      else if (appareil.contains(',')) {
        final deviceIds =
            appareil.split(',').map((e) => _normalizeDeviceId(e)).toList();
        final normalizedDeviceId = _normalizeDeviceId(_deviceId);

        if (normalizedDeviceId != null &&
            deviceIds.contains(normalizedDeviceId)) {
          debugPrint(
            '✅ [NotificationService] Annonce pour cet appareil (liste multiple)',
          );
          debugPrint('   - Match trouvé dans liste: $deviceIds');
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
          debugPrint(
            '✅ [NotificationService] AnnouncementManager rafraîchi immédiatement',
          );
        } catch (e) {
          debugPrint(
            '⚠️ [NotificationService] Impossible de rafraîchir AnnouncementManager: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur traitement annonce: $e');
    }
  }

  /// Gérer les notifications en arrière-plan
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📱 [NotificationService] Message reçu en arrière-plan:');
    debugPrint('   - Titre: ${message.notification?.title}');
    debugPrint('   - Corps: ${message.notification?.body}');
    debugPrint('   - Données: ${message.data}');

    // Filtrer pour les clients: ignorer les types non autorisés
    if (_isClientUser && !_isAllowedClientType(message.data)) {
      debugPrint(
          '🚫 [NotificationService] (BG) Notification ignorée pour client. Type=${message.data['type']}');
      return;
    }

    // Les notifications avec 'notification' dans le payload sont affichées automatiquement par Firebase
    // Mais on peut aussi afficher une notification locale pour garantir l'affichage

    // Si la notification n'a pas de title/body dans notification, essayer de l'afficher manuellement
    if (message.notification == null ||
        message.notification?.title == null ||
        message.notification?.body == null) {
      // Essayer d'afficher une notification locale avec les données disponibles
      final title =
          message.data['title'] ?? message.data['titre'] ?? 'Art Luxury Bus';
      final body = message.data['body'] ??
          message.data['message'] ??
          message.data['contenu'] ??
          'Nouvelle notification';

      // Initialiser les notifications locales si nécessaire
      if (_localNotifications == null) {
        _localNotifications = FlutterLocalNotificationsPlugin();
        await _initializeLocalNotifications();
      }

      await _showLocalNotification(
        title: title,
        body: body,
        data: message.data,
      );

      debugPrint(
          '✅ [NotificationService] Notification locale affichée en arrière-plan');
    }
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

    if (data?['vibrate_only']?.toString() == '1') {
      await _localNotifications!.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _caisseVibrationChannel.id,
            _caisseVibrationChannel.name,
            channelDescription: _caisseVibrationChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            playSound: false,
            enableVibration: true,
          ),
          // iOS n'a pas de mode vibreur seul : un son muet déclenche la vibration
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'silence.caf',
          ),
        ),
        payload: data?.toString(),
      );
      return;
    }

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
      sound: RawResourceAndroidNotificationSound(
          'notification'), // Son personnalisé
      enableVibration: true,
      enableLights: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification.caf', // Son personnalisé iOS (format CAF requis)
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
    debugPrint(
      '🎤 [NotificationService] TEST - Simulation notification d\'annonce...',
    );

    try {
      // Simuler une notification d'annonce reçue
      const fakeMessage = RemoteMessage(
        data: {
          'msg_type': 'annonce',
          'type': 'message_notification',
          'message_id': '999',
          'appareil': 'mobile',
          'titre': 'Test Annonce',
          'contenu':
              'Ceci est un test d\'annonce vocale pour vérifier le fonctionnement',
        },
        notification: RemoteNotification(
          title: 'Test Annonce',
          body: 'Ceci est un test d\'annonce vocale',
        ),
      );

      // Déclencher le traitement comme si c'était une vraie notification
      await _handleAnnouncementMessage(fakeMessage);

      debugPrint(
        '✅ [NotificationService] TEST - Notification d\'annonce simulée',
      );
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
