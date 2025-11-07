import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin/horaires_list_screen.dart';
import 'admin/video_advertisements_screen.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
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
import '../models/feature_permission_model.dart';
import '../providers/feature_permission_provider.dart';

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

  /// Mettre à jour le contexte pour le gestionnaire d'annonces vocales
  void _updateVoiceAnnouncementsContext() {
    try {
      debugPrint(
          '🔊 [HomePage] Mise à jour du contexte pour les annonces vocales...');
      // Définir le contexte pour l'affichage des annonces
      if (mounted) {
        AnnouncementManager().setContext(context);
        debugPrint(
            '✅ [HomePage] Contexte mis à jour pour les annonces vocales');
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Ne pas forcer le rechargement automatique - laisser l'AdBanner gérer sa propre reprise
    // Le rechargement avec la clé se fait uniquement quand on revient de la page de recharge
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: _buildNotificationIcon(
                      Icons.notifications_outlined, unreadCount, false),
                  activeIcon: _buildNotificationIcon(
                      Icons.notifications, unreadCount, true),
                  label: 'Notifications',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.apps_rounded),
                  activeIcon: Icon(Icons.apps),
                  label: 'Services',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
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

  /// Vérifier si une fonctionnalité est activée pour l'utilisateur
  /// Retourne true par défaut si les permissions ne sont pas encore chargées (pour éviter de cacher les fonctionnalités pendant le chargement)
  bool _isFeatureEnabled(WidgetRef ref, String featureCode) {
    try {
      final permissionsAsync = ref.read(featurePermissionsProvider);

      return permissionsAsync.when(
        data: (response) {
          final permission = response.permissions.firstWhere(
            (p) => p.featureCode == featureCode,
            orElse: () => FeaturePermission(
              featureCode: featureCode,
              featureName: '',
              category: 'general',
              isEnabled: true, // Par défaut activé si non trouvé
              requiresAdmin: false,
            ),
          );
          return permission.isEnabled;
        },
        loading: () =>
            true, // Par défaut activé pendant le chargement pour éviter de cacher les fonctionnalités
        error: (error, stackTrace) {
          debugPrint(
              '⚠️ [HomePage] Erreur vérification permission $featureCode: $error');
          // En cas d'erreur, retourner true par défaut pour ne pas bloquer l'utilisateur
          return true;
        },
      );
    } catch (e) {
      debugPrint(
          '⚠️ [HomePage] Exception vérification permission $featureCode: $e');
      // Par défaut, retourner true si erreur pour ne pas bloquer l'utilisateur
      return true;
    }
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
      body: RefreshIndicator(
        onRefresh: () async {
          // Rafraîchir les données de l'utilisateur
          debugPrint('🔄 [HomePage] Actualisation de l\'onglet Accueil');
          await _loadSolde();
          await _loadSlides();
          await Future.delayed(const Duration(milliseconds: 500));
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
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bienvenue à',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
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
                            // Solde en haut à droite avec bouton recharge
                            Align(
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
                                      color:
                                          Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Solde : ',
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
                                                          Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                '${_solde.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
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
                                      final result = await Navigator.push(
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
                                      setState(() {
                                        _adBannerKey++;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryOrange,
                                        borderRadius: BorderRadius.circular(8),
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
                            ),
                            // Bonjour en bas
                            Padding(
                              padding: const EdgeInsets.only(top: 30),
                              child: Text(
                                'Bonjour, ${user.name.split(' ').first}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.95),
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
                        key: ValueKey('ad_banner_$_adBannerKey'), height: 180),

                    const SizedBox(height: 20),

                    // Quick Actions
                    _buildQuickActions(user),

                    const SizedBox(height: 24),

                    // Section Services
                    _buildServicesHeader(user),

                    const SizedBox(height: 16),

                    // Catégories de services
                    _buildServicesCategories(user),

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
          hintText: 'Rechercher un trajet, une ville...',
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
        children: [
          if (!_hasAttendanceRole(user)) ...[
            if (_isFeatureEnabled(ref, FeatureCodes.reservation))
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
                  label: 'Réserver',
                  color: AppTheme.primaryBlue,
                  useWhiteBackground: true,
                ),
              ),
            if (_isFeatureEnabled(ref, FeatureCodes.mesTrajets))
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
                  label: 'Mes trajets',
                  color: AppTheme.primaryOrange,
                ),
              ),
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
                label: 'Info',
                color: Colors.blue,
              ),
            ),
          ],
          if (_hasAttendanceRole(user)) ...[
            if (_isFeatureEnabled(ref, FeatureCodes.qrScanner))
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const QrScannerScreen(),
                    ),
                  );
                },
                child: _buildQuickActionItem(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scanner',
                  color: Colors.purple,
                ),
              ),
            if (_isFeatureEnabled(ref, FeatureCodes.attendanceHistory))
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AttendanceHistoryScreen(),
                    ),
                  );
                },
                child: _buildQuickActionItem(
                  icon: Icons.history_rounded,
                  label: 'Historique',
                  color: AppTheme.primaryOrange,
                ),
              ),
            _buildQuickActionItem(
              icon: Icons.access_time_rounded,
              label: 'Statut',
              color: AppTheme.primaryBlue,
            ),
          ],
        ],
      ),
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
  Widget _buildServicesHeader(User user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nos Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tout ce dont vous avez besoin',
              style: TextStyle(
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
                'Voir tout',
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
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      crossAxisSpacing: 12,
      mainAxisSpacing: 16,
      children: [
        // INTERFACE CLIENT - Services spécifiques aux clients
        if (_isClient(user)) ...[
          if (_isFeatureEnabled(ref, FeatureCodes.reservation))
            _buildServiceIcon(
              icon: Icons.confirmation_number_rounded,
              label: 'Réserver',
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
          if (_isFeatureEnabled(ref, FeatureCodes.loyalty))
            _buildServiceIcon(
              icon: Icons.card_giftcard_rounded,
              label: 'Fidélité',
              color: const Color(0xFF9333EA),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoyaltyHomeScreen(),
                  ),
                );
              },
            ),
          if (_isFeatureEnabled(ref, FeatureCodes.courrier))
            _buildServiceIcon(
              icon: Icons.local_shipping_rounded,
              label: 'Courrier',
              color: AppTheme.primaryOrange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyMailsScreen(),
                  ),
                );
              },
            ),
          if (_isFeatureEnabled(ref, FeatureCodes.feedback))
            _buildServiceIcon(
              icon: Icons.feedback_rounded,
              label: 'Feedback',
              color: const Color(0xFF14B8A6),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),
        ]
        // INTERFACE POINTAGE - Fidélité et Feedback uniquement
        else if (_hasAttendanceRole(user)) ...[
          if (_isFeatureEnabled(ref, FeatureCodes.loyalty))
            _buildServiceIcon(
              icon: Icons.card_giftcard_rounded,
              label: 'Fidélité',
              color: const Color(0xFF9333EA),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoyaltyHomeScreen(),
                  ),
                );
              },
            ),
          if (_isFeatureEnabled(ref, FeatureCodes.feedback))
            _buildServiceIcon(
              icon: Icons.feedback_rounded,
              label: 'Feedback',
              color: const Color(0xFF14B8A6),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),
        ]
        // INTERFACE ADMIN - Tous les services
        else ...[
          if (_isFeatureEnabled(ref, FeatureCodes.busManagement))
            _buildServiceIcon(
              icon: Icons.directions_bus_rounded,
              label: 'Gestion Bus',
              color: AppTheme.primaryBlue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BusDashboardScreen(),
                  ),
                );
              },
            ),
          if (_isFeatureEnabled(ref, FeatureCodes.loyalty))
            _buildServiceIcon(
              icon: Icons.card_giftcard_rounded,
              label: 'Fidélité',
              color: const Color(0xFF9333EA),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoyaltyHomeScreen(),
                  ),
                );
              },
            ),
          if (_isFeatureEnabled(ref, FeatureCodes.courrier))
            _buildServiceIcon(
              icon: Icons.local_shipping_rounded,
              label: 'Courrier',
              color: AppTheme.primaryOrange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyMailsScreen(),
                  ),
                );
              },
            ),
          if (_isFeatureEnabled(ref, FeatureCodes.horaires))
            _buildServiceIcon(
              icon: Icons.schedule_rounded,
              label: 'Horaires',
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
          if (_isFeatureEnabled(ref, FeatureCodes.feedback))
            _buildServiceIcon(
              icon: Icons.feedback_rounded,
              label: 'Feedback',
              color: const Color(0xFF14B8A6),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),
          if (_isFeatureEnabled(ref, FeatureCodes.gares))
            _buildServiceIcon(
              icon: Icons.location_on_rounded,
              label: 'Gares',
              color: const Color(0xFFEF4444),
              onTap: () {
                // TODO: Navigation vers gares
              },
            ),
          if (_isFeatureEnabled(ref, FeatureCodes.payment))
            _buildServiceIcon(
              icon: Icons.payment_rounded,
              label: 'Paiement',
              color: const Color(0xFF6366F1),
              onTap: () {
                // TODO: Navigation vers paiement
              },
            ),
          if (_isFeatureEnabled(ref, FeatureCodes.videoAdvertisements))
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
          _buildServiceIcon(
            icon: Icons.apps_rounded,
            label: 'Plus',
            color: const Color(0xFF64748B),
            onTap: () {
              setState(() {
                // Index 2 pour tous (Services)
                _currentIndex = 2;
              });
            },
          ),
        ],
      ],
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
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_slides.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Slides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
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
            // Dégradé pour le texte
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  slide.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
    if (role == null) return 'Utilisateur';

    final roleMap = {
      'admin': 'Administrateur',
      'administrateur': 'Administrateur',
      'manager': 'Gestionnaire',
      'gestionnaire': 'Gestionnaire',
      'driver': 'Chauffeur',
      'chauffeur': 'Chauffeur',
      'agent': 'Agent',
      'employe': 'Employé',
      'user': 'Client',
      'client': 'Client',
    };

    return roleMap[role.toLowerCase()] ?? 'Utilisateur';
  }

  Widget _buildNotificationsTab(User user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
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
                    tooltip: 'Tout marquer comme lu',
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
                            title: const Text(
                                'Supprimer toutes les notifications'),
                            content: const Text(
                              'Êtes-vous sûr de vouloir supprimer toutes vos notifications ? Cette action est irréversible.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldDelete == true && mounted) {
                        // Afficher un indicateur de chargement
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        // Supprimer toutes les notifications
                        await ref
                            .read(notificationProvider.notifier)
                            .deleteAllNotifications();

                        // Fermer l'indicateur de chargement
                        if (mounted) {
                          Navigator.of(context).pop();
                        }

                        // Vérifier le résultat et afficher un message
                        if (mounted) {
                          final notificationState = ref.read(notificationProvider);
                          
                          if (notificationState.error != null) {
                            // Afficher un message d'erreur
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(notificationState.error ?? 'Erreur lors de la suppression'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            // Recharger les notifications depuis le serveur pour synchroniser
                            await ref.read(notificationProvider.notifier).refresh();
                            
                            // Afficher un message de succès
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Toutes les notifications ont été supprimées'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      }
                    },
                    tooltip: 'Supprimer toutes les notifications',
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
                      // Exclure les notifications de type feedback/suggestion
                      return notif.type != 'feedback' &&
                          notif.type != 'suggestion' &&
                          notif.type != 'new_feedback' &&
                          notif.type != 'urgent_feedback';
                    }).toList()
                  : notificationState.notifications;

          if (notificationState.isLoading &&
              notificationState.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryBlue,
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
                    child: const Text('Réessayer'),
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
                    'Aucune notification',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous n\'avez pas encore reçu de notifications',
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
                    child: const Text('Actualiser'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
            color: AppTheme.primaryBlue,
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
                              color: AppTheme.primaryBlue,
                            )
                          : ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(notificationProvider.notifier)
                                    .loadMore();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Charger plus'),
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Supprimer',
              style: TextStyle(
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
                    const Text(
                      'Supprimer notification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Voulez-vous vraiment supprimer cette notification ?\n\n"${notification.title}"',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Annuler',
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Theme.of(context).cardColor.withValues(alpha: 0.5)
              : AppTheme.primaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
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
              color: _getNotificationTypeColor(notification.type)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getNotificationTypeIcon(notification.type),
              color: _getNotificationTypeColor(notification.type),
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.w500 : FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            notification.message,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Badge de priorité
              if (notification.data != null &&
                  notification.data!['priority'] != null)
                _buildPriorityBadge(notification.data!['priority'].toString()),

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
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'new_feedback':
        return Icons.feedback_outlined;
      case 'feedback_status':
        return Icons.update;
      case 'promotion':
      case 'offer':
        return Icons.local_offer;
      case 'reminder':
      case 'travel':
        return Icons.schedule;
      case 'loyalty':
      case 'points':
        return Icons.card_giftcard;
      case 'alert':
      case 'urgent':
        return Icons.warning_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'new_feedback':
        return Colors.blue;
      case 'feedback_status':
        return Colors.orange;
      case 'promotion':
      case 'offer':
        return Colors.purple;
      case 'reminder':
      case 'travel':
        return Colors.green;
      case 'loyalty':
      case 'points':
        return Colors.amber;
      case 'alert':
      case 'urgent':
        return Colors.red;
      default:
        return AppTheme.primaryBlue;
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
        title: const Text('Services'),
        backgroundColor: AppTheme.primaryBlue,
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
                    'Tous nos services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Découvrez tout ce que nous pouvons faire pour vous',
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
            _buildServicesGrid(user),

            const SizedBox(height: 100), // Espace pour bottom nav
          ],
        ),
      ),
    );
  }

  // Grille de services compacte
  Widget _buildServicesGrid(User user) {
    final services = _getServicesForUser(user);

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
  List<Map<String, dynamic>> _getServicesForUser(User user) {
    List<Map<String, dynamic>> services = [];

    // Services communs (toujours disponibles si permissions activées)
    if (_isFeatureEnabled(ref, FeatureCodes.loyalty)) {
      services.add({
        'icon': Icons.card_giftcard_rounded,
        'title': 'Programme Fidélité',
        'subtitle': 'Cumulez des points et avantages',
        'color': const Color(0xFF9333EA),
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LoyaltyHomeScreen())),
      });
    }

    if (_isFeatureEnabled(ref, FeatureCodes.feedback)) {
      services.add({
        'icon': Icons.feedback_rounded,
        'title': 'Suggestions',
        'subtitle': 'Partagez vos idées',
        'color': const Color(0xFF14B8A6),
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const FeedbackScreen())),
      });
    }

    if (_hasAttendanceRole(user)) {
      if (_isFeatureEnabled(ref, FeatureCodes.qrScanner)) {
        services.add({
          'icon': Icons.qr_code_scanner_rounded,
          'title': 'Scanner QR',
          'subtitle': 'Pointage rapide',
          'color': const Color(0xFF9333EA),
          'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const QrScannerScreen())),
        });
      }
      if (_isFeatureEnabled(ref, FeatureCodes.attendanceHistory)) {
        services.add({
          'icon': Icons.history_rounded,
          'title': 'Historique',
          'subtitle': 'Vos pointages',
          'color': AppTheme.primaryOrange,
          'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AttendanceHistoryScreen())),
        });
      }
    } else if (_isAdminOrChefAgence(user)) {
      // Seulement pour Super Admin, Admin et Chef agence
      if (_isFeatureEnabled(ref, FeatureCodes.busManagement)) {
        services.add({
          'icon': Icons.directions_bus_rounded,
          'title': 'Gestion Bus',
          'subtitle': 'Flotte et maintenance',
          'color': AppTheme.primaryBlue,
          'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BusDashboardScreen())),
        });
      }
      if (_isFeatureEnabled(ref, FeatureCodes.horaires)) {
        services.add({
          'icon': Icons.schedule_rounded,
          'title': 'Horaires',
          'subtitle': 'Consulter les horaires',
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
      }
      if (_isFeatureEnabled(ref, FeatureCodes.courrier)) {
        services.add({
          'icon': Icons.local_shipping_rounded,
          'title': 'Courrier',
          'subtitle': 'Mes courriers',
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
      if (_isFeatureEnabled(ref, FeatureCodes.videoAdvertisements)) {
        services.add({
          'icon': Icons.video_library_rounded,
          'title': 'Mes Vidéos',
          'subtitle': 'Gérer les vidéos publicitaires',
          'color': const Color(0xFFE91E63),
          'onTap': () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const VideoAdvertisementsScreen(),
              ),
            );
          },
        });
      }
    } else if (_isClient(user)) {
      // Services pour les clients
      if (_isFeatureEnabled(ref, FeatureCodes.reservation)) {
        services.add({
          'icon': Icons.confirmation_number_rounded,
          'title': 'Réserver',
          'subtitle': 'Réserver un trajet',
          'color': AppTheme.primaryBlue,
          'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ReservationScreen())),
        });
      }
      if (_isFeatureEnabled(ref, FeatureCodes.mesTrajets)) {
        services.add({
          'icon': Icons.history_rounded,
          'title': 'Mes Trajets',
          'subtitle': 'Voir mes réservations',
          'color': AppTheme.primaryOrange,
          'onTap': () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MyTripsScreen())),
        });
      }
      if (_isFeatureEnabled(ref, FeatureCodes.courrier)) {
        services.add({
          'icon': Icons.local_shipping_rounded,
          'title': 'Courrier',
          'subtitle': 'Mes courriers',
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
      if (_isFeatureEnabled(ref, FeatureCodes.payment)) {
        services.add({
          'icon': Icons.payment_rounded,
          'title': 'Paiement',
          'subtitle': 'Effectuer un paiement',
          'color': const Color(0xFF6366F1),
          'onTap': () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paiement - En développement')),
            );
          },
        });
      }
    }

    // Service d'aide toujours disponible
    if (_isFeatureEnabled(ref, FeatureCodes.support)) {
      services.add({
        'icon': Icons.help_center_rounded,
        'title': 'Aide',
        'subtitle': 'Centre d\'aide',
        'color': const Color(0xFF8B5CF6),
        'onTap': () {}, // TODO: Navigation
      });
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Compte
                  _buildProfileSection(
                    title: 'Mon Compte',
                    icon: Icons.person_rounded,
                    options: [
                      _buildModernProfileOption(
                        icon: Icons.person_outline,
                        title: 'Informations personnelles',
                        subtitle: 'Modifier vos données',
                        color: AppTheme.primaryBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                      _buildModernProfileOption(
                        icon: Icons.security_rounded,
                        title: 'Sécurité',
                        subtitle: 'Mot de passe et sécurité',
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
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section Préférences (seulement pour non-pointeurs)
                  if (!_hasAttendanceRole(user)) ...[
                    _buildProfileSection(
                      title: 'Préférences',
                      icon: Icons.settings_rounded,
                      options: [
                        _buildModernProfileOption(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Gérer vos alertes',
                          color: AppTheme.primaryOrange,
                          onTap: () {},
                        ),
                        _buildModernProfileOption(
                          icon: Icons.campaign_rounded,
                          title: 'Annonces Vocales',
                          subtitle: 'Configuration des annonces',
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
                          title: 'Apparence',
                          subtitle: 'Thème clair, sombre ou système',
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
                        _buildModernProfileOption(
                          icon: Icons.language_rounded,
                          title: 'Langue',
                          subtitle: 'Français',
                          color: Colors.purple,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Section Support
                  _buildProfileSection(
                    title: 'Support',
                    icon: Icons.help_center_rounded,
                    options: [
                      _buildModernProfileOption(
                        icon: Icons.help_outline,
                        title: 'Aide et support',
                        subtitle: 'Contactez notre équipe',
                        color: Colors.teal,
                        onTap: () {},
                      ),
                      _buildModernProfileOption(
                        icon: Icons.info_outline,
                        title: 'À propos',
                        subtitle: 'Infos appareil & version',
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      // Outils de débogage (visible uniquement en mode debug)
                      if (kDebugMode)
                        _buildModernProfileOption(
                          icon: Icons.bug_report,
                          title: 'Outils de débogage',
                          subtitle: 'Tester les notifications et annonces',
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange
                              : Colors.blue,
                          onTap: () {
                            Navigator.pushNamed(context, '/debug');
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
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryBlue,
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
                title: const Text(
                  'Déconnexion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text(
                  'Êtes-vous sûr de vouloir vous déconnecter ?',
                  style: TextStyle(fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Annuler',
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
                      'Déconnecter',
                      style: TextStyle(fontWeight: FontWeight.w600),
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
                  'Se déconnecter',
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
