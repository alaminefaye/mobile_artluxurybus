import 'package:flutter/material.dart';
import '../models/bagage_model.dart';
import '../services/translation_service.dart';
import 'package:intl/intl.dart';

class BagageDetailScreen extends StatefulWidget {
  final BagageModel bagage;

  const BagageDetailScreen({super.key, required this.bagage});

  @override
  State<BagageDetailScreen> createState() => _BagageDetailScreenState();
}

class _BagageDetailScreenState extends State<BagageDetailScreen> {
  late BagageModel _bagage;

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

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
        title: Text(t('bagage_detail.title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 24),
            _buildInfoSection(t('bagage_detail.general_info'), [
              _buildInfoRow(t('bagage_detail.number'), _bagage.numero),
              _buildInfoRow(t('bagage_detail.destination'), _bagage.destination),
              if (_bagage.poids != null)
                _buildInfoRow(t('bagage_detail.weight'), '${_bagage.poids} kg'),
              if (_bagage.valeur != null)
                _buildInfoRow(
                  t('bagage_detail.value'),
                  NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                      .format(_bagage.valeur),
                ),
              if (_bagage.montant != null)
                _buildInfoRow(
                  t('bagage_detail.amount_paid'),
                  NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                      .format(_bagage.montant),
                ),
            ]),
            const SizedBox(height: 24),
            _buildInfoSection(t('bagage_detail.owner'), [
              _buildInfoRow(t('bagage_detail.name'), _bagage.nom),
              _buildInfoRow(t('bagage_detail.firstname'), _bagage.prenom),
              _buildInfoRow(t('bagage_detail.phone'), _bagage.telephone),
            ]),
            if (_bagage.contenu != null) ...[
              const SizedBox(height: 24),
              _buildInfoSection(t('bagage_detail.content'), [
                Text(_bagage.contenu!),
              ]),
            ],
            const SizedBox(height: 24),
            _buildInfoSection(t('bagage_detail.additional_info'), [
              _buildInfoRow(
                t('bagage_detail.registration_date'),
                DateFormat('dd/MM/yyyy à HH:mm').format(_bagage.createdAt),
              ),
              _buildInfoRow(
                t('bagage_detail.has_ticket'),
                _bagage.hasTicket ? t('bagage_detail.yes') : t('bagage_detail.no'),
              ),
              if (_bagage.hasTicket && _bagage.ticketNumber != null)
                _buildInfoRow(t('bagage_detail.ticket_number'), _bagage.ticketNumber!),
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
                  _bagage.hasTicket ? t('bagage_detail.with_ticket') : t('bagage_detail.without_ticket'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _bagage.hasTicket ? Colors.green : Colors.orange,
                  ),
                ),
                Text(
                  _bagage.hasTicket
                      ? t('bagage_detail.ticket_associated')
                      : t('bagage_detail.no_ticket'),
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
