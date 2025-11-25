import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mail_model.dart';
import '../services/mail_api_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_indicator.dart';
import '../theme/app_theme.dart';
import 'mail_detail_screen.dart';
import 'create_mail_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MailManagementScreen extends ConsumerStatefulWidget {
  const MailManagementScreen({super.key});

  @override
  ConsumerState<MailManagementScreen> createState() =>
      _MailManagementScreenState();
}

class _MailManagementScreenState extends ConsumerState<MailManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MailDashboard? _dashboard;
  bool _isLoadingDashboard = true;
  String? _dashboardError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });

    try {
      final dashboard = await MailApiService.getDashboard();
      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _isLoadingDashboard = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _dashboardError = e.toString();
        _isLoadingDashboard = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Fermer le clavier quand on tape en dehors des champs
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        drawer: _buildDrawer(context),
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.primaryOrange
              : AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          title: const Text(
            'Gestion des Courriers',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.dashboard, size: 22), text: 'Stats'),
              Tab(icon: Icon(Icons.pending_actions, size: 22), text: 'Attente'),
              Tab(icon: Icon(Icons.check_circle, size: 22), text: 'Collectés'),
              Tab(icon: Icon(Icons.list, size: 22), text: 'Tous'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboardTab(),
            _buildMailListTab(
                isCollected: false, tabController: _tabController),
            _buildMailListTab(isCollected: true, tabController: _tabController),
            _buildMailListTab(tabController: _tabController),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateMailScreen(),
              ),
            );
            if (result == true) {
              _loadDashboard();
            }
          },
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const Icon(Icons.add, size: 28),
          label: const Text(
            'Nouveau Courrier',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppTheme.primaryOrange,
                        AppTheme.primaryOrange.withValues(alpha: 0.8)
                      ]
                    : [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlue.withValues(alpha: 0.8)
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.name ?? '').isNotEmpty
                    ? user!.name.substring(0, 1).toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            accountName: Text(
              user?.name ?? 'Utilisateur',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Mon Profil',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showProfileDialog(context);
            },
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: Icon(
              Icons.lock,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              'Changer mot de passe',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showChangePasswordDialog(context);
            },
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Se déconnecter',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    final user = ref.read(authProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Mon Profil',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileItem('Nom', user?.name ?? 'N/A'),
            const SizedBox(height: 12),
            _buildProfileItem('Email', user?.email ?? 'N/A'),
            const SizedBox(height: 12),
            _buildProfileItem('Téléphone', user?.phoneNumber ?? 'N/A'),
            const SizedBox(height: 12),
            _buildProfileItem('Rôle', user?.role ?? 'Agent'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.6) ??
                Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          title: Text(
            'Changer le mot de passe',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color:
                        isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.lock,
                    color:
                        isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.lock,
                    color:
                        isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
                  ),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Les mots de passe ne correspondent pas'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final authService = AuthService();
                        final result = await authService.changePassword(
                          currentPassword: currentPasswordController.text,
                          newPassword: newPasswordController.text,
                          newPasswordConfirmation:
                              confirmPasswordController.text,
                        );

                        if (context.mounted) {
                          if (result['success'] == true) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ??
                                    'Mot de passe changé avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ??
                                    'Erreur lors du changement'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: LoadingIndicator(strokeWidth: 2),
                    )
                  : const Text('Changer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Déconnexion',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_isLoadingDashboard) {
      return const CenteredLoadingIndicator();
    }

    if (_dashboardError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_dashboardError!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_dashboard == null) {
      return Center(
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsPeriodCard('Aujourd\'hui', _dashboard!.today),
          const SizedBox(height: 16),
          _buildStatsPeriodCard('Cette semaine', _dashboard!.week),
          const SizedBox(height: 16),
          _buildStatsPeriodCard('Ce mois', _dashboard!.month),
          const SizedBox(height: 24),
          _buildTopDestinations(),
          const SizedBox(height: 24),
          _buildPendingMailsSection(),
          const SizedBox(height: 24),
          _buildRecentCollectionsSection(),
        ],
      ),
    );
  }

  Widget _buildStatsPeriodCard(String title, DashboardPeriod period) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final primaryColor = isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cardColor,
          gradient: isDark
              ? null
              : LinearGradient(
                  colors: [primaryColor.withValues(alpha: 0.1), cardColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.mail,
                  'Total',
                  period.total.toString(),
                  primaryColor,
                ),
                _buildStatItem(
                  Icons.check_circle,
                  'Collectés',
                  period.collected.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.pending,
                  'En attente',
                  period.pending.toString(),
                  Colors.orange,
                ),
              ],
            ),
            Divider(
              height: 24,
              color: Theme.of(context).dividerColor,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${NumberFormat('#,###', 'fr_FR').format(period.revenue)} FCFA',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.6) ??
                Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTopDestinations() {
    if (_dashboard!.topDestinations.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Destinations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            ..._dashboard!.topDestinations.map((dest) {
              return ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: primaryColor,
                ),
                title: Text(
                  dest.destination,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                trailing: Chip(
                  label: Text('${dest.count}'),
                  backgroundColor: isDark
                      ? primaryColor.withValues(alpha: 0.3)
                      : primaryColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingMailsSection() {
    if (_dashboard!.pendingMails.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Courriers en attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._dashboard!.pendingMails.take(5).map((mail) {
          return _buildMailCard(mail);
        }),
      ],
    );
  }

  Widget _buildRecentCollectionsSection() {
    if (_dashboard!.recentCollections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Collectés récemment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._dashboard!.recentCollections.take(5).map((mail) {
          return _buildMailCard(mail);
        }),
      ],
    );
  }

  Widget _buildMailListTab({bool? isCollected, TabController? tabController}) {
    return MailListView(
      isCollected: isCollected,
      onRefresh: _loadDashboard,
      tabController: tabController,
    );
  }

  Widget _buildMailCard(MailModel mail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: mail.isCollected
              ? (isDark ? Colors.green.shade800 : Colors.green.shade100)
              : (isDark ? Colors.orange.shade800 : Colors.orange.shade100),
          child: Icon(
            mail.isCollected ? Icons.check_circle : Icons.pending,
            color: mail.isCollected ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          mail.mailNumber,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expéditeur: ${mail.senderName}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            Text(
              'Destination: ${mail.destination}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                      .format(mail.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 22),
              tooltip: 'Envoyer sur WhatsApp',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _sendTrackingLinkViaWhatsApp(mail),
            ),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MailDetailScreen(mail: mail),
            ),
          );
          if (result != null) {
            if (result is Map && result['goToCollected'] == true) {
              // Recharger et aller à l'onglet Collectés (index 2)
              _loadDashboard();
              _tabController.animateTo(2);
            } else if (result == true) {
              _loadDashboard();
            }
          }
        },
      ),
    );
  }

  Future<void> _sendTrackingLinkViaWhatsApp(MailModel mail) async {
    try {
      // Formater le numéro de téléphone pour WhatsApp
      String phone = mail.recipientPhone;

      // Ajouter l'indicatif +225 (Côte d'Ivoire) si nécessaire
      if (!phone.startsWith('+')) {
        phone = '+225$phone';
      }

      // Nettoyer le numéro (supprimer les espaces et caractères non numériques sauf +)
      phone = phone.split('').where((c) {
        final code = c.codeUnitAt(0);
        return c == '+' || (code >= 48 && code <= 57);
      }).join();

      // Construire l'URL de suivi
      final trackingUrl = 'https://skf-artluxurybus.com/track/mail/${mail.id}';

      // Créer le message
      final message =
          'Bonjour, voici le lien pour suivre votre courrier ${mail.mailNumber}: $trackingUrl';

      // Encoder le message pour l'URL
      final encodedMessage = Uri.encodeComponent(message);

      // Construire l'URL WhatsApp
      final whatsappUrl = 'https://wa.me/$phone?text=$encodedMessage';

      // Ouvrir WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class MailListView extends StatefulWidget {
  final bool? isCollected;
  final VoidCallback? onRefresh;
  final TabController? tabController;

  const MailListView({
    super.key,
    this.isCollected,
    this.onRefresh,
    this.tabController,
  });

  @override
  State<MailListView> createState() => _MailListViewState();
}

class _MailListViewState extends State<MailListView> {
  List<MailModel> _mails = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadMails();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadMails() async {
    if (_isLoading) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _mails = [];
    });

    try {
      final response = await MailApiService.getMails(
        page: _currentPage,
        isCollected: widget.isCollected,
        search: _searchQuery,
      );

      if (!mounted) return;

      final List mailsData = response['data']['data'] ?? [];
      final List<MailModel> newMails =
          mailsData.map((e) => MailModel.fromJson(e)).toList();

      setState(() {
        _mails = newMails;
        _hasMore = response['data']['next_page_url'] != null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      final response = await MailApiService.getMails(
        page: _currentPage,
        isCollected: widget.isCollected,
        search: _searchQuery,
      );

      if (!mounted) return;

      final List mailsData = response['data']['data'] ?? [];
      final List<MailModel> newMails =
          mailsData.map((e) => MailModel.fromJson(e)).toList();

      setState(() {
        _mails.addAll(newMails);
        _hasMore = response['data']['next_page_url'] != null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentPage--;
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
    _loadMails();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher un courrier...',
              hintStyle: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.6),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.6),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onSubmitted: _performSearch,
          ),
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _mails.isEmpty) {
      return const CenteredLoadingIndicator();
    }

    if (_error != null && _mails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMails,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_mails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.4) ??
                  Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun courrier',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.6) ??
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadMails();
        widget.onRefresh?.call();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: _mails.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _mails.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: LoadingIndicator(),
              ),
            );
          }

          final mail = _mails[index];
          return _buildMailCard(mail);
        },
      ),
    );
  }

  Widget _buildMailCard(MailModel mail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: mail.isCollected
              ? (isDark ? Colors.green.shade800 : Colors.green.shade100)
              : (isDark ? Colors.orange.shade800 : Colors.orange.shade100),
          child: Icon(
            mail.isCollected ? Icons.check_circle : Icons.pending,
            color: mail.isCollected ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          mail.mailNumber,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expéditeur: ${mail.senderName}',
              style: TextStyle(color: subtitleColor),
            ),
            Text(
              'Téléphone: ${mail.senderPhone}',
              style: TextStyle(color: subtitleColor),
            ),
            Text(
              'Destination: ${mail.destination}',
              style: TextStyle(color: subtitleColor),
            ),
            Text(
              'Type: ${mail.packageType}',
              style: TextStyle(color: subtitleColor),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                      .format(mail.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 13,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yy').format(mail.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.6) ??
                        Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 22),
              tooltip: 'Envoyer sur WhatsApp',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _sendTrackingLinkViaWhatsApp(mail),
            ),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MailDetailScreen(mail: mail),
            ),
          );
          if (result != null) {
            if (result is Map && result['goToCollected'] == true) {
              // Aller à l'onglet Collectés (index 2)
              widget.tabController?.animateTo(2);
            }
            setState(() {});
          }
          if (result == true) {
            _loadMails();
            widget.onRefresh?.call();
          }
        },
      ),
    );
  }

  Future<void> _sendTrackingLinkViaWhatsApp(MailModel mail) async {
    try {
      // Formater le numéro de téléphone pour WhatsApp
      String phone = mail.recipientPhone;

      // Ajouter l'indicatif +225 (Côte d'Ivoire) si nécessaire
      if (!phone.startsWith('+')) {
        phone = '+225$phone';
      }

      // Nettoyer le numéro (supprimer les espaces et caractères non numériques sauf +)
      phone = phone.split('').where((c) {
        final code = c.codeUnitAt(0);
        return c == '+' || (code >= 48 && code <= 57);
      }).join();

      // Construire l'URL de suivi
      final trackingUrl = 'https://skf-artluxurybus.com/track/mail/${mail.id}';

      // Créer le message
      final message =
          'Bonjour, voici le lien pour suivre votre courrier ${mail.mailNumber}: $trackingUrl';

      // Encoder le message pour l'URL
      final encodedMessage = Uri.encodeComponent(message);

      // Construire l'URL WhatsApp
      final whatsappUrl = 'https://wa.me/$phone?text=$encodedMessage';

      // Ouvrir WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
