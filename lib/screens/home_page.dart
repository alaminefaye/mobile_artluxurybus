import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin/horaires_list_screen.dart';
import 'admin/video_advertisements_screen.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/translation_provider.dart';
import '../services/translation_service.dart';
import '../models/user.dart';
import '../services/notification_service.dart';
import '../services/feedback_api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_api_service.dart';
import '../services/ads_api_service.dart';
import '../services/horaire_service.dart';
import '../services/video_advertisement_service.dart';
import '../services/slide_service.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../models/slide_model.dart';
import '../widgets/location_display_widget.dart';
import '../widgets/ad_banner.dart';
import 'notification_detail_screen.dart';
import 'loyalty_home_screen.dart';
import 'auth/login_screen.dart';
import 'feedback_screen.dart';
import 'qr_scanner_screen.dart';
import 'attendance_history_screen.dart';
import 'bus/bus_dashboard_screen.dart';
import 'about_screen.dart';
import 'voice_settings_screen.dart';
import 'theme_settings_screen.dart';
import 'language_settings_screen.dart';
import 'company_info_screen.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';
import 'my_trips_screen.dart';
import 'my_mails_screen.dart';
import '../services/announcement_manager.dart';
import '../services/trip_service.dart';
import 'reservation_screen.dart';
import '../services/depart_service.dart';
import '../services/reservation_service.dart';
import 'recharge_screen.dart';
import '../services/recharge_service.dart';
import '../providers/feature_permission_provider.dart';
import '../models/feature_permission_model.dart';
import '../providers/loyalty_provider.dart';
import 'promo_code_management_screen.dart';
import 'expense_management_screen.dart';
import 'admin_dashboard_screen.dart';
import 'message_management_screen.dart';
import 'job_application_form_screen.dart';
import 'admin/job_applications_list_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const HomePage({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  late int _currentIndex;
  double _solde = 0.0;
  bool _isLoadingSolde = false;
  int _adBannerKey = 0; // Clé pour forcer le rechargement de l'AdBanner
  List<Slide> _slides = [];
  bool _isLoadingSlides = false;
  PageController? _slidesPageController;
  Timer? _slidesTimer;
  int _currentSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialTabIndex;
    _loadSolde();
    _loadSlides();
    // Initialiser le token pour l'API des feedbacks et FCM
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Mettre à jour le contexte dès le début
      _updateVoiceAnnouncementsContext();
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        // Définir le token auth pour l'API
        final authService = AuthService();
        final token = await authService.getToken();
        if (token != null) {
          FeedbackApiService.setToken(token);
          NotificationApiService.setToken(token);
          AdsApiService.setToken(token);
          HoraireService.setToken(token);
          VideoAdvertisementService.setToken(token);
          SlideService.setToken(token);
          TripService.setToken(token);
          DepartService.setToken(token);
          ReservationService.setToken(token);
          RechargeService.setToken(token);

          // Charger les notifications pour tous les utilisateurs
          // Le filtrage des notifications de feedback se fera côté affichage
          ref
              .read(notificationProvider.notifier)
              .loadNotifications(refresh: true);
        }

        // Obtenir et enregistrer le token FCM pour tous les utilisateurs
        // Tous peuvent recevoir des notifications (sauf feedback pour pointage)
        try {
          final fcmToken = await NotificationService.getCurrentToken();
          if (fcmToken != null) {
            // Token FCM obtenu, tentative d'enregistrement
            final result = await FeedbackApiService.registerFcmToken(fcmToken);

            if (result['success'] == true) {
              // Token FCM enregistré avec succès sur le serveur
            } else {
              // Problème d'enregistrement serveur
            }
          }
        } catch (e) {
          // Erreur lors de l'enregistrement FCM
        }

        // 🔊 METTRE À JOUR LE CONTEXTE POUR LES ANNONCES VOCALES
        _updateVoiceAnnouncementsContext();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mettre à jour le contexte chaque fois que les dépendances changent
    // (par exemple quand on change d'onglet ou qu'on navigue)
    _updateVoiceAnnouncementsContext();
  }

  /// Mettre à jour le contexte pour le gestionnaire d'annonces vocales
  void _updateVoiceAnnouncementsContext() {
    try {
      debugPrint(
          '🔊 [HomePage] Mise à jour du contexte pour les annonces vocales...');
      // Définir le contexte pour l'affichage des annonces
      if (mounted && context.mounted) {
        // Vérifier que le Navigator est disponible
        final navigator = Navigator.maybeOf(context);
        if (navigator != null) {
          AnnouncementManager().setContext(context);
          debugPrint(
              '✅ [HomePage] Contexte mis à jour pour les annonces vocales (Navigator OK)');
        } else {
          debugPrint(
              '⚠️ [HomePage] Navigator non disponible - contexte non défini');
        }
      } else {
        debugPrint(
            '⚠️ [HomePage] Widget ou contexte non monté - contexte non défini');
      }
    } catch (e) {
      debugPrint(
          '❌ [HomePage] Erreur mise à jour contexte annonces vocales: $e');
    }
  }

  /// Charger le solde depuis l'API
  Future<void> _loadSolde() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoadingSolde = true;
      });

      final result = await RechargeService.getSolde();

      if (!mounted) return;

      setState(() {
        _isLoadingSolde = false;
        if (result['success'] == true) {
          final soldeValue = result['solde'];
          if (soldeValue is double) {
            _solde = soldeValue;
          } else if (soldeValue is int) {
            _solde = soldeValue.toDouble();
          } else if (soldeValue is String) {
            _solde = double.tryParse(soldeValue) ?? 0.0;
          } else {
            _solde = 0.0;
          }
        } else {
          // En cas d'erreur, garder le solde à 0 mais ne pas crasher
          _solde = 0.0;
          debugPrint(
              '⚠️ [HomePage] Erreur lors du chargement du solde: ${result['message']}');
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [HomePage] Exception lors du chargement du solde: $e');
      debugPrint('❌ [HomePage] Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoadingSolde = false;
          _solde = 0.0;
        });
      }
    }
  }

  Future<void> _loadSlides() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoadingSlides = true;
      });

      final slideService = SlideService();
      final slides = await slideService.getActiveSlides();

      if (!mounted) return;

      setState(() {
        _isLoadingSlides = false;
        _slides = slides;
      });

      // Initialiser ou réinitialiser le PageController et le Timer après le chargement des slides
      if (slides.isNotEmpty) {
        if (_slidesPageController != null &&
            _slidesPageController!.hasClients) {
          // Si le PageController existe déjà, juste réinitialiser le timer
          _currentSlideIndex = 0;
          _slidesPageController!.jumpToPage(0);
          _startAutoScroll();
        } else {
          // Sinon, initialiser complètement
          _initializeSlidesAutoScroll();
        }
      } else {
        // Si pas de slides, nettoyer
        _slidesTimer?.cancel();
        _slidesPageController?.dispose();
        _slidesPageController = null;
      }
    } catch (e) {
      debugPrint('❌ [HomePage] Erreur lors du chargement des slides: $e');
      if (mounted) {
        setState(() {
          _isLoadingSlides = false;
          _slides = [];
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _slidesTimer?.cancel();
    _slidesPageController?.dispose();
    super.dispose();
  }

  void _initializeSlidesAutoScroll() {
    // Annuler le timer existant s'il y en a un
    _slidesTimer?.cancel();

    // Disposer du PageController existant s'il y en a un
    _slidesPageController?.dispose();

    // Créer un nouveau PageController
    _slidesPageController = PageController(initialPage: 0);
    _currentSlideIndex = 0;

    // Démarrer le défilement automatique
    _startAutoScroll();
  }

  void _onSlideChanged(int index) {
    if (_currentSlideIndex != index) {
      setState(() {
        _currentSlideIndex = index;
      });

      // Réinitialiser le timer quand l'utilisateur change manuellement de slide
      _resetAutoScrollTimer();
    }
  }

  void _onSlideTapped() {
    // Arrêter temporairement le défilement automatique quand l'utilisateur interagit
    _resetAutoScrollTimer();
  }

  void _resetAutoScrollTimer() {
    // Annuler le timer actuel
    _slidesTimer?.cancel();

    // Redémarrer le défilement automatique après 5 secondes d'inactivité
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted &&
          _slides.isNotEmpty &&
          _slidesPageController != null &&
          _slidesPageController!.hasClients) {
        _startAutoScroll();
      }
    });
  }

  void _startAutoScroll() {
    // Annuler le timer existant
    _slidesTimer?.cancel();

    // Démarrer le timer pour le défilement automatique (toutes les 3 secondes)
    _slidesTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_slidesPageController != null &&
          _slidesPageController!.hasClients &&
          _slides.isNotEmpty) {
        _currentSlideIndex = (_currentSlideIndex + 1) % _slides.length;
        _slidesPageController!.animateToPage(
          _currentSlideIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Note: didChangeAppLifecycleState removed - letting AdBanner handle its own state
  // Reload with key only happens when returning from recharge page

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryOrange,
          ),
        ),
      );
    }

    if (!authState.isAuthenticated || user == null) {
      return const LoginScreen();
    }

    // Tous les utilisateurs ont accès aux notifications
    // Le filtrage se fait dans le contenu (feedback exclu pour Pointage)
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(user),
          _buildNotificationsTab(user),
          _buildServicesTab(user),
          _buildProfileTab(user),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Consumer(
          builder: (context, ref, child) {
            final unreadCount = ref.watch(unreadNotificationCountProvider);
            final translationService = TranslationService();

            // Tous les utilisateurs ont les mêmes onglets
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });

                // Rafraîchir les notifications quand on va sur l'onglet Notifications
                if (index == 1) {
                  debugPrint(
                      '🔄 [HomePage] Rafraîchissement des notifications...');
                  ref
                      .read(notificationProvider.notifier)
                      .loadNotifications(refresh: true);
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor:
                  Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              selectedItemColor:
                  Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
              unselectedItemColor: Theme.of(context)
                  .bottomNavigationBarTheme
                  .unselectedItemColor,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_rounded),
                  activeIcon: const Icon(Icons.home),
                  label: translationService.translate('navigation.home'),
                ),
                BottomNavigationBarItem(
                  icon: _buildNotificationIcon(
                      Icons.notifications_outlined, unreadCount, false),
                  activeIcon: _buildNotificationIcon(
                      Icons.notifications, unreadCount, true),
                  label:
                      translationService.translate('navigation.notifications'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.apps_rounded),
                  activeIcon: const Icon(Icons.apps),
                  label: translationService.translate('navigation.services'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: translationService.translate('navigation.profile'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(
      IconData iconData, int unreadCount, bool isActive) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(iconData),
        if (unreadCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // Vérifier si l'utilisateur est un client
  bool _isClient(User user) {
    if (user.role != null) {
      final roleLower = user.role!.toLowerCase();
      return roleLower.contains('client');
    }

    // Vérifier via permissions
    if (user.permissions != null) {
      final hasClientPermissions = user.permissions!.any((p) =>
          p.toLowerCase().contains('loyalty') ||
          p.toLowerCase().contains('own_profile'));
      final hasAdminPermissions = user.permissions!.any((p) =>
          p.toLowerCase().contains('manage') ||
          p.toLowerCase().contains('admin'));
      return hasClientPermissions && !hasAdminPermissions;
    }

    return false;
  }

  // Vérifier si l'utilisateur est Super Admin, Admin ou Chef agence
  bool _isAdminOrChefAgence(User user) {
    if (user.role != null) {
      final roleLower = user.role!.toLowerCase();
      return roleLower.contains('super admin') ||
          roleLower.contains('super_admin') ||
          roleLower == 'admin' ||
          roleLower.contains('administrateur') ||
          roleLower.contains('chef agence') ||
          roleLower.contains('chef_agence');
    }

    // Vérifier via displayRole si présent
    if (user.displayRole != null) {
      final displayRoleLower = user.displayRole!.toLowerCase();
      return displayRoleLower.contains('super admin') ||
          displayRoleLower.contains('super_admin') ||
          displayRoleLower == 'admin' ||
          displayRoleLower.contains('administrateur') ||
          displayRoleLower.contains('chef agence') ||
          displayRoleLower.contains('chef_agence');
    }

    // Vérifier via roles list si présent
    if (user.roles != null && user.roles!.isNotEmpty) {
      return user.roles!.any((r) {
        final roleStr = r.toString().toLowerCase();
        return roleStr.contains('super admin') ||
            roleStr.contains('super_admin') ||
            roleStr == 'admin' ||
            roleStr.contains('administrateur') ||
            roleStr.contains('chef agence') ||
            roleStr.contains('chef_agence');
      });
    }

    return false;
  }

  // Vérifier si l'utilisateur est Super Admin ou Admin (pas Chef Agence)
  bool _isSuperAdminOrAdmin(User user) {
    if (user.role != null) {
      final roleLower = user.role!.toLowerCase();
      return roleLower.contains('super admin') ||
          roleLower.contains('super_admin') ||
          roleLower == 'admin' ||
          roleLower.contains('administrateur');
    }

    // Vérifier via roles list si présent
    if (user.rolesList != null && user.rolesList!.isNotEmpty) {
      return user.rolesList!.any((r) {
        final roleStr = r.toString().toLowerCase();
        return roleStr.contains('super admin') ||
            roleStr.contains('super_admin') ||
            roleStr == 'admin' ||
            roleStr.contains('administrateur');
      });
    }

    // Vérifier aussi dans roles (ancien format)
    if (user.roles != null && user.roles!.isNotEmpty) {
      return user.roles!.any((r) {
        final roleStr = r.toString().toLowerCase();
        return roleStr.contains('super admin') ||
            roleStr.contains('super_admin') ||
            roleStr == 'admin' ||
            roleStr.contains('administrateur');
      });
    }

    return false;
  }

  bool _isSuperAdminAdminOrRH(User user) {
    final roles = <String>[];
    if (user.role != null) roles.add(user.role!.toLowerCase());
    if (user.displayRole != null) roles.add(user.displayRole!.toLowerCase());
    if (user.rolesList != null) {
      roles.addAll(user.rolesList!.map((r) => r.toString().toLowerCase()));
    }
    if (user.roles != null) {
      roles.addAll(user.roles!.map((r) => r.toString().toLowerCase()));
    }
    return roles.any((r) =>
        r.contains('super admin') ||
        r.contains('super_admin') ||
        r == 'admin' ||
        r.contains('administrateur') ||
        r == 'rh' ||
        r.contains('ressources humaines'));
  }

  // Vérifier si l'utilisateur est Super Admin, Admin, Chef agence ou Accueil
  bool _canManageMessages(User user) {
    if (user.role != null) {
      final roleLower = user.role!.toLowerCase();
      return roleLower.contains('super admin') ||
          roleLower.contains('super_admin') ||
          roleLower == 'admin' ||
          roleLower.contains('administrateur') ||
          roleLower.contains('chef agence') ||
          roleLower.contains('chef_agence') ||
          roleLower.contains('accueil');
    }

    // Vérifier via displayRole si présent
    if (user.displayRole != null) {
      final displayRoleLower = user.displayRole!.toLowerCase();
      return displayRoleLower.contains('super admin') ||
          displayRoleLower.contains('super_admin') ||
          displayRoleLower == 'admin' ||
          displayRoleLower.contains('administrateur') ||
          displayRoleLower.contains('chef agence') ||
          displayRoleLower.contains('chef_agence') ||
          displayRoleLower.contains('accueil');
    }

    // Vérifier via roles list si présent
    if (user.rolesList != null && user.rolesList!.isNotEmpty) {
      return user.rolesList!.any((r) {
        final roleStr = r.toString().toLowerCase();
        return roleStr.contains('super admin') ||
            roleStr.contains('super_admin') ||
            roleStr == 'admin' ||
            roleStr.contains('administrateur') ||
            roleStr.contains('chef agence') ||
            roleStr.contains('chef_agence') ||
            roleStr.contains('accueil');
      });
    }

    // Vérifier aussi dans roles (ancien format)
    if (user.roles != null && user.roles!.isNotEmpty) {
      return user.roles!.any((r) {
        final roleStr = r.toString().toLowerCase();
        return roleStr.contains('super admin') ||
            roleStr.contains('super_admin') ||
            roleStr == 'admin' ||
            roleStr.contains('administrateur') ||
            roleStr.contains('chef agence') ||
            roleStr.contains('chef_agence') ||
            roleStr.contains('accueil');
      });
    }

    return false;
  }

  // Vérifier si l'utilisateur a le rôle PDG
  bool _isPDG(User user) {
    // Vérifier dans le rôle principal
    if (user.role != null) {
      final roleLower = user.role!.toLowerCase();
      if (roleLower == 'pdg' || roleLower.contains('directeur')) {
        return true;
      }
    }

    // Vérifier dans displayRole
    if (user.displayRole != null) {
      final displayRoleLower = user.displayRole!.toLowerCase();
      if (displayRoleLower == 'pdg' || displayRoleLower.contains('directeur')) {
        return true;
      }
    }

    // Vérifier dans la liste des rôles
    if (user.roles != null && user.roles!.isNotEmpty) {
      return user.roles!.any((r) {
        final roleStr = r.toString().toLowerCase();
        return roleStr == 'pdg' || roleStr.contains('directeur');
      });
    }

    // Vérifier dans rolesList (nouveau format)
    if (user.rolesList != null && user.rolesList!.isNotEmpty) {
      return user.rolesList!.any((r) {
        final roleStr = r.toString().toLowerCase();
        return roleStr == 'pdg' || roleStr.contains('directeur');
      });
    }

    return false;
  }

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  /// Traduire le titre et le message d'une notification basé sur son type et ses données
  Map<String, String> _translateNotification(NotificationModel notification) {
    final type = notification.type.toLowerCase();
    final data = notification.data ?? {};

    String translatedTitle = notification.title;
    String translatedMessage = notification.message;

    // Si le titre ou le message contiennent déjà des clés de traduction, les utiliser directement
    // Sinon, traduire basé sur le type

    switch (type) {
      case 'new_ticket':
      case 'ticket_created':
        translatedTitle = t('notifications.new_ticket_title');
        // Extraire les informations de route depuis les données ou le message
        String route = '';
        if (data.containsKey('destination') &&
            data.containsKey('embarquement')) {
          route = '${data['embarquement']} → ${data['destination']}';
        } else if (data.containsKey('trajet')) {
          final trajet = data['trajet'];
          if (trajet is Map) {
            route =
                '${trajet['embarquement'] ?? ''} → ${trajet['destination'] ?? ''}';
          }
        } else {
          // Essayer d'extraire depuis le message original
          final message = notification.message;
          // Pattern pour "pour Abidjan → Bouaké" ou "pour Abidjan -> Bouaké" ou "pour Abidjan → Yamoussoukro"
          // Rechercher "pour" suivi du texte jusqu'à "a été"
          final routeMatch1 =
              RegExp(r'pour\s+([^a]+?)\s+a été', caseSensitive: false)
                  .firstMatch(message);
          if (routeMatch1 != null) {
            route = routeMatch1.group(1)?.trim() ?? '';
            // Nettoyer la route (retirer les éventuels caractères indésirables)
            route = route.replaceAll(RegExp(r'\s+'), ' ').trim();
          } else {
            // Essayer de trouver directement "Ville1 → Ville2" dans le message
            final routeMatch2 = RegExp(
                    r'([A-Za-zÀ-ÿÉéèêëïîôùûüç\s-]+?)\s*→\s*([A-Za-zÀ-ÿÉéèêëïîôùûüç\s-]+)')
                .firstMatch(message);
            if (routeMatch2 != null) {
              route =
                  '${routeMatch2.group(1)?.trim()} → ${routeMatch2.group(2)?.trim()}';
            } else {
              // Essayer un pattern plus large pour trouver deux villes
              final routeMatch3 = RegExp(
                      r'([A-Z][a-zÀ-ÿéèêëïîôùûüç]+)\s*(?:→|->|-)\s*([A-Z][a-zÀ-ÿéèêëïîôùûüç]+)')
                  .firstMatch(message);
              if (routeMatch3 != null) {
                route =
                    '${routeMatch3.group(1)?.trim()} → ${routeMatch3.group(2)?.trim()}';
              } else {
                // Si on ne trouve rien, utiliser les données ou le message complet
                route = data['route']?.toString() ??
                    (message.length > 50
                        ? '${message.substring(0, 50)}...'
                        : message);
              }
            }
          }
        }
        translatedMessage = t('notifications.new_ticket_message')
            .replaceAll('{{route}}', route);
        break;

      case 'loyalty_point':
      case 'points':
      case 'loyalty':
        translatedTitle = t('notifications.loyalty_point_title');
        // Extraire le nombre de points
        int points = 1;
        if (data.containsKey('points_earned')) {
          points = int.tryParse(data['points_earned'].toString()) ?? 1;
        } else if (data.containsKey('points')) {
          points = int.tryParse(data['points'].toString()) ?? 1;
        } else {
          // Essayer d'extraire depuis le message original
          final message = notification.message;
          // Patterns pour "1 point" ou "gagné 1 point" ou "1 point de fidélité"
          final pointsMatch = RegExp(r'(\d+)\s+point').firstMatch(message);
          if (pointsMatch != null) {
            points = int.tryParse(pointsMatch.group(1) ?? '1') ?? 1;
          } else {
            // Essayer "Vous avez gagné 1 point"
            final pointsMatch2 = RegExp(r'gagné\s+(\d+)').firstMatch(message);
            if (pointsMatch2 != null) {
              points = int.tryParse(pointsMatch2.group(1) ?? '1') ?? 1;
            }
          }
        }
        translatedMessage = t('notifications.loyalty_point_message')
            .replaceAll('{{points}}', points.toString());
        break;

      case 'feedback_status':
      case 'suggestion_status':
        translatedTitle = t('notifications.feedback_status_title');
        String status = data['status']?.toString() ?? '';
        if (status.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message.toLowerCase();
          if (message.contains('approuvé') || message.contains('approved')) {
            status = t('feedback.status_approved');
          } else if (message.contains('rejeté') ||
              message.contains('rejected')) {
            status = t('feedback.status_rejected');
          } else if (message.contains('en attente') ||
              message.contains('pending')) {
            status = t('feedback.status_pending');
          } else {
            status = status.isNotEmpty ? status : 'traité';
          }
        }
        translatedMessage = t('notifications.feedback_status_message')
            .replaceAll('{{status}}', status);
        break;

      case 'promotion':
      case 'offer':
        translatedTitle = t('notifications.promotion_title');
        String promoMessage =
            data['message']?.toString() ?? notification.message;
        translatedMessage = t('notifications.promotion_message')
            .replaceAll('{{message}}', promoMessage);
        break;

      case 'reminder':
      case 'travel':
        translatedTitle = t('notifications.travel_reminder_title');
        String destination = data['destination']?.toString() ?? '';
        if (destination.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          final destMatch = RegExp(r'vers\s+(.+?)(?:\.|$)').firstMatch(message);
          if (destMatch != null) {
            destination = destMatch.group(1) ?? '';
          }
        }
        translatedMessage = t('notifications.travel_reminder_message')
            .replaceAll('{{destination}}', destination);
        break;

      case 'alert':
      case 'urgent':
        translatedTitle = t('notifications.alert_title');
        String alertMessage =
            data['message']?.toString() ?? notification.message;
        translatedMessage = t('notifications.alert_message')
            .replaceAll('{{message}}', alertMessage);
        break;

      case 'new_mail_sender':
      case 'mail_created':
        translatedTitle = t('notifications.mail_created_title');
        String destination = data['destination']?.toString() ?? '';
        String number =
            data['mail_number']?.toString() ?? data['number']?.toString() ?? '';
        if (destination.isEmpty || number.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          // Pattern pour destination: "pour Abidjan" ou "destination: Abidjan"
          final destMatch1 =
              RegExp(r'pour\s+([A-Za-zÀ-ÿÉéèêëïîôùûüç\s-]+?)(?:\s|\.|$)')
                  .firstMatch(message);
          final destMatch2 = RegExp(
                  r'destination[:\s]+([A-Za-zÀ-ÿÉéèêëïîôùûüç\s-]+?)(?:\s|\.|$)')
              .firstMatch(message);
          if (destMatch1 != null) {
            destination = destMatch1.group(1)?.trim() ?? '';
          }
          if (destination.isEmpty && destMatch2 != null) {
            destination = destMatch2.group(1)?.trim() ?? '';
          }

          // Pattern pour numéro: "Numéro: MAIL001" ou "Numéro MAIL001" ou simplement un code alphanumérique
          final numMatch1 =
              RegExp(r'Numéro[:\s]+([A-Z0-9-]+)').firstMatch(message);
          final numMatch2 = RegExp(r'([A-Z]{2,}[0-9-]+)').firstMatch(message);
          if (numMatch1 != null) {
            number = numMatch1.group(1)?.trim() ?? '';
          }
          if (number.isEmpty && numMatch2 != null) {
            number = numMatch2.group(1)?.trim() ?? '';
          }
        }
        translatedMessage = t('notifications.mail_created_message')
            .replaceAll('{{destination}}', destination)
            .replaceAll('{{number}}', number);
        break;

      case 'new_mail_recipient':
      case 'mail_received':
        translatedTitle = t('notifications.mail_received_title');
        String sender =
            data['sender']?.toString() ?? data['expediteur']?.toString() ?? '';
        String destination = data['destination']?.toString() ?? '';
        String number =
            data['mail_number']?.toString() ?? data['number']?.toString() ?? '';
        if (sender.isEmpty || destination.isEmpty || number.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          // Pattern pour expéditeur: "de Jean" ou "expéditeur: Jean" ou "Vous avez reçu un courrier de Jean"
          final senderMatch1 =
              RegExp(r'de\s+([A-Za-zÀ-ÿÉéèêëïîôùûüç\s-]+?)(?:\s+pour|\s|\.)')
                  .firstMatch(message);
          final senderMatch2 = RegExp(
                  r'expéditeur[:\s]+([A-Za-zÀ-ÿÉéèêëïîôùûüç\s-]+?)(?:\s+pour|\s|\.)')
              .firstMatch(message);
          if (senderMatch1 != null) {
            sender = senderMatch1.group(1)?.trim() ?? '';
          }
          if (sender.isEmpty && senderMatch2 != null) {
            sender = senderMatch2.group(1)?.trim() ?? '';
          }

          // Pattern pour destination
          final destMatch1 =
              RegExp(r'pour\s+([A-Za-zÀ-ÿÉéèêëïîôùûüç\s-]+?)(?:\s|\.|$)')
                  .firstMatch(message);
          final destMatch2 = RegExp(
                  r'destination[:\s]+([A-Za-zÀ-ÿÉéèêëïîôùûüç\s-]+?)(?:\s|\.|$)')
              .firstMatch(message);
          if (destMatch1 != null) {
            destination = destMatch1.group(1)?.trim() ?? '';
          }
          if (destination.isEmpty && destMatch2 != null) {
            destination = destMatch2.group(1)?.trim() ?? '';
          }

          // Pattern pour numéro
          final numMatch1 =
              RegExp(r'Numéro[:\s]+([A-Z0-9-]+)').firstMatch(message);
          final numMatch2 = RegExp(r'([A-Z]{2,}[0-9-]+)').firstMatch(message);
          if (numMatch1 != null) {
            number = numMatch1.group(1)?.trim() ?? '';
          }
          if (number.isEmpty && numMatch2 != null) {
            number = numMatch2.group(1)?.trim() ?? '';
          }
        }
        translatedMessage = t('notifications.mail_received_message')
            .replaceAll('{{sender}}', sender)
            .replaceAll('{{destination}}', destination)
            .replaceAll('{{number}}', number);
        break;

      case 'mail_collected':
        translatedTitle = t('notifications.mail_collected_title');
        String number =
            data['mail_number']?.toString() ?? data['number']?.toString() ?? '';
        if (number.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          // Pattern pour numéro de courrier: "MAIL001" ou "Numéro: MAIL001" ou "courrier MAIL001"
          final numMatch1 =
              RegExp(r'Numéro[:\s]+([A-Z0-9-]+)').firstMatch(message);
          final numMatch2 =
              RegExp(r'courrier\s+([A-Z0-9-]+)').firstMatch(message);
          final numMatch3 = RegExp(r'([A-Z]{2,}[0-9-]+)').firstMatch(message);
          if (numMatch1 != null) {
            number = numMatch1.group(1)?.trim() ?? '';
          }
          if (number.isEmpty && numMatch2 != null) {
            number = numMatch2.group(1)?.trim() ?? '';
          }
          if (number.isEmpty && numMatch3 != null) {
            number = numMatch3.group(1)?.trim() ?? '';
          }
        }
        translatedMessage = t('notifications.mail_collected_message')
            .replaceAll('{{number}}', number);
        break;

      case 'departure_time_changed':
      case 'departure_modified':
      case 'departure_updated':
        translatedTitle = t('notifications.departure_changed_title');
        String route = '';
        String time = '';
        if (data.containsKey('route')) {
          route = data['route'].toString();
        } else if (data.containsKey('embarquement') &&
            data.containsKey('destination')) {
          route = '${data['embarquement']} → ${data['destination']}';
        }
        if (data.containsKey('new_time')) {
          time = data['new_time'].toString();
        } else if (data.containsKey('heure_depart')) {
          time = data['heure_depart'].toString();
        }
        if (route.isEmpty || time.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          final routeMatch = RegExp(
                  r'pour\s+([A-Za-zÀ-ÿÉéèêëïîôùûüç\s→-]+?)(?:\s+a été|\s|\.)')
              .firstMatch(message);
          final timeMatch = RegExp(r'(\d{1,2}:\d{2})').firstMatch(message);
          if (routeMatch != null) {
            route = routeMatch.group(1)?.trim() ?? '';
          }
          if (timeMatch != null) {
            time = timeMatch.group(1)?.trim() ?? '';
          }
        }
        translatedMessage = t('notifications.departure_changed_message')
            .replaceAll('{{route}}', route)
            .replaceAll('{{time}}', time);
        break;

      case 'departure_cancelled':
        translatedTitle = t('notifications.departure_cancelled_title');
        String route = data['route']?.toString() ?? '';
        if (route.isEmpty &&
            data.containsKey('embarquement') &&
            data.containsKey('destination')) {
          route = '${data['embarquement']} → ${data['destination']}';
        }
        if (route.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          final routeMatch = RegExp(
                  r'pour\s+([A-Za-zÀ-ÿÉéèêëïîôùûüç\s→-]+?)(?:\s+a été|\s|\.)')
              .firstMatch(message);
          if (routeMatch != null) {
            route = routeMatch.group(1)?.trim() ?? '';
          }
        }
        translatedMessage = t('notifications.departure_cancelled_message')
            .replaceAll('{{route}}', route);
        break;

      case 'reservation_confirmed':
        translatedTitle = t('notifications.reservation_confirmed_title');
        String route = data['route']?.toString() ?? '';
        if (route.isEmpty &&
            data.containsKey('embarquement') &&
            data.containsKey('destination')) {
          route = '${data['embarquement']} → ${data['destination']}';
        }
        if (route.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          final routeMatch = RegExp(
                  r'pour\s+([A-Za-zÀ-ÿÉéèêëïîôùûüç\s→-]+?)(?:\s+a été|\s|\.)')
              .firstMatch(message);
          if (routeMatch != null) {
            route = routeMatch.group(1)?.trim() ?? '';
          }
        }
        translatedMessage = t('notifications.reservation_confirmed_message')
            .replaceAll('{{route}}', route);
        break;

      case 'reservation_cancelled':
        translatedTitle = t('notifications.reservation_cancelled_title');
        String route = data['route']?.toString() ?? '';
        if (route.isEmpty &&
            data.containsKey('embarquement') &&
            data.containsKey('destination')) {
          route = '${data['embarquement']} → ${data['destination']}';
        }
        if (route.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          final routeMatch = RegExp(
                  r'pour\s+([A-Za-zÀ-ÿÉéèêëïîôùûüç\s→-]+?)(?:\s+a été|\s|\.)')
              .firstMatch(message);
          if (routeMatch != null) {
            route = routeMatch.group(1)?.trim() ?? '';
          }
        }
        translatedMessage = t('notifications.reservation_cancelled_message')
            .replaceAll('{{route}}', route);
        break;

      case 'vidange_alert':
        translatedTitle = t('notifications.vidange_alert_title');
        int count = int.tryParse(data['nombre_total']?.toString() ??
                data['total_count']?.toString() ??
                '0') ??
            0;
        translatedMessage = t('notifications.vidange_alert_message')
            .replaceAll('{{count}}', count.toString());
        break;

      case 'vidange_completed':
        translatedTitle = t('notifications.vidange_completed_title');
        String bus = data['bus_immatriculation']?.toString() ??
            data['bus']?.toString() ??
            '';
        if (bus.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          final busMatch = RegExp(r'bus\s+([A-Z0-9\s-]+?)(?:\s+a été|\s|\.)')
              .firstMatch(message);
          if (busMatch != null) {
            bus = busMatch.group(1)?.trim() ?? '';
          }
        }
        translatedMessage = t('notifications.vidange_completed_message')
            .replaceAll('{{bus}}', bus);
        break;

      case 'vidange_updated':
        translatedTitle = t('notifications.vidange_updated_title');
        String bus = data['bus_immatriculation']?.toString() ??
            data['bus']?.toString() ??
            '';
        if (bus.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          final busMatch = RegExp(r'bus\s+([A-Z0-9\s-]+?)(?:\s+a été|\s|\.)')
              .firstMatch(message);
          if (busMatch != null) {
            bus = busMatch.group(1)?.trim() ?? '';
          }
        }
        translatedMessage = t('notifications.vidange_updated_message')
            .replaceAll('{{bus}}', bus);
        break;

      case 'breakdown_new':
      case 'new_breakdown':
        translatedTitle = t('notifications.breakdown_new_title');
        String bus = data['bus_immatriculation']?.toString() ??
            data['bus']?.toString() ??
            '';
        if (bus.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          final busMatch =
              RegExp(r'Bus\s+([A-Z0-9\s-]+?)(?:\s|\.| $)').firstMatch(message);
          if (busMatch != null) {
            bus = busMatch.group(1)?.trim() ?? '';
          }
        }
        translatedMessage =
            t('notifications.breakdown_new_message').replaceAll('{{bus}}', bus);
        break;

      case 'breakdown_updated':
      case 'breakdown_modified':
        translatedTitle = t('notifications.breakdown_updated_title');
        String bus = data['bus_immatriculation']?.toString() ??
            data['bus']?.toString() ??
            '';
        if (bus.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          final busMatch =
              RegExp(r'Bus\s+([A-Z0-9\s-]+?)(?:\s|\.| $)').firstMatch(message);
          if (busMatch != null) {
            bus = busMatch.group(1)?.trim() ?? '';
          }
        }
        translatedMessage = t('notifications.breakdown_updated_message')
            .replaceAll('{{bus}}', bus);
        break;

      case 'breakdown_status':
      case 'breakdown_status_changed':
        translatedTitle = t('notifications.breakdown_status_title');
        String bus = data['bus_immatriculation']?.toString() ??
            data['bus']?.toString() ??
            '';
        String status = data['status']?.toString() ?? '';
        if (bus.isEmpty || status.isEmpty) {
          // Essayer d'extraire depuis le message
          final message = notification.message;
          final busMatch =
              RegExp(r'Bus\s+([A-Z0-9\s-]+?)(?:\s|\.| $)').firstMatch(message);
          if (busMatch != null) {
            bus = busMatch.group(1)?.trim() ?? '';
          }
          // Le statut peut être dans le message
          if (status.isEmpty) {
            final statusMatch = RegExp(
                    r'statut[:\s]+([A-Za-zÀ-ÿÉéèêëïîôùûüç\s-]+?)(?:\s|\.| $)')
                .firstMatch(message);
            if (statusMatch != null) {
              status = statusMatch.group(1)?.trim() ?? '';
            }
          }
        }
        translatedMessage = t('notifications.breakdown_status_message')
            .replaceAll('{{bus}}', bus)
            .replaceAll('{{status}}', status);
        break;

      case 'message_notification':
      case 'system_message':
        translatedTitle = t('notifications.message_notification_title');
        String messageText =
            data['message']?.toString() ?? notification.message;
        translatedMessage = t('notifications.message_notification_message')
            .replaceAll('{{message}}', messageText);
        break;

      case 'system':
        translatedTitle = t('notifications.system_title');
        String messageText =
            data['message']?.toString() ?? notification.message;
        translatedMessage = t('notifications.system_message')
            .replaceAll('{{message}}', messageText);
        break;

      case 'general':
        translatedTitle = t('notifications.general_title');
        String messageText =
            data['message']?.toString() ?? notification.message;
        translatedMessage = t('notifications.general_message')
            .replaceAll('{{message}}', messageText);
        break;

      default:
        // Pour les autres types, utiliser les textes originaux ou essayer de les traduire
        // On garde les textes originaux s'ils ne correspondent à aucun type connu
        break;
    }

    return {
      'title': translatedTitle,
      'message': translatedMessage,
    };
  }

  // Vérifier si l'utilisateur a le rôle de pointage
  bool _hasAttendanceRole(User user) {
    // Les clients et admins ne sont PAS des utilisateurs pointage
    if (_isClient(user)) return false;

    // Les admins et super admins DOIVENT voir les notifications
    // Seuls les utilisateurs avec rôle UNIQUEMENT "Pointage" ne les voient pas

    // 1. Vérifier d'abord le rôle (si présent)
    if (user.role != null) {
      final roleLower = user.role!.toLowerCase();

      // Si c'est un admin ou super admin, toujours afficher les notifications
      if (roleLower.contains('admin') ||
          roleLower.contains('super') ||
          roleLower.contains('administrateur')) {
        return false; // Ne PAS cacher les notifications pour les admins
      }

      // Cacher les notifications uniquement pour les rôles de pointage
      if (roleLower.contains('pointage') ||
          roleLower.contains('attendance') ||
          roleLower.contains('employee') ||
          roleLower.contains('employé') ||
          roleLower.contains('staff')) {
        return true; // Cacher pour pointage
      }
    }

    // 2. Si pas de rôle, vérifier les permissions
    if (user.permissions != null && user.permissions!.isNotEmpty) {
      // Si l'utilisateur a des permissions admin, ne pas cacher
      for (var permission in user.permissions!) {
        final permLower = permission.toLowerCase();
        if (permLower.contains('manage_all') ||
            permLower.contains('admin') ||
            permLower.contains('super')) {
          return false; // Ne PAS cacher pour les admins
        }
      }

      // Vérifier si l'utilisateur a UNIQUEMENT des permissions de pointage
      bool hasOnlyAttendancePermissions = true;
      for (var permission in user.permissions!) {
        final permLower = permission.toLowerCase();

        // Si la permission n'est pas liée au pointage/attendance, c'est un utilisateur normal
        if (!permLower.contains('attendance') &&
            !permLower.contains('pointage') &&
            !permLower.contains('qr') &&
            !permLower.contains('scan') &&
            !permLower.contains('mark_attendance') &&
            !permLower.contains('view_own_attendance') &&
            !permLower.contains('personal_dashboard') &&
            !permLower.contains('locations')) {
          hasOnlyAttendancePermissions = false;
          break;
        }
      }

      if (hasOnlyAttendancePermissions) {
        return true; // Cacher pour pointage
      }
    }

    return false; // Par défaut, afficher les notifications
  }

  Widget _buildHomeTab(User user) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer(
        builder: (context, ref, child) {
          return RefreshIndicator(
            onRefresh: () async {
              // Rafraîchir toutes les données de la page d'accueil
              debugPrint(
                  '🔄 [HomePage] Actualisation complète de l\'onglet Accueil');

              // Liste des tâches à exécuter en parallèle
              final futures = <Future>[];

              // 1. Rafraîchir le solde
              futures.add(_loadSolde());

              // 2. Rafraîchir les slides
              futures.add(_loadSlides());

              // 3. Rafraîchir les permissions des fonctionnalités
              futures.add(
                Future(() async {
                  debugPrint(
                      '🔄 [HomePage] Actualisation des permissions des fonctionnalités');
                  // Invalider le provider pour forcer le rechargement
                  ref.invalidate(featurePermissionsProvider);
                  // Attendre que le provider se recharge en vérifiant son état
                  try {
                    await ref.read(featurePermissionsProvider.future);
                    debugPrint(
                        '✅ [HomePage] Permissions des fonctionnalités rechargées');
                  } catch (e) {
                    debugPrint(
                        '⚠️ [HomePage] Erreur lors du rechargement des permissions: $e');
                  }
                }),
              );

              // 4. Forcer le rechargement de l'AdBanner
              futures.add(
                Future(() async {
                  if (mounted) {
                    setState(() {
                      _adBannerKey++;
                      debugPrint(
                          '🔄 [HomePage] AdBanner rechargé (clé: $_adBannerKey)');
                    });
                  }
                }),
              );

              // 5. Rafraîchir le profil utilisateur (sauf pour les clients pour éviter de perdre les données client)
              // et rafraîchir les données du client si c'est un client
              futures.add(
                Future(() async {
                  final authState = ref.read(authProvider);
                  final currentUser = authState.user;

                  // Vérifier si l'utilisateur est un client
                  final isClient = currentUser != null &&
                      (currentUser.role?.toLowerCase().contains('client') ??
                          false);

                  // Pour TOUS les utilisateurs (clients et autres rôles), rafraîchir le profil utilisateur
                  debugPrint(
                      '🔄 [HomePage] Actualisation du profil utilisateur pour le rôle: ${currentUser?.role ?? "inconnu"}');
                  try {
                    await ref.read(authProvider.notifier).refreshUserProfile();
                    debugPrint('✅ [HomePage] Profil utilisateur rafraîchi');
                  } catch (e) {
                    debugPrint(
                        '⚠️ [HomePage] Erreur lors du rafraîchissement du profil: $e');
                  }

                  // Pour les clients uniquement, rafraîchir aussi les données client dans loyaltyProvider
                  if (isClient) {
                    debugPrint(
                        '🔄 [HomePage] Actualisation des données client');
                    try {
                      final loyaltyNotifier =
                          ref.read(loyaltyProvider.notifier);
                      final loyaltyState = ref.read(loyaltyProvider);

                      // Si on a déjà un client dans le state, rafraîchir ses données
                      if (loyaltyState.client?.telephone != null) {
                        await loyaltyNotifier.refreshClient();
                        debugPrint('✅ [HomePage] Données client rafraîchies');
                      } else {
                        // Sinon, vérifier les points avec le téléphone de l'utilisateur
                        final phoneNumber = currentUser.phoneNumber;
                        if (phoneNumber != null && phoneNumber.isNotEmpty) {
                          await loyaltyNotifier.checkClientPoints(phoneNumber);
                          debugPrint('✅ [HomePage] Points client vérifiés');
                        }
                      }
                    } catch (e) {
                      debugPrint(
                          '⚠️ [HomePage] Erreur lors du rafraîchissement des données client: $e');
                    }
                  }
                }),
              );

              // Exécuter toutes les tâches en parallèle
              await Future.wait(futures);

              // Attendre un peu pour que l'UI se mette à jour
              await Future.delayed(const Duration(milliseconds: 200));

              debugPrint('✅ [HomePage] Actualisation complète terminée');
            },
            color: AppTheme.primaryBlue,
            child: CustomScrollView(
              slivers: [
                // Header avec image de fond et effet parallax
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppTheme.primaryBlue,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image de fond
                        Image.asset(
                          'art.jpg',
                          fit: BoxFit.cover,
                        ),
                        // Dégradé noir transparent pour voir l'image clairement
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.5),
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                        // Contenu
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Bienvenue en haut
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t('home.welcome_to'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const Text(
                                      'ART LUXURY BUS',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                // Solde en haut à droite avec bouton recharge (affiché seulement si la fonctionnalité recharge est activée)
                                Consumer(
                                  builder: (context, ref, child) {
                                    final isRechargeEnabled = ref.watch(
                                      isFeatureEnabledProvider(
                                          FeatureCodes.recharge),
                                    );

                                    // Si la fonctionnalité recharge est désactivée, ne pas afficher le solde
                                    if (!isRechargeEnabled) {
                                      return const SizedBox.shrink();
                                    }

                                    return Align(
                                      alignment: Alignment.topRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  t('home.balance'),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.9),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                _isLoadingSolde
                                                    ? const SizedBox(
                                                        width: 12,
                                                        height: 12,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  Colors.white),
                                                        ),
                                                      )
                                                    : Text(
                                                        '${_solde.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Bouton recharger
                                          GestureDetector(
                                            onTap: () async {
                                              debugPrint(
                                                  '🔄 Navigation vers recharge du solde');
                                              final result =
                                                  await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const RechargeScreen(),
                                                ),
                                              );
                                              // Recharger le solde après retour de la page de recharge
                                              if (result == true) {
                                                _loadSolde();
                                              }
                                              // Forcer le rechargement de l'AdBanner après retour
                                              if (mounted) {
                                                setState(() {
                                                  _adBannerKey++;
                                                });
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryOrange,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.add_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                // Bonjour en bas
                                Padding(
                                  padding: const EdgeInsets.only(top: 30),
                                  child: Text(
                                    '${t("home.greeting")}, ${user.name.split(' ').first}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: const [
                    Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: LocationDisplayWidget(
                        iconColor: Colors.white,
                        textColor: Colors.white,
                        fontSize: 13,
                        showDropdownIcon: true,
                      ),
                    ),
                  ],
                ),

                // Contenu principal
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
// Barre de recherche
                        _buildSearchBar(),

                        const SizedBox(height: 12),

                        // Ad banner avec clé pour forcer le rechargement
                        AdBanner(
                            key: ValueKey('ad_banner_$_adBannerKey'),
                            height: 180),

                        const SizedBox(height: 20),

                        // Quick Actions
                        _buildQuickActions(user),

                        const SizedBox(height: 24),

                        // Section Services (affichée seulement s'il y a des services actifs)
                        Consumer(
                          builder: (context, ref, child) {
                            // Vérifier s'il y a des services actifs
                            final hasServices = _hasActiveServices(user, ref);
                            if (!hasServices) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildServicesHeader(user),
                                const SizedBox(height: 16),
                                _buildServicesCategories(user),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Section Slides
                        _buildSlidesSection(),

                        const SizedBox(height: 100), // Espace pour bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Barre de recherche moderne
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isDark ? Border.all(color: Colors.grey.shade700, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: t('home.search_placeholder'),
          hintStyle: TextStyle(
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white : AppTheme.primaryBlue,
            size: 22,
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // Quick Actions
  Widget _buildQuickActions(User user) {
    return Consumer(
      builder: (context, ref, child) {
        // Construire la liste des quick actions actives
        final List<Widget> quickActions = [];

        if (!_hasAttendanceRole(user)) {
          // Réservation
          final isReservationEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.reservation),
          );
          if (isReservationEnabled) {
            quickActions.add(
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReservationScreen(),
                    ),
                  );
                },
                child: _buildQuickActionItem(
                  icon: Icons.confirmation_number_rounded,
                  label: t('home.book'),
                  color: AppTheme.primaryBlue,
                  useWhiteBackground: true,
                ),
              ),
            );
          }

          // Mes Trajets
          final isMyTripsEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.myTrips),
          );
          if (isMyTripsEnabled) {
            quickActions.add(
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyTripsScreen(),
                    ),
                  );
                },
                child: _buildQuickActionItem(
                  icon: Icons.history_rounded,
                  label: t('home.my_trips'),
                  color: AppTheme.primaryOrange,
                ),
              ),
            );
          }

          // Info
          final isInfoEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.info),
          );
          if (isInfoEnabled) {
            quickActions.add(
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyInfoScreen(),
                    ),
                  );
                },
                child: _buildQuickActionItem(
                  icon: Icons.info_rounded,
                  label: t('home.info'),
                  color: Colors.blue,
                ),
              ),
            );
          }
        }

        // Si aucune action active, ne pas afficher la section du tout
        if (quickActions.isEmpty) {
          return const SizedBox.shrink();
        }

        // Afficher le container avec les actions actives
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.1),
                AppTheme.primaryOrange.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: quickActions,
          ),
        );
      },
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    bool useWhiteBackground = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = useWhiteBackground && isDark
        ? Colors.white
        : (isDark ? color.withValues(alpha: 0.15) : Colors.white);
    final iconColor = useWhiteBackground && isDark
        ? color
        : (isDark ? color.withValues(alpha: 0.9) : color);
    final borderColor = useWhiteBackground && isDark
        ? color.withValues(alpha: 0.3)
        : (isDark ? color.withValues(alpha: 0.4) : Colors.transparent);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  // Header Section Services
  // Helper pour vérifier s'il y a des services actifs
  bool _hasActiveServices(User user, WidgetRef ref) {
    if (_isClient(user)) {
      return ref.watch(isFeatureEnabledProvider(FeatureCodes.reservation)) ||
          ref.watch(isFeatureEnabledProvider(FeatureCodes.loyalty)) ||
          ref.watch(isFeatureEnabledProvider(FeatureCodes.mail)) ||
          ref.watch(isFeatureEnabledProvider(FeatureCodes.feedback));
    } else if (_hasAttendanceRole(user)) {
      // Pour pointage: Scanner et Historique sont toujours disponibles
      // + Fidélité et Feedback si activés
      return true; // Scanner et Historique sont toujours disponibles
    } else {
      // Admin - toujours au moins les horaires et vidéos
      return true;
    }
  }

  Widget _buildServicesHeader(User user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('home.our_services'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t('home.everything_you_need'),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            setState(() {
              // Index 2 pour tous (Services)
              _currentIndex = 2;
            });
          },
          child: Row(
            children: [
              Text(
                t('home.see_all'),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesCategories(User user) {
    return Consumer(
      builder: (context, ref, child) {
        // Construire la liste des services actifs
        final List<Widget> services = [];

        if (_isClient(user)) {
          // Réservation
          final isReservationEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.reservation),
          );
          if (isReservationEnabled) {
            services.add(
              _buildServiceIcon(
                icon: Icons.confirmation_number_rounded,
                label: t('home.book'),
                color: AppTheme.primaryBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReservationScreen(),
                    ),
                  );
                },
              ),
            );
          }

          // Programme de Fidélité
          final isLoyaltyEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.loyalty),
          );
          if (isLoyaltyEnabled) {
            services.add(
              _buildServiceIcon(
                icon: Icons.card_giftcard_rounded,
                label: t('services.loyalty'),
                color: const Color(0xFF9333EA),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoyaltyHomeScreen(),
                    ),
                  );
                },
              ),
            );
          }

          // Courrier
          final isMailEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.mail),
          );
          if (isMailEnabled) {
            services.add(
              _buildServiceIcon(
                icon: Icons.local_shipping_rounded,
                label: t('services.mail'),
                color: AppTheme.primaryOrange,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MyMailsScreen(),
                    ),
                  );
                },
              ),
            );
          }

          // Feedback
          final isFeedbackEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.feedback),
          );
          if (isFeedbackEnabled) {
            services.add(
              _buildServiceIcon(
                icon: Icons.feedback_rounded,
                label: t('services.feedback'),
                color: const Color(0xFF14B8A6),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FeedbackScreen(),
                    ),
                  );
                },
              ),
            );
          }
        } else if (_hasAttendanceRole(user)) {
          // Scanner QR Code (toujours disponible pour pointage)
          services.add(
            _buildServiceIcon(
              icon: Icons.qr_code_scanner_rounded,
              label: t('services.qr_scanner'),
              color: const Color(0xFF9333EA),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QrScannerScreen(),
                  ),
                );
              },
            ),
          );

          // Historique de pointage (toujours disponible pour pointage)
          services.add(
            _buildServiceIcon(
              icon: Icons.history_rounded,
              label: t('services.history'),
              color: AppTheme.primaryOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceHistoryScreen(),
                  ),
                );
              },
            ),
          );

          // Programme de Fidélité
          final isLoyaltyEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.loyalty),
          );
          if (isLoyaltyEnabled) {
            services.add(
              _buildServiceIcon(
                icon: Icons.card_giftcard_rounded,
                label: t('services.loyalty'),
                color: const Color(0xFF9333EA),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoyaltyHomeScreen(),
                    ),
                  );
                },
              ),
            );
          }

          // Feedback
          final isFeedbackEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.feedback),
          );
          if (isFeedbackEnabled) {
            services.add(
              _buildServiceIcon(
                icon: Icons.feedback_rounded,
                label: t('services.feedback'),
                color: const Color(0xFF14B8A6),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FeedbackScreen(),
                    ),
                  );
                },
              ),
            );
          }
        } else {
          // INTERFACE ADMIN
          // Gestion des Bus
          final isBusManagementEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.busManagement),
          );
          if (isBusManagementEnabled) {
            services.add(
              _buildServiceIcon(
                icon: Icons.directions_bus_rounded,
                label: t('services.bus_management'),
                color: AppTheme.primaryBlue,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BusDashboardScreen(),
                    ),
                  );
                },
              ),
            );
          }

          // Programme de Fidélité
          final isLoyaltyEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.loyalty),
          );
          if (isLoyaltyEnabled) {
            services.add(
              _buildServiceIcon(
                icon: Icons.card_giftcard_rounded,
                label: t('services.loyalty'),
                color: const Color(0xFF9333EA),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoyaltyHomeScreen(),
                    ),
                  );
                },
              ),
            );
          }

          // Courrier
          final isMailEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.mail),
          );
          if (isMailEnabled) {
            services.add(
              _buildServiceIcon(
                icon: Icons.local_shipping_rounded,
                label: t('services.mail'),
                color: AppTheme.primaryOrange,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MyMailsScreen(),
                    ),
                  );
                },
              ),
            );
          }

          // Horaires (toujours disponible pour admin)
          services.add(
            _buildServiceIcon(
              icon: Icons.schedule_rounded,
              label: t('services.schedules'),
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HorairesListScreen(),
                  ),
                );
              },
            ),
          );

          // Feedback
          final isFeedbackEnabled = ref.watch(
            isFeatureEnabledProvider(FeatureCodes.feedback),
          );
          if (isFeedbackEnabled) {
            services.add(
              _buildServiceIcon(
                icon: Icons.feedback_rounded,
                label: t('services.feedback'),
                color: const Color(0xFF14B8A6),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FeedbackScreen(),
                    ),
                  );
                },
              ),
            );
          }

          // Vidéos (toujours disponible pour admin)
          services.add(
            _buildServiceIcon(
              icon: Icons.video_library_rounded,
              label: 'Mes Vidéos',
              color: const Color(0xFFE91E63),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VideoAdvertisementsScreen(),
                  ),
                );
              },
            ),
          );
        }

        // Si aucun service actif, ne pas afficher la grille
        if (services.isEmpty) {
          return const SizedBox.shrink();
        }

        // Adapter le nombre de colonnes selon le nombre de services
        // Minimum 2 colonnes pour un meilleur rendu visuel, maximum 4 colonnes
        final crossAxisCount = services.length <= 2
            ? services.length
            : (services.length <= 4 ? services.length : 4);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          children: services,
        );
      },
    );
  }

  // Attendance-specific widget removed; use _buildAttendanceServices instead
  Widget _buildServiceIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Section Slides
  Widget _buildSlidesSection() {
    if (_isLoadingSlides) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryOrange,
          ),
        ),
      );
    }

    if (_slides.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _slidesPageController,
            itemCount: _slides.length,
            onPageChanged: _onSlideChanged,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return GestureDetector(
                onTap: _onSlideTapped,
                child: _buildSlideCard(slide),
              );
            },
          ),
        ),
        // Indicateurs de pagination
        if (_slides.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentSlideIndex == index
                        ? AppTheme.primaryBlue
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSlideCard(Slide slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image du slide
            Image.network(
              slide.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // NOTE: role-specific content is provided via the section builders

  // Role-specific content removed: services are now built via section builders

  // Old feature card helper removed in favor of modern service card

  String _getRoleDisplayName(String? role) {
    if (role == null) return t('common.user');

    final roleMap = {
      'admin': t('common.administrator'),
      'administrateur': t('common.administrator'),
      'manager': t('common.manager'),
      'gestionnaire': t('common.manager'),
      'driver': t('common.driver'),
      'chauffeur': t('common.driver'),
      'agent': t('common.agent'),
      'employe': t('common.employee'),
      'user': t('common.client'),
      'client': t('common.client'),
    };

    return roleMap[role.toLowerCase()] ?? t('common.user');
  }

  Widget _buildNotificationsTab(User user) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t('notifications.title')),
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final notificationState = ref.watch(notificationProvider);
              // Afficher les boutons seulement s'il y a des notifications
              if (notificationState.notifications.isEmpty) {
                return const SizedBox.shrink();
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton pour marquer toutes comme lues (toujours visible s'il y a des notifications)
                  IconButton(
                    icon: const Icon(Icons.mark_email_read),
                    onPressed: () {
                      ref.read(notificationProvider.notifier).markAllAsRead();
                    },
                    tooltip: t('notifications.mark_all_read'),
                  ),
                  // Bouton pour supprimer toutes les notifications
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      // Afficher une boîte de dialogue de confirmation
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                t('notifications.delete_all_confirmation')),
                            content: Text(
                              t('notifications.delete_all_message'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(t('notifications.cancel')),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: Text(t('notifications.delete')),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldDelete == true) {
                        if (!mounted) return;

                        // Capturer après vérification de mounted
                        // ignore: use_build_context_synchronously
                        final navigator = Navigator.of(context);
                        // ignore: use_build_context_synchronously
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        // Afficher un indicateur de chargement
                        showDialog(
                          // ignore: use_build_context_synchronously
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        );

                        // Supprimer toutes les notifications
                        await ref
                            .read(notificationProvider.notifier)
                            .deleteAllNotifications();

                        // Fermer l'indicateur de chargement
                        if (mounted) {
                          navigator.pop();
                        }

                        // Vérifier le résultat et afficher un message
                        if (mounted) {
                          final notificationState =
                              ref.read(notificationProvider);

                          if (notificationState.error != null) {
                            // Afficher un message d'erreur
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(notificationState.error ??
                                    t('notifications.delete_error')),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            // Recharger les notifications depuis le serveur pour synchroniser
                            await ref
                                .read(notificationProvider.notifier)
                                .refresh();

                            // Afficher un message de succès
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(t('notifications.all_deleted')),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      }
                    },
                    tooltip: t('notifications.delete_all'),
                  ),
                  if (_isSuperAdminAdminOrRH(user))
                    IconButton(
                      icon: const Icon(Icons.work_outline),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const JobApplicationsListScreen(),
                          ),
                        );
                      },
                      tooltip: 'Voir demandes d\'emploi',
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final notificationState = ref.watch(notificationProvider);

          // Filtrer les notifications de feedback pour les clients et utilisateurs pointage
          final filteredNotifications =
              (_isClient(user) || _hasAttendanceRole(user))
                  ? notificationState.notifications.where((notif) {
                      // Exclure UNIQUEMENT les notifications de type feedback/suggestion
                      // NE PAS filtrer les notifications de type 'notification', 'message_notification' ou 'new_job_application'
                      final shouldInclude = notif.type != 'feedback' &&
                          notif.type != 'suggestion' &&
                          notif.type != 'new_feedback' &&
                          notif.type != 'urgent_feedback';

                      // Log pour debug
                      if (!shouldInclude) {
                        debugPrint(
                            '🔔 [FILTRE] Notification exclue: type=${notif.type}, titre=${notif.title}');
                      } else {
                        debugPrint(
                            '✅ [FILTRE] Notification incluse: type=${notif.type}, titre=${notif.title}');
                      }

                      return shouldInclude;
                    }).toList()
                  : notificationState.notifications;

          // Log pour debug
          debugPrint(
              '🔔 [FILTRE] Total notifications: ${notificationState.notifications.length}');
          debugPrint(
              '🔔 [FILTRE] Notifications filtrées: ${filteredNotifications.length}');
          debugPrint('🔔 [FILTRE] Est client: ${_isClient(user)}');
          debugPrint(
              '🔔 [FILTRE] A rôle pointage: ${_hasAttendanceRole(user)}');
          if (notificationState.notifications.isNotEmpty) {
            debugPrint(
                '🔔 [FILTRE] Types de notifications: ${notificationState.notifications.map((n) => n.type).toSet().join(", ")}');
          }

          if (notificationState.isLoading &&
              notificationState.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryOrange,
              ),
            );
          }

          if (notificationState.error != null &&
              notificationState.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    notificationState.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(notificationProvider.notifier).refresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(t('notifications.try_again')),
                  ),
                ],
              ),
            );
          }

          if (filteredNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('notifications.none'),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('notifications.none_message'),
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(notificationProvider.notifier).refresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(t('common.refresh')),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
            color: AppTheme.primaryOrange,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredNotifications.length +
                  (notificationState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredNotifications.length) {
                  // Bouton "Charger plus"
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: notificationState.isLoading
                          ? const CircularProgressIndicator(
                              color: AppTheme.primaryOrange,
                            )
                          : ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(notificationProvider.notifier)
                                    .loadMore();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppTheme.primaryOrange
                                    : AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(t('common.load_more')),
                            ),
                    ),
                  );
                }

                final notification = filteredNotifications[index];
                return _buildDynamicNotificationCard(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDynamicNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              t('notifications.delete'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Afficher une confirmation avant de supprimer
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t('notifications.delete_notification'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  t('notifications.delete_notification_message')
                      .replaceAll('{{title}}', notification.title),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      t('auth.cancel'),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Supprimer',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        // Supprimer la notification
        ref
            .read(notificationProvider.notifier)
            .deleteNotification(notification.id);

        // Attendre un peu avant d'afficher le SnackBar
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notification supprimée',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      },
      child: Builder(
        builder: (context) {
          final primaryColor = _getNotificationPrimaryColor(context);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                  : primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notification.isRead
                    ? Theme.of(context).dividerColor.withValues(alpha: 0.3)
                    : primaryColor.withValues(alpha: 0.3),
                width: notification.isRead ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              onTap: () {
                // Marquer comme lu avant d'ouvrir
                if (!notification.isRead) {
                  ref
                      .read(notificationProvider.notifier)
                      .markAsRead(notification.id);
                }

                // Ouvrir l'écran de détail
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationDetailScreen(
                      notification: notification,
                    ),
                  ),
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationTypeColor(notification.type, context)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationTypeIcon(notification.type),
                  color: _getNotificationTypeColor(notification.type, context),
                  size: 20,
                ),
              ),
              title: Builder(
                builder: (context) {
                  final translated = _translateNotification(notification);
                  return Text(
                    translated['title'] ?? notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                },
              ),
              subtitle: Builder(
                builder: (context) {
                  final translated = _translateNotification(notification);
                  return Text(
                    translated['message'] ?? notification.message,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Badge de priorité
                  if (notification.data != null &&
                      notification.data!['priority'] != null)
                    _buildPriorityBadge(
                        notification.data!['priority'].toString()),

                  Text(
                    notification.getTimeAgo(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getNotificationPrimaryColor(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'new_ticket':
      case 'ticket_created':
        return Icons.confirmation_number;
      case 'new_mail_sender':
      case 'new_mail_recipient':
      case 'mail_created':
      case 'mail_received':
      case 'mail_collected':
        return Icons.mail;
      case 'loyalty_point':
      case 'loyalty':
      case 'points':
        return Icons.card_giftcard;
      case 'new_feedback':
        return Icons.feedback_outlined;
      case 'feedback_status':
        return Icons.update;
      case 'promotion':
      case 'offer':
        return Icons.local_offer;
      case 'reminder':
      case 'travel':
      case 'departure_time_changed':
      case 'departure_modified':
      case 'departure_updated':
        return Icons.schedule;
      case 'alert':
      case 'urgent':
        return Icons.warning_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  // Fonction helper pour obtenir la couleur primaire selon le thème
  // Orange en mode dark, bleu en mode light
  Color _getNotificationPrimaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue;
  }

  Color _getNotificationTypeColor(String type, BuildContext context) {
    final primaryColor = _getNotificationPrimaryColor(context);

    switch (type.toLowerCase()) {
      case 'new_ticket':
      case 'ticket_created':
        return primaryColor;
      case 'new_mail_sender':
      case 'new_mail_recipient':
      case 'mail_created':
      case 'mail_received':
      case 'mail_collected':
        return primaryColor;
      case 'loyalty_point':
      case 'loyalty':
      case 'points':
        return Colors.amber;
      case 'new_feedback':
        return primaryColor;
      case 'feedback_status':
        return Colors.orange;
      case 'promotion':
      case 'offer':
        return Colors.purple;
      case 'reminder':
      case 'travel':
      case 'departure_time_changed':
      case 'departure_modified':
      case 'departure_updated':
        return Colors.green;
      case 'alert':
      case 'urgent':
        return Colors.red;
      default:
        return primaryColor;
    }
  }

  Widget _buildPriorityBadge(String priority) {
    Color badgeColor;
    String badgeText;

    switch (priority.toLowerCase()) {
      case 'high':
      case 'haute':
      case 'urgent':
        badgeColor = Colors.red;
        badgeText = 'URGENT';
        break;
      case 'medium':
      case 'moyenne':
      case 'moyen':
        badgeColor = Colors.amber;
        badgeText = 'MOYEN';
        break;
      case 'low':
      case 'basse':
      case 'faible':
        badgeColor = Colors.green;
        badgeText = 'FAIBLE';
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'NORMAL';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildServicesTab(User user) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('common.services')),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.primaryOrange
            : AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                    AppTheme.primaryOrange.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('home.all_our_services'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('home.discover_services'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Grille de services en 2 colonnes
            Consumer(
              builder: (context, ref, child) {
                return _buildServicesGrid(user, ref);
              },
            ),

            const SizedBox(height: 100), // Espace pour bottom nav
          ],
        ),
      ),
    );
  }

  // Grille de services compacte
  Widget _buildServicesGrid(User user, WidgetRef ref) {
    final services = _getServicesForUser(user, ref);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildCompactServiceCard(
          icon: service['icon'],
          title: service['title'],
          subtitle: service['subtitle'],
          color: service['color'],
          onTap: service['onTap'],
        );
      },
    );
  }

  // Liste des services selon le rôle et les permissions
  List<Map<String, dynamic>> _getServicesForUser(User user, WidgetRef ref) {
    List<Map<String, dynamic>> services = [];

    // Récupérer les permissions actuelles
    final permissionsAsync = ref.watch(featurePermissionsProvider);
    final permissions = permissionsAsync.value?.permissions ?? [];

    // Helper pour vérifier si une fonctionnalité est activée
    bool isFeatureEnabled(String featureCode) {
      final permission = permissions.firstWhere(
        (p) => p.featureCode == featureCode,
        orElse: () => FeaturePermission(
          featureCode: featureCode,
          featureName: '',
          category: 'general',
          isEnabled: false,
          requiresAdmin: false,
        ),
      );
      return permission.isEnabled;
    }

    // Soumettre ma candidature (visible pour tous)
    services.add({
      'icon': Icons.work_outline,
      'title': 'Soumettre ma candidature',
      'subtitle': 'Lettre de motivation et CV (PDF)',
      'color': AppTheme.primaryBlue,
      'onTap': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const JobApplicationFormScreen(),
          ),
        );
      },
    });

    // Programme de Fidélité
    if (isFeatureEnabled(FeatureCodes.loyalty)) {
      services.add({
        'icon': Icons.card_giftcard_rounded,
        'title': t('services.loyalty_program'),
        'subtitle': t('services.loyalty_subtitle'),
        'color': const Color(0xFF9333EA),
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LoyaltyHomeScreen())),
      });
    }

    // Feedback
    if (isFeatureEnabled(FeatureCodes.feedback)) {
      services.add({
        'icon': Icons.feedback_rounded,
        'title': t('services.suggestions'),
        'subtitle': t('services.suggestions_subtitle'),
        'color': const Color(0xFF14B8A6),
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const FeedbackScreen())),
      });
    }

    if (_hasAttendanceRole(user)) {
      services.add({
        'icon': Icons.qr_code_scanner_rounded,
        'title': t('services.qr_scanner'),
        'subtitle': t('services.qr_scanner_subtitle'),
        'color': const Color(0xFF9333EA),
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const QrScannerScreen())),
      });
      services.add({
        'icon': Icons.history_rounded,
        'title': t('services.history'),
        'subtitle': t('services.attendance_history'),
        'color': AppTheme.primaryOrange,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen())),
      });
    } else if (_isAdminOrChefAgence(user)) {
      // Seulement pour Super Admin, Admin et Chef agence
      // Gestion des Bus
      if (isFeatureEnabled(FeatureCodes.busManagement)) {
        services.add({
          'icon': Icons.directions_bus_rounded,
          'title': t('services.bus_management'),
          'subtitle': t('services.bus_fleet'),
          'color': AppTheme.primaryBlue,
          'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BusDashboardScreen())),
        });
      }

      // Horaires (toujours disponible pour admin)
      services.add({
        'icon': Icons.schedule_rounded,
        'title': t('services.schedules'),
        'subtitle': t('services.view_schedules'),
        'color': const Color(0xFF10B981),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HorairesListScreen(),
            ),
          );
        },
      });

      // Messages & Annonces (Super Admin, Admin, Chef agence et Accueil)
      if (_canManageMessages(user)) {
        services.add({
          'icon': Icons.message_rounded,
          'title': 'Messages & Annonces',
          'subtitle': 'Créer et gérer les notifications et annonces',
          'color': AppTheme.primaryOrange,
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MessageManagementScreen(),
              ),
            );
          },
        });
      }

      // Courrier
      if (isFeatureEnabled(FeatureCodes.mail)) {
        services.add({
          'icon': Icons.local_shipping_rounded,
          'title': t('services.mail'),
          'subtitle': t('services.my_mails'),
          'color': AppTheme.primaryOrange,
          'onTap': () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MyMailsScreen(),
              ),
            );
          },
        });
      }

      // Vidéos (toujours disponible pour admin)

      services.add({
        'icon': Icons.video_library_rounded,
        'title': t('services.videos'),
        'subtitle': t('services.manage_videos'),
        'color': const Color(0xFFE91E63),
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const VideoAdvertisementsScreen(),
            ),
          );
        },
      });

      // Réservation
      if (isFeatureEnabled(FeatureCodes.reservation)) {
        services.add({
          'icon': Icons.confirmation_number_rounded,
          'title': t('services.reservation'),
          'subtitle': t('services.book_trip'),
          'color': AppTheme.primaryBlue,
          'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ReservationScreen())),
        });
      }

      // Mes Trajets
      if (isFeatureEnabled(FeatureCodes.myTrips)) {
        services.add({
          'icon': Icons.history_rounded,
          'title': t('services.my_trips'),
          'subtitle': t('services.view_trips'),
          'color': AppTheme.primaryOrange,
          'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MyTripsScreen())),
        });
      }

      // Courrier
      if (isFeatureEnabled(FeatureCodes.mail)) {
        services.add({
          'icon': Icons.local_shipping_rounded,
          'title': t('services.mail'),
          'subtitle': t('services.my_mails'),
          'color': AppTheme.primaryOrange,
          'onTap': () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MyMailsScreen(),
              ),
            );
          },
        });
      }

      // Recharge (si activée)
      if (isFeatureEnabled(FeatureCodes.recharge)) {
        services.add({
          'icon': Icons.account_balance_wallet_rounded,
          'title': t('services.recharge'),
          'subtitle': t('services.recharge_subtitle'),
          'color': const Color(0xFF10B981),
          'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RechargeScreen())),
        });
      }
    }

    // Pour les utilisateurs clients (pas Accueil/Admin)
    if (!_hasAttendanceRole(user) && !_isAdminOrChefAgence(user)) {
      if (isFeatureEnabled(FeatureCodes.reservation)) {
        services.add({
          'icon': Icons.confirmation_number_rounded,
          'title': t('services.reservation'),
          'subtitle': t('services.book_trip'),
          'color': AppTheme.primaryBlue,
          'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ReservationScreen())),
        });
      }
      if (isFeatureEnabled(FeatureCodes.myTrips)) {
        services.add({
          'icon': Icons.history_rounded,
          'title': t('services.my_trips'),
          'subtitle': t('services.view_trips'),
          'color': AppTheme.primaryOrange,
          'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MyTripsScreen())),
        });
      }
      if (isFeatureEnabled(FeatureCodes.mail)) {
        services.add({
          'icon': Icons.local_shipping_rounded,
          'title': t('services.mail'),
          'subtitle': t('services.my_mails'),
          'color': AppTheme.primaryOrange,
          'onTap': () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MyMailsScreen(),
              ),
            );
          },
        });
      }
      if (isFeatureEnabled(FeatureCodes.recharge)) {
        services.add({
          'icon': Icons.account_balance_wallet_rounded,
          'title': t('services.recharge'),
          'subtitle': t('services.recharge_subtitle'),
          'color': const Color(0xFF10B981),
          'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RechargeScreen())),
        });
      }
    }
    return services;
  }

  // Carte de service compacte
  Widget _buildCompactServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(User user) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header compact et moderne
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryBlue,
                      AppTheme.primaryBlue.withValues(alpha: 0.8),
                      AppTheme.primaryOrange.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Cercles décoratifs
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    // Contenu du profil
                    SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Photo de profil compacte
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditProfileScreen(),
                                    ),
                                  );
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 35,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.2),
                                      backgroundImage: user.profilePhotoUrl !=
                                              null
                                          ? NetworkImage(user.profilePhotoUrl!)
                                          : null,
                                      child: user.profilePhotoUrl == null
                                          ? Text(
                                              user.name.isNotEmpty
                                                  ? user.name[0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryOrange,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _getRoleDisplayName(user.role),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final locale = ref.watch(languageProvider);
                final translationNotifier =
                    ref.read(translationLoadingProvider.notifier);
                final translationService =
                    translationNotifier.translationService;

                // S'assurer que les traductions sont chargées pour cette langue actuelle
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  translationNotifier.loadTranslations(locale);
                });

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Dashboard (Super Admin, Admin et PDG uniquement)
                      if (_isSuperAdminOrAdmin(user) || _isPDG(user)) ...[
                        _buildProfileSection(
                          title: 'Tableau de bord',
                          icon: Icons.dashboard_rounded,
                          options: [
                            _buildModernProfileOption(
                              icon: Icons.dashboard_outlined,
                              title: 'Dashboard Administrateur',
                              subtitle:
                                  'Statistiques et rapports en temps réel',
                              color: AppTheme.primaryBlue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminDashboardScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section Laisser-passer (Super Admin et Admin uniquement)
                      if (_isSuperAdminOrAdmin(user)) ...[
                        _buildProfileSection(
                          title: 'Laisser-passer',
                          icon: Icons.local_offer_rounded,
                          options: [
                            _buildModernProfileOption(
                              icon: Icons.local_offer_outlined,
                              title: 'Gérer les codes promotionnels',
                              subtitle: 'Créer et gérer les laisser-passer',
                              color: AppTheme.primaryOrange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PromoCodeManagementScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section Gestion des dépenses (Super Admin et Admin uniquement)
                      if (_isSuperAdminOrAdmin(user)) ...[
                        _buildProfileSection(
                          title: 'Gestion des dépenses',
                          icon: Icons.receipt_long_rounded,
                          options: [
                            _buildModernProfileOption(
                              icon: Icons.receipt_long_outlined,
                              title: 'Liste des dépenses',
                              subtitle:
                                  'Voir toutes les dépenses et valider/rejeter',
                              color: Colors.blue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ExpenseManagementScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildModernProfileOption(
                              icon: Icons.pending_actions,
                              title: 'Dépenses en attente',
                              subtitle:
                                  'Valider ou rejeter les dépenses en attente',
                              color: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ExpenseManagementScreen(
                                            showPendingOnly: true),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section Recrutement
                      _buildProfileSection(
                        title: 'Recrutement',
                        icon: Icons.work_outline,
                        options: [
                          if (_isSuperAdminAdminOrRH(user))
                            _buildModernProfileOption(
                              icon: Icons.list_alt,
                              title: 'Liste des candidatures',
                              subtitle: 'Voir toutes les demandes d\'emploi',
                              color: AppTheme.primaryOrange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const JobApplicationsListScreen(),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section Compte
                      _buildProfileSection(
                        title:
                            translationService.translate('profile.my_account'),
                        icon: Icons.person_rounded,
                        options: [
                          _buildModernProfileOption(
                            icon: Icons.person_outline,
                            title: translationService
                                .translate('profile.personal_info'),
                            subtitle: translationService
                                .translate('profile.edit_data'),
                            color: AppTheme.primaryBlue,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          _buildModernProfileOption(
                            icon: Icons.security_rounded,
                            title: translationService
                                .translate('profile.security'),
                            subtitle: translationService
                                .translate('profile.password_security'),
                            color: Colors.green,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SecurityScreen(),
                                ),
                              );
                            },
                          ),
                          _buildModernProfileOption(
                            icon: Icons.delete_forever,
                            title: 'Supprimer mon compte',
                            subtitle: 'Cette action est irréversible',
                            color: Colors.red,
                            onTap: () async {
                              final passwordController =
                                  TextEditingController();
                              final confirmController = TextEditingController();
                              final isDark = Theme.of(context).brightness ==
                                  Brightness.dark;

                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Supprimer mon compte'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Veuillez saisir votre mot de passe et taper "DELETE" pour confirmer.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: passwordController,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Mot de passe',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: confirmController,
                                        decoration: const InputDecoration(
                                          labelText: 'Confirmation',
                                          hintText: 'Tapez DELETE',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (passwordController.text
                                                .trim()
                                                .isEmpty ||
                                            confirmController.text
                                                .trim()
                                                .isEmpty) {
                                          ScaffoldMessenger.of(dialogContext)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Veuillez remplir tous les champs.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        if (confirmController.text.trim() !=
                                            'DELETE') {
                                          ScaffoldMessenger.of(dialogContext)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Veuillez taper "DELETE" pour confirmer la suppression.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        Navigator.pop(dialogContext, true);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true && context.mounted) {
                                // Afficher le loader
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (dialogContext) => const PopScope(
                                    canPop: false,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                );

                                try {
                                  debugPrint('📡 [DELETE] Appel API...');
                                  final authService = AuthService();
                                  final result =
                                      await authService.deleteAccount(
                                    password: passwordController.text.trim(),
                                    confirmation: confirmController.text.trim(),
                                  );

                                  debugPrint('📥 [DELETE] Result: $result');
                                  debugPrint(
                                      '🔍 [DELETE] success=${result['success']}');

                                  if (context.mounted) {
                                    Navigator.pop(context); // fermer le loader
                                  }

                                  // Vérifier si la suppression a réussi
                                  if (result['success'] == true) {
                                    debugPrint(
                                        '✅ [DELETE] Suppression réussie - Déconnexion...');
                                    await ref
                                        .read(authProvider.notifier)
                                        .logout();
                                    debugPrint('🚪 [DELETE] Logout terminé');

                                    debugPrint(
                                        '🧑 [DELETE] Navigation vers Login');
                                    if (context.mounted) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  } else {
                                    // Afficher l'erreur sans déconnecter
                                    debugPrint(
                                        '❌ [DELETE] Échec: ${result['message']}');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(result['message'] ??
                                              'Erreur lors de la suppression du compte'),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e, stackTrace) {
                                  debugPrint('🔥 [DELETE] Exception: $e');
                                  debugPrint('🔥 [DELETE] Stack: $stackTrace');

                                  if (context.mounted) {
                                    Navigator.pop(context); // fermer le loader
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Erreur: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Section Préférences (seulement pour non-pointeurs)
                      if (!_hasAttendanceRole(user)) ...[
                        _buildProfileSection(
                          title: translationService
                              .translate('profile.preferences'),
                          icon: Icons.settings_rounded,
                          options: [
                            _buildModernProfileOption(
                              icon: Icons.campaign_rounded,
                              title: translationService
                                  .translate('profile.voice_announcements'),
                              subtitle: translationService
                                  .translate('profile.announcement_config'),
                              color: Colors.deepPurple,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const VoiceSettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildModernProfileOption(
                              icon: Icons.palette_outlined,
                              title: translationService
                                  .translate('profile.appearance'),
                              subtitle: translationService
                                  .translate('profile.theme_description'),
                              color: Colors.amber,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ThemeSettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            Consumer(
                              builder: (context, ref, child) {
                                final locale = ref.watch(languageProvider);
                                final languageNotifier =
                                    ref.read(languageProvider.notifier);
                                final languageName =
                                    languageNotifier.getDisplayName(locale);

                                return _buildModernProfileOption(
                                  icon: Icons.language_rounded,
                                  title: translationService
                                      .translate('profile.language'),
                                  subtitle: languageName,
                                  color: Colors.purple,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LanguageSettingsScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section Support
                      _buildProfileSection(
                        title: translationService.translate('profile.support'),
                        icon: Icons.help_center_rounded,
                        options: [
                          _buildModernProfileOption(
                            icon: Icons.help_outline,
                            title: translationService
                                .translate('profile.help_support'),
                            subtitle: translationService
                                .translate('profile.contact_team'),
                            color: Colors.teal,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const FeedbackScreen(),
                                ),
                              );
                            },
                          ),
                          _buildModernProfileOption(
                            icon: Icons.info_outline,
                            title:
                                translationService.translate('profile.about'),
                            subtitle: translationService
                                .translate('profile.about_info'),
                            color: Colors.indigo,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AboutScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Bouton de déconnexion compact
                      _buildLogoutButton(),

                      const SizedBox(height: 80), // Espace pour bottom nav
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Section de profil compacte
  Widget _buildProfileSection({
    required String title,
    required IconData icon,
    required List<Widget> options,
  }) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.orange : AppTheme.primaryBlue;
    final backgroundColor = isDark
        ? Colors.orange.withValues(alpha: 0.1)
        : AppTheme.primaryBlue.withValues(alpha: 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...options,
      ],
    );
  }

  // Option de profil compacte
  Widget _buildModernProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.color
              ?.withValues(alpha: 0.5),
        ),
        onTap: onTap,
      ),
    );
  }

  // Bouton de déconnexion compact
  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            // Afficher une confirmation
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  t('auth.logout_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  t('auth.logout_message'),
                  style: const TextStyle(fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      t('auth.cancel'),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      t('auth.logout_button'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );

            if (shouldLogout == true) {
              await ref.read(authProvider.notifier).logout();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.red[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  t('auth.logout'),
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
