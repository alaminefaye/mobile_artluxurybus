import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bus_provider.dart';
import '../../models/bus_models.dart';
import 'bus_detail_screen.dart';

class BusListScreen extends ConsumerStatefulWidget {
  const BusListScreen({super.key});

  @override
  ConsumerState<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends ConsumerState<BusListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Charger les bus au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(busListProvider.notifier).loadBuses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busListState = ref.watch(busListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Bus'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),
          
          // Filtres actifs
          if (_selectedStatus != null || _searchController.text.isNotEmpty)
            _buildActiveFilters(),
          
          // Liste des bus
          Expanded(
            child: _buildBusList(busListState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un bus (immatriculation, marque...)',
          hintStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(busListProvider.notifier).setSearchQuery(null);
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {}); // Rafraîchir l'UI pour le bouton clear
          // Debounce pour éviter trop de requêtes
          Future.delayed(const Duration(milliseconds: 300), () {
            if (value == _searchController.text && mounted) {
              ref.read(busListProvider.notifier).setSearchQuery(
                value.isEmpty ? null : value,
              );
            }
          });
        },
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor.withValues(alpha: 0.5),
      child: Row(
        children: [
          Text(
            'Filtres actifs:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedStatus != null)
                    _buildFilterChip(
                      'Statut: ${_getStatusLabel(_selectedStatus!)}',
                      () {
                        setState(() => _selectedStatus = null);
                        ref.read(busListProvider.notifier).setStatusFilter(null);
                      },
                    ),
                  if (_searchController.text.isNotEmpty)
                    _buildFilterChip(
                      'Recherche: ${_searchController.text}',
                      () {
                        _searchController.clear();
                        ref.read(busListProvider.notifier).setSearchQuery(null);
                      },
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _searchController.clear();
              });
              ref.read(busListProvider.notifier).clearFilters();
            },
            child: Text(
              'Effacer',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        onDeleted: onDeleted,
        deleteIcon: Icon(
          Icons.close,
          size: 16,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildBusList(BusListState state) {
    if (state.isLoading && state.buses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.buses.isEmpty) {
      return _buildErrorWidget(state.error!);
    }

    if (state.buses.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(busListProvider.notifier).refreshBuses();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.buses.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.buses.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final bus = state.buses[index];
          return _buildBusCard(bus);
        },
      ),
    );
  }

  Widget _buildBusCard(Bus bus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusDetailScreen(busId: bus.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icône du bus
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(bus.status ?? 'inactive').withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: _getStatusColor(bus.status ?? 'inactive'),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Informations principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.registrationNumber ?? 'N/A',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bus.brand ?? ''} ${bus.model ?? 'Modèle inconnu'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge statut
                  if (bus.status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(bus.status!).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusLabel(bus.status!),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(bus.status!),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Informations secondaires
              Row(
                children: [
                  if (bus.capacity != null)
                    _buildInfoChip(
                      Icons.airline_seat_recline_normal,
                      '${bus.capacity} places',
                    ),
                  if (bus.capacity != null)
                    const SizedBox(width: 8),
                  if (bus.year != null)
                    _buildInfoChip(
                      Icons.calendar_today,
                      '${bus.year}',
                    ),
                  if (bus.year != null)
                    const SizedBox(width: 8),
                  if (bus.currentMileage != null)
                    _buildInfoChip(
                      Icons.speed,
                      '${bus.currentMileage!.toStringAsFixed(0)} km',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun bus trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos filtres de recherche',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(busListProvider.notifier).refreshBuses();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('Tous', null),
            _buildStatusOption('Actif', 'active'),
            _buildStatusOption('Maintenance', 'maintenance'),
            _buildStatusOption('Inactif', 'inactive'),
            _buildStatusOption('Hors service', 'out_of_service'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String label, String? value) {
    final isSelected = _selectedStatus == value;
    return RadioListTile<String?>(
      title: Text(label),
      value: value,
      // ignore: deprecated_member_use
      groupValue: _selectedStatus,
      // ignore: deprecated_member_use
      onChanged: (newValue) {
        setState(() => _selectedStatus = newValue);
        ref.read(busListProvider.notifier).setStatusFilter(newValue);
        Navigator.pop(context);
      },
      fillColor: WidgetStateProperty.all(Colors.deepPurple),
      selected: isSelected,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'available':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      case 'out_of_service':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Actif';
      case 'available':
        return 'Disponible';
      case 'maintenance':
        return 'Maintenance';
      case 'inactive':
        return 'Inactif';
      case 'out_of_service':
        return 'Hors service';
      default:
        return status;
    }
  }
}
