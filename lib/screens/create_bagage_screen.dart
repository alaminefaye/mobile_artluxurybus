import 'package:flutter/material.dart';
import '../services/bagage_api_service.dart';
import '../services/mail_api_service.dart';

class CreateBagageScreen extends StatefulWidget {
  const CreateBagageScreen({super.key});

  @override
  State<CreateBagageScreen> createState() => _CreateBagageScreenState();
}

class _CreateBagageScreenState extends State<CreateBagageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _valeurController = TextEditingController();
  final _poidsController = TextEditingController();
  final _montantController = TextEditingController();
  final _contenuController = TextEditingController();
  final _ticketNumberController = TextEditingController();

  String? _selectedDestination;
  bool _hasTicket = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Écouteurs pour auto-fill
    _telephoneController.addListener(() {
      final phone = _telephoneController.text.trim();
      if (phone.length == 10) {
        _autoFillFromPhone(phone);
      }
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _valeurController.dispose();
    _poidsController.dispose();
    _montantController.dispose();
    _contenuController.dispose();
    _ticketNumberController.dispose();
    super.dispose();
  }

  Future<void> _autoFillFromPhone(String phone) async {
    try {
      final result = await MailApiService.checkLoyaltyPoints(phone);
      
      if (result['success'] == true && result['client'] != null) {
        final clientName = result['client']['nom_complet'] ?? '';
        
        if (clientName.isNotEmpty) {
          // Séparer le nom complet en nom et prénom
          final parts = clientName.trim().split(' ');
          String nom = '';
          String prenom = '';
          
          if (parts.length == 1) {
            // Si un seul mot, mettre dans le nom
            nom = parts[0];
          } else if (parts.length >= 2) {
            // Le premier mot = nom, le reste = prénom
            nom = parts[0];
            prenom = parts.sublist(1).join(' ');
          }
          
          setState(() {
            // Remplir seulement si les champs sont vides
            if (_nomController.text.isEmpty && nom.isNotEmpty) {
              _nomController.text = nom;
            }
            if (_prenomController.text.isEmpty && prenom.isNotEmpty) {
              _prenomController.text = prenom;
            }
          });
          
          // Afficher un message de confirmation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Client trouvé: $clientName'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement (client non trouvé = normal)
      debugPrint('Client non trouvé pour le numéro $phone');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une destination'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await BagageApiService.createBagage(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        destination: _selectedDestination!,
        valeur: _valeurController.text.isNotEmpty
            ? double.parse(_valeurController.text)
            : null,
        poids: _poidsController.text.isNotEmpty
            ? double.parse(_poidsController.text)
            : null,
        montant: _montantController.text.isNotEmpty
            ? double.parse(_montantController.text)
            : null,
        contenu: _contenuController.text.trim().isEmpty
            ? null
            : _contenuController.text.trim(),
        hasTicket: _hasTicket,
        ticketNumber: _ticketNumberController.text.trim().isEmpty
            ? null
            : _ticketNumberController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bagage enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            'Nouveau Bagage',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Titre section propriétaire
                    const Text(
                      'Informations du propriétaire',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nom
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ce champ est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Prénom
                    TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ce champ est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Téléphone
                    TextFormField(
                      controller: _telephoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone *',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                        hintText: '0707123456',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ce champ est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Titre section bagage
                    const Text(
                      'Informations du bagage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Destination
                    DropdownButtonFormField<String>(
                      value: _selectedDestination,
                      decoration: const InputDecoration(
                        labelText: 'Destination *',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Sélectionner une destination'),
                      items: BagageApiService.getDestinations().map((dest) {
                        return DropdownMenuItem(
                          value: dest,
                          child: Text(dest),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner une destination';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedDestination = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Row: Poids et Valeur
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _poidsController,
                            decoration: const InputDecoration(
                              labelText: 'Poids (kg)',
                              prefixIcon: Icon(Icons.scale),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _valeurController,
                            decoration: const InputDecoration(
                              labelText: 'Valeur (FCFA)',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Montant
                    TextFormField(
                      controller: _montantController,
                      decoration: const InputDecoration(
                        labelText: 'Montant à payer (FCFA)',
                        prefixIcon: Icon(Icons.payments),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Contenu
                    TextFormField(
                      controller: _contenuController,
                      decoration: const InputDecoration(
                        labelText: 'Contenu',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        hintText: 'Description du contenu',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Titre section ticket
                    const Text(
                      'Informations ticket',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Switch: Le client possède un ticket?
                    SwitchListTile(
                      title: const Text('Le client possède un ticket ?'),
                      subtitle: Text(
                        _hasTicket
                            ? 'Oui, le client a un ticket'
                            : 'Non, le client n\'a pas de ticket',
                      ),
                      value: _hasTicket,
                      onChanged: (value) {
                        setState(() {
                          _hasTicket = value;
                          if (!value) {
                            _ticketNumberController.clear();
                          }
                        });
                      },
                      activeColor: Colors.green,
                    ),

                    // Numéro de ticket (si has_ticket = true)
                    if (_hasTicket) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ticketNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de ticket',
                          prefixIcon: Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(),
                          hintText: 'Ex: BG35438',
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Bouton d'enregistrement
                    ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.check_circle, size: 24),
                      label: const Text(
                        'Enregistrer le bagage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}

