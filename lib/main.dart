import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_page.dart';
import 'screens/splash_screen.dart';
import 'screens/notification_detail_screen.dart';
import 'models/notification_model.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging AVANT tout
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  debugPrint('🚀 [MAIN] Démarrage de l\'application...');
  
  // Initialiser les notifications Firebase
  debugPrint('🔔 [MAIN] Initialisation des notifications...');
  await NotificationService.initialize();
  debugPrint('✅ [MAIN] Notifications initialisées');
  
  debugPrint('🎯 [MAIN] Lancement de l\'app...');
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
  }

  /// Écouter les changements d'authentification pour les notifications en attente
  void _setupAuthListener() {
    // Écouter les changements d'état d'authentification
    ref.listenManual(authProvider, (previous, next) {
      debugPrint('🔐 [MAIN] Changement d\'authentification: ${next.isAuthenticated}');
      
      // Si l'utilisateur vient de se connecter et qu'on a une notification en attente
      if (next.isAuthenticated && _pendingNotification != null) {
        debugPrint('✅ [MAIN] Utilisateur maintenant authentifié, navigation vers notification en attente');
        
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
      debugPrint('🔔 [MAIN] Notification cliquée: $notification');
      if (notification['type'] == 'tap' || notification['type'] == 'local_tap') {
        _handleNotificationNavigation(notification);
      }
    });
  }

  /// Vérifier si l'app a été ouverte via une notification (app fermée)
  Future<void> _checkInitialNotification() async {
    debugPrint('🔍 [MAIN] Vérification notification initiale...');
    
    // Attendre que l'app soit complètement initialisée
    await Future.delayed(const Duration(seconds: 3));
    
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    
    if (initialMessage == null) {
      debugPrint('ℹ️ [MAIN] Aucune notification initiale');
      return;
    }
    
    debugPrint('🔔 [MAIN] App ouverte via notification: ${initialMessage.notification?.title}');
    debugPrint('📦 [MAIN] Données notification: ${initialMessage.data}');
    
    // Vérifier que l'utilisateur est authentifié avant de naviguer
    final authState = ref.read(authProvider);
    debugPrint('🔐 [MAIN] État authentification: ${authState.isAuthenticated}');
    
    if (!authState.isAuthenticated) {
      debugPrint('⚠️ [MAIN] Utilisateur non authentifié, mise en attente de la notification...');
      // Sauvegarder la notification pour navigation après connexion
      _pendingNotification = initialMessage;
      debugPrint('💾 [MAIN] Notification sauvegardée en attente');
      return;
    }
    
    debugPrint('✅ [MAIN] Utilisateur authentifié, navigation immédiate vers notifications');
    _handleNotificationNavigation({
      'type': 'tap',
      'notification_type': initialMessage.data['type'],
      'title': initialMessage.notification?.title,
      'body': initialMessage.notification?.body,
      'data': initialMessage.data,
    });
  }

  /// Gérer la navigation selon le type de notification
  void _handleNotificationNavigation(Map<String, dynamic> notification) {
    debugPrint('🔔 [MAIN] Navigation vers notification: $notification');
    
    // Attendre que la navigation soit prête
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = _navigatorKey.currentContext;
      if (context == null || !mounted) {
        debugPrint('❌ [MAIN] Contexte de navigation non disponible');
        return;
      }

      // D'abord naviguer vers HomePage avec l'onglet Notifications
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomePage(initialTabIndex: 1), // Index 1 = Notifications
        ),
        (route) => false,
      );
      
      debugPrint('✅ [MAIN] Navigation vers onglet Notifications effectuée');
      
      // Ensuite, si on a un ID de notification, ouvrir le détail
      final data = notification['data'] as Map<String, dynamic>?;
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
              type: data['type']?.toString() ?? '',
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
            
            debugPrint('✅ [MAIN] Navigation vers détail de la notification effectuée');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Art Luxury Bus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: _navigatorKey,
      home: const SplashScreen(),
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
