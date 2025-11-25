import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../models/voting_session.dart';
import '../../providers/voting_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/voting_api_service.dart';
import 'voting_results_screen.dart';

class VotingDetailScreen extends ConsumerStatefulWidget {
  final int sessionId;

  const VotingDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<VotingDetailScreen> createState() => _VotingDetailScreenState();
}

class _VotingDetailScreenState extends ConsumerState<VotingDetailScreen> {
  int? _selectedCandidateId;
  bool _isVoting = false;
  String? _deviceId;
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startCountdown(DateTime endTime) {
    _countdownTimer?.cancel();

    void updateTimer() {
      final now = DateTime.now();
      final difference = endTime.difference(now);

      if (difference.isNegative) {
        setState(() {
          _remainingTime = Duration.zero;
        });
        _countdownTimer?.cancel();
      } else {
        setState(() {
          _remainingTime = difference;
        });
      }
    }

    updateTimer();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => updateTimer());
  }

  Future<void> _loadDeviceId() async {
    final deviceId = await VotingApiService.getDeviceId();
    setState(() {
      _deviceId = deviceId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionAsync = ref.watch(votingSessionProvider(widget.sessionId));
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Session de vote',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor:
            const Color(0xFF6366F1), // Bleu violet comme les autres pages
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(votingSessionProvider(widget.sessionId));
            },
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) {
          // Si l'utilisateur a déjà voté, afficher les résultats
          if (session.hasVoted) {
            return _buildAlreadyVotedView(context, session, isDark);
          }

          // Sinon, afficher le formulaire de vote
          return _buildVotingForm(context, session, user, isDark);
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadyVotedView(
      BuildContext context, VotingSession session, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Vous avez déjà voté !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre vote pour ${session.votedCandidate?.candidateName} a été enregistré avec succès.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VotingResultsScreen(sessionId: session.id),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart),
                label: const Text('Voir les résultats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingForm(
      BuildContext context, VotingSession session, dynamic user, bool isDark) {
    // Démarrer le compte à rebours
    if (_countdownTimer == null || !_countdownTimer!.isActive) {
      _startCountdown(session.endTime);
    }

    // Si la session n'a pas encore commencé, mode lecture seule
    final bool isScheduled = DateTime.now().isBefore(session.startTime);

    // Filtrer les candidats selon la recherche
    final filteredCandidates = session.candidates.where((candidate) {
      if (_searchQuery.isEmpty) return true;
      return candidate.candidateName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compteur de temps restant
          _buildCountdownTimer(isDark),

          const SizedBox(height: 16),

          // Barre de recherche
          _buildSearchBar(isDark),

          // Bandeau d’information si programmée
          if (isScheduled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.orange.shade800 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.orange.shade700 : Colors.orange.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule,
                      size: 16,
                      color:
                          isDark ? Colors.orange.shade200 : Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette session est programmée. Vous pouvez consulter les candidats, le vote ouvrira bientôt.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // En-tête de la session
          Card(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (session.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      session.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '${session.totalVotes} votes enregistrés',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Titre de la liste des candidats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choisissez votre candidat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (_searchQuery.isNotEmpty)
                Text(
                  '${filteredCandidates.length} résultat(s)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Message si aucun résultat
          if (filteredCandidates.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun candidat trouvé',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Liste des candidats
          ...filteredCandidates.map((candidate) {
            final isSelected = _selectedCandidateId == candidate.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCandidateId = candidate.id;
                });
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFD4AF37)
                        : (isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Photo du candidat (cliquable)
                      GestureDetector(
                        onTap: candidate.photoPath != null
                            ? () => _showPhotoPreview(context, candidate)
                            : null,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                            image: candidate.photoPath != null
                                ? DecorationImage(
                                    image: NetworkImage(candidate.photoPath!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: candidate.photoPath == null
                              ? Icon(Icons.person,
                                  size: 40, color: Colors.grey.shade600)
                              : Stack(
                                  children: [
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.zoom_in,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Nom et numéro du candidat
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (candidate.candidateNumber != null) ...[
                              Text(
                                'N° ${candidate.candidateNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              candidate.candidateName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (candidate.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                candidate.description!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Sélection par checkbox (nouvelle API Flutter)
                      Checkbox(
                        value: _selectedCandidateId == candidate.id,
                        onChanged: (bool? value) {
                          setState(() {
                            _selectedCandidateId =
                                value == true ? candidate.id : null;
                          });
                        },
                        activeColor: const Color(0xFFD4AF37),
                        shape: const CircleBorder(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Bouton de vote
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isScheduled || _selectedCandidateId == null || _isVoting)
                  ? null
                  : () => _confirmAndVote(context, session, user),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor:
                    isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                disabledForegroundColor:
                    isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
              child: _isVoting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isScheduled ? 'Vote non disponible (programmée)' : 'Confirmer mon vote',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Information sur l'ID de l'appareil
          if (_deviceId != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.blue.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.smartphone,
                      size: 16,
                      color:
                          isDark ? Colors.blue.shade300 : Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre appareil est identifié de manière unique pour éviter les votes multiples',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmAndVote(
      BuildContext context, VotingSession session, dynamic user) async {
    final candidate =
        session.candidates.firstWhere((c) => c.id == _selectedCandidateId);

    // Boîte de dialogue de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer votre vote'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vous êtes sur le point de voter pour :'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4AF37)),
                ),
                child: Row(
                  children: [
                    if (candidate.candidateNumber != null) ...[
                      Text(
                        'N° ${candidate.candidateNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        candidate.candidateName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ Ce vote est définitif et ne pourra pas être modifié.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
              ),
              child: const Text('Confirmer',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await _submitVote(context, session, candidate, user);
    }
  }

  Future<void> _submitVote(BuildContext context, VotingSession session,
      Candidate candidate, dynamic user) async {
    setState(() {
      _isVoting = true;
    });

    try {
      // Récupérer les informations de l'utilisateur
      String voterName = user?.name ?? '';
      // Essayer phoneNumber d'abord, puis phone (getter)
      String voterPhone = user?.phoneNumber ?? user?.phone ?? '';

      // Vérifier que l'utilisateur a un nom et un téléphone
      if (!context.mounted) return;
      if (voterName.isEmpty || voterPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(voterPhone.isEmpty
                ? '❌ Veuillez compléter votre profil avec votre numéro de téléphone avant de voter'
                : '❌ Veuillez compléter votre profil (nom et téléphone) avant de voter'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Envoyer le vote
      final response = await VotingApiService.vote(
        sessionId: session.id,
        candidateId: candidate.id,
        voterFullName: voterName,
        voterPhone: voterPhone,
        appVersion: '1.0.4',
      );

      if (!context.mounted) return;
      if (response['success'] == true) {
        // Invalider le provider pour rafraîchir les données
        ref.invalidate(votingSessionProvider(widget.sessionId));
        ref.invalidate(votingSessionsProvider);

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${response['message']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Naviguer vers les résultats
        if (session.showResultsDuringVote) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VotingResultsScreen(sessionId: session.id),
            ),
          );
        }
      } else {
        // Afficher le message d'erreur
        final errorMessage = response['message'] ?? 'Erreur lors du vote';
        final details = response['details'];

        String fullMessage = errorMessage;
        if (details != null && details['message'] != null) {
          fullMessage = details['message'] as String;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fullMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  // Barre de recherche
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher un candidat par nom...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // Compteur de temps restant
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

  // Prévisualisation de la photo du candidat
  void _showPhotoPreview(BuildContext context, Candidate candidate) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Image en plein écran
            Center(
              child: InteractiveViewer(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      candidate.photoPath!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade900,
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Bouton de fermeture
            Positioned(
              top: 40,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // Nom du candidat en bas
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (candidate.candidateNumber != null)
                      Text(
                        'N° ${candidate.candidateNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    Text(
                      candidate.candidateName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (candidate.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        candidate.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
