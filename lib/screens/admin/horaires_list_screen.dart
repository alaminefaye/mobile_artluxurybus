import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/horaire_riverpod_provider.dart';
import '../../theme/app_theme.dart';
import 'horaire_form_screen.dart';

class HorairesListScreen extends ConsumerWidget {
  const HorairesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horairesState = ref.watch(horaireProvider);
    final horaires = horairesState.horaires;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Horaires'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(horaireProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: horairesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : horairesState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur: ${horairesState.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(horaireProvider.notifier).refresh();
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : horaires.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun horaire',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(horaireProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: horaires.length,
                        itemBuilder: (context, index) {
                          final horaire = horaires[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(horaire.statut),
                                child: const Icon(Icons.schedule, color: Colors.white),
                              ),
                              title: Text(
                                '${horaire.trajet.embarquement} → ${horaire.trajet.destination}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Gare: ${horaire.gare.nom}'),
                                  Text('Heure: ${horaire.heure}'),
                                  if (horaire.busNumber != null)
                                    Text('Bus: ${horaire.busNumber}'),
                                  Text(
                                    'Statut: ${horaire.statutLibelle}',
                                    style: TextStyle(
                                      color: _getStatusColor(horaire.statut),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Modifier'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HoraireFormScreen(horaire: horaire),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    _confirmDelete(context, ref, horaire.id);
                                  }
                                },
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HoraireFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvel horaire'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'a_l_heure':
        return Colors.blue;
      case 'embarquement':
        return Colors.green;
      case 'termine':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int horaireId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet horaire ?'),
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

    if (confirmed == true && context.mounted) {
      // TODO: Implémenter la suppression via l'API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suppression non implémentée - À faire'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
