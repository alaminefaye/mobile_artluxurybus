import 'package:flutter/material.dart';
import '../models/bagage_model.dart';
import '../services/bagage_api_service.dart';
import 'bagage_detail_screen.dart';
import 'create_bagage_screen.dart';
import 'package:intl/intl.dart';

class BagageManagementScreen extends StatefulWidget {
  const BagageManagementScreen({super.key});

  @override
  State<BagageManagementScreen> createState() => _BagageManagementScreenState();
}

class _BagageManagementScreenState extends State<BagageManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BagageDashboard? _dashboard;
  bool _isLoadingDashboard = true;
  String? _dashboardError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final dashboard = await BagageApiService.getDashboard();
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
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
          title: const Text(
            'Gestion des Bagages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Stats'),
              Tab(icon: Icon(Icons.luggage), text: 'Avec Ticket'),
              Tab(icon: Icon(Icons.list), text: 'Tous'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboardTab(),
            _buildBagageListTab(hasTicket: true),
            _buildBagageListTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateBagageScreen(),
              ),
            );
            if (result == true) {
              _loadDashboard();
            }
          },
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const Icon(Icons.add, size: 28),
          label: const Text(
            'Nouveau Bagage',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_isLoadingDashboard) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dashboardError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_dashboardError'),
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
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte Aujourd'hui
          _buildStatCard(
            'Aujourd\'hui',
            _dashboard!.today,
            Colors.blue,
            Icons.today,
          ),
          const SizedBox(height: 16),

          // Carte Cette semaine
          _buildStatCard(
            'Cette semaine',
            _dashboard!.week,
            Colors.green,
            Icons.date_range,
          ),
          const SizedBox(height: 16),

          // Carte Ce mois
          _buildStatCard(
            'Ce mois',
            _dashboard!.month,
            Colors.orange,
            Icons.calendar_month,
          ),
          const SizedBox(height: 24),

          // Top Destinations
          if (_dashboard!.topDestinations.isNotEmpty) ...[
            const Text(
              'Top Destinations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._dashboard!.topDestinations.map((dest) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(Icons.location_on, color: Colors.orange.shade700),
                  ),
                  title: Text(dest.destination),
                  trailing: Text(
                    '${dest.count}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Bagages récents
          if (_dashboard!.recentBagages.isNotEmpty) ...[
            const Text(
              'Bagages Récents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._dashboard!.recentBagages.map((bagage) {
              return _buildBagageCard(bagage);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    DashboardPeriod period,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', period.total.toString(), Icons.luggage),
                _buildStatItem('Avec Ticket', period.withTicket.toString(), Icons.check_circle),
                _buildStatItem('Sans Ticket', period.withoutTicket.toString(), Icons.cancel),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Revenus',
                  NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                      .format(period.revenue),
                  Icons.attach_money,
                ),
                _buildStatItem(
                  'Poids',
                  '${period.weight.toStringAsFixed(1)} kg',
                  Icons.scale,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBagageListTab({bool? hasTicket}) {
    return BagageListView(
      hasTicket: hasTicket,
      onRefresh: _loadDashboard,
    );
  }

  Widget _buildBagageCard(BagageModel bagage) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              bagage.hasTicket ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(
            bagage.hasTicket ? Icons.check_circle : Icons.luggage,
            color: bagage.hasTicket ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          bagage.numero,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${bagage.nom} ${bagage.prenom}'),
            Text('Destination: ${bagage.destination}'),
          ],
        ),
        trailing: bagage.montant != null
            ? Text(
                NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                    .format(bagage.montant),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              )
            : null,
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BagageDetailScreen(bagage: bagage),
            ),
          );
          if (result == true) {
            _loadDashboard();
          }
        },
      ),
    );
  }
}

class BagageListView extends StatefulWidget {
  final bool? hasTicket;
  final VoidCallback? onRefresh;

  const BagageListView({
    super.key,
    this.hasTicket,
    this.onRefresh,
  });

  @override
  State<BagageListView> createState() => _BagageListViewState();
}

class _BagageListViewState extends State<BagageListView> {
  List<BagageModel> _bagages = [];
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
    _loadBagages();
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

  Future<void> _loadBagages() async {
    if (_isLoading) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _bagages = [];
    });

    try {
      final response = await BagageApiService.getBagages(
        page: _currentPage,
        hasTicket: widget.hasTicket,
        search: _searchQuery,
      );

      if (!mounted) return;

      final List bagagesData = response['data']['data'] ?? [];
      final List<BagageModel> newBagages =
          bagagesData.map((e) => BagageModel.fromJson(e)).toList();

      setState(() {
        _bagages = newBagages;
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

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      final response = await BagageApiService.getBagages(
        page: _currentPage,
        hasTicket: widget.hasTicket,
        search: _searchQuery,
      );

      if (!mounted) return;

      final List bagagesData = response['data']['data'] ?? [];
      final List<BagageModel> newBagages =
          bagagesData.map((e) => BagageModel.fromJson(e)).toList();

      setState(() {
        _bagages.addAll(newBagages);
        _hasMore = response['data']['next_page_url'] != null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _currentPage--;
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
    _loadBagages();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onSubmitted: _onSearch,
          ),
        ),

        // Liste des bagages
        Expanded(
          child: _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erreur: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBagages,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _bagages.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.luggage_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun bagage trouvé',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBagages,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _bagages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _bagages.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final bagage = _bagages[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: bagage.hasTicket
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                child: Icon(
                                  bagage.hasTicket ? Icons.check_circle : Icons.luggage,
                                  color: bagage.hasTicket ? Colors.green : Colors.orange,
                                ),
                              ),
                              title: Text(
                                bagage.numero,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bagage.nomComplet),
                                  Text('📍 ${bagage.destination}'),
                                  if (bagage.poids != null)
                                    Text('⚖️ ${bagage.poids} kg'),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (bagage.montant != null)
                                    Text(
                                      NumberFormat.currency(
                                              symbol: 'FCFA ', decimalDigits: 0)
                                          .format(bagage.montant),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 13,
                                      ),
                                    ),
                                  Text(
                                    DateFormat('dd/MM/yy').format(bagage.createdAt),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BagageDetailScreen(bagage: bagage),
                                  ),
                                );
                                if (result == true) {
                                  _loadBagages();
                                  widget.onRefresh?.call();
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

