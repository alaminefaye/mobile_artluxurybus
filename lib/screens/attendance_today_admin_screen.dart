import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/attendance_api_service.dart';
import '../services/dashboard_api_service.dart';
import '../services/auth_service.dart';
import '../models/employee_presence_today.dart';
import '../models/dashboard_stats.dart' as dash;
import '../theme/app_theme.dart';

class AttendanceTodayAdminScreen extends ConsumerStatefulWidget {
  const AttendanceTodayAdminScreen({super.key});

  @override
  ConsumerState<AttendanceTodayAdminScreen> createState() =>
      _AttendanceTodayAdminScreenState();
}

class _AttendanceTodayAdminScreenState
    extends ConsumerState<AttendanceTodayAdminScreen> {
  List<EmployeePresenceToday> _employees = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';
  String _positionFilter = '';
  List<String> _positions = [];
  dash.DashboardStats? _dashboardStats;
  DashboardApiService? _dashboardService;

  final _searchController = TextEditingController();
  final _positionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token != null) {
        _dashboardService = DashboardApiService(
            baseUrl: 'https://skf-artluxurybus.com/api', token: token);
      }

      // Charger les postes disponibles
      final positions = await AttendanceApiService.getPositions();

      await Future.wait([
        _loadEmployees(),
        _loadDashboardStats(),
      ]);

      setState(() {
        _positions = positions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployees() async {
    final list = await AttendanceApiService.getTodayEmployeesPresence(
      search: _search.isNotEmpty ? _search : null,
      position: _positionFilter.isNotEmpty ? _positionFilter : null,
      perPage: 100,
      page: 1,
    );
    list.sort((a, b) {
      // Trier: ceux qui ont pointé en haut
      final aPoint = a.hasPointed ? 1 : 0;
      final bPoint = b.hasPointed ? 1 : 0;
      if (aPoint != bPoint) return bPoint.compareTo(aPoint);
      // Ensuite par nom
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    _employees = list;
  }

  Future<void> _loadDashboardStats() async {
    if (_dashboardService == null) return;
    try {
      _dashboardStats = await _dashboardService!.getDashboardStats();
    } catch (_) {
      // Ignorer si dashboard non accessible pour ce rôle
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Présences du jour'),
        backgroundColor: isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initialize,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _initialize, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initialize,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 12),
          _buildSearchFilters(),
          const SizedBox(height: 12),
          _buildEmployeesList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final stats = _dashboardStats?.employees;
    final present = stats?.presentCount ?? 0;
    final departed = stats?.departedCount ?? 0;
    final inProgress = stats?.inProgressCount ?? 0;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Entrées', present, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Sorties', departed, Colors.red)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('En cours', inProgress, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Rechercher par nom, téléphone',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _onSearchChanged(),
        ),
        const SizedBox(height: 8),
        // Dropdown pour les postes
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Filtrer par poste',
            prefixIcon: Icon(Icons.badge_outlined),
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _positionFilter.isEmpty ? null : _positionFilter,
              hint: const Text('Sélectionner un poste'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Tous les postes'),
                ),
                ..._positions.map((position) => DropdownMenuItem(
                      value: position,
                      child: Text(position),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _positionFilter = value ?? '';
                  _positionController.text = _positionFilter;
                });
                _onSearchChanged();
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: ElevatedButton.icon(
              onPressed: _onSearchChanged,
              icon: const Icon(Icons.filter_alt),
              label: const Text('Appliquer'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onSearchChanged() async {
    setState(() {
      _search = _searchController.text.trim();
      _positionFilter = _positionController.text.trim();
      _isLoading = true;
      _error = null;
    });
    try {
      await _loadEmployees();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildEmployeesList() {
    if (_employees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('Aucun employé trouvé pour aujourd\'hui',
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _employees.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final emp = _employees[index];
        return _buildEmployeeCard(emp);
      },
    );
  }

  Widget _buildEmployeeCard(EmployeePresenceToday emp) {
    Color statusColor = Colors.grey;
    String statusLabel = 'Non pointé';
    IconData statusIcon = Icons.help_outline;

    switch (emp.currentStatus) {
      case 'checked_in':
        statusColor = Colors.green;
        statusLabel = 'Présent (Entrée)';
        statusIcon = Icons.login_rounded;
        break;
      case 'checked_out':
        statusColor = Colors.red;
        statusLabel = 'Parti (Sortie)';
        statusIcon = Icons.logout_rounded;
        break;
      case 'on_break':
        statusColor = Colors.orange;
        statusLabel = 'En pause';
        statusIcon = Icons.coffee_rounded;
        break;
      case 'not_checked_in':
      default:
        statusColor = Colors.grey;
        statusLabel = 'Non pointé';
        statusIcon = Icons.help_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Icon(statusIcon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emp.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (emp.phone != null && emp.phone!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(emp.phone!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ),
                              ],
                            ),
                          if (emp.position != null && emp.position!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.badge,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(emp.position!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.login_rounded,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(emp.checkedInAt ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout_rounded,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(emp.checkedOutAt ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
