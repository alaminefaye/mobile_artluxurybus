import 'package:flutter/material.dart';
import '../../models/bus_models.dart';
import '../../services/bus_api_service.dart';
import 'technical_visit_form_screen.dart';

class TechnicalVisitDetailScreen extends StatelessWidget {
  final TechnicalVisit visit;
  final int busId;

  const TechnicalVisitDetailScreen({
    super.key,
    required this.visit,
    required this.busId,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _deleteVisit(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la visite'),
        content: const Text('Voulez-vous vraiment supprimer cette visite technique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await BusApiService().deleteTechnicalVisit(busId, visit.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visite technique supprimée'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retour avec refresh
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
    }
  }

  void _editVisit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicalVisitFormScreen(
          busId: busId,
          visit: visit,
        ),
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        Navigator.pop(context, true); // Retour avec refresh
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = visit.expirationDate.isBefore(DateTime.now());
    final isExpiringSoon = visit.expirationDate.isBefore(
      DateTime.now().add(const Duration(days: 30)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails Visite Technique'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editVisit(context),
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteVisit(context),
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header avec statut
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isExpired
                      ? [Colors.red.shade400, Colors.red.shade700]
                      : isExpiringSoon
                          ? [Colors.orange.shade400, Colors.orange.shade700]
                          : [Colors.green.shade400, Colors.green.shade700],
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isExpired
                        ? Icons.warning_rounded
                        : isExpiringSoon
                            ? Icons.schedule
                            : Icons.check_circle,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isExpired
                        ? 'EXPIRÉ'
                        : isExpiringSoon
                            ? 'EXPIRE BIENTÔT'
                            : 'VALIDE',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expire le ${_formatDate(visit.expirationDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.deepPurple[200]
                          : Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _InfoCard(
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    title: 'Date de visite',
                    value: _formatDate(visit.visitDate),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _InfoCard(
                    icon: Icons.event_available,
                    iconColor: isExpired ? Colors.red : Colors.green,
                    title: 'Date d\'expiration',
                    value: _formatDate(visit.expirationDate),
                  ),
                  
                  if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.notes,
                      iconColor: Colors.orange,
                      title: 'Notes',
                      value: visit.notes!,
                    ),
                  ],

                  const SizedBox(height: 12),
                  
                  _InfoCard(
                    icon: Icons.info_outline,
                    iconColor: Colors.purple,
                    title: 'Statut',
                    value: isExpired
                        ? 'Expiré'
                        : isExpiringSoon
                            ? 'Expire dans ${visit.expirationDate.difference(DateTime.now()).inDays} jours'
                            : 'Valide',
                  ),
                ],
              ),
            ),

            // Document photo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.deepPurple[200]
                          : Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (visit.documentPhoto != null && visit.documentPhoto!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        visit.documentPhoto!.startsWith('http')
                            ? visit.documentPhoto!
                            : 'https://gestion-compagny.universaltechnologiesafrica.com/storage/${visit.documentPhoto!}',
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
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aucun document disponible',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
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
            padding: const EdgeInsets.all(12),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
