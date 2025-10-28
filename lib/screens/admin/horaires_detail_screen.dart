import 'package:flutter/material.dart';
import '../../models/horaire_model.dart';
import '../../services/horaire_service.dart';
import '../../theme/app_theme.dart';
import 'horaire_form_screen.dart';

class HorairesDetailScreen extends StatefulWidget {
  const HorairesDetailScreen({super.key});

  @override
  State<HorairesDetailScreen> createState() => _HorairesDetailScreenState();
}

class _HorairesDetailScreenState extends State<HorairesDetailScreen> {
  final _horaireService = HoraireService();
  final _searchController = TextEditingController();
  
  List<Horaire> _allHoraires = [];
  List<Horaire> _filteredHoraires = [];
  Map<String, List<Horaire>> _horairesByGare = {};
  
  bool _isLoading = true;
  String? _selectedGareFilter;
  String? _selectedStatutFilter;
  String? _selectedTrajetFilter;
  String _selectedSortOption = 'heure'; // heure, gare, statut
  
  // Listes pour les filtres
  List<String> _garesNames = [];
  List<String> _trajetsDestinations = [];

  @override
  void initState() {
    super.initState();
    _loadHoraires();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHoraires() async {
    setState(() => _isLoading = true);
    try {
      final horaires = await _horaireService.fetchAllHoraires();
      setState(() {
        _allHoraires = horaires;
        _filteredHoraires = horaires;
        _groupHorairesByGare();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement horaires: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _loadHoraires,
            ),
          ),
        );
      }
    }
  }

  void _groupHorairesByGare() {
    _horairesByGare.clear();
    _garesNames.clear();
    _trajetsDestinations.clear();
    
    // Collecter les destinations uniques pour le filtre
    final destinationsSet = <String>{};
    
    for (var horaire in _filteredHoraires) {
      final gareName = horaire.gare.nom;
      if (!_horairesByGare.containsKey(gareName)) {
        _horairesByGare[gareName] = [];
        _garesNames.add(gareName);
      }
      _horairesByGare[gareName]!.add(horaire);
      
      // Ajouter la destination
      destinationsSet.add(horaire.trajet.destination);
    }
    
    _trajetsDestinations = destinationsSet.toList()..sort();
    
    // Trier les horaires dans chaque gare selon l'option de tri
    _horairesByGare.forEach((key, value) {
      _sortHoraires(value);
    });
    
    // Trier les noms de gares
    _garesNames.sort();
  }
  
  void _sortHoraires(List<Horaire> horaires) {
    switch (_selectedSortOption) {
      case 'heure':
        horaires.sort((a, b) => a.heure.compareTo(b.heure));
        break;
      case 'statut':
        horaires.sort((a, b) {
          final order = {'a_l_heure': 0, 'embarquement': 1, 'termine': 2};
          return (order[a.statut] ?? 3).compareTo(order[b.statut] ?? 3);
        });
        break;
      case 'destination':
        horaires.sort((a, b) => a.trajet.destination.compareTo(b.trajet.destination));
        break;
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredHoraires = _allHoraires.where((horaire) {
        // Filtre par recherche (heure ou trajet)
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty || 
            horaire.heure.contains(searchQuery) ||
            horaire.trajet.embarquement.toLowerCase().contains(searchQuery) ||
            horaire.trajet.destination.toLowerCase().contains(searchQuery);
        
        // Filtre par gare
        final matchesGare = _selectedGareFilter == null || 
            horaire.gare.nom == _selectedGareFilter;
        
        // Filtre par statut
        final matchesStatut = _selectedStatutFilter == null || 
            horaire.statut == _selectedStatutFilter;
        
        // Filtre par destination
        final matchesTrajet = _selectedTrajetFilter == null ||
            horaire.trajet.destination == _selectedTrajetFilter;
        
        return matchesSearch && matchesGare && matchesStatut && matchesTrajet;
      }).toList();
      
      _groupHorairesByGare();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedGareFilter = null;
      _selectedStatutFilter = null;
      _selectedTrajetFilter = null;
      _selectedSortOption = 'heure';
      _filteredHoraires = _allHoraires;
      _groupHorairesByGare();
    });
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'a_l_heure':
        return Colors.blue;
      case 'embarquement':
        return Colors.green;
      case 'termine':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut) {
      case 'a_l_heure':
        return Icons.check_circle;
      case 'embarquement':
        return Icons.flight_takeoff;
      case 'termine':
        return Icons.check_circle_outline;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails des Horaires'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHoraires,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1a1a2e),
                  const Color(0xFF16213e),
                ],
              ),
            ),
            child: Column(
              children: [
                // Recherche par heure ou trajet
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Rechercher (heure, ville...)',
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    hintText: 'Ex: 06:00, Dakar, Thiès',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey.shade400),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0f3460),
                  ),
                  onChanged: (value) => _applyFilters(),
                ),
                
                const SizedBox(height: 12),
                
                // Ligne 1: Gare et Statut
                Row(
                  children: [
                    // Filtre par gare
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGareFilter,
                        dropdownColor: const Color(0xFF0f3460),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Gare',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.location_on, size: 20, color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0f3460),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8,
                          ),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Toutes', style: TextStyle(fontSize: 14)),
                          ),
                          ..._garesNames.map((gare) => DropdownMenuItem(
                            value: gare,
                            child: Text(gare, 
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedGareFilter = value);
                          _applyFilters();
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Filtre par statut
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatutFilter,
                        dropdownColor: const Color(0xFF0f3460),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Statut',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.info_outline, size: 20, color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0f3460),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8,
                          ),
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Tous', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'a_l_heure',
                            child: Text('À l\'heure', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'embarquement',
                            child: Text('Embarquement', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'termine',
                            child: Text('Terminé', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatutFilter = value);
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Ligne 2: Destination et Tri
                Row(
                  children: [
                    // Filtre par destination
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTrajetFilter,
                        dropdownColor: const Color(0xFF0f3460),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Destination',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.place, size: 20, color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0f3460),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8,
                          ),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Toutes', style: TextStyle(fontSize: 14)),
                          ),
                          ..._trajetsDestinations.map((dest) => DropdownMenuItem(
                            value: dest,
                            child: Text(dest, 
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedTrajetFilter = value);
                          _applyFilters();
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Tri
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSortOption,
                        dropdownColor: const Color(0xFF0f3460),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Trier par',
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.sort, size: 20, color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0f3460),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8,
                          ),
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'heure',
                            child: Text('Heure', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'statut',
                            child: Text('Statut', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'destination',
                            child: Text('Destination', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedSortOption = value!);
                          _groupHorairesByGare();
                        },
                      ),
                    ),
                  ],
                ),
                
                // Bouton réinitialiser si des filtres sont actifs
                if (_selectedGareFilter != null || 
                    _selectedStatutFilter != null ||
                    _selectedTrajetFilter != null ||
                    _searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.clear_all, color: Colors.white70),
                          label: const Text('Réinitialiser', 
                            style: TextStyle(color: Colors.white70),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_filteredHoraires.length} résultat${_filteredHoraires.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Résultats
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHoraires.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, 
                              size: 64, 
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun horaire trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _resetFilters,
                              child: const Text('Réinitialiser les filtres'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHoraires,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _horairesByGare.length,
                          itemBuilder: (context, index) {
                            final gareName = _garesNames[index];
                            final horaires = _horairesByGare[gareName]!;
                            
                            return _buildGareSection(gareName, horaires);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGareSection(String gareName, List<Horaire> horaires) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la gare
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1a1a2e),
                  const Color(0xFF16213e),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, 
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    gareName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${horaires.length} horaire${horaires.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des horaires
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: horaires.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final horaire = horaires[index];
              return _buildHoraireItem(horaire);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHoraireItem(Horaire horaire) {
    final statutColor = _getStatutColor(horaire.statut);
    final statutIcon = _getStatutIcon(horaire.statut);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: statutColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, color: statutColor, size: 20),
            const SizedBox(height: 4),
            Text(
              horaire.heure,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statutColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${horaire.trajet.embarquement} → ${horaire.trajet.destination}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Icon(statutIcon, color: statutColor, size: 20),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (horaire.busNumber != null)
            Row(
              children: [
                const Icon(Icons.directions_bus, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Bus: ${horaire.busNumber}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statutColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              horaire.statutLibelle,
              style: TextStyle(
                color: statutColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        color: AppTheme.primaryBlue,
        onPressed: () => _editHoraire(horaire),
        tooltip: 'Modifier',
      ),
      onTap: () => _showHoraireDetails(horaire),
    );
  }

  void _editHoraire(Horaire horaire) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HoraireFormScreen(horaire: horaire),
      ),
    );
    
    if (result == true) {
      _loadHoraires();
    }
  }

  void _showHoraireDetails(Horaire horaire) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final statutColor = _getStatutColor(horaire.statut);
          
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicateur de drag
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Titre
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statutColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStatutIcon(horaire.statut),
                          color: statutColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Horaire #${horaire.id}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              horaire.statutLibelle,
                              style: TextStyle(
                                fontSize: 16,
                                color: statutColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Informations
                  _buildDetailRow(
                    Icons.access_time,
                    'Heure de départ',
                    horaire.heure,
                    Colors.blue,
                  ),
                  
                  _buildDetailRow(
                    Icons.location_on,
                    'Gare',
                    horaire.gare.nom,
                    Colors.orange,
                  ),
                  
                  _buildDetailRow(
                    Icons.route,
                    'Trajet',
                    '${horaire.trajet.embarquement} → ${horaire.trajet.destination}',
                    Colors.purple,
                  ),
                  
                  _buildDetailRow(
                    Icons.attach_money,
                    'Prix',
                    '${horaire.trajet.prix.toStringAsFixed(0)} FCFA',
                    Colors.green,
                  ),
                  
                  if (horaire.busNumber != null)
                    _buildDetailRow(
                      Icons.directions_bus,
                      'Bus assigné',
                      horaire.busNumber!,
                      Colors.teal,
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _editHoraire(horaire);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Modifier'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Fermer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
