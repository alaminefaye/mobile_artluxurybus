import 'package:flutter/material.dart';
import '../models/bagage_model.dart';
import 'package:intl/intl.dart';

class BagageDetailScreen extends StatefulWidget {
  final BagageModel bagage;

  const BagageDetailScreen({super.key, required this.bagage});

  @override
  State<BagageDetailScreen> createState() => _BagageDetailScreenState();
}

class _BagageDetailScreenState extends State<BagageDetailScreen> {
  late BagageModel _bagage;

  @override
  void initState() {
    super.initState();
    _bagage = widget.bagage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        title: const Text('Détails du Bagage'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 24),
            _buildInfoSection('Informations générales', [
              _buildInfoRow('Numéro', _bagage.numero),
              _buildInfoRow('Destination', _bagage.destination),
              if (_bagage.poids != null)
                _buildInfoRow('Poids', '${_bagage.poids} kg'),
              if (_bagage.valeur != null)
                _buildInfoRow(
                  'Valeur',
                  NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                      .format(_bagage.valeur),
                ),
              if (_bagage.montant != null)
                _buildInfoRow(
                  'Montant payé',
                  NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                      .format(_bagage.montant),
                ),
            ]),
            const SizedBox(height: 24),
            _buildInfoSection('Propriétaire', [
              _buildInfoRow('Nom', _bagage.nom),
              _buildInfoRow('Prénom', _bagage.prenom),
              _buildInfoRow('Téléphone', _bagage.telephone),
            ]),
            if (_bagage.contenu != null) ...[
              const SizedBox(height: 24),
              _buildInfoSection('Contenu', [
                Text(_bagage.contenu!),
              ]),
            ],
            const SizedBox(height: 24),
            _buildInfoSection('Informations supplémentaires', [
              _buildInfoRow(
                'Date d\'enregistrement',
                DateFormat('dd/MM/yyyy à HH:mm').format(_bagage.createdAt),
              ),
              _buildInfoRow(
                'Possède un ticket',
                _bagage.hasTicket ? 'Oui' : 'Non',
              ),
              if (_bagage.hasTicket && _bagage.ticketNumber != null)
                _buildInfoRow('Numéro de ticket', _bagage.ticketNumber!),
            ]),
            const SizedBox(height: 32),
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
        color:
            _bagage.hasTicket ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _bagage.hasTicket ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _bagage.hasTicket ? Icons.check_circle : Icons.luggage,
            color: _bagage.hasTicket ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bagage.hasTicket ? 'Avec Ticket' : 'Sans Ticket',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _bagage.hasTicket ? Colors.green : Colors.orange,
                  ),
                ),
                Text(
                  _bagage.hasTicket
                      ? 'Ce bagage a un ticket associé'
                      : 'Ce bagage n\'a pas de ticket',
                  style: TextStyle(
                    fontSize: 12,
                    color: _bagage.hasTicket
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
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
                color: Colors.orange,
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
