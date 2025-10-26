import 'package:flutter/material.dart';
import '../../models/bus_models.dart';
import 'vidange_form_screen.dart';
import '../../services/bus_api_service.dart';

class VidangeDetailScreen extends StatelessWidget {
  final BusVidange vidange;
  final int busId;

  const VidangeDetailScreen({
    super.key,
    required this.vidange,
    required this.busId,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int _getDaysRemaining() {
    final now = DateTime.now();
    final difference = vidange.nextVidangeDate.difference(now);
    return difference.inDays;
  }

  Color _getStatusColor() {
    final daysRemaining = _getDaysRemaining();
    if (daysRemaining < 0) return Colors.red; // En retard
    if (daysRemaining <= 3) return Colors.orange; // Urgent (3 jours ou moins)
    return Colors.green; // OK
  }

  String _getStatusLabel() {
    final daysRemaining = _getDaysRemaining();
    if (daysRemaining < 0) return 'EN RETARD';
    if (daysRemaining == 0) return 'AUJOURD\'HUI';
    if (daysRemaining <= 3) return 'URGENT - $daysRemaining JOURS';
    return 'OK - $daysRemaining JOURS';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor();
    final daysRemaining = _getDaysRemaining();
    final isOverdue = daysRemaining < 0;
    final isUrgent = daysRemaining >= 0 && daysRemaining <= 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la vidange'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VidangeFormScreen(
                    busId: busId,
                    vidange: vidange,
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
                  colors: [statusColor, statusColor.withOpacity(0.7)],
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
                        isOverdue ? Icons.warning_rounded : Icons.oil_barrel,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isOverdue 
                              ? 'Vidange en retard !' 
                              : isUrgent 
                                  ? 'Vidange urgente !' 
                                  : 'Vidange planifiée',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                      _getStatusLabel(),
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

            // Alerte si urgent ou en retard
            if (isOverdue || isUrgent)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  border: Border.all(color: statusColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: statusColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isOverdue
                            ? 'Cette vidange est en retard de ${daysRemaining.abs()} jour(s) !'
                            : 'Cette vidange doit être effectuée dans $daysRemaining jour(s) !',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                    'Informations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.teal[200] : Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _InfoCard(
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    title: 'Dernière vidange',
                    value: _formatDate(vidange.lastVidangeDate),
                  ),
                  
                  _InfoCard(
                    icon: Icons.event,
                    iconColor: statusColor,
                    title: 'Prochaine vidange',
                    value: _formatDate(vidange.nextVidangeDate),
                  ),
                  
                  _InfoCard(
                    icon: Icons.access_time,
                    iconColor: statusColor,
                    title: 'Jours restants',
                    value: daysRemaining < 0 
                        ? 'En retard de ${daysRemaining.abs()} jour(s)'
                        : '$daysRemaining jour(s)',
                  ),
                  
                  if (vidange.notes != null && vidange.notes!.isNotEmpty)
                    _InfoCard(
                      icon: Icons.note,
                      iconColor: Colors.grey,
                      title: 'Notes',
                      value: vidange.notes!,
                    ),
                ],
              ),
            ),

            // Bouton "Marquer comme effectuée"
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showMarkCompletedDialog(context),
                  icon: const Icon(Icons.check_circle, size: 28),
                  label: const Text(
                    'Marquer comme effectuée',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Marquer comme effectuée',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cette action va :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text('• Marquer la vidange comme effectuée aujourd\'hui', style: TextStyle(fontSize: 13)),
              SizedBox(height: 4),
              Text('• Planifier la prochaine dans 10 jours', style: TextStyle(fontSize: 13)),
              SizedBox(height: 12),
              Text('Continuer ?', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _markCompleted(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _markCompleted(BuildContext context) async {
    debugPrint('🔄 [VIDANGE] Début _markCompleted');
    
    // Sauvegarder une référence au Navigator AVANT le showDialog
    final navigator = Navigator.of(context);
    
    try {
      // Afficher un indicateur de chargement
      debugPrint('⏳ [VIDANGE] Affichage du loading...');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );

      final now = DateTime.now();
      final nextVidange = now.add(const Duration(days: 10));

      final data = {
        'last_vidange_date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'next_vidange_date': '${nextVidange.year}-${nextVidange.month.toString().padLeft(2, '0')}-${nextVidange.day.toString().padLeft(2, '0')}',
        'notes': vidange.notes,
      };

      debugPrint('📡 [VIDANGE] Appel API updateVidange...');
      await BusApiService().updateVidange(busId, vidange.id, data);
      debugPrint('✅ [VIDANGE] API terminée avec succès');

      // Fermer le loading D'ABORD avec la référence sauvegardée
      debugPrint('🔚 [VIDANGE] Fermeture du loading...');
      try {
        navigator.pop(); // Utiliser la référence sauvegardée
        debugPrint('✅ [VIDANGE] Loading fermé');
      } catch (e) {
        debugPrint('⚠️ [VIDANGE] Erreur fermeture loading: $e');
      }

      // Vérifier si le widget est toujours monté APRÈS avoir fermé le loading
      if (!context.mounted) {
        debugPrint('⚠️ [VIDANGE] Widget démonté, abandon de la navigation');
        return;
      }

      // Attendre un peu pour que le dialogue se ferme
      await Future.delayed(const Duration(milliseconds: 300));

      // Vérifier à nouveau si le widget est toujours monté
      if (!context.mounted) {
        debugPrint('⚠️ [VIDANGE] Widget démonté après fermeture loading');
        return;
      }

      // Afficher le message de succès
      debugPrint('📢 [VIDANGE] Affichage du message de succès');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vidange effectuée et reconduite pour 10 jours'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Retourner à la liste AVEC signal de rafraîchissement
      debugPrint('🔙 [VIDANGE] Retour à la liste avec rafraîchissement');
      Navigator.of(context).pop(true); // true = besoin de rafraîchir
      debugPrint('✅ [VIDANGE] Navigation terminée');
    } catch (e, stackTrace) {
      debugPrint('❌ [VIDANGE] Erreur: $e');
      debugPrint('📍 [VIDANGE] Stack trace: $stackTrace');
      
      // Fermer le loading D'ABORD avec la référence sauvegardée
      try {
        navigator.pop(); // Utiliser la référence sauvegardée
        debugPrint('✅ [VIDANGE] Loading fermé après erreur');
      } catch (popError) {
        debugPrint('⚠️ [VIDANGE] Erreur fermeture loading: $popError');
      }
      
      // Vérifier si le widget est toujours monté pour afficher l'erreur
      if (!context.mounted) {
        debugPrint('⚠️ [VIDANGE] Widget démonté, impossible d\'afficher l\'erreur');
        return;
      }
      
      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la vidange'),
        content: const Text(
          'Voulez-vous vraiment supprimer cette vidange ?',
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
                await BusApiService().deleteVidange(busId, vidange.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vidange supprimée'),
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
