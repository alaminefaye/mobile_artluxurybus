import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bus_provider.dart';
import '../../models/bus_models.dart';
import '../../services/bus_api_service.dart';
import 'fuel_record_detail_screen.dart';
import 'fuel_record_form_screen.dart';
import 'technical_visit_form_screen.dart';
import 'technical_visit_detail_screen.dart';
import 'insurance_form_screen.dart';
import 'insurance_detail_screen.dart';
import 'breakdown_form_screen.dart';
import 'breakdown_detail_screen.dart';
import 'vidange_form_screen.dart';
import 'vidange_detail_screen.dart';

class BusDetailScreen extends ConsumerStatefulWidget {
  final int busId;

  const BusDetailScreen({super.key, required this.busId});

  @override
  ConsumerState<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends ConsumerState<BusDetailScreen> {
  // Filtres pour Carburant
  String _selectedPeriod = 'Ce mois';
  String _selectedYear = '2025';
  
  // Filtres pour Visites Techniques
  String _selectedTechPeriod = 'Ce mois';
  String _selectedTechYear = '2025';
  
  // Filtres pour Assurances
  String _selectedInsurancePeriod = 'Ce mois';
  String _selectedInsuranceYear = '2025';
  
  // Filtres pour Pannes
  String _selectedBreakdownPeriod = 'Ce mois';
  String _selectedBreakdownYear = '2025';

  @override
  Widget build(BuildContext context) {
    final busDetailsAsync = ref.watch(busDetailsProvider(widget.busId));

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
    final maintenanceAsync = ref.watch(maintenanceListProvider(widget.busId));
    
    return maintenanceAsync.when(
      data: (response) {
        if (response.data.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(maintenanceListProvider(widget.busId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _buildEmptyState('Aucune maintenance enregistrée'),
              ),
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(maintenanceListProvider(widget.busId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
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
                title: Text(maintenance.maintenanceType ?? 'Type non spécifié'),
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
        ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildFuelTab(WidgetRef ref) {
    // Récupérer TOUTES les données (filtrage côté UI)
    final fuelHistoryAsync = ref.watch(fuelHistoryProvider(widget.busId));
    
    return Stack(
      children: [
        Column(
          children: [
        // Filtres
        Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
          child: Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Période',
                  ['Aujourd\'hui', 'Ce mois', 'Année'],
                  _selectedPeriod,
                  (value) {
                    if (value != null && mounted) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                      // Les données se rafraîchissent automatiquement
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterDropdown(
                  'Année',
                  ['2025', '2024', '2023'],
                  _selectedYear,
                  (value) {
                    if (value != null && mounted) {
                      setState(() {
                        _selectedYear = value;
                      });
                      // Les données se rafraîchissent automatiquement
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        ),
        // Statistiques de carburant (filtrées)
        fuelHistoryAsync.when(
          data: (response) {
            final filteredStats = _calculateFilteredStats(response.data);
            return Builder(
              builder: (context) => Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            'Total',
                            '${filteredStats['total']!.toStringAsFixed(0)} FCFA',
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatBox(
                            'Nombre',
                            '${filteredStats['count']!.toInt()} enreg.',
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatBox(
                            'Moyenne',
                            '${filteredStats['average']!.toStringAsFixed(0)} FCFA',
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        
        // Historique
        Expanded(
          child: fuelHistoryAsync.when(
            data: (response) {
              // Appliquer les filtres
              final filteredData = _filterFuelRecords(response.data);
              
              if (filteredData.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(fuelHistoryProvider(widget.busId));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: _buildEmptyState(
                        _selectedPeriod.isNotEmpty || _selectedYear.isNotEmpty
                            ? 'Aucun enregistrement pour cette période'
                            : 'Aucun enregistrement de carburant'
                      ),
                    ),
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(fuelHistoryProvider(widget.busId));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                  final fuel = filteredData[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        child: const Icon(Icons.local_gas_station, color: Colors.blue),
                      ),
                      title: Builder(
                        builder: (context) => Text(
                          '${fuel.cost.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      subtitle: Builder(
                        builder: (context) => Text(
                          _formatDateTime(fuel.fueledAt),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      trailing: fuel.notes != null && fuel.notes!.isNotEmpty
                          ? Builder(
                              builder: (context) => Icon(
                                Icons.note,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FuelRecordDetailScreen(
                              fuelRecord: fuel,
                              busId: widget.busId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
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
                    builder: (context) => FuelRecordFormScreen(busId: widget.busId),
                  ),
                );
                
                if (result == true) {
                  // Rafraîchir la liste
                  ref.invalidate(fuelHistoryProvider(widget.busId));
                  ref.invalidate(fuelStatsProvider(widget.busId));
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
    final visitsAsync = ref.watch(technicalVisitsProvider(widget.busId));
    
    return Stack(
      children: [
        Column(
          children: [
            // Filtres
            Builder(
              builder: (context) => Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        'Période',
                        ['Aujourd\'hui', 'Ce mois', 'Année'],
                        _selectedTechPeriod,
                        (value) {
                          if (value != null && mounted) {
                            setState(() {
                              _selectedTechPeriod = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        'Année',
                        ['2025', '2024', '2023'],
                        _selectedTechYear,
                        (value) {
                          if (value != null && mounted) {
                            setState(() {
                              _selectedTechYear = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Liste filtrée
            Expanded(
              child: visitsAsync.when(
                data: (response) {
                  final filteredData = _filterTechnicalVisits(response.data);
                  
                  if (filteredData.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(technicalVisitsProvider(widget.busId));
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: _buildEmptyState(
                            _selectedTechPeriod.isNotEmpty || _selectedTechYear.isNotEmpty
                                ? 'Aucune visite pour cette période'
                                : 'Aucune visite technique enregistrée'
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(technicalVisitsProvider(widget.busId));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                      final visit = filteredData[index];
            final isExpiring = visit.expirationDate.isBefore(
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
                    Text('Expire le ${_formatDate(visit.expirationDate)}'),
                    if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        visit.notes!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editTechnicalVisit(visit);
                    } else if (value == 'delete') {
                      _deleteTechnicalVisit(visit);
                    } else if (value == 'details') {
                      _showTechnicalVisitDetails(visit);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Détails'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () => _showTechnicalVisitDetails(visit),
              ),
            );
                    },
                  ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),
        
        // Bouton FAB pour ajouter une visite
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'visit_fab',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TechnicalVisitFormScreen(busId: widget.busId),
                ),
              );
              // Rafraîchir la liste
              ref.invalidate(technicalVisitsProvider(widget.busId));
            },
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceTab(WidgetRef ref) {
    final insuranceAsync = ref.watch(insuranceHistoryProvider(widget.busId));
    
    return Stack(
      children: [
        Column(
          children: [
            // Filtres
            Builder(
              builder: (context) => Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        'Période',
                        ['Aujourd\'hui', 'Ce mois', 'Année'],
                        _selectedInsurancePeriod,
                        (value) {
                          if (value != null && mounted) {
                            setState(() {
                              _selectedInsurancePeriod = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        'Année',
                        ['2025', '2024', '2023'],
                        _selectedInsuranceYear,
                        (value) {
                          if (value != null && mounted) {
                            setState(() {
                              _selectedInsuranceYear = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Liste filtrée
            Expanded(
              child: insuranceAsync.when(
                data: (response) {
                  final filteredData = _filterInsurances(response.data);
                  
                  if (filteredData.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(insuranceHistoryProvider(widget.busId));
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: _buildEmptyState(
                            _selectedInsurancePeriod.isNotEmpty || _selectedInsuranceYear.isNotEmpty
                                ? 'Aucune assurance pour cette période'
                                : 'Aucune assurance enregistrée'
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(insuranceHistoryProvider(widget.busId));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                      final insurance = filteredData[index];
            final isActive = insurance.expiryDate.isAfter(DateTime.now());
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InsuranceDetailScreen(
                        insurance: insurance,
                        busId: widget.busId,
                      ),
                    ),
                  ).then((needsRefresh) {
                    if (needsRefresh == true) {
                      ref.invalidate(insuranceHistoryProvider(widget.busId));
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
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
                      _InfoRow('Début', _formatDate(insurance.startDate)),
                      _InfoRow('Fin', _formatDate(insurance.expiryDate)),
                      _InfoRow('Coût', '${insurance.cost.toStringAsFixed(0)} FCFA'),
                      if (insurance.documentPhoto != null && insurance.documentPhoto!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.attach_file, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'Document disponible',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
                    },
                  ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),
        
        // Bouton FAB pour ajouter une assurance
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'insurance_fab',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InsuranceFormScreen(busId: widget.busId),
                ),
              );
              // Rafraîchir la liste
              ref.invalidate(insuranceHistoryProvider(widget.busId));
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownsTab(WidgetRef ref) {
    final breakdownsState = ref.watch(breakdownsProvider(widget.busId));
    
    return Stack(
      children: [
        Column(
          children: [
            // Filtres
            Builder(
              builder: (context) => Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        'Période',
                        ['Aujourd\'hui', 'Ce mois', 'Année'],
                        _selectedBreakdownPeriod,
                        (value) {
                          if (value != null && mounted) {
                            setState(() {
                              _selectedBreakdownPeriod = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        'Année',
                        ['2025', '2024', '2023'],
                        _selectedBreakdownYear,
                        (value) {
                          if (value != null && mounted) {
                            setState(() {
                              _selectedBreakdownYear = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Liste filtrée
            Expanded(
              child: breakdownsState.isLoading && breakdownsState.breakdowns.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Builder(
                      builder: (context) {
                        final filteredData = _filterBreakdowns(breakdownsState.breakdowns);
                        
                        if (filteredData.isEmpty) {
                          return RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(breakdownsProvider(widget.busId));
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: _buildEmptyState(
                                  _selectedBreakdownPeriod.isNotEmpty || _selectedBreakdownYear.isNotEmpty
                                      ? 'Aucune panne pour cette période'
                                      : 'Aucune panne enregistrée'
                                ),
                              ),
                            ),
                          );
                        }
                        
                        return RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(breakdownsProvider(widget.busId));
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredData.length,
                            itemBuilder: (context, index) {
                            final breakdown = filteredData[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BreakdownDetailScreen(
                    breakdown: breakdown,
                    busId: widget.busId,
                  ),
                ),
              ).then((needsRefresh) {
                if (needsRefresh == true) {
                  ref.invalidate(breakdownsProvider(widget.busId));
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: _getStatutColor(breakdown.statutReparation),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        breakdown.descriptionProbleme,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                        color: _getStatutColor(breakdown.statutReparation).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatutLabel(breakdown.statutReparation),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getStatutColor(breakdown.statutReparation),
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
                Text(
                  'Réparation: ${breakdown.reparationEffectuee}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (breakdown.prixPiece != null)
                  Text(
                    'Coût pièce: ${breakdown.prixPiece!.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          ),
        );
                          },
                        ),
                        );
                      },
                    ),
            ),
          ],
        ),
        
        // Bouton FAB pour ajouter une panne
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'breakdown_fab',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BreakdownFormScreen(busId: widget.busId),
                ),
              );
              // Rafraîchir la liste
              ref.invalidate(breakdownsProvider(widget.busId));
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildVidangesTab(WidgetRef ref) {
    final vidangesState = ref.watch(vidangesProvider(widget.busId));
    
    if (vidangesState.isLoading && vidangesState.vidanges.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (vidangesState.vidanges.isEmpty) {
      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vidangesProvider(widget.busId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _buildEmptyState('Aucune vidange enregistrée'),
              ),
            ),
          ),
          
          // Bouton FAB pour ajouter une vidange
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'vidange_fab',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VidangeFormScreen(busId: widget.busId),
                  ),
                );
                // Rafraîchir la liste
                ref.invalidate(vidangesProvider(widget.busId));
              },
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }
    
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(vidangesProvider(widget.busId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: vidangesState.vidanges.length,
            itemBuilder: (context, index) {
            final vidange = vidangesState.vidanges[index];
            final now = DateTime.now();
            final daysRemaining = vidange.nextVidangeDate.difference(now).inDays;
            final isPast = daysRemaining < 0;
            final isUrgent = daysRemaining >= 0 && daysRemaining <= 3;
            
            Color statusColor;
            IconData statusIcon;
            String statusText;
            
            if (isPast) {
              statusColor = Colors.red;
              statusIcon = Icons.warning_rounded;
              statusText = 'EN RETARD';
            } else if (isUrgent) {
              statusColor = Colors.orange;
              statusIcon = Icons.warning;
              statusText = 'URGENT - $daysRemaining jour${daysRemaining > 1 ? 's' : ''}';
            } else {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              statusText = 'OK - $daysRemaining jours';
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: (isPast || isUrgent) ? 4 : 1,
              color: (isPast || isUrgent) 
                  ? statusColor.withValues(alpha: 0.05)
                  : null,
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VidangeDetailScreen(
                        vidange: vidange,
                        busId: widget.busId,
                      ),
                    ),
                  ).then((needsRefresh) {
                    if (needsRefresh == true) {
                      ref.invalidate(vidangesProvider(widget.busId));
                    }
                  });
                },
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.oil_barrel,
                    color: statusColor,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Vidange ${isPast ? "en retard" : isUrgent ? "urgente" : "planifiée"}',
                        style: TextStyle(
                          fontWeight: (isPast || isUrgent) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isPast || isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Dernière: ${_formatDate(vidange.lastVidangeDate)}'),
                    Text(
                      'Prochaine: ${_formatDate(vidange.nextVidangeDate)}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: (isPast || isUrgent) ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (vidange.notes != null && vidange.notes!.isNotEmpty)
                      Text(
                        vidange.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: Icon(
                  statusIcon,
                  color: statusColor,
                  size: (isPast || isUrgent) ? 32 : 24,
                ),
              ),
            );
          },
        ),
        ),
        
        // Bouton FAB pour ajouter une vidange
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'vidange_fab',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VidangeFormScreen(busId: widget.busId),
                ),
              );
              // Rafraîchir la liste
              ref.invalidate(vidangesProvider(widget.busId));
            },
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add),
          ),
        ),
      ],
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
                onPressed: () => ref.refresh(busDetailsProvider(widget.busId)),
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

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'terminee':
        return Colors.green;
      case 'en_cours':
        return Colors.blue;
      case 'en_attente_pieces':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut.toLowerCase()) {
      case 'terminee':
        return 'Terminée';
      case 'en_cours':
        return 'En cours';
      case 'en_attente_pieces':
        return 'En attente pièces';
      default:
        return statut;
    }
  }

  // ===== Méthodes pour Visites Techniques =====
  
  void _showTechnicalVisitDetails(TechnicalVisit visit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicalVisitDetailScreen(
          visit: visit,
          busId: widget.busId,
        ),
      ),
    ).then((needsRefresh) {
      if (needsRefresh == true) {
        // Rafraîchir les données après modification/suppression
        ref.invalidate(busDetailsProvider(widget.busId));
      }
    });
  }

  void _editTechnicalVisit(TechnicalVisit visit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicalVisitFormScreen(
          busId: widget.busId,
          visit: visit,
        ),
      ),
    ).then((_) {
      // Rafraîchir les données après modification
      ref.invalidate(busDetailsProvider(widget.busId));
    });
  }

  void _deleteTechnicalVisit(TechnicalVisit visit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la visite'),
        content: Text(
          'Voulez-vous vraiment supprimer la visite technique du ${_formatDate(visit.visitDate)} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await BusApiService().deleteTechnicalVisit(widget.busId, visit.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Visite technique supprimée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Rafraîchir les données
                  ref.invalidate(busDetailsProvider(widget.busId));
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
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Filtrer les enregistrements de carburant selon la période et l'année sélectionnées
  List<FuelRecord> _filterFuelRecords(List<FuelRecord> records) {
    final now = DateTime.now();
    
    return records.where((record) {
      final recordDate = record.fueledAt;
      
      // Filtre par année
      if (_selectedYear.isNotEmpty) {
        final yearInt = int.tryParse(_selectedYear);
        if (yearInt != null && recordDate.year != yearInt) {
          return false;
        }
      }
      
      // Filtre par période
      if (_selectedPeriod.isNotEmpty) {
        switch (_selectedPeriod) {
          case 'Aujourd\'hui':
            if (recordDate.year != now.year ||
                recordDate.month != now.month ||
                recordDate.day != now.day) {
              return false;
            }
            break;
          case 'Ce mois':
            if (recordDate.year != now.year || recordDate.month != now.month) {
              return false;
            }
            break;
          case 'Année':
            if (recordDate.year != now.year) {
              return false;
            }
            break;
        }
      }
      
      return true;
    }).toList();
  }

  /// Calculer les statistiques filtrées
  Map<String, double> _calculateFilteredStats(List<FuelRecord> records) {
    final filteredRecords = _filterFuelRecords(records);
    
    double total = 0;
    for (var record in filteredRecords) {
      total += record.cost;
    }
    
    return {
      'total': total,
      'count': filteredRecords.length.toDouble(),
      'average': filteredRecords.isEmpty ? 0 : total / filteredRecords.length,
    };
  }

  /// Filtrer les visites techniques selon la période et l'année
  List<TechnicalVisit> _filterTechnicalVisits(List<TechnicalVisit> visits) {
    final now = DateTime.now();
    
    return visits.where((visit) {
      final visitDate = visit.visitDate;
      
      // Filtre par année
      if (_selectedTechYear.isNotEmpty) {
        final yearInt = int.tryParse(_selectedTechYear);
        if (yearInt != null && visitDate.year != yearInt) {
          return false;
        }
      }
      
      // Filtre par période
      if (_selectedTechPeriod.isNotEmpty) {
        switch (_selectedTechPeriod) {
          case 'Aujourd\'hui':
            if (visitDate.year != now.year ||
                visitDate.month != now.month ||
                visitDate.day != now.day) {
              return false;
            }
            break;
          case 'Ce mois':
            if (visitDate.year != now.year || visitDate.month != now.month) {
              return false;
            }
            break;
          case 'Année':
            if (visitDate.year != now.year) {
              return false;
            }
            break;
        }
      }
      
      return true;
    }).toList();
  }

  /// Filtrer les assurances selon la période et l'année
  List<InsuranceRecord> _filterInsurances(List<InsuranceRecord> insurances) {
    final now = DateTime.now();
    
    return insurances.where((insurance) {
      final startDate = insurance.startDate;
      
      // Filtre par année
      if (_selectedInsuranceYear.isNotEmpty) {
        final yearInt = int.tryParse(_selectedInsuranceYear);
        if (yearInt != null && startDate.year != yearInt) {
          return false;
        }
      }
      
      // Filtre par période
      if (_selectedInsurancePeriod.isNotEmpty) {
        switch (_selectedInsurancePeriod) {
          case 'Aujourd\'hui':
            if (startDate.year != now.year ||
                startDate.month != now.month ||
                startDate.day != now.day) {
              return false;
            }
            break;
          case 'Ce mois':
            if (startDate.year != now.year || startDate.month != now.month) {
              return false;
            }
            break;
          case 'Année':
            if (startDate.year != now.year) {
              return false;
            }
            break;
        }
      }
      
      return true;
    }).toList();
  }

  /// Filtrer les pannes selon la période et l'année
  List<BusBreakdown> _filterBreakdowns(List<BusBreakdown> breakdowns) {
    final now = DateTime.now();
    
    return breakdowns.where((breakdown) {
      final reportDate = breakdown.breakdownDate;
      
      // Filtre par année
      if (_selectedBreakdownYear.isNotEmpty) {
        final yearInt = int.tryParse(_selectedBreakdownYear);
        if (yearInt != null && reportDate.year != yearInt) {
          return false;
        }
      }
      
      // Filtre par période
      if (_selectedBreakdownPeriod.isNotEmpty) {
        switch (_selectedBreakdownPeriod) {
          case 'Aujourd\'hui':
            if (reportDate.year != now.year ||
                reportDate.month != now.month ||
                reportDate.day != now.day) {
              return false;
            }
            break;
          case 'Ce mois':
            if (reportDate.year != now.year || reportDate.month != now.month) {
              return false;
            }
            break;
          case 'Année':
            if (reportDate.year != now.year) {
              return false;
            }
            break;
        }
      }
      
      return true;
    }).toList();
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
