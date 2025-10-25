import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bus_provider.dart';
import '../../models/bus_models.dart';
import 'fuel_record_detail_screen.dart';
import 'fuel_record_form_screen.dart';

class BusDetailScreen extends ConsumerWidget {
  final int busId;

  const BusDetailScreen({super.key, required this.busId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busDetailsAsync = ref.watch(busDetailsProvider(busId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Bus'),
        backgroundColor: Colors.deepPurple,
      ),
      body: busDetailsAsync.when(
        data: (bus) => _buildBusDetails(context, bus, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(context, error, ref),
      ),
    );
  }

  Widget _buildBusDetails(BuildContext context, Bus bus, WidgetRef ref) {
    return DefaultTabController(
      length: 7,
      child: Column(
        children: [
          // En-tête avec informations principales
          _buildBusHeader(bus),
          
          // Onglets
          Container(
            color: Colors.grey[100],
            child: const TabBar(
              isScrollable: true,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
              tabs: [
                Tab(icon: Icon(Icons.info), text: 'Infos'),
                Tab(icon: Icon(Icons.build), text: 'Maintenance'),
                Tab(icon: Icon(Icons.local_gas_station), text: 'Carburant'),
                Tab(icon: Icon(Icons.fact_check), text: 'Visites'),
                Tab(icon: Icon(Icons.shield), text: 'Assurance'),
                Tab(icon: Icon(Icons.warning), text: 'Pannes'),
                Tab(icon: Icon(Icons.oil_barrel), text: 'Vidanges'),
              ],
            ),
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              children: [
                _buildInfoTab(bus),
                _buildMaintenanceTab(ref),
                _buildFuelTab(ref),
                _buildTechnicalVisitsTab(ref),
                _buildInsuranceTab(ref),
                _buildBreakdownsTab(ref),
                _buildVidangesTab(ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusHeader(Bus bus) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.registrationNumber ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bus.capacity != null 
                          ? '${bus.capacity} sièges'
                          : 'Capacité inconnue',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(bus.status ?? 'unknown'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Bus bus) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('Informations Générales', [
          _InfoRow('Marque', bus.brand ?? 'N/A'),
          _InfoRow('Modèle', bus.model ?? 'N/A'),
          if (bus.year != null) _InfoRow('Année', '${bus.year}'),
          _InfoRow('Capacité', bus.capacity != null ? '${bus.capacity} places' : 'N/A'),
          _InfoRow('Statut', _getStatusLabel(bus.status ?? 'unknown')),
          if (bus.color != null) _InfoRow('Couleur', bus.color!),
        ]),
        
        const SizedBox(height: 16),
        
        _buildInfoCard('Informations Techniques', [
          if (bus.chassisNumber != null)
            _InfoRow('N° Chassis', bus.chassisNumber!),
          if (bus.engineNumber != null)
            _InfoRow('N° Moteur', bus.engineNumber!),
          if (bus.currentMileage != null)
            _InfoRow('Kilométrage', '${bus.currentMileage!.toStringAsFixed(0)} km'),
        ]),
        
        if (bus.notes != null) ...[
          const SizedBox(height: 16),
          _buildInfoCard('Notes', [
            _InfoRow('', bus.notes!, isNote: true),
          ]),
        ],
      ],
    );
  }

  Widget _buildMaintenanceTab(WidgetRef ref) {
    final maintenanceAsync = ref.watch(maintenanceListProvider(busId));
    
    return maintenanceAsync.when(
      data: (response) {
        if (response.data.isEmpty) {
          return _buildEmptyState('Aucune maintenance enregistrée');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.data.length,
          itemBuilder: (context, index) {
            final maintenance = response.data[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  child: const Icon(Icons.build, color: Colors.orange),
                ),
                title: Text(maintenance.maintenanceType),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(maintenance.maintenanceDate)),
                    if (maintenance.description != null)
                      Text(
                        maintenance.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
                trailing: maintenance.cost != null
                    ? Text(
                        '${maintenance.cost!.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildFuelTab(WidgetRef ref) {
    final fuelHistoryAsync = ref.watch(fuelHistoryProvider(busId));
    final fuelStatsAsync = ref.watch(fuelStatsProvider(busId));
    
    return Stack(
      children: [
        Column(
          children: [
        // Filtres
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Période',
                  ['Aujourd\'hui', 'Ce mois', 'Année'],
                  'Ce mois',
                  (value) {
                    // TODO: Implémenter filtrage
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterDropdown(
                  'Année',
                  ['2025', '2024', '2023'],
                  '2025',
                  (value) {
                    // TODO: Implémenter filtrage
                  },
                ),
              ),
            ],
          ),
        ),
        // Statistiques de carburant
        fuelStatsAsync.when(
          data: (stats) => Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        'Total',
                        '${stats.totalConsumption.toStringAsFixed(0)} FCFA',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        'Ce mois',
                        '${stats.lastMonthConsumption.toStringAsFixed(0)} FCFA',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        'Année passée',
                        '0 FCFA', // TODO: Calculer depuis API
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        
        // Historique
        Expanded(
          child: fuelHistoryAsync.when(
            data: (response) {
              if (response.data.isEmpty) {
                return _buildEmptyState('Aucun enregistrement de carburant');
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: response.data.length,
                itemBuilder: (context, index) {
                  final fuel = response.data[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        child: const Icon(Icons.local_gas_station, color: Colors.blue),
                      ),
                      title: Text(
                        '${fuel.cost.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      subtitle: Text(_formatDateTime(fuel.fueledAt)),
                      trailing: fuel.notes != null && fuel.notes!.isNotEmpty
                          ? const Icon(Icons.note, color: Colors.grey)
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FuelRecordDetailScreen(
                              fuelRecord: fuel,
                              busId: busId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error.toString()),
          ),
        ),
          ],
        ),
        
        // Bouton Flottant Ajouter
        Positioned(
          bottom: 16,
          right: 16,
          child: Builder(
            builder: (context) => FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FuelRecordFormScreen(busId: busId),
                  ),
                );
                
                if (result == true) {
                  // Rafraîchir la liste
                  ref.invalidate(fuelHistoryProvider(busId));
                  ref.invalidate(fuelStatsProvider(busId));
                }
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalVisitsTab(WidgetRef ref) {
    final visitsAsync = ref.watch(technicalVisitsProvider(busId));
    
    return visitsAsync.when(
      data: (response) {
        if (response.data.isEmpty) {
          return _buildEmptyState('Aucune visite technique enregistrée');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.data.length,
          itemBuilder: (context, index) {
            final visit = response.data[index];
            final isExpiring = visit.expiryDate.isBefore(
              DateTime.now().add(const Duration(days: 30)),
            );
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (isExpiring ? Colors.red : Colors.green).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.fact_check,
                    color: isExpiring ? Colors.red : Colors.green,
                  ),
                ),
                title: Text('Visite du ${_formatDate(visit.visitDate)}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expire le ${_formatDate(visit.expiryDate)}'),
                    Text(
                      'Résultat: ${visit.result}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: isExpiring
                    ? const Icon(Icons.warning, color: Colors.red)
                    : const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildInsuranceTab(WidgetRef ref) {
    final insuranceAsync = ref.watch(insuranceHistoryProvider(busId));
    
    return insuranceAsync.when(
      data: (response) {
        if (response.data.isEmpty) {
          return _buildEmptyState('Aucune assurance enregistrée');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: response.data.length,
          itemBuilder: (context, index) {
            final insurance = response.data[index];
            final isActive = insurance.expiryDate.isAfter(DateTime.now());
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shield,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insurance.insuranceCompany,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isActive ? Colors.green : Colors.red)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Expirée',
                            style: TextStyle(
                              fontSize: 11,
                              color: isActive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow('Police N°', insurance.policyNumber),
                    _InfoRow('Type', insurance.coverageType),
                    _InfoRow('Début', _formatDate(insurance.startDate)),
                    _InfoRow('Fin', _formatDate(insurance.expiryDate)),
                    _InfoRow('Prime', '${insurance.premium.toStringAsFixed(0)} FCFA'),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildBreakdownsTab(WidgetRef ref) {
    final breakdownsState = ref.watch(breakdownsProvider(busId));
    
    if (breakdownsState.isLoading && breakdownsState.breakdowns.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (breakdownsState.breakdowns.isEmpty) {
      return _buildEmptyState('Aucune panne enregistrée');
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: breakdownsState.breakdowns.length,
      itemBuilder: (context, index) {
        final breakdown = breakdownsState.breakdowns[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: _getSeverityColor(breakdown.severity),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        breakdown.description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(breakdown.severity).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getSeverityLabel(breakdown.severity),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getSeverityColor(breakdown.severity),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(breakdown.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getBreakdownStatusLabel(breakdown.status),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getStatusColor(breakdown.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${_formatDate(breakdown.breakdownDate)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                if (breakdown.repairCost != null)
                  Text(
                    'Coût: ${breakdown.repairCost!.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVidangesTab(WidgetRef ref) {
    final vidangesState = ref.watch(vidangesProvider(busId));
    
    if (vidangesState.isLoading && vidangesState.vidanges.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (vidangesState.vidanges.isEmpty) {
      return _buildEmptyState('Aucune vidange enregistrée');
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vidangesState.vidanges.length,
      itemBuilder: (context, index) {
        final vidange = vidangesState.vidanges[index];
        final isCompleted = vidange.completedAt != null;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isCompleted ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.1),
              child: Icon(
                Icons.oil_barrel,
                color: isCompleted ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(vidange.type),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vidange.plannedDate != null)
                  Text('Prévu: ${_formatDate(vidange.plannedDate!)}'),
                if (isCompleted && vidange.completedAt != null)
                  Text('Effectué: ${_formatDate(vidange.completedAt!)}'),
                if (vidange.cost != null)
                  Text(
                    'Coût: ${vidange.cost!.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            trailing: Icon(
              isCompleted ? Icons.check_circle : Icons.pending,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: Theme.of(context).cardColor,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            hint: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
              'Erreur',
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
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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
                'Une erreur est survenue lors du chargement des détails du bus.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(busDetailsProvider(busId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return 'Élevée';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Faible';
      default:
        return severity;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'reported':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getBreakdownStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return 'Résolu';
      case 'in_progress':
        return 'En cours';
      case 'reported':
        return 'Signalé';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isNote;

  const _InfoRow(this.label, this.value, {this.isNote = false});

  @override
  Widget build(BuildContext context) {
    if (isNote) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.titleMedium?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
