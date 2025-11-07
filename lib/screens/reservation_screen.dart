import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/depart_service.dart';
import 'departures_results_screen.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedEmbarquement;
  String? _selectedDestination;
  DateTime? _selectedDate;
  final _nombreSiegesController = TextEditingController();
  
  List<String> _embarquements = [];
  List<String> _destinations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _nombreSiegesController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final embarquements = await DepartService.getEmbarquements();
      final destinations = await DepartService.getDestinations();

      setState(() {
        _embarquements = embarquements;
        _destinations = destinations;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des villes: $e')),
        );
      }
    }
  }

  Future<void> _searchDeparts() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEmbarquement == null || _selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un embarquement et une destination'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dateStr = _selectedDate!.toIso8601String().split('T')[0];
      final nombreSieges = _nombreSiegesController.text.isNotEmpty
          ? int.tryParse(_nombreSiegesController.text)
          : null;

      final result = await DepartService.searchDeparts(
        embarquement: _selectedEmbarquement,
        destination: _selectedDestination,
        dateDepart: dateStr,
        nombreSieges: nombreSieges,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        final departs = result['data'] ?? [];
        // Naviguer vers la page de résultats
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeparturesResultsScreen(
                departs: departs,
                embarquement: _selectedEmbarquement!,
                destination: _selectedDestination!,
                date: _selectedDate!.toIso8601String().split('T')[0],
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors de la recherche'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: Colors.orange,
                    onPrimary: Colors.white,
                    surface: Theme.of(context).cardColor,
                    onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                  )
                : Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réserver un voyage'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Formulaire de recherche
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Embarquement
                  DropdownButtonFormField<String>(
                    value: _selectedEmbarquement,
                    decoration: InputDecoration(
                      labelText: 'Embarquement',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.location_on, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: _embarquements.map((ville) {
                      return DropdownMenuItem(
                        value: ville,
                        child: Text(ville, style: const TextStyle(color: Colors.black87)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEmbarquement = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Destination
                  DropdownButtonFormField<String>(
                    value: _selectedDestination,
                    decoration: InputDecoration(
                      labelText: 'Destination',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.place, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: _destinations.map((ville) {
                      return DropdownMenuItem(
                        value: ville,
                        child: Text(ville, style: const TextStyle(color: Colors.black87)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDestination = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white70),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Sélectionner une date',
                              style: TextStyle(
                                color: _selectedDate != null ? Colors.white : Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre de sièges (optionnel)
                  TextFormField(
                    controller: _nombreSiegesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nombre de sièges (optionnel)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Limite à 5 résultats',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      prefixIcon: const Icon(Icons.event_seat, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final num = int.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Nombre invalide';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Bouton de recherche
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _searchDeparts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Rechercher',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Espace vide - les résultats seront affichés sur une page séparée
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Remplissez le formulaire et cliquez sur "Rechercher"',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

