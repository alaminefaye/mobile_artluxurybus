import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart' as theme_provider;
import 'screens/auth/login_screen.dart';
import 'screens/home_page.dart';
import 'screens/splash_screen.dart';
import 'screens/notification_detail_screen.dart';
import 'screens/my_trips_screen.dart';
import 'screens/loyalty_home_screen.dart';
import 'models/notification_model.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/video_advertisement_service.dart';
import 'services/feedback_api_service.dart';
import 'services/notification_api_service.dart';
import 'services/ads_api_service.dart';
import 'services/horaire_service.dart';
import 'services/announcement_manager.dart';
import 'debug/debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🚀 [Main] Initialisation de l\'application...');

    // Initialiser l'authentification AVANT les notifications
    final authService = AuthService();
    final token = await authService.getToken();

    if (token != null) {
      debugPrint('✅ [Main] Token d\'authentification trouvé');
      FeedbackApiService.setToken(token);
      NotificationApiService.setToken(token);
      AdsApiService.setToken(token);
      HoraireService.setToken(token);
      VideoAdvertisementService.setToken(token);
    } else {
      debugPrint('⚠️ [Main] Aucun token d\'authentification');
    }

    // Initialiser les notifications Firebase APRÈS l'auth
    debugPrint('🔔 [Main] Initialisation Firebase Messaging...');
    await NotificationService.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ [Main] Timeout Firebase - continue quand même');
      },
    );
    debugPrint('✅ [Main] Firebase Messaging initialisé');

    // Initialiser le gestionnaire d'annonces GLOBALEMENT
    try {
      debugPrint('📢 [Main] Démarrage AnnouncementManager...');
      await AnnouncementManager().start();
      debugPrint('✅ [Main] AnnouncementManager démarré');
    } catch (e) {
      debugPrint('⚠️ [Main] Erreur AnnouncementManager: $e');
      // Continuer malgré l'erreur
    }

    debugPrint('✅ [Main] Initialisation terminée - Lancement de l\'app');
  } catch (e, stackTrace) {
    debugPrint('❌ [Main] ERREUR lors de l\'initialisation: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continuer malgré l'erreur pour éviter le crash
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  RemoteMessage? _pendingNotification;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
    _setupAuthListener();
    _checkInitialNotification();

    // Définir le contexte global pour l'AnnouncementManager après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Utiliser le context du MaterialApp qui est toujours valide
        final navigatorContext = _navigatorKey.currentContext;
        if (navigatorContext != null) {
          AnnouncementManager().setContext(navigatorContext);
          debugPrint(
              '✅ [Main] Contexte Navigator défini pour AnnouncementManager');
        } else {
          // Fallback au context actuel
          AnnouncementManager().setContext(context);
          debugPrint(
              '⚠️ [Main] Contexte fallback utilisé pour AnnouncementManager');
        }
      }
    });
  }

  /// Écouter les changements d'authentification pour les notifications en attente
  void _setupAuthListener() {
    // Écouter les changements d'état d'authentification
    ref.listenManual(authProvider, (previous, next) {
      // Si l'utilisateur vient de se connecter et qu'on a une notification en attente
      if (next.isAuthenticated && _pendingNotification != null) {
        // Attendre un peu que HomePage soit prête
        Future.delayed(const Duration(seconds: 2), () {
          if (_pendingNotification != null) {
            _handleNotificationNavigation({
              'type': 'tap',
              'notification_type': _pendingNotification!.data['type'],
              'title': _pendingNotification!.notification?.title,
              'body': _pendingNotification!.notification?.body,
              'data': _pendingNotification!.data,
            });
            _pendingNotification = null; // Réinitialiser
          }
        });
      }
    });
  }

  /// Écouter les clics sur les notifications quand l'app est ouverte
  void _setupNotificationListener() {
    NotificationService.notificationStream?.listen((notification) {
      if (notification['type'] == 'tap' ||
          notification['type'] == 'local_tap') {
        _handleNotificationNavigation(notification);
      }
    });
  }

  /// Vérifier si l'app a été ouverte via une notification (app fermée)
  Future<void> _checkInitialNotification() async {
    // Attendre que l'app soit complètement initialisée
    await Future.delayed(const Duration(seconds: 3));

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage == null) {
      return;
    }

    // Vérifier que l'utilisateur est authentifié avant de naviguer
    final authState = ref.read(authProvider);

    if (!authState.isAuthenticated) {
      // Sauvegarder la notification pour navigation après connexion
      _pendingNotification = initialMessage;
      return;
    }

    _handleNotificationNavigation({
      'type': 'tap',
      'notification_type':
          initialMessage.data['msg_type'] ?? initialMessage.data['type'],
      'title': initialMessage.notification?.title,
      'body': initialMessage.notification?.body,
      'data': initialMessage.data,
    });
  }

  /// Gérer la navigation selon le type de notification
  void _handleNotificationNavigation(Map<String, dynamic> notification) {
    // Attendre que la navigation soit prête
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = _navigatorKey.currentContext;
      if (context == null || !mounted) {
        return;
      }

      final data = notification['data'] as Map<String, dynamic>?;
      final notificationType = data?['type']?.toString() ?? '';
      final action = data?['action']?.toString() ?? '';

      debugPrint(
          '🔔 Navigation notification: type=$notificationType, action=$action');

      // NOUVEAU: Gérer les notifications de tickets
      if (notificationType == 'new_ticket' && action == 'view_trips') {
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MyTripsScreen(),
          ),
        );
        debugPrint('✅ Navigation vers Mes Trajets (nouveau ticket)');
        return;
      }

      // NOUVEAU: Gérer les notifications de points de fidélité
      if (notificationType == 'loyalty_point' && action == 'view_loyalty') {
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LoyaltyHomeScreen(),
          ),
        );
        debugPrint('✅ Navigation vers Programme Fidélité (nouveau point)');
        return;
      }

      // Navigation par défaut vers l'onglet Notifications
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              const HomePage(initialTabIndex: 1), // Index 1 = Notifications
        ),
        (route) => false,
      );

      // Ensuite, si on a un ID de notification, ouvrir le détail
      if (data != null && data['notification_id'] != null) {
        // Attendre que HomePage soit montée
        Future.delayed(const Duration(milliseconds: 1000), () {
          final newContext = _navigatorKey.currentContext;
          if (newContext != null && mounted) {
            // Créer un objet NotificationModel à partir des données
            final notificationModel = NotificationModel(
              id: int.tryParse(data['notification_id'].toString()) ?? 0,
              title: notification['title']?.toString() ?? '',
              message: notification['body']?.toString() ?? '',
              type: data['msg_type']?.toString() ??
                  data['type']?.toString() ??
                  '',
              isRead: false,
              createdAt: DateTime.now(),
            );

            // Naviguer vers l'écran de détail
            // ignore: use_build_context_synchronously
            Navigator.of(newContext).push(
              MaterialPageRoute(
                builder: (context) => NotificationDetailScreen(
                  notification: notificationModel,
                ),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(theme_provider.themeModeProvider);

    return MaterialApp(
      title: 'Art Luxury Bus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode == theme_provider.ThemeMode.system
          ? ThemeMode.system
          : themeMode == theme_provider.ThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.light,
      navigatorKey: _navigatorKey,
      // Configuration des localisations pour supporter le français
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // Français
        Locale('en', 'US'), // Anglais
      ],
      locale: const Locale('fr', 'FR'), // Langue par défaut
      home: const SplashScreen(),
      routes: {
        '/debug': (context) => const DebugScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Afficher un écran de chargement pendant la vérification
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement...'),
            ],
          ),
        ),
      );
    }

    // Rediriger selon le statut d'authentification
    if (authState.isAuthenticated) {
      return const HomePage();
    } else {
      return const LoginScreen();
    }
  }
}
