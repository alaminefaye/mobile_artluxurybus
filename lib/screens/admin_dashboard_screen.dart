import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/dashboard_api_service.dart';
import '../services/auth_service.dart';
import '../models/dashboard_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_indicator.dart';
import 'auth/login_screen.dart';
import 'departure_analysis_screen.dart';

/// Écran Dashboard pour les rôles Super Admin, Admin et PDG
/// Affiche les statistiques en temps réel de la compagnie
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  DashboardApiService? _dashboardService;
  DashboardStats? _dashboardStats;
  Map<int, double> _monthlyRevenue = {};
  Map<int, double> _artMonthlyRevenue = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Formateur de nombres avec séparateurs de milliers
  final _numberFormat = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('🔍 [AdminDashboard] Début initialisation...');

      // Récupérer le token
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        debugPrint('❌ [AdminDashboard] Pas de token');
        setState(() {
          _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
          _isLoading = false;
        });
        return;
      }

      debugPrint(
          '✅ [AdminDashboard] Token récupéré: ${token.substring(0, 20)}...');

      // Vérifier les infos utilisateur
      final user = await authService.getSavedUser();
      if (user != null) {
        debugPrint('👤 [AdminDashboard] Utilisateur: ${user.name}');
        debugPrint('💼 [AdminDashboard] Rôle: ${user.role}');
        debugPrint('💼 [AdminDashboard] Roles: ${user.roles}');
      }

      // Initialiser le service Dashboard
      _dashboardService = DashboardApiService(
        baseUrl: 'https://skf-artluxurybus.com/api',
        token: token,
      );

      debugPrint('📡 [AdminDashboard] Appel API dashboard...');
      // Charger les statistiques
      final stats = await _dashboardService!.getDashboardStats();
      debugPrint('✅ [AdminDashboard] Statistiques reçues');

      // Charger les revenus mensuels
      final monthly = await _dashboardService!.getMonthlyRevenue();
      debugPrint('✅ [AdminDashboard] Revenus mensuels reçus');

      setState(() {
        _dashboardStats = stats;
        _monthlyRevenue = monthly.guichet;
        _artMonthlyRevenue = monthly.application;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [AdminDashboard] Erreur chargement dashboard: $e');
      debugPrint('📄 [AdminDashboard] Stack trace: $stackTrace');

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Déconnexion de l'utilisateur
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final authService = AuthService();
        await authService.logout();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('❌ Erreur déconnexion: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tableau de Bord',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeDashboard,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingIndicator(),
            SizedBox(height: 16),
            Text('Chargement des statistiques...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_dashboardStats == null) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return RefreshIndicator(
      onRefresh: _initializeDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête avec date
          _buildDateHeader(),
          const SizedBox(height: 16),

          _buildCombinedRevenueCard(),
          const SizedBox(height: 16),

          _buildTotalRevenueCard(),
          const SizedBox(height: 16),

          _buildArtRevenueCard(),
          const SizedBox(height: 16),

          // Revenus détaillés (Tickets et Courriers+Bagages)
          _buildRevenueDetailsGrid(),
          const SizedBox(height: 16),

          // Grille de statistiques principales
          _buildStatsGrid(),
          const SizedBox(height: 16),

          // Section Tickets
          _buildSectionTitle('Billets'),
          _buildTicketsCard(),
          const SizedBox(height: 16),

          // Section Courriers & Bagages
          _buildSectionTitle('Courriers & Bagages'),
          _buildMailAndBagageCard(),
          const SizedBox(height: 16),

          // Section Employés
          _buildSectionTitle('Employés'),
          _buildEmployeesCard(),
          const SizedBox(height: 16),

          // Section Clients
          _buildSectionTitle('Clients'),
          _buildClientsCard(),
          const SizedBox(height: 16),

          // Section Bus
          _buildSectionTitle('Flotte'),
          _buildBusesCard(),
          const SizedBox(height: 24),

          _buildSectionTitle('Chiffre d\'affaires du guichet'),
          _buildMonthlyRevenueChart(
            title: 'Guichet',
            revenue: _monthlyRevenue,
            barColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.primaryOrange.withValues(alpha: 0.8)
                : AppTheme.primaryBlue,
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Chiffre d\'affaires de l\'application'),
          _buildMonthlyRevenueChart(
            title: 'Application',
            revenue: _artMonthlyRevenue,
            barColor: const Color(0xFF0F6E56),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Chiffre d\'affaires guichet + application'),
          _buildMonthlyRevenueChart(
            title: 'Guichet + application',
            revenue: _combinedMonthlyRevenue(),
            barColor: const Color(0xFF1B3A4B),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark
          ? AppTheme.primaryBlue.withValues(alpha: 0.9)
          : AppTheme.primaryBlue,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques du jour',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _dashboardStats!.dateFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Bouton Analyse
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DepartureAnalysisScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics, size: 18),
              label: const Text(
                'Analyse',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryBlue,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRevenueCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      color: isDark ? const Color(0xFFD4A574) : AppTheme.primaryOrange,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'REVENU TOTAL DU GUICHET',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_numberFormat.format(_dashboardStats!.totalDailyRevenue.toInt())} FCFA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtRevenueCard() {
    final stats = _dashboardStats!;
    return Card(
      elevation: 4,
      color: const Color(0xFF0F6E56),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'REVENU DANS L\'APPLICATION',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Revenu du jour',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${_numberFormat.format(stats.artDailyRevenue.toInt())} FCFA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedRevenueCard() {
    final stats = _dashboardStats!;
    final daily = stats.totalDailyRevenue + stats.artDailyRevenue;

    return Card(
      elevation: 4,
      color: const Color(0xFF1B3A4B),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'REVENU TOTAL DU JOUR',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_numberFormat.format(daily.toInt())} FCFA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agence + application',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueDetailsGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mailBagageRevenue = _dashboardStats!.mails.totalRevenue +
        _dashboardStats!.bagages.totalRevenue;

    return Row(
      children: [
        // Total Tickets
        Expanded(
          child: Card(
            elevation: 3,
            color: isDark ? Colors.blue.shade700 : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 32,
                    color: isDark ? Colors.white : Colors.blue.shade700,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Tickets',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_numberFormat.format(_dashboardStats!.tickets.totalRevenue.toInt())} FCFA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Total Courriers + Bagages
        Expanded(
          child: Card(
            elevation: 3,
            color: isDark ? Colors.purple.shade700 : Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.mail,
                    size: 32,
                    color: isDark ? Colors.white : Colors.purple.shade700,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Courriers + Bagages',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_numberFormat.format(mailBagageRevenue.toInt())} FCFA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.purple.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _buildStatCard(
          'Billets',
          _dashboardStats!.ticketsCount.toString(),
          Icons.confirmation_number,
          Colors.blue,
        ),
        _buildStatCard(
          'Départs',
          _dashboardStats!.departsCount.toString(),
          Icons.directions_bus,
          Colors.green,
        ),
        _buildStatCard(
          'Courriers',
          _dashboardStats!.mailsCount.toString(),
          Icons.mail,
          Colors.purple,
        ),
        _buildStatCard(
          'Bagages',
          _dashboardStats!.bagagesCount.toString(),
          Icons.luggage,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? Colors.grey.shade800 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 22,
                height: 1.1,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : color,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                height: 1.1,
                color: isDark ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTicketsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tickets = _dashboardStats!.tickets;
    return Card(
      color: isDark ? Colors.grey.shade800 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
                'Total', tickets.count.toString(), Icons.confirmation_number),
            _buildDetailRow('Payés', tickets.paidCount.toString(), Icons.paid),
            _buildDetailRow(
                'Gratuits', tickets.freeCount.toString(), Icons.card_giftcard),
            _buildDetailRow(
                'Fidélité', tickets.loyaltyCount.toString(), Icons.loyalty),
            _buildDetailRow('Codes Promo', tickets.promoCodeCount.toString(),
                Icons.discount),
            const Divider(),
            _buildRevenueRow('Recettes', tickets.totalRevenue),
          ],
        ),
      ),
    );
  }

  Widget _buildMailAndBagageCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mails = _dashboardStats!.mails;
    final bagages = _dashboardStats!.bagages;
    return Card(
      color: isDark ? Colors.grey.shade800 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Courriers',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                )),
            const SizedBox(height: 8),
            _buildDetailRow('Total', mails.count.toString(), Icons.mail),
            _buildDetailRow('Collectés', mails.collectedCount.toString(),
                Icons.check_circle),
            _buildDetailRow(
                'En attente', mails.pendingCount.toString(), Icons.pending),
            _buildRevenueRow('Recettes', mails.totalRevenue),
            const Divider(),
            const SizedBox(height: 8),
            Text('Bagages',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                )),
            const SizedBox(height: 8),
            _buildDetailRow('Total', bagages.count.toString(), Icons.luggage),
            _buildRevenueRow('Recettes', bagages.totalRevenue),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeesCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final employees = _dashboardStats!.employees;
    return Card(
      color: isDark ? Colors.grey.shade800 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
                'Total actifs', employees.totalActive.toString(), Icons.people),
            _buildDetailRow('Présents', employees.presentCount.toString(),
                Icons.check_circle, Colors.green),
            _buildDetailRow('En cours', employees.inProgressCount.toString(),
                Icons.access_time, Colors.orange),
            _buildDetailRow('Absents', employees.absentCount.toString(),
                Icons.cancel, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clients = _dashboardStats!.clients;
    return Card(
      color: isDark ? Colors.grey.shade800 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
                'Total clients', clients.total.toString(), Icons.people),
            _buildDetailRow('Nouveaux aujourd\'hui',
                clients.newToday.toString(), Icons.person_add),
            _buildDetailRow('Avec comptes', clients.withAccounts.toString(),
                Icons.account_circle),
          ],
        ),
      ),
    );
  }

  Widget _buildBusesCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buses = _dashboardStats!.buses;
    return Card(
      color: isDark ? Colors.grey.shade800 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
                'Total', buses.total.toString(), Icons.directions_bus),
            _buildDetailRow('Actifs', buses.active.toString(),
                Icons.check_circle, Colors.green),
            _buildDetailRow('En maintenance', buses.inMaintenance.toString(),
                Icons.build, Colors.orange),
            _buildDetailRow('Hors service', buses.outOfService.toString(),
                Icons.cancel, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      [Color? iconColor]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: iconColor ?? (isDark ? Colors.white70 : Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueRow(String label, double amount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.attach_money,
              size: 20, color: isDark ? Colors.greenAccent : Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.greenAccent : Colors.green,
              ),
            ),
          ),
          Text(
            '${_numberFormat.format(amount.toInt())} FCFA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.greenAccent : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Map<int, double> _combinedMonthlyRevenue() {
    return {
      for (var month = 1; month <= 12; month++)
        month: (_monthlyRevenue[month] ?? 0) + (_artMonthlyRevenue[month] ?? 0),
    };
  }

  Widget _buildMonthlyRevenueChart({
    required String title,
    required Map<int, double> revenue,
    required Color barColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Noms des mois en français
    final monthNames = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];

    // Vérifier si on a des données
    final hasData =
        revenue.isNotEmpty && revenue.values.any((value) => value > 0);

    // Trouver le montant maximum pour l'échelle
    final maxRevenue = hasData
        ? revenue.values.reduce((a, b) => a > b ? a : b)
        : 1000000.0;

    // Arrondir au million supérieur pour une belle échelle
    final maxY = maxRevenue > 0
        ? ((maxRevenue / 1000000).ceil() * 1000000.0)
        : 1000000.0;

    return Card(
      color: isDark ? Colors.grey.shade800 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
                if (!hasData)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Pas de données',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.orange.shade200
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY > 0 ? maxY : 1000000,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                          isDark ? Colors.grey.shade900 : Colors.grey.shade800,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${monthNames[group.x.toInt()]}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${_numberFormat.format(rod.toY.toInt())} FCFA',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < 12) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                monthNames[value.toInt()],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          // Afficher les valeurs en millions
                          final millions = (value / 1000000).toInt();
                          if (millions == 0 && value == 0) {
                            return Text(
                              '0',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                              ),
                            );
                          } else if (value % 1000000 == 0 && millions > 0) {
                            return Text(
                              '${millions}M',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 5 : 200000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        width: 1,
                      ),
                      left: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  barGroups: List.generate(12, (index) {
                    final month = index + 1;
                    final amount = revenue[month] ?? 0.0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: amount,
                          color: barColor,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
