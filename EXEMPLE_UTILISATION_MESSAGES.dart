// ============================================================================
// EXEMPLES D'UTILISATION DU SYSTÈME DE MESSAGES & ANNONCES
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:artluxurybus/screens/messages_screen.dart';
import 'package:artluxurybus/widgets/messages_home_widget.dart';
import 'package:artluxurybus/providers/message_provider.dart';

// ============================================================================
// EXEMPLE 1 : Ajouter un bouton dans le menu/drawer
// ============================================================================

class ExempleMenuAvecMessages extends ConsumerWidget {
  const ExempleMenuAvecMessages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFD4AF37)),
            child: Text(
              'Art Luxury Bus',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Autres items du menu...
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Accueil'),
            onTap: () => Navigator.pop(context),
          ),
          
          // ⭐ ITEM MESSAGES AVEC BADGE
          ListTile(
            leading: const Icon(Icons.message, color: Color(0xFFD4AF37)),
            title: const Text('Messages & Annonces'),
            trailing: Consumer(
              builder: (context, ref, child) {
                final count = ref.watch(unreadMessagesCountProvider);
                if (count > 0) {
                  return Badge(
                    label: Text('$count'),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.chevron_right),
                  );
                }
                return const Icon(Icons.chevron_right);
              },
            ),
            onTap: () {
              Navigator.pop(context); // Fermer le drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessagesScreen(),
                ),
              );
            },
          ),
          
          const Divider(),
          
          // Autres items...
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXEMPLE 2 : Ajouter un badge dans l'AppBar
// ============================================================================

class ExempleAppBarAvecBadge extends ConsumerWidget {
  const ExempleAppBarAvecBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNewMessages = ref.watch(hasNewMessagesProvider);

