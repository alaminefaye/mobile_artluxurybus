import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/mail_api_service.dart';

class CreateMailScreen extends StatefulWidget {
  const CreateMailScreen({super.key});

  @override
  State<CreateMailScreen> createState() => _CreateMailScreenState();
}

class _CreateMailScreenState extends State<CreateMailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _packageValueController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedDestination;
  String? _selectedPackageType;
  String? _selectedReceivingAgency;
  File? _photo;
  bool _isLoyaltyMail = false;
  bool _isLoading = false;
  bool _isCheckingLoyalty = false;
  
  // Variables pour la fidélité
  final _loyaltyPhoneController = TextEditingController();
  Map<String, dynamic>? _clientLoyaltyInfo;
  int _clientPoints = 0;
  bool _canUseFreeMail = false;
  int? _clientProfileId;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    
    // Écouteur pour le téléphone de l'expéditeur
    _senderPhoneController.addListener(() {
      final phone = _senderPhoneController.text.trim();
      if (phone.length == 10) {
        _autoFillNameFromPhone(phone, isRecipient: false);
      }
    });
    
    // Écouteur pour le téléphone du bénéficiaire
    _recipientPhoneController.addListener(() {
      final phone = _recipientPhoneController.text.trim();
      if (phone.length == 10) {
        _autoFillNameFromPhone(phone, isRecipient: true);
      }
    });
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _amountController.dispose();
    _packageValueController.dispose();
    _descriptionController.dispose();
    _loyaltyPhoneController.dispose();
    super.dispose();
  }
  
  /// Auto-remplir le nom à partir du numéro de téléphone
  Future<void> _autoFillNameFromPhone(String phone, {required bool isRecipient}) async {
    try {
      final result = await MailApiService.checkLoyaltyPoints(phone);
      
      if (result['success'] == true && result['client'] != null) {
        final clientName = result['client']['nom_complet'] ?? '';
        
        if (clientName.isNotEmpty) {
          setState(() {
            if (isRecipient) {
              // Remplir le nom du bénéficiaire
              if (_recipientNameController.text.isEmpty) {
                _recipientNameController.text = clientName;
              }
            } else {
              // Remplir le nom de l'expéditeur
              if (_senderNameController.text.isEmpty) {
                _senderNameController.text = clientName;
              }
            }
          });
          
          // Afficher un message de confirmation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isRecipient 
                    ? '✓ Bénéficiaire trouvé: $clientName'
                    : '✓ Expéditeur trouvé: $clientName'
                ),
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

  /// Vérifier les points de fidélité d'un client
  Future<void> _checkLoyaltyPoints() async {
    if (_loyaltyPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un numéro de téléphone'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCheckingLoyalty = true);

    try {
      final result = await MailApiService.checkLoyaltyPoints(
        _loyaltyPhoneController.text.trim(),
      );

      if (result['success'] == true) {
        setState(() {
          _clientLoyaltyInfo = result['client'];
          _clientPoints = result['client']['points'] ?? 0;
          _canUseFreeMail = result['has_free_mail'] ?? false;
          _clientProfileId = result['client']['id'];
          
          // Pré-remplir le téléphone de l'expéditeur
          _senderPhoneController.text = result['client']['telephone'] ?? '';
          _senderNameController.text = result['client']['nom_complet'] ?? '';
        });

        if (mounted) {
          if (_canUseFreeMail) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Client trouvé! $_clientPoints points disponibles - Courrier gratuit possible!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Client trouvé! $_clientPoints points (10 requis pour un courrier gratuit)'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Client non trouvé'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _clientLoyaltyInfo = null;
          _clientPoints = 0;
          _canUseFreeMail = false;
          _clientProfileId = null;
        });
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
      setState(() {
        _clientLoyaltyInfo = null;
        _clientPoints = 0;
        _canUseFreeMail = false;
        _clientProfileId = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isCheckingLoyalty = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _photo = File(image.path);
      });
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

    if (_selectedPackageType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de colis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await MailApiService.createMail(
        destination: _selectedDestination!,
        senderName: _senderNameController.text.trim(),
        senderPhone: _senderPhoneController.text.trim(),
        recipientName: _recipientNameController.text.trim(),
        recipientPhone: _recipientPhoneController.text.trim(),
        amount: double.parse(_amountController.text),
        packageValue: _packageValueController.text.trim(),
        packageType: _selectedPackageType!,
        receivingAgency: _selectedReceivingAgency!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        photo: _photo,
        isLoyaltyMail: _isLoyaltyMail,
        clientProfileId: _clientProfileId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Courrier créé avec succès'),
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
        // Fermer le clavier quand on tape en dehors des champs
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
        title: const Text(
          'Nouveau Courrier',
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
                  // Section Fidélité courrier
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.card_giftcard, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Fidélité courrier',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Téléphone du client',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _loyaltyPhoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    hintText: 'Ex: 0123456789',
                                    prefixIcon: Icon(Icons.phone),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isCheckingLoyalty ? null : _checkLoyaltyPoints,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                child: _isCheckingLoyalty
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Vérifier'),
                              ),
                            ],
                          ),
                          if (_clientLoyaltyInfo != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _canUseFreeMail ? Colors.green.shade100 : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _canUseFreeMail ? Colors.green : Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _canUseFreeMail ? Icons.check_circle : Icons.info,
                                        color: _canUseFreeMail ? Colors.green : Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$_clientPoints points de fidélité',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _canUseFreeMail ? Colors.green.shade900 : Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_canUseFreeMail) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      '🎉 Courrier gratuit disponible!',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    SwitchListTile(
                                      title: const Text('Utiliser les points (courrier gratuit)'),
                                      value: _isLoyaltyMail,
                                      onChanged: (value) {
                                        setState(() {
                                          _isLoyaltyMail = value;
                                          if (value) {
                                            _amountController.text = '0';
                                          }
                                        });
                                      },
                                      activeTrackColor: Colors.green,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${10 - _clientPoints} points restants pour un courrier gratuit',
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Informations de l\'expéditeur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senderNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'expéditeur *',
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
                  TextFormField(
                    controller: _senderPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone de l\'expéditeur *',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
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
                  const Text(
                    'Informations du destinataire',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _recipientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du destinataire *',
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
                  TextFormField(
                    controller: _recipientPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone du destinataire *',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
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
                  const Text(
                    'Informations du colis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDestination,
                    decoration: const InputDecoration(
                      labelText: 'Destination *',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    items: MailApiService.getDestinations().map((dest) {
                      return DropdownMenuItem(
                        value: dest,
                        child: Text(dest),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDestination = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedReceivingAgency,
                    decoration: const InputDecoration(
                      labelText: 'Agence de réception *',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Sélectionner une agence'),
                    items: [
                      'Bouaké',
                      'Yamoussoukro',
                      'Abidjan Adjamé',
                      'Abidjan Yopougon',
                      'Daloa',
                      'Bouafle Toumori',
                      'Korhogo',
                    ].map((agency) {
                      return DropdownMenuItem(
                        value: agency,
                        child: Text(agency),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner une agence';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedReceivingAgency = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPackageType,
                    decoration: const InputDecoration(
                      labelText: 'Type de colis *',
                      prefixIcon: Icon(Icons.inventory_2),
                      border: OutlineInputBorder(),
                    ),
                    items: MailApiService.getPackageTypes().map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPackageType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _packageValueController,
                    decoration: const InputDecoration(
                      labelText: 'Valeur du colis *',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      hintText: 'Ex: 50 000 FCFA',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ce champ est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Montant à payer (FCFA) *',
                      prefixIcon: Icon(Icons.payments),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ce champ est requis';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Veuillez entrer un nombre valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optionnel)',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Photo du colis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_photo != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _photo!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _photo = null),
                      icon: const Icon(Icons.delete),
                      label: const Text('Supprimer la photo'),
                    ),
                  ] else
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Prendre une photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text(
                      'Créer le courrier',
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
