import 'package:flutter/material.dart';
import '../../models/bus_models.dart';
import '../../services/bus_api_service.dart';

class FuelRecordDetailScreen extends StatelessWidget {
  final FuelRecord fuelRecord;
  final int busId;

  const FuelRecordDetailScreen({
    super.key,
    required this.fuelRecord,
    required this.busId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails Carburant'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigation vers formulaire d'édition (bientôt disponible)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Modification à venir')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec coût principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.local_gas_station,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${fuelRecord.cost.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Informations détaillées
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard('Informations Principales', [
                    _buildInfoRow(
                      'Date de ravitaillement',
                      _formatDate(fuelRecord.fueledAt),
                      Icons.calendar_today,
                    ),
                    _buildInfoRow(
                      'Coût total',
                      '${fuelRecord.cost.toStringAsFixed(0)} FCFA',
                      Icons.attach_money,
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // plus de champs supplémentaires inutilisés

                  const SizedBox(height: 16),

                  // Photo de la facture
                  if (fuelRecord.invoicePhoto != null)
                    _buildInfoCard('Facture', [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          'https://gestion-compagny.universaltechnologiesafrica.com/storage/${fuelRecord.invoicePhoto}',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, size: 48),
                                    SizedBox(height: 8),
                                    Text('Image non disponible'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ]),

                  const SizedBox(height: 16),

                  // Notes
                  if (fuelRecord.notes != null && fuelRecord.notes!.isNotEmpty)
                    _buildInfoCard('Notes', [
                      Text(
                        fuelRecord.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ]),

                  const SizedBox(height: 16),

                  // Date d'enregistrement
                  if (fuelRecord.createdAt != null)
                    _buildInfoCard('Informations Système', [
                      _buildInfoRow(
                        'Enregistré le',
                        _formatDateTime(fuelRecord.createdAt!),
                        Icons.info_outline,
                      ),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet enregistrement ?'),
        content: const Text(
          'Cette action est irréversible. Voulez-vous vraiment supprimer cet enregistrement de carburant ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Fermer dialog
              
              try {
                final apiService = BusApiService();
                await apiService.deleteFuelRecord(busId, fuelRecord.id);
                
                if (context.mounted) {
                  Navigator.pop(context, true); // Retour avec succès
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enregistrement supprimé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
