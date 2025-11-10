import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/embarkment_model.dart';
import '../services/embarkment_service.dart';
import '../services/depart_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_helper.dart';
import 'embarkment_detail_screen.dart';

class EmbarkmentScreen extends ConsumerStatefulWidget {
  const EmbarkmentScreen({super.key});

  @override
  ConsumerState<EmbarkmentScreen> createState() => _EmbarkmentScreenState();
}

class _EmbarkmentScreenState extends ConsumerState<EmbarkmentScreen> {
  List<EmbarkmentDepart> _departs = [];
  List<EmbarkmentDepart> _filteredDeparts = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Recherche et filtres
  final TextEditingController _searchController = TextEditingController();
  String? _selectedEmbarquement;
  String? _selectedDestination;
  String? _selectedHeure;
  List<String> _embarquements = [];
  List<String> _destinations = [];
  List<String> _heures = [];

  @override
  void initState() {
    super.initState();
    _loadDeparts();
    _loadTrajets();
    _searchController.addListener(_filterDeparts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrajets() async {
    try {
      final embarquements = await DepartService.getEmbarquements();
      final destinations = await DepartService.getDestinations();
      
      // Extraire les heures uniques des départs
      final heuresSet = <String>{};
      for (var depart in _departs) {
        if (depart.heureDepart != null && depart.heureDepart!.isNotEmpty) {
          heuresSet.add(depart.heureDepart!);
        }
      }
      final heures = heuresSet.toList()..sort();
      
      setState(() {
        _embarquements = embarquements;
        _destinations = destinations;
        _heures = heures;
      });
    } catch (e) {
      debugPrint('Erreur chargement trajets: $e');
    }
  }

  void _filterDeparts() {
    setState(() {
      _filteredDeparts = _departs.where((depart) {
        // Filtre par recherche
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          final routeText = depart.routeText.toLowerCase();
          final busNumber = depart.bus?.registrationNumber?.toLowerCase() ?? '';
          final departNumber = depart.numeroDepart?.toLowerCase() ?? '';
          if (!routeText.contains(searchQuery) &&
              !busNumber.contains(searchQuery) &&
              !departNumber.contains(searchQuery)) {
            return false;
          }
        }

        // Filtre par embarquement
        if (_selectedEmbarquement != null && _selectedEmbarquement!.isNotEmpty) {
          if (depart.trajet?.embarquement != _selectedEmbarquement) {
            return false;
          }
        }

        // Filtre par destination
        if (_selectedDestination != null && _selectedDestination!.isNotEmpty) {
          if (depart.trajet?.destination != _selectedDestination) {
            return false;
          }
        }

        // Filtre par heure
        if (_selectedHeure != null && _selectedHeure!.isNotEmpty) {
          if (depart.heureDepart != _selectedHeure) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedEmbarquement = null;
      _selectedDestination = null;
      _selectedHeure = null;
    });
    _filterDeparts();
  }

  Future<void> _loadDeparts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await EmbarkmentService.getDepartsForEmbarkment();
      
      if (result['success'] == true) {
        final data = result['data'] as List<dynamic>;
        setState(() {
          _departs = data
              .map((json) => EmbarkmentDepart.fromJson(json as Map<String, dynamic>))
              .toList();
          _filteredDeparts = _departs;
          _isLoading = false;
        });
        // Recharger les heures après avoir chargé les départs
        _loadTrajets();
        _filterDeparts();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorMessage = ErrorMessageHelper.getOperationError(
        'charger',
        error: e,
        customMessage: 'Impossible de charger les départs. Veuillez réessayer.',
      );
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion d\'Embarquement'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeparts,
            tooltip: 'Actualiser',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: Theme.of(context).cardColor,
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
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
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDeparts,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Section recherche et filtres
                    _buildSearchAndFilters(isDark),
                    
                    // Liste des départs
                    Expanded(
                      child: _departs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun départ disponible',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _filteredDeparts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.7)
                                            : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Aucun résultat trouvé',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark
                                              ? Colors.white
                                              : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: _clearFilters,
                                        child: Text(
                                          'Réinitialiser les filtres',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadDeparts,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _filteredDeparts.length,
                                    itemBuilder: (context, index) {
                                      final depart = _filteredDeparts[index];
                                      return _buildDepartCard(depart, isDark);
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    final hasActiveFilters = _searchController.text.isNotEmpty ||
        _selectedEmbarquement != null ||
        _selectedDestination != null ||
        _selectedHeure != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par trajet, bus, numéro...',
            hintStyle: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _filterDeparts();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          
          // Filtres par trajet
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Embarquement',
                  _embarquements,
                  _selectedEmbarquement,
                  (value) {
                    setState(() {
                      _selectedEmbarquement = value;
                    });
                    _filterDeparts();
                  },
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Destination',
                  _destinations,
                  _selectedDestination,
                  (value) {
                    setState(() {
                      _selectedDestination = value;
                    });
                    _filterDeparts();
                  },
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Filtre par heure
          _buildFilterDropdown(
            'Heure de départ',
            _heures,
            _selectedHeure,
            (value) {
              setState(() {
                _selectedHeure = value;
              });
              _filterDeparts();
            },
            isDark,
          ),
          
          // Bouton réinitialiser les filtres
          if (hasActiveFilters) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: Icon(
                  Icons.clear_all,
                  size: 18,
                  color: isDark
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  'Réinitialiser les filtres',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
            hint: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Tous',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            ...items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              );
            }),
          ],
          onChanged: onChanged,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 14,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildDepartCard(EmbarkmentDepart depart, bool isDark) {
    final isReady = depart.isReadyForEmbarkment;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isReady ? 4 : 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isReady
              ? AppTheme.primaryOrange
              : Theme.of(context).dividerColor,
          width: isReady ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmbarkmentDetailScreen(departId: depart.id),
            ),
          ).then((_) {
            // Recharger la liste après retour
            _loadDeparts();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec badge "Prêt pour embarquement"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          depart.routeText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Départ #${depart.numeroDepart ?? depart.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isReady)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PRÊT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Informations du départ
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    depart.dateDepartFormatted ?? depart.dateDepart ?? 'N/A',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    depart.heureDepart ?? 'N/A',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              if (depart.bus != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.directions_bus,
                      size: 16,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bus: ${depart.bus!.registrationNumber ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              
              // Statistiques
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Places',
                      '${depart.nombrePlaces}',
                      Icons.event_seat,
                      Colors.blue,
                      isDark,
                    ),
                    _buildStatItem(
                      'Réservées',
                      '${depart.placesReservees}',
                      Icons.bookmark,
                      Colors.orange,
                      isDark,
                    ),
                    _buildStatItem(
                      'Scannés',
                      '${depart.ticketsScannes}',
                      Icons.qr_code_scanner,
                      Colors.green,
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Déconnexion',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
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
}

