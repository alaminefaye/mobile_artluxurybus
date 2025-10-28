import 'package:flutter/material.dart';
import '../../models/horaire_model.dart';
import '../../theme/app_theme.dart';

class HoraireFormScreen extends StatefulWidget {
  final Horaire? horaire; // null = création, non-null = modification

  const HoraireFormScreen({super.key, this.horaire});

  @override
  State<HoraireFormScreen> createState() => _HoraireFormScreenState();
}

class _HoraireFormScreenState extends State<HoraireFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heureController = TextEditingController();
  
  bool _isLoading = false;
  bool get _isEditing => widget.horaire != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _heureController.text = widget.horaire!.heure;
    }
  }

  @override
  void dispose() {
    _heureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

              // Sélection Gare (TODO)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Gare'),
                  subtitle: Text(_isEditing ? widget.horaire!.gare.nom : 'À sélectionner'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sélection de gare - À implémenter')),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Sélection Trajet (TODO)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.route),
                  title: const Text('Trajet'),
                  subtitle: Text(_isEditing 
                      ? '${widget.horaire!.trajet.embarquement} → ${widget.horaire!.trajet.destination}'
                      : 'À sélectionner'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sélection de trajet - À implémenter')),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Sélection Bus (TODO)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_bus),
                  title: const Text('Bus'),
                  subtitle: Text(_isEditing && widget.horaire!.busNumber != null
                      ? widget.horaire!.busNumber!
                      : 'Optionnel'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sélection de bus - À implémenter')),
                    );
                  },
                ),
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

    setState(() => _isLoading = true);

    try {
      // TODO: Implémenter l'appel API
      await Future.delayed(const Duration(seconds: 1));

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
