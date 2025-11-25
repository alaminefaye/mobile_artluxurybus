import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/voting_session.dart';
import '../../providers/voting_provider.dart';
import '../../services/voting_api_service.dart';
import 'dart:async';

class VotingResultsScreen extends ConsumerStatefulWidget {
  final int sessionId;

  const VotingResultsScreen({super.key, required this.sessionId});

  @override
  ConsumerState<VotingResultsScreen> createState() =>
      _VotingResultsScreenState();
}

class _VotingResultsScreenState extends ConsumerState<VotingResultsScreen> {
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _loadEndTime();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEndTime() async {
    try {
      final sessionResp = await VotingApiService.getSession(widget.sessionId);
      if (sessionResp['success'] == true) {
        final data = sessionResp['data'] as Map<String, dynamic>;
        final endTimeStr = data['end_time'] as String?;
        if (endTimeStr != null) {
          final dt = DateTime.parse(endTimeStr);
          setState(() {
            _endTime = dt;
          });
          _startCountdown(dt);
        }
      }
    } catch (_) {}
  }

  void _startCountdown(DateTime endTime) {
    _countdownTimer?.cancel();
    void updateTimer() {
      final now = DateTime.now();
      final difference = endTime.difference(now);
      if (difference.isNegative) {
        setState(() => _remainingTime = Duration.zero);
        _countdownTimer?.cancel();
      } else {
        setState(() => _remainingTime = difference);
      }
    }

    updateTimer();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => updateTimer());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultsAsync = ref.watch(votingResultsProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Résultats du vote',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(votingResultsProvider(widget.sessionId));
              _loadEndTime();
            },
          ),
        ],
      ),
      body: resultsAsync.when(
        data: (data) {
          final sessionData = data['session'] as Map<String, dynamic>;
          final candidates = (data['candidates'] as List<dynamic>)
              .map((c) => Candidate.fromJson(c as Map<String, dynamic>))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(votingResultsProvider(widget.sessionId));
              await _loadEndTime();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compteur de temps restant (comme sur l'écran de vote)
                  if (_endTime != null) _buildCountdownTimer(isDark),

                  const SizedBox(height: 16),

                  // En-tête de la session
                  Card(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sessionData['title'] as String,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.how_to_vote,
                                  size: 20, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              const Text(
                                'Total des votes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${sessionData['total_votes']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.people_alt,
                                  size: 20, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              const Text(
                                'Candidats',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${candidates.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Titre de la section
                  Text(
                    'Classement des candidats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Liste des candidats
                  ...candidates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final candidate = entry.value;
                    final isFirst = index == 0;
                    final isSecond = index == 1;
                    final isThird = index == 2;

                    return _buildCandidateResultCard(
                      context,
                      candidate,
                      index + 1,
                      isFirst,
                      isSecond,
                      isThird,
                      isDark,
                    );
                  }),
                ],
              ),
            ),
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
                  ref.invalidate(votingResultsProvider(widget.sessionId));
                  _loadEndTime();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownTimer(bool isDark) {
    final days = _remainingTime.inDays;
    final hours = _remainingTime.inHours % 24;
    final minutes = _remainingTime.inMinutes % 60;
    final seconds = _remainingTime.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6366F1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_bottom, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Temps restant pour voter :',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeUnit(days.toString().padLeft(2, '0'), 'JOURS'),
              _buildTimeUnit(hours.toString().padLeft(2, '0'), 'HEURES'),
              _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'MINUTES'),
              _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'SECONDES'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => Container(
                      color: Colors.black,
                      padding: const EdgeInsets.all(16),
                      child: const Icon(Icons.broken_image,
                          color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: const Icon(Icons.close, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateResultCard(
    BuildContext context,
    Candidate candidate,
    int position,
    bool isFirst,
    bool isSecond,
    bool isThird,
    bool isDark,
  ) {
    Color podiumColor = Colors.grey.shade700;
    IconData podiumIcon = Icons.emoji_events_outlined;

    if (isFirst) {
      podiumColor = const Color(0xFFFFD700); // Or
      podiumIcon = Icons.emoji_events;
    } else if (isSecond) {
      podiumColor = const Color(0xFFC0C0C0); // Argent
      podiumIcon = Icons.emoji_events;
    } else if (isThird) {
      podiumColor = const Color(0xFFCD7F32); // Bronze
      podiumIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isFirst
            ? const BorderSide(color: Color(0xFFD4AF37), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Position / Médaille
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: podiumColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        podiumIcon,
                        color: podiumColor,
                        size: isFirst || isSecond || isThird ? 24 : 20,
                      ),
                      Text(
                        '$position',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: podiumColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Photo du candidat
                InkWell(
                  onTap: () {
                    if (candidate.photoPath != null) {
                      _showImagePreview(candidate.photoPath!);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                      image: candidate.photoPath != null
                          ? DecorationImage(
                              image: NetworkImage(candidate.photoPath!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: candidate.photoPath == null
                        ? Icon(Icons.person, color: Colors.grey.shade500)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                // Nom et numéro
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (candidate.candidateNumber != null) ...[
                        Text(
                          'N° ${candidate.candidateNumber}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        candidate.candidateName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pourcentage
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${candidate.votePercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Barre de progression
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: candidate.votePercentage / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isFirst
                            ? [const Color(0xFFD4AF37), const Color(0xFFFFD700)]
                            : [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Nombre de votes
            Text(
              '${candidate.voteCount} vote${candidate.voteCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
