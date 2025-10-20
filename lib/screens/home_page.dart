import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../services/notification_service.dart';
import '../services/feedback_api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_api_service.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import 'notification_detail_screen.dart';
import 'loyalty_home_screen.dart';
import 'auth/login_screen.dart';
import 'feedback_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
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
          
          // Charger les notifications
          ref.read(notificationProvider.notifier).loadNotifications(refresh: true);
        }
        
        // Obtenir et enregistrer le token FCM
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
      }
    });
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

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(user),
          _buildNotificationsTab(),
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
            
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppTheme.primaryBlue,
              unselectedItemColor: Colors.grey[600],
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
                  icon: _buildNotificationIcon(Icons.notifications_outlined, unreadCount, false),
                  activeIcon: _buildNotificationIcon(Icons.notifications, unreadCount, true),
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

  Widget _buildNotificationIcon(IconData iconData, int unreadCount, bool isActive) {
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

  Widget _buildHomeTab(User user) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header moderne avec couleurs Art Luxury Bus
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.primaryBlue.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Barre du haut avec menu et profil
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Côte d\'Ivoire',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Message de bienvenue
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bienvenue !',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Où souhaitez-vous voyager aujourd\'hui ?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catégories de services
                    _buildServicesCategories(),
                    
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

  Widget _buildServicesCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catégories de Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.85,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            _buildServiceIcon(
              icon: Icons.directions_bus,
              label: 'Voyages',
              color: AppTheme.primaryBlue,
              onTap: () {
                // TODO: Navigation vers voyages
              },
            ),
            _buildServiceIcon(
              icon: Icons.card_giftcard,
              label: 'Fidélité',
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoyaltyHomeScreen(),
                  ),
                );
              },
            ),
            _buildServiceIcon(
              icon: Icons.local_shipping,
              label: 'Courrier',
              color: AppTheme.primaryOrange,
              onTap: () {
                // TODO: Navigation vers courrier
              },
            ),
            _buildServiceIcon(
              icon: Icons.schedule,
              label: 'Horaires',
              color: Colors.green,
              onTap: () {
                // TODO: Navigation vers horaires
              },
            ),
            _buildServiceIcon(
              icon: Icons.feedback,
              label: 'Suggestions',
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),
            _buildServiceIcon(
              icon: Icons.location_on,
              label: 'Gares',
              color: Colors.red,
              onTap: () {
                // TODO: Navigation vers gares
              },
            ),
            _buildServiceIcon(
              icon: Icons.payment,
              label: 'Paiement',
              color: Colors.indigo,
              onTap: () {
                // TODO: Navigation vers paiement
              },
            ),
            _buildServiceIcon(
              icon: Icons.more_horiz,
              label: 'Plus',
              color: Colors.grey,
              onTap: () {
                setState(() {
                  _currentIndex = 2; // Aller vers l'onglet Services
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }












  Widget _buildRoleBasedContent(BuildContext context, User user) {
    final role = user.role?.toLowerCase() ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos fonctionnalités',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        
        // Contenu spécifique par rôle
        if (role.contains('admin') || role.contains('administrateur'))
          _buildAdminContent(context)
        else if (role.contains('manager') || role.contains('gestionnaire'))
          _buildManagerContent(context)
        else if (role.contains('driver') || role.contains('chauffeur'))
          _buildDriverContent(context)
        else if (role.contains('agent') || role.contains('employe'))
          _buildAgentContent(context)
        else
          _buildDefaultUserContent(context),
      ],
    );
  }

  Widget _buildAdminContent(BuildContext context) {
    return Column(
      children: [
        _buildFeatureCard(
          icon: Icons.dashboard,
          title: 'Tableau de bord Admin',
          subtitle: 'Vue d\'ensemble complète du système',
          color: AppTheme.primaryBlue,
          onTap: () {
            // TODO: Navigation vers admin dashboard
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.people,
          title: 'Gestion des utilisateurs',
          subtitle: 'Gérer les comptes et les rôles',
          color: AppTheme.primaryOrange,
          onTap: () {
            // TODO: Navigation vers gestion utilisateurs
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.directions_bus,
          title: 'Gestion des véhicules',
          subtitle: 'Gérer la flotte de bus',
          color: Colors.green,
          onTap: () {
            // TODO: Navigation vers gestion véhicules
          },
        ),
      ],
    );
  }

  Widget _buildManagerContent(BuildContext context) {
    return Column(
      children: [
        _buildFeatureCard(
          icon: Icons.schedule,
          title: 'Planification des trajets',
          subtitle: 'Organiser les horaires et itinéraires',
          color: AppTheme.primaryBlue,
          onTap: () {
            // TODO: Navigation vers planification
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.assignment,
          title: 'Rapports de gestion',
          subtitle: 'Consulter les statistiques',
          color: AppTheme.primaryOrange,
          onTap: () {
            // TODO: Navigation vers rapports
          },
        ),
      ],
    );
  }

  Widget _buildDriverContent(BuildContext context) {
    return Column(
      children: [
        _buildFeatureCard(
          icon: Icons.map,
          title: 'Mes trajets',
          subtitle: 'Voir mes trajets assignés',
          color: AppTheme.primaryBlue,
          onTap: () {
            // TODO: Navigation vers trajets chauffeur
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.checklist,
          title: 'État du véhicule',
          subtitle: 'Signaler l\'état du bus',
          color: Colors.green,
          onTap: () {
            // TODO: Navigation vers état véhicule
          },
        ),
      ],
    );
  }

  Widget _buildAgentContent(BuildContext context) {
    return Column(
      children: [
        _buildFeatureCard(
          icon: Icons.confirmation_number,
          title: 'Vente de billets',
          subtitle: 'Gérer les ventes et réservations',
          color: AppTheme.primaryBlue,
          onTap: () {
            // TODO: Navigation vers vente billets
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.support_agent,
          title: 'Service client',
          subtitle: 'Assistance et support',
          color: AppTheme.primaryOrange,
          onTap: () {
            // TODO: Navigation vers service client
          },
        ),
      ],
    );
  }

  Widget _buildDefaultUserContent(BuildContext context) {
    return Column(
      children: [
        _buildFeatureCard(
          icon: Icons.search,
          title: 'Rechercher un trajet',
          subtitle: 'Trouver et réserver vos billets',
          color: AppTheme.primaryBlue,
          onTap: () {
            // TODO: Navigation vers recherche trajets
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.history,
          title: 'Mes réservations',
          subtitle: 'Historique de vos voyages',
          color: AppTheme.primaryOrange,
          onTap: () {
            // TODO: Navigation vers réservations
          },
        ),
      ],
    );
  }


  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

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

  Widget _buildNotificationsTab() {
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
              if (notificationState.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: () {
                    ref.read(notificationProvider.notifier).markAllAsRead();
                  },
                  tooltip: 'Tout marquer comme lu',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final notificationState = ref.watch(notificationProvider);

          if (notificationState.isLoading && notificationState.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryBlue,
              ),
            );
          }

          if (notificationState.error != null && notificationState.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    notificationState.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
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

          if (notificationState.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous n\'avez pas encore reçu de notifications',
                    style: TextStyle(
                      color: Colors.grey[500],
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
              itemCount: notificationState.notifications.length + 
                         (notificationState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == notificationState.notifications.length) {
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
                              ref.read(notificationProvider.notifier).loadMore();
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

                final notification = notificationState.notifications[index];
                return _buildDynamicNotificationCard(notification);
              },
            ),
          );
        },
      ),
    );
  }


  Widget _buildDynamicNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead 
          ? Colors.white 
          : AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        onTap: () {
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
            color: _getNotificationTypeColor(notification.type).withValues(alpha: 0.1),
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
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
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
            if (notification.data != null && notification.data!['priority'] != null)
              _buildPriorityBadge(notification.data!['priority'].toString()),
            
            Text(
              notification.getTimeAgo(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
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
            color: badgeColor.withOpacity(0.3),
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
            const Text(
              'Tous nos services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Services basés sur le rôle
            _buildRoleBasedContent(context, user),
            
            const SizedBox(height: 24),
            
            // Services communs
            const Text(
              'Services généraux',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              icon: Icons.card_giftcard,
              title: 'Programme Fidélité',
              subtitle: 'Cumulez des points et obtenez des avantages',
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoyaltyHomeScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.feedback,
              title: 'Suggestions & Préoccupations',
              subtitle: 'Partagez vos idées et signalez vos problèmes',
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.support,
              title: 'Support & Aide',
              subtitle: 'Contactez notre équipe de support',
              color: Colors.orange,
              onTap: () {
                // TODO: Navigation vers support
              },
            ),
            
            const SizedBox(height: 100), // Espace pour la bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(User user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigation vers édition profil
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Photo de profil et infos
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getRoleDisplayName(user.role),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Options du profil
            _buildProfileOption(
              icon: Icons.person,
              title: 'Informations personnelles',
              onTap: () {
                // TODO: Navigation vers infos personnelles
              },
            ),
            _buildProfileOption(
              icon: Icons.security,
              title: 'Sécurité et mot de passe',
              onTap: () {
                // TODO: Navigation vers sécurité
              },
            ),
            _buildProfileOption(
              icon: Icons.notifications,
              title: 'Préférences de notification',
              onTap: () {
                // TODO: Navigation vers préférences
              },
            ),
            _buildProfileOption(
              icon: Icons.help,
              title: 'Aide et support',
              onTap: () {
                // TODO: Navigation vers aide
              },
            ),
            _buildProfileOption(
              icon: Icons.info,
              title: 'À propos',
              onTap: () {
                // TODO: Navigation vers à propos
              },
            ),
            
            const SizedBox(height: 24),
            
            // Bouton de déconnexion
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 100), // Espace pour la bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
