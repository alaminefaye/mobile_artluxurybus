import 'package:flutter/material.dart';
import '../../models/bus_models.dart';
import 'breakdown_form_screen.dart';
import '../../services/bus_api_service.dart';

class BreakdownDetailScreen extends StatelessWidget {
  final BusBreakdown breakdown;
  final int busId;

  const BreakdownDetailScreen({
    super.key,
    required this.breakdown,
    required this.busId,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'terminee':
        return Colors.green;
      case 'en_cours':
        return Colors.blue;
      case 'en_attente_pieces':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut.toLowerCase()) {
      case 'terminee':
        return 'TERMINÉE';
      case 'en_cours':
        return 'EN COURS';
      case 'en_attente_pieces':
        return 'EN ATTENTE PIÈCES';
      default:
        return statut.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statutColor = _getStatutColor(breakdown.statutReparation);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la panne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BreakdownFormScreen(
                    busId: busId,
                    breakdown: breakdown,
                  ),
                ),
              ).then((needsRefresh) {
                if (needsRefresh == true) {
                  Navigator.pop(context, true);
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statutColor, statutColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          breakdown.descriptionProbleme,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatutLabel(breakdown.statutReparation),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informations Principales
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations Principales',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.orange[200] : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _InfoCard(
                    icon: Icons.calendar_today,
                    iconColor: Colors.red,
                    title: 'Date de panne',
                    value: _formatDate(breakdown.breakdownDate),
                  ),
                  
                  _InfoCard(
                    icon: Icons.build,
                    iconColor: Colors.blue,
                    title: 'Réparation effectuée',
                    value: breakdown.reparationEffectuee,
                  ),
                  
                  _InfoCard(
                    icon: Icons.engineering,
                    iconColor: Colors.purple,
                    title: 'Diagnostic mécanicien',
                    value: breakdown.diagnosticMecanicien,
                  ),
                  
                  if (breakdown.kilometrage != null)
                    _InfoCard(
                      icon: Icons.speed,
                      iconColor: Colors.indigo,
                      title: 'Kilométrage',
                      value: '${breakdown.kilometrage} km',
                    ),
                  
                  if (breakdown.pieceRemplacee != null && breakdown.pieceRemplacee!.isNotEmpty)
                    _InfoCard(
                      icon: Icons.settings,
                      iconColor: Colors.teal,
                      title: 'Pièce remplacée',
                      value: breakdown.pieceRemplacee!,
                    ),
                  
                  if (breakdown.prixPiece != null)
                    _InfoCard(
                      icon: Icons.attach_money,
                      iconColor: Colors.green,
                      title: 'Prix de la pièce',
                      value: '${breakdown.prixPiece!.toStringAsFixed(0)} FCFA',
                    ),
                  
                  if (breakdown.notesComplementaires != null && breakdown.notesComplementaires!.isNotEmpty)
                    _InfoCard(
                      icon: Icons.note,
                      iconColor: Colors.grey,
                      title: 'Notes complémentaires',
                      value: breakdown.notesComplementaires!,
                    ),
                ],
              ),
            ),

            // Photo de facture
            if (breakdown.facturePhoto != null && breakdown.facturePhoto!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Facture',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.orange[200] : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        breakdown.facturePhoto!.startsWith('http')
                            ? breakdown.facturePhoto!
                            : 'https://gestion-compagny.universaltechnologiesafrica.com/storage/${breakdown.facturePhoto!}',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Theme.of(context).cardColor,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image non disponible',
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la panne'),
        content: Text(
          'Voulez-vous vraiment supprimer cette panne ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await BusApiService().deleteBreakdown(busId, breakdown.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Panne supprimée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, true);
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
