import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/horaire_model.dart';
import '../../services/horaire_service.dart';
import '../../theme/app_theme.dart';

class HoraireFormScreen extends ConsumerStatefulWidget {
  final Horaire? horaire; // null = création, non-null = modification

  const HoraireFormScreen({super.key, this.horaire});

  @override
  ConsumerState<HoraireFormScreen> createState() => _HoraireFormScreenState();
}

class _HoraireFormScreenState extends ConsumerState<HoraireFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heureController = TextEditingController();
  final _horaireService = HoraireService();
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool get _isEditing => widget.horaire != null;

  // Listes déroulantes
  List<Gare> _gares = [];
  List<Trajet> _trajets = [];
  List<Bus> _buses = [];

  // Sélections
  Gare? _selectedGare;
  Trajet? _selectedTrajet;
  Bus? _selectedBus;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (_isEditing) {
      _heureController.text = widget.horaire!.heure;
      _selectedGare = Gare(
        id: widget.horaire!.gare.id,
        nom: widget.horaire!.gare.nom,
        appareil: widget.horaire!.gare.appareil,
      );
      _selectedTrajet = widget.horaire!.trajet;
      if (widget.horaire!.busNumber != null) {
        // Le bus sera sélectionné une fois la liste chargée
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final results = await Future.wait([
        _horaireService.fetchGares(),
        _horaireService.fetchTrajets(),
        _horaireService.fetchBuses(),
      ]);

      setState(() {
        _gares = results[0] as List<Gare>;
        _trajets = results[1] as List<Trajet>;
        _buses = results[2] as List<Bus>;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _heureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Modifier l\'horaire' : 'Nouvel horaire'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'horaire' : 'Nouvel horaire'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Message d'information
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isEditing
                              ? 'Modification de l\'horaire #${widget.horaire!.id}'
                              : 'Interface de création d\'horaire',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Heure
              TextFormField(
                controller: _heureController,
                decoration: InputDecoration(
                  labelText: 'Heure de départ',
                  hintText: 'HH:MM',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une heure';
                  }
                  // Validation format HH:MM
                  final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
                  if (!timeRegex.hasMatch(value)) {
                    return 'Format invalide (HH:MM)';
                  }
                  return null;
                },
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    _heureController.text = 
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),

              const SizedBox(height: 16),

              // Sélection Gare
              DropdownButtonFormField<Gare>(
                value: _selectedGare,
                decoration: InputDecoration(
                  labelText: 'Gare *',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _gares.map((gare) {
                  return DropdownMenuItem(
                    value: gare,
                    child: Text(gare.nom),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedGare = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une gare';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Sélection Trajet
              DropdownButtonFormField<Trajet>(
                value: _selectedTrajet,
                decoration: InputDecoration(
                  labelText: 'Trajet *',
                  prefixIcon: const Icon(Icons.route),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _trajets.map((trajet) {
                  return DropdownMenuItem(
                    value: trajet,
                    child: Text('${trajet.embarquement} → ${trajet.destination}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTrajet = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner un trajet';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Sélection Bus (optionnel)
              DropdownButtonFormField<Bus>(
                value: _selectedBus,
                decoration: InputDecoration(
                  labelText: 'Bus (optionnel)',
                  prefixIcon: const Icon(Icons.directions_bus),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem<Bus>(
                    value: null,
                    child: Text('Aucun'),
                  ),
                  ..._buses.map((bus) {
                    return DropdownMenuItem(
                      value: bus,
                      child: Text('${bus.registrationNumber} (${bus.seatCount} places)'),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() => _selectedBus = value);
                },
              ),

              const SizedBox(height: 32),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveHoraire,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
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
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(_isEditing ? 'Modifier' : 'Créer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveHoraire() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGare == null || _selectedTrajet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        // Modification
        await _horaireService.updateHoraire(
          id: widget.horaire!.id,
          gareId: _selectedGare!.id,
          trajetId: _selectedTrajet!.id ?? 0,
          busId: _selectedBus?.id,
          heure: _heureController.text,
        );
      } else {
        // Création
        await _horaireService.createHoraire(
          gareId: _selectedGare!.id,
          trajetId: _selectedTrajet!.id ?? 0,
          busId: _selectedBus?.id,
          heure: _heureController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Horaire modifié avec succès' 
                : 'Horaire créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true = succès
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
