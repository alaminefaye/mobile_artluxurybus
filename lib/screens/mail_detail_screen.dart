import 'package:flutter/material.dart';
import '../models/mail_model.dart';
import 'package:intl/intl.dart';
import 'collection_form_screen.dart';

class MailDetailScreen extends StatefulWidget {
  final MailModel mail;

  const MailDetailScreen({super.key, required this.mail});

  @override
  State<MailDetailScreen> createState() => _MailDetailScreenState();
}

class _MailDetailScreenState extends State<MailDetailScreen> {
  late MailModel _mail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mail = widget.mail;
  }

  Future<void> _toggleCollection() async {
    if (!mounted) return;

    // Ouvrir le formulaire de collection
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionFormScreen(mail: _mail),
      ),
    );

    // Si la collection a réussi, retourner avec indication de redirection vers Collectés
    if (result == true && mounted) {
      Navigator.pop(context, {'success': true, 'goToCollected': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Courrier'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(),
                  const SizedBox(height: 24),
                  _buildInfoSection('Informations générales', [
                    _buildInfoRow('Numéro', _mail.mailNumber),
                    _buildInfoRow('Destination', _mail.destination),
                    _buildInfoRow('Agence de réception', _mail.receivingAgency),
                    _buildInfoRow(
                      'Montant',
                      NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                          .format(_mail.amount),
                    ),
                    _buildInfoRow('Type de colis', _mail.packageType),
                    _buildInfoRow('Valeur du colis', _mail.packageValue),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection('Expéditeur', [
                    _buildInfoRow('Nom', _mail.senderName),
                    _buildInfoRow('Téléphone', _mail.senderPhone),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection('Destinataire', [
                    _buildInfoRow('Nom', _mail.recipientName),
                    _buildInfoRow('Téléphone', _mail.recipientPhone),
                  ]),
                  if (_mail.description != null) ...[
                    const SizedBox(height: 24),
                    _buildInfoSection('Description', [
                      Text(_mail.description!),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  _buildInfoSection('Informations supplémentaires', [
                    _buildInfoRow(
                      'Date de création',
                      DateFormat('dd/MM/yyyy à HH:mm').format(_mail.createdAt),
                    ),
                    if (_mail.createdByUser != null)
                      _buildInfoRow('Créé par', _mail.createdByUser!.name),
                    if (_mail.isCollected) ...[
                      _buildInfoRow(
                        'Date de collection',
                        _mail.collectedAt != null
                            ? DateFormat('dd/MM/yyyy à HH:mm')
                                .format(_mail.collectedAt!)
                            : 'N/A',
                      ),
                      if (_mail.collectedByUser != null)
                        _buildInfoRow(
                            'Collecté par', _mail.collectedByUser!.name),
                    ],
                  ]),
                  if (_mail.clientProfile != null) ...[
                    const SizedBox(height: 24),
                    _buildInfoSection('Fidélité', [
                      _buildInfoRow('Client', _mail.clientProfile!.nom),
                      _buildInfoRow(
                        'Points fidélité',
                        _mail.clientProfile!.points.toString(),
                      ),
                      _buildInfoRow(
                        'Points courrier',
                        _mail.clientProfile!.mailPoints.toString(),
                      ),
                    ]),
                  ],
                  if (!_mail.isCollected) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isLoading ? null : _toggleCollection,
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Marquer comme collecté',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _mail.isCollected ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _mail.isCollected ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _mail.isCollected ? Icons.check_circle : Icons.pending,
            color: _mail.isCollected ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mail.isCollected ? 'Collecté' : 'En attente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _mail.isCollected ? Colors.green : Colors.orange,
                  ),
                ),
                if (_mail.isCollected && _mail.collectedAt != null)
                  Text(
                    'Le ${DateFormat('dd/MM/yyyy à HH:mm').format(_mail.collectedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
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
                color: Colors.blue,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