    return AppBar(
      title: const Text('Art Luxury Bus'),
      backgroundColor: const Color(0xFFD4AF37),
      foregroundColor: Colors.black,
      actions: [
        // ⭐ BADGE DE NOTIFICATION
        IconButton(
          icon: Badge(
            isLabelVisible: hasNewMessages,
            backgroundColor: Colors.red,
            child: const Icon(Icons.notifications),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MessagesScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================================
// EXEMPLE 3 : Page d'accueil avec widget de messages
// ============================================================================

class ExemplePageAccueilAvecMessages extends StatelessWidget {
  const ExemplePageAccueilAvecMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Bannière de bienvenue
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
              child: const Text(
                'Bienvenue sur Art Luxury Bus',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            
            // ⭐ WIDGET MESSAGES (Option 1 : Carte complète)
            const MessagesHomeWidget(),
            
            // ⭐ WIDGET MESSAGES (Option 2 : Badge compact)
            // const Padding(
            //   padding: EdgeInsets.all(16),
            //   child: MessagesCounterWidget(),
            // ),
            
            // ⭐ WIDGET MESSAGES (Option 3 : Bannière)
            // const MessageBannerWidget(),
            
            // Autres widgets de la page d'accueil...
            _buildServiceCard('Réservation', Icons.book_online),
            _buildServiceCard('Mes trajets', Icons.directions_bus),
            _buildServiceCard('Fidélité', Icons.card_giftcard),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFD4AF37)),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

// ============================================================================
// EXEMPLE 4 : Afficher uniquement les notifications
// ============================================================================

class ExemplePageNotificationsUniquement extends ConsumerWidget {
  const ExemplePageNotificationsUniquement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text('Aucune notification'),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                leading: const Icon(
                  Icons.notifications,
                  color: Color(0xFFD4AF37),
                ),
                title: Text(notif.titre),
                subtitle: Text(notif.contenu),
                onTap: () {
                  // Afficher les détails
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}

// ============================================================================
// EXEMPLE 5 : Rafraîchir manuellement les messages
// ============================================================================

class ExempleRefreshMessages extends ConsumerWidget {
  const ExempleRefreshMessages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          // ⭐ BOUTON REFRESH
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(messagesNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: messagesAsync.when(
        data: (messages) => ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(messages[index].titre),
              subtitle: Text(messages[index].contenu),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
      // ⭐ PULL TO REFRESH
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(messagesNotifierProvider.notifier).refresh();
        },
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// ============================================================================
// EXEMPLE 6 : Filtrer les messages par gare
// ============================================================================

class ExempleMessagesParGare extends ConsumerWidget {
  final int gareId;

  const ExempleMessagesParGare({
    super.key,
    required this.gareId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⭐ PROVIDER AVEC PARAMÈTRE GARE_ID
    final messagesAsync = ref.watch(activeMessagesByGareProvider(gareId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages de la gare'),
      ),
      body: messagesAsync.when(
        data: (messages) {
          if (messages.isEmpty) {
            return const Center(
              child: Text('Aucun message pour cette gare'),
            );
          }

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(
                    message.isNotification
                        ? Icons.notifications
                        : Icons.campaign,
                    color: const Color(0xFFD4AF37),
                  ),
                  title: Text(message.titre),
                  subtitle: Text(message.contenu),
                  trailing: message.gare != null
                      ? Chip(label: Text(message.gare!.nom))
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}

// ============================================================================
// EXEMPLE 7 : Compteur de messages dans un widget personnalisé
// ============================================================================

class ExempleCompteurPersonnalise extends ConsumerWidget {
  const ExempleCompteurPersonnalise({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesNotifierProvider);

    return messagesAsync.when(
      data: (messages) {
        final notifications = messages.where((m) => m.isNotification).length;
        final annonces = messages.where((m) => m.isAnnonce).length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Mes Messages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // ⭐ COMPTEUR NOTIFICATIONS
                    _buildCounter(
                      context,
                      'Notifications',
                      notifications,
                      Icons.notifications,
                      const Color(0xFFD4AF37),
                    ),
                    // ⭐ COMPTEUR ANNONCES
                    _buildCounter(
                      context,
                      'Annonces',
                      annonces,
                      Icons.campaign,
                      Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessagesScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Voir tous les messages'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildCounter(
    BuildContext context,
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

// ============================================================================
// EXEMPLE 8 : Navigation avec go_router
// ============================================================================

/*
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ExemplePageAccueilAvecMessages(),
    ),
    
    // ⭐ ROUTE MESSAGES
    GoRoute(
      path: '/messages',
      builder: (context, state) => const MessagesScreen(),
    ),
    
    // ⭐ ROUTE MESSAGES PAR GARE
    GoRoute(
      path: '/messages/gare/:id',
      builder: (context, state) {
        final gareId = int.parse(state.pathParameters['id']!);
        return ExempleMessagesParGare(gareId: gareId);
      },
    ),
  ],
);

// Utilisation dans le code
context.push('/messages');
context.push('/messages/gare/3');
*/

// ============================================================================
// EXEMPLE 9 : Écouter les changements de messages
// ============================================================================

class ExempleEcouteChangements extends ConsumerStatefulWidget {
  const ExempleEcouteChangements({super.key});

  @override
  ConsumerState<ExempleEcouteChangements> createState() =>
      _ExempleEcouteChangementsState();
}

class _ExempleEcouteChangementsState
    extends ConsumerState<ExempleEcouteChangements> {
  @override
  void initState() {
    super.initState();
    
    // ⭐ ÉCOUTER LES CHANGEMENTS
    ref.listenManual(messagesNotifierProvider, (previous, next) {
      next.whenData((messages) {
        if (messages.isNotEmpty) {
          // Afficher un snackbar quand de nouveaux messages arrivent
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${messages.length} message(s) disponible(s)'),
              backgroundColor: const Color(0xFFD4AF37),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Écoute des changements de messages...'),
      ),
    );
  }
}

// ============================================================================
// EXEMPLE 10 : Afficher un message spécifique
// ============================================================================

class ExempleAfficherMessageSpecifique extends ConsumerWidget {
  final int messageId;

  const ExempleAfficherMessageSpecifique({
    super.key,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⭐ RÉCUPÉRER UN MESSAGE PAR ID
    final messageAsync = ref.watch(messageByIdProvider(messageId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du message'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
      body: messageAsync.when(
        data: (message) {
          if (message == null) {
            return const Center(child: Text('Message introuvable'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge type
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: message.isNotification
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.isNotification ? 'Notification' : 'Annonce',
                    style: TextStyle(
                      color: message.isNotification
                          ? const Color(0xFFD4AF37)
                          : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Titre
                Text(
                  message.titre,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Contenu
                Text(
                  message.contenu,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),

                // Informations supplémentaires
                if (message.gare != null) ...[
                  _buildInfoRow(
                    Icons.location_on,
                    'Gare',
                    message.gare!.nom,
                  ),
                ],
                if (message.formattedPeriod.isNotEmpty) ...[
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Période',
                    message.formattedPeriod,
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

// ============================================================================
// FIN DES EXEMPLES
// ============================================================================
