import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart' as theme_provider;
import 'providers/language_provider.dart';
import 'services/translation_service.dart';
import 'widgets/loading_indicator.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_page.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/notification_detail_screen.dart';
import 'screens/my_trips_screen.dart';
import 'screens/my_mails_screen.dart';
import 'screens/loyalty_home_screen.dart';
import 'models/notification_model.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/onboarding_service.dart';
import 'services/auth_service.dart';
import 'services/feedback_api_service.dart';
import 'services/notification_api_service.dart';
import 'services/announcement_manager.dart';
import 'services/trip_service.dart';
import 'services/depart_service.dart';
import 'services/reservation_service.dart';
import 'services/mail_api_service.dart';
import 'services/bagage_api_service.dart';
import 'services/recharge_service.dart';
import 'services/feature_permission_service.dart';
import 'services/version_check_service.dart';
import 'debug/debug_screen.dart';
import 'screens/management_hub_screen.dart';
import 'screens/mail_management_screen.dart';
import 'screens/mail_detail_screen.dart' as mail_detail;
import 'screens/embarkment_screen.dart';
import 'screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🚀 [Main] Initialisation de l\'application...');

    // Charger les traductions - d'abord charger depuis SharedPreferences
    try {
      debugPrint('🌍 [Main] Chargement des traductions...');
      final translationService = TranslationService();

      // Charger la langue depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('app_language_code') ?? 'fr';
      final countryCode = prefs.getString('app_country_code') ?? 'FR';
      final locale = Locale(languageCode, countryCode);

      await translationService.loadTranslations(locale);
      if (translationService.isLoaded) {
        debugPrint(
            '✅ [Main] Traductions chargées pour: $languageCode-$countryCode');
      } else {
        debugPrint('⚠️ [Main] Traductions non chargées');
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ [Main] Erreur lors du chargement des traductions: $e');
      debugPrint('Stack trace: $stackTrace');
      // Essayer de charger le français par défaut en cas d'erreur
      try {
        final translationService = TranslationService();
        await translationService.loadTranslations(const Locale('fr', 'FR'));
      } catch (e2) {
        debugPrint(
            '❌ [Main] Impossible de charger les traductions françaises: $e2');
      }
    }

    // Initialiser l'authentification AVANT les notifications
    final authService = AuthService();
    final token = await authService.getToken();

    if (token != null) {
      debugPrint('✅ [Main] Token d\'authentification trouvé');
      FeedbackApiService.setToken(token);
      NotificationApiService.setToken(token);
      TripService.setToken(token);
      DepartService.setToken(token);
      ReservationService.setToken(token);
      MailApiService.setToken(token);
      BagageApiService.setToken(token);
      RechargeService.setToken(token);

      // Charger les permissions de l'utilisateur au démarrage
      try {
        debugPrint('📋 [Main] Chargement des permissions utilisateur...');
        final featurePermissionService = FeaturePermissionService();
        await featurePermissionService.syncPermissions();
        debugPrint('✅ [Main] Permissions chargées avec succès');
      } catch (e) {
        debugPrint('⚠️ [Main] Erreur lors du chargement des permissions: $e');
        // Continuer malgré l'erreur
      }
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

    // Vérifier la version de l'application (en arrière-plan, ne bloque pas le démarrage)
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        debugPrint('📱 [Main] Vérification de la version...');
        final versionCheck = await VersionCheckService.checkVersion();
        if (versionCheck['success'] == true && versionCheck['data'] != null) {
          final data = versionCheck['data'];
          debugPrint(
              '📱 [Main] Version check: update_required=${data['update_required']}, force_update=${data['force_update']}');
          // Stocker dans SharedPreferences pour y accéder depuis MyApp
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_version_check', json.encode(data));
        }
      } catch (e) {
        debugPrint('⚠️ [Main] Erreur vérification version: $e');
        // Continuer malgré l'erreur
      }
    });

    debugPrint('✅ [Main] Initialisation terminée - Lancement de l\'app');
  } catch (e, stackTrace) {
    debugPrint('❌ [Main] ERREUR lors de l\'initialisation: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continuer malgré l'erreur pour éviter le crash
  }

  runApp(const ProviderScope(child: MyApp()));
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

    // Vérifier la version après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final versionCheckJson = prefs.getString('pending_version_check');
          if (versionCheckJson != null) {
            final versionData =
                json.decode(versionCheckJson) as Map<String, dynamic>;
            _handleVersionCheck(versionData);
            // Supprimer après traitement
            await prefs.remove('pending_version_check');
          }
        } catch (e) {
          debugPrint('⚠️ [MyApp] Erreur traitement version check: $e');
        }
      }
    });

    // Définir le contexte global pour l'AnnouncementManager après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Utiliser le context du MaterialApp qui est toujours valide
        final navigatorContext = _navigatorKey.currentContext;
        if (navigatorContext != null) {
          AnnouncementManager().setContext(navigatorContext);
          debugPrint(
            '✅ [Main] Contexte Navigator défini pour AnnouncementManager',
          );
        } else {
          // Fallback au context actuel
          AnnouncementManager().setContext(context);
          debugPrint(
            '⚠️ [Main] Contexte fallback utilisé pour AnnouncementManager',
          );
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

  /// Gérer la vérification de version
  void _handleVersionCheck(Map<String, dynamic> versionData) {
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext == null) return;

    final updateRequired = versionData['update_required'] == true;
    final forceUpdate = versionData['force_update'] == true;
    final updateAvailable = versionData['update_available'] == true;
    final updateMessage =
        versionData['update_message'] ?? 'Une nouvelle version est disponible.';
    final updateUrl = versionData['update_url'];
    final releaseNotes = versionData['release_notes'];

    if (updateRequired || forceUpdate) {
      // Afficher dialog bloquante (mise à jour obligatoire)
      _showForceUpdateDialog(
        navigatorContext,
        updateMessage,
        updateUrl,
        releaseNotes,
      );
    } else if (updateAvailable) {
      // Afficher dialog non bloquante (mise à jour recommandée)
      _showOptionalUpdateDialog(
        navigatorContext,
        updateMessage,
        updateUrl,
        releaseNotes,
      );
    }
  }

  /// Afficher dialog de mise à jour obligatoire
  void _showForceUpdateDialog(
    BuildContext context,
    String message,
    String? updateUrl,
    String? releaseNotes,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Non fermable
      builder: (context) => PopScope(
        canPop: false, // Empêcher la fermeture
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.system_update, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mise à jour obligatoire',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Notes de version:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    releaseNotes,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (updateUrl != null && updateUrl.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  // Ouvrir l'URL de mise à jour
                  launchUrl(Uri.parse(updateUrl));
                },
                icon: const Icon(Icons.download),
                label: const Text('Mettre à jour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton(
                onPressed: () {
                  // Si pas d'URL, rediriger vers Play Store / App Store
                  final platform = Platform.isAndroid
                      ? 'https://play.google.com/store/apps/details?id=com.artluxurybus.app'
                      : 'https://apps.apple.com/app/id123456789';
                  launchUrl(Uri.parse(platform));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mettre à jour'),
              ),
          ],
        ),
      ),
    );
  }

  /// Afficher dialog de mise à jour optionnelle
  void _showOptionalUpdateDialog(
    BuildContext context,
    String message,
    String? updateUrl,
    String? releaseNotes,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true, // Fermable
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nouvelle version disponible',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes de version:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  releaseNotes,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
          if (updateUrl != null && updateUrl.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                launchUrl(Uri.parse(updateUrl));
              },
              icon: const Icon(Icons.download),
              label: const Text('Mettre à jour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final platform = Platform.isAndroid
                    ? 'https://play.google.com/store/apps/details?id=com.artluxurybus.app'
                    : 'https://apps.apple.com/app/id123456789';
                launchUrl(Uri.parse(platform));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mettre à jour'),
            ),
        ],
      ),
    );
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
        '🔔 Navigation notification: type=$notificationType, action=$action',
      );

      // NOUVEAU: Gérer les notifications de tickets
      if (notificationType == 'new_ticket' && action == 'view_trips') {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const MyTripsScreen()),
        );
        debugPrint('✅ Navigation vers Mes Trajets (nouveau ticket)');
        return;
      }

      // NOUVEAU: Gérer les notifications de changement d'heure de départ
      if (notificationType == 'departure_time_changed' &&
          action == 'view_trips') {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const MyTripsScreen()),
        );
        debugPrint(
          '✅ Navigation vers Mes Trajets (changement d\'heure de départ)',
        );
        return;
      }

      // NOUVEAU: Gérer les notifications de points de fidélité
      if (notificationType == 'loyalty_point' && action == 'view_loyalty') {
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LoyaltyHomeScreen()),
        );
        debugPrint('✅ Navigation vers Programme Fidélité (nouveau point)');
        return;
      }

      // NOUVEAU: Gérer les notifications de courriers
      if ((notificationType == 'new_mail_sender' ||
              notificationType == 'new_mail_recipient' ||
              notificationType == 'mail_collected') &&
          action == 'view_mail') {
        // Vérifier le rôle de l'utilisateur pour décider où naviguer
        final authState = ref.read(authProvider);
        final user = authState.user;
        final userRole = user?.role?.trim().toLowerCase() ?? '';
        final permissions = user?.permissions ?? [];
        final roles = user?.roles ?? [];

        // Vérifier si l'utilisateur a le rôle courrier ou la permission courrier
        final hasMailRole = userRole == 'courrier' ||
            roles.any((r) => r.toLowerCase().contains('courrier')) ||
            permissions.any((p) => p.toLowerCase().contains('courrier')) ||
            permissions.any((p) => p.toLowerCase().contains('mail'));

        debugPrint('🔔 [Notification] Rôle utilisateur: $userRole');
        debugPrint('🔔 [Notification] Has mail role: $hasMailRole');

        // Vérifier si on a un ID de courrier pour ouvrir directement les détails
        final mailId = data != null
            ? int.tryParse(data['mail_id']?.toString() ?? '')
            : null;

        if (hasMailRole) {
          // Pour les agents avec rôle courrier
          if (mailId != null) {
            // Si on a un ID de courrier, ouvrir directement les détails
            MailApiService.getMailDetails(mailId).then((mail) {
              final newContext = _navigatorKey.currentContext;
              if (newContext != null && mounted) {
                // ignore: use_build_context_synchronously
                Navigator.of(newContext).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        mail_detail.MailDetailScreen(mail: mail),
                  ),
                );
                debugPrint(
                  '✅ Navigation vers détails du courrier #${mail.mailNumber} (agent)',
                );
              }
            }).catchError((e) {
              debugPrint('❌ Erreur lors du chargement des détails: $e');
              // En cas d'erreur, naviguer vers la page de gestion
              final newContext = _navigatorKey.currentContext;
              if (newContext != null && mounted) {
                // ignore: use_build_context_synchronously
                Navigator.of(newContext).push(
                  MaterialPageRoute(
                    builder: (context) => const MailManagementScreen(),
                  ),
                );
              }
            });
          } else {
            // Pas d'ID, naviguer vers la page de gestion (seulement si pas déjà dessus)
            // ignore: use_build_context_synchronously
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MailManagementScreen(),
              ),
            );
            debugPrint('✅ Navigation vers Gestion des Courriers (agent)');
          }
        } else {
          // Pour les clients
          if (mailId != null) {
            // Si on a un ID de courrier, ouvrir directement les détails
            MailApiService.getMailDetails(mailId).then((mail) {
              final newContext = _navigatorKey.currentContext;
              if (newContext != null && mounted) {
                // ignore: use_build_context_synchronously
                Navigator.of(newContext).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        mail_detail.MailDetailScreen(mail: mail),
                  ),
                );
                debugPrint(
                  '✅ Navigation vers détails du courrier #${mail.mailNumber} (client)',
                );
              }
            }).catchError((e) {
              debugPrint('❌ Erreur lors du chargement des détails: $e');
              // En cas d'erreur, naviguer vers Mes Courriers
              final newContext = _navigatorKey.currentContext;
              if (newContext != null && mounted) {
                // ignore: use_build_context_synchronously
                Navigator.of(newContext).push(
                  MaterialPageRoute(
                    builder: (context) => const MyMailsScreen(),
                  ),
                );
              }
            });
          } else {
            // Pas d'ID, naviguer vers Mes Courriers
            // ignore: use_build_context_synchronously
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MyMailsScreen()),
            );
            debugPrint('✅ Navigation vers Mes Courriers (client)');
          }
        }
        return;
      }

      // Navigation par défaut vers l'onglet Notifications (seulement si pas de type spécifique)
      // ignore: use_build_context_synchronously
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              const HomePage(initialTabIndex: 1), // Index 1 = Notifications
        ),
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
                builder: (context) =>
                    NotificationDetailScreen(notification: notificationModel),
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
    final locale = ref.watch(languageProvider);
    // Écouter l'état d'authentification pour rebuilder l'app automatiquement
    final authState = ref.watch(authProvider);

    // S'assurer que les traductions sont chargées pour la locale actuelle
    ref.listen(languageProvider, (previous, next) async {
      if (previous != next) {
        final translationService = TranslationService();
        if (!translationService.isLoaded ||
            translationService.currentLocale != next) {
          await translationService.loadTranslations(next);
          debugPrint(
              '✅ [MyApp] Traductions rechargées pour: ${next.languageCode}-${next.countryCode}');
        }
      }
    });

    return MaterialApp(
      title: 'ART MOBILE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode == theme_provider.ThemeMode.system
          ? ThemeMode.system
          : themeMode == theme_provider.ThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.light,
      navigatorKey: _navigatorKey,
      // Configuration des localisations pour supporter le français et l'anglais
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // Français
        Locale('en', 'US'), // Anglais
      ],
      locale: locale, // Langue sélectionnée par l'utilisateur
      // Utiliser AuthWrapper comme home pour que l'app rebuilde automatiquement après connexion
      home: const AuthWrapper(),
      routes: {'/debug': (context) => const DebugScreen()},
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _showSplash = true;
  bool _onboardingChecked = false;
  bool _shouldShowOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Vérifier si l'onboarding a été complété
    final isOnboardingCompleted =
        await OnboardingService.isOnboardingCompleted();

    setState(() {
      _shouldShowOnboarding = !isOnboardingCompleted;
      _onboardingChecked = true;
    });

    // Attendre un peu pour l'animation du splash
    await Future.delayed(const Duration(milliseconds: 3000));

    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Afficher le splash screen au démarrage
    if (_showSplash || !_onboardingChecked) {
      return const SplashScreen();
    }

    // Afficher l'onboarding si nécessaire
    if (_shouldShowOnboarding) {
      return const OnboardingScreen();
    }

    // Afficher un écran de chargement pendant la vérification
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingIndicator(),
              SizedBox(height: 16),
              Text('Chargement...'),
            ],
          ),
        ),
      );
    }

    // Rediriger selon le statut d'authentification et le rôle/permissions
    if (authState.isAuthenticated) {
      final user = authState.user;
      final userRole = user?.role?.trim().toLowerCase();
      final permissions = user?.permissions ?? [];
      final roles = user?.roles ?? [];

      debugPrint('🔍 [AuthWrapper] Rôle utilisateur: "$userRole"');
      debugPrint('🔍 [AuthWrapper] DisplayRole: "${user?.displayRole}"');
      debugPrint('🔍 [AuthWrapper] Roles: $roles');
      debugPrint('🔍 [AuthWrapper] RolesList: ${user?.rolesList}');
      debugPrint('🔍 [AuthWrapper] Permissions: $permissions');

      // Vérifier si l'utilisateur a le rôle "PDG" (redirection automatique vers dashboard)
      bool isPDG = false;
      if (userRole != null &&
          (userRole == 'pdg' || userRole.contains('directeur'))) {
        isPDG = true;
      } else if (user?.displayRole != null &&
          (user!.displayRole!.trim().toLowerCase() == 'pdg' ||
              user.displayRole!.trim().toLowerCase().contains('directeur'))) {
        isPDG = true;
      } else if (roles.isNotEmpty) {
        isPDG = roles.any(
          (r) =>
              r.toString().trim().toLowerCase() == 'pdg' ||
              r.toString().trim().toLowerCase().contains('directeur'),
        );
      }

      // Vérifier si l'utilisateur a le rôle "courrier"
      // Vérifier dans role, displayRole, ou roles[]
      bool isCourrier = false;
      if (userRole != null && userRole == 'courrier') {
        isCourrier = true;
      } else if (user?.displayRole != null &&
          user!.displayRole!.trim().toLowerCase() == 'courrier') {
        isCourrier = true;
      } else if (roles.isNotEmpty) {
        isCourrier = roles.any(
          (r) => r.toString().trim().toLowerCase() == 'courrier',
        );
      }

      // Vérifier si l'utilisateur a le rôle "embarquement"
      bool isEmbarkment = false;
      if (userRole != null &&
          (userRole.contains('embarquement') ||
              userRole.contains('embarkment'))) {
        isEmbarkment = true;
      } else if (user?.displayRole != null &&
          (user!.displayRole!.trim().toLowerCase().contains('embarquement') ||
              user.displayRole!.trim().toLowerCase().contains('embarkment'))) {
        isEmbarkment = true;
      } else if (roles.isNotEmpty) {
        isEmbarkment = roles.any(
          (r) =>
              r.toString().trim().toLowerCase().contains('embarquement') ||
              r.toString().trim().toLowerCase().contains('embarkment'),
        );
      } else if (permissions.isNotEmpty) {
        isEmbarkment = permissions.any(
          (p) =>
              p.toLowerCase().contains('embarquement') ||
              p.toLowerCase().contains('embarkment') ||
              p.toLowerCase().contains('scan_ticket'),
        );
      }

      // Rediriger vers AdminDashboardScreen si l'utilisateur a le rôle "PDG"
      if (isPDG) {
        debugPrint(
          '✅ [AuthWrapper] Redirection vers AdminDashboardScreen (rôle: PDG)',
        );
        return const AdminDashboardScreen();
      }

      // Rediriger vers EmbarkmentScreen si l'utilisateur a le rôle "embarquement"
      if (isEmbarkment) {
        debugPrint(
          '✅ [AuthWrapper] Redirection vers EmbarkmentScreen (rôle: embarquement)',
        );
        return const EmbarkmentScreen();
      }

      // Rediriger vers ManagementHubScreen UNIQUEMENT si l'utilisateur a le rôle "courrier"
      if (isCourrier) {
        debugPrint(
          '✅ [AuthWrapper] Redirection vers ManagementHubScreen (rôle: courrier)',
        );
        return const ManagementHubScreen();
      }

      // Tous les autres utilisateurs authentifiés vont vers HomePage
      debugPrint(
        '➡️ [AuthWrapper] Redirection vers HomePage (rôle: "$userRole")',
      );
      return const HomePage();
    } else {
      return const LoginScreen();
    }
  }
}
