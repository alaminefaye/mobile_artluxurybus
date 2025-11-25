import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/voting_session.dart';
import '../../providers/voting_provider.dart';
import 'voting_detail_screen.dart';
import 'voting_results_screen.dart';

class VotingSessionsScreen extends ConsumerWidget {
  const VotingSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionsAsync = ref.watch(votingSessionsGroupedProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'Sessions de vote',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor:
              const Color(0xFF6366F1), // Bleu violet comme les autres pages
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'En cours'),
              Tab(text: 'Programmées'),
              Tab(text: 'Terminées'),
            ],
          ),
        ),
        body: sessionsAsync.when(
          data: (grouped) {
            final active = grouped['active'] ?? <VotingSession>[];
            final scheduled = grouped['scheduled'] ?? <VotingSession>[];
            final finished = grouped['finished'] ?? <VotingSession>[];

            if (active.isEmpty && scheduled.isEmpty && finished.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.how_to_vote_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune session disponible',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Revenez plus tard',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }

            Widget buildList(List<VotingSession> items,
                {required String emptyTitle,
                String emptySubtitle = 'Revenez plus tard'}) {
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.how_to_vote_outlined,
                        size: 80,
                        color: isDark ? Colors.white54 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyTitle,
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        emptySubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(votingSessionsGroupedProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualiser'),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(votingSessionsGroupedProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final session = items[index];
                    return _buildSessionCard(context, session, isDark);
                  },
                ),
              );
            }

            return TabBarView(
              children: [
                buildList(active, emptyTitle: 'Aucune session en cours'),
                buildList(scheduled, emptyTitle: 'Aucune session programmée'),
                buildList(finished, emptyTitle: 'Aucune session terminée'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(votingSessionsGroupedProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(
      BuildContext context, VotingSession session, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');
    final now = DateTime.now();
    final isFinished = now.isAfter(session.endTime);
    final isScheduled = now.isBefore(session.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VotingDetailScreen(sessionId: session.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  _buildStatusBadge(session, isDark),
                ],
              ),

              if (session.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  session.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Informations
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '${dateFormat.format(session.startTime)} - ${dateFormat.format(session.endTime)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '${timeFormat.format(session.startTime)} - ${timeFormat.format(session.endTime)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.people,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '${session.candidates.length} candidats • ${session.totalVotes} votes',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.grey.shade600),
                  ),
                ],
              ),

              // Badge "Déjà voté"
              if (session.hasVoted) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Vous avez voté pour ${session.votedCandidate?.candidateName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Bouton d'action
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isFinished || session.hasVoted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VotingResultsScreen(sessionId: session.id),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VotingDetailScreen(sessionId: session.id),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isFinished || session.hasVoted)
                        ? Colors.blue.shade600
                        : const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    (isFinished || session.hasVoted)
                        ? 'Voir les résultats'
                        : (isScheduled
                            ? 'Voir les candidats'
                            : 'Voter maintenant'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(VotingSession session, bool isDark) {
    final isActive = session.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.circle : Icons.schedule,
            size: 8,
            color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'En cours' : session.timeRemaining,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
