import 'package:flutter/material.dart';
import '../models/mail_model.dart';
import '../services/mail_api_service.dart';
import 'package:intl/intl.dart';

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
    setState(() => _isLoading = true);

    try {
      final updatedMail = _mail.isCollected
          ? await MailApiService.markAsUncollected(_mail.id)
          : await MailApiService.markAsCollected(_mail.id);

      setState(() {
        _mail = updatedMail;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _mail.isCollected
                  ? 'Courrier marqué comme collecté'
                  : 'Collection annulée',
            ),
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

  Future<void> _deleteMail() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le courrier'),
        content:
            const Text('Voulez-vous vraiment supprimer ce courrier ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await MailApiService.deleteMail(_mail.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Courrier supprimé avec succès'),
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
        title: const Text('Détails du Courrier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteMail,
          ),
        ],
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
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mail.isCollected
                            ? Colors.orange
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isLoading ? null : _toggleCollection,
                      icon: Icon(
                        _mail.isCollected
                            ? Icons.cancel
                            : Icons.check_circle,
                      ),
                      label: Text(
                        _mail.isCollected
                            ? 'Annuler la collection'
                            : 'Marquer comme collecté',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
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
