import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../models/mail_model.dart';
import '../services/mail_api_service.dart';

class CollectionFormScreen extends StatefulWidget {
  final MailModel mail;

  const CollectionFormScreen({super.key, required this.mail});

  @override
  State<CollectionFormScreen> createState() => _CollectionFormScreenState();
}

class _CollectionFormScreenState extends State<CollectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idCardController = TextEditingController();
  final _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec les infos du destinataire
    _nameController.text = widget.mail.recipientName;
    _phoneController.text = widget.mail.recipientPhone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idCardController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier la signature
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez signer pour confirmer la réception'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convertir la signature en image
      final signatureBytes = await _signatureController.toPngBytes();

      // Marquer comme collecté avec les infos
      await MailApiService.markAsCollectedWithDetails(
        widget.mail.id,
        collectorName: _nameController.text.trim(),
        collectorPhone: _phoneController.text.trim(),
        collectorIdCard: _idCardController.text.trim(),
        signatureBytes: signatureBytes,
      );

      if (mounted) {
        Navigator.pop(context, true); // Retour avec succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Courrier marqué comme collecté'),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'Formulaire de Collection',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info du colis
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mail, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Informations du courrier',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildInfoRow('Numéro', widget.mail.mailNumber),
                          const SizedBox(height: 8),
                          _buildInfoRow('Destination', widget.mail.destination),
                          const SizedBox(height: 8),
                          _buildInfoRow('Type', widget.mail.packageType),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Formulaire destinataire
                  Text(
                    'Informations du bénéficiaire',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom complet *',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Téléphone *',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ce champ est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _idCardController,
                    decoration: InputDecoration(
                      labelText: 'Numéro de pièce d\'identité *',
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'CNI, Passeport, etc.',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ce champ est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Zone de signature
                  Text(
                    'Signature du bénéficiaire *',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Signez dans la zone ci-dessous pour confirmer la réception',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Signature(
                            controller: _signatureController,
                            height: 200,
                            backgroundColor: Colors.grey.shade50,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  _signatureController.clear();
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Effacer'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton de validation
                  ElevatedButton.icon(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text(
                      'Confirmer la collection',
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
