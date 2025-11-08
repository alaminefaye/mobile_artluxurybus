import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/reservation_service.dart';
import '../services/translation_service.dart';
import '../providers/auth_provider.dart';
import 'payment_screen.dart';

class ClientInfoScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> depart;
  final List<int> selectedSeats;
  final int? stopEmbarkId;
  final int? stopDisembarkId;

  const ClientInfoScreen({
    super.key,
    required this.depart,
    required this.selectedSeats,
    this.stopEmbarkId,
    this.stopDisembarkId,
  });

  @override
  ConsumerState<ClientInfoScreen> createState() => _ClientInfoScreenState();
}

class _ClientInfoScreenState extends ConsumerState<ClientInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  int? _clientProfileId;
  bool _isReserving = false;
  bool _isDisposed = false;

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profileResult = await ReservationService.getMyProfile();

    if (profileResult['success'] == true && profileResult['client'] != null) {
      final client = profileResult['client'];
      if (mounted && !_isDisposed) {
        setState(() {
          _nomController.text = client['nom_complet'] ?? '';
          _telephoneController.text = client['telephone'] ?? '';
          _clientProfileId = client['id'];
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          final authState = ref.read(authProvider);
          if (authState.user != null) {
            setState(() {
              _nomController.text = authState.user!.name;
              _telephoneController.text = authState.user!.phoneNumber ?? '';
            });
          }
        }
      });
    }
  }

  void _showPartialCreationDialog({
    required List<Map<String, dynamic>> createdReservations,
    required List<int> failedSeats,
    required Map<int, String> failedSeatsReasons,
    required bool hasRateLimitError,
    required double totalAmount,
    String? sessionId,
    String? expiresAt,
    int? countdownSeconds,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t('client_info.partial_creation'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ ${createdReservations.length} ${t("client_info.reservations_created")}',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
              Text(
                  '🎫 Siège(s): ${createdReservations.map((r) => r['seat_number']).join(", ")}'),
              const SizedBox(height: 16),
              Text(
                '❌ ${failedSeats.length} ${t("client_info.seats_failed")}',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...failedSeats.map((seat) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${t("client_info.seat_error").replaceAll("{{seat}}", seat.toString()).replaceAll("{{error}}", failedSeatsReasons[seat] ?? t("client_info.unknown_error"))}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  )),
              if (hasRateLimitError) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t('client_info.rate_limit_warning'),
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Continuer avec les réservations réussies vers la page de paiement
              final firstReservation = createdReservations[0];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                    reservationId: firstReservation['reservation_id'],
                    sessionId: sessionId ??
                        'mobile_${_clientProfileId}_${DateTime.now().millisecondsSinceEpoch}',
                    amount: totalAmount,
                    depart: widget.depart,
                    seatNumber: createdReservations.first['seat_number'],
                    selectedSeats: createdReservations
                        .map((r) => r['seat_number'] as int)
                        .toList(),
                    expiresAt: expiresAt ??
                        DateTime.now()
                            .add(const Duration(minutes: 5))
                            .toIso8601String(),
                    countdownSeconds: countdownSeconds ?? 300,
                    reservations: createdReservations,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: Text(t('client_info.continue_with_success')),
          ),
        ],
      ),
    );
  }

  void _showAllFailedDialog({
    required List<int> failedSeats,
    required Map<int, String> failedSeatsReasons,
    required bool hasRateLimitError,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t('client_info.reservation_failed'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '❌ ${t("client_info.all_seats_failed")}',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                  '${t("client_info.seats_failed")}: ${failedSeats.join(", ")}'),
              const SizedBox(height: 12),
              ...failedSeats.map((seat) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${t("client_info.seat_error").replaceAll("{{seat}}", seat.toString()).replaceAll("{{error}}", failedSeatsReasons[seat] ?? t("client_info.unknown_error"))}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  )),
              if (hasRateLimitError) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '⏳ Trop de requêtes. Attendez quelques instants avant de réessayer.',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Réessayer tous les sièges
              _retryFailedSeats(failedSeats);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: Text(t('client_info.try_again')),
          ),
        ],
      ),
    );
  }

  Future<void> _retryFailedSeats(List<int> seatsToRetry) async {
    if (seatsToRetry.isEmpty) return;

    debugPrint(
        '🔄 [ClientInfoScreen] Réessai pour ${seatsToRetry.length} siège(s): ${seatsToRetry.join(", ")}');

    // Mettre à jour la liste des sièges à traiter
    // On va créer une nouvelle réservation avec seulement les sièges échoués
    // Pour cela, on doit modifier widget.selectedSeats, mais comme c'est final,
    // on va plutôt relancer le processus avec seulement ces sièges

    // Créer un nouveau ClientInfoScreen avec seulement les sièges à réessayer
    // Mais d'abord, on doit fermer le dialog actuel si ouvert
    Navigator.of(context).pop(); // Fermer le dialog précédent

    // Relancer la réservation avec seulement les sièges échoués
    // On va utiliser une approche différente : créer un widget temporaire
    // ou mieux : modifier directement la logique pour réessayer

    // Pour l'instant, on va simplement relancer _handleReservation
    // mais avec une liste modifiée. Comme on ne peut pas modifier widget.selectedSeats,
    // on va créer une nouvelle instance du widget avec les sièges à réessayer

    // Solution temporaire : naviguer vers un nouveau ClientInfoScreen avec les sièges à réessayer
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ClientInfoScreen(
          depart: widget.depart,
          selectedSeats: seatsToRetry, // Seulement les sièges à réessayer
          stopEmbarkId: widget.stopEmbarkId,
          stopDisembarkId: widget.stopDisembarkId,
        ),
      ),
    );

    // Attendre un peu pour que le widget soit monté, puis déclencher la réservation
    Future.delayed(const Duration(milliseconds: 500), () {
      // Le nouveau widget va charger le profil, puis l'utilisateur devra cliquer sur "Valider"
      // Pour automatiser, on pourrait utiliser un GlobalKey, mais c'est plus complexe
      // Pour l'instant, on laisse l'utilisateur cliquer sur "Valider"
    });
  }

  Future<void> _handleReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_telephoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('client_info.phone_required')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isReserving = true;
    });

    try {
      // Rechercher ou créer le ClientProfile
      int? clientProfileId = _clientProfileId;

      if (clientProfileId == null) {
        final searchResult =
            await ReservationService.searchOrCreateClientProfile(
          _telephoneController.text,
        );

        if (searchResult['success'] == true && searchResult['exists'] == true) {
          clientProfileId = searchResult['client']['id'];
        } else {
          if (mounted && !_isDisposed) {
            setState(() {
              _isReserving = false;
            });
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('client_info.client_not_found')),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      // Créer une réservation pour CHAQUE siège sélectionné (SANS CONFIRMER)
      // On va créer les réservations et naviguer vers la page de paiement
      List<Map<String, dynamic>> createdReservations = [];
      List<int> failedSeats = [];
      Map<int, String> failedSeatsReasons = {};
      double totalAmount = 0.0;
      String? sessionId;
      String? expiresAt;
      int? countdownSeconds;

      debugPrint(
          '🎫 [ClientInfoScreen] Début création réservations pour ${widget.selectedSeats.length} siège(s): ${widget.selectedSeats.join(", ")}');

      // Afficher un indicateur de chargement
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  '${t("client_info.processing")}\n'
                  '${t("trips.seat")} ${createdReservations.length + failedSeats.length + 1}/${widget.selectedSeats.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  t('common.loading'),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      // Boucle pour créer chaque réservation avec délai pour éviter le rate limiting
      bool hasRateLimitError = false;

      for (int i = 0; i < widget.selectedSeats.length; i++) {
        final seatNumber = widget.selectedSeats[i];
        debugPrint(
            '🔄 [ClientInfoScreen] Création réservation siège $seatNumber (${i + 1}/${widget.selectedSeats.length})');

        // Délai entre chaque siège : 2 secondes minimum pour respecter le rate limit
        if (i > 0) {
          await Future.delayed(const Duration(seconds: 2));
        }

        // Retry avec backoff exponentiel en cas d'erreur 429
        bool success = false;
        int retryCount = 0;
        const maxRetries = 3;
        String? lastError;

        while (!success && retryCount < maxRetries) {
          if (!mounted || _isDisposed) {
            debugPrint(
                '⚠️ [ClientInfoScreen] Widget démonté, abandon siège $seatNumber');
            failedSeats.add(seatNumber);
            failedSeatsReasons[seatNumber] = t('client_info.widget_unmounted');
            break;
          }

          try {
            final result = await ReservationService.createReservation(
              departId: widget.depart['id'],
              seatNumber: seatNumber,
              clientProfileId: clientProfileId!,
              stopEmbarkId: widget.stopEmbarkId,
              stopDisembarkId: widget.stopDisembarkId,
            );

            // Vérifier si c'est une erreur 429 (Too Many Attempts)
            final isRateLimit = result['success'] == false &&
                (result['status_code'] == 429 ||
                    result['message']?.toString().contains('429') == true ||
                    result['message']?.toString().contains('Too Many') ==
                        true ||
                    result['message']?.toString().contains('rate limit') ==
                        true ||
                    result['message']?.toString().contains('Trop de') == true);

            if (isRateLimit) {
              hasRateLimitError = true;
              retryCount++;
              lastError =
                  result['message']?.toString() ?? t('client_info.rate_limit');

              if (retryCount < maxRetries) {
                final delay = Duration(seconds: 3 * (1 << (retryCount - 1)));
                debugPrint(
                    '⏳ [ClientInfoScreen] Rate limit pour siège $seatNumber, attente ${delay.inSeconds}s (tentative $retryCount/$maxRetries)');
                await Future.delayed(delay);
                continue;
              } else {
                debugPrint(
                    '❌ [ClientInfoScreen] Échec siège $seatNumber après $maxRetries tentatives (rate limit)');
                failedSeats.add(seatNumber);
                failedSeatsReasons[seatNumber] =
                    t('client_info.too_many_attempts');
                break;
              }
            }

            if (result['success'] == true) {
              final reservationData = result['data'];
              final reservationId = reservationData?['reservation_id'];

              // Convertir le montant en double (gère String et num)
              double amount = 0.0;
              final amountValue =
                  reservationData?['amount'] ?? widget.depart['prix'] ?? 0.0;
              if (amountValue is num) {
                amount = amountValue.toDouble();
              } else if (amountValue is String) {
                amount = double.tryParse(amountValue) ?? 0.0;
              } else {
                amount = 0.0;
              }

              if (reservationId != null) {
                // Stocker les informations de réservation (SANS CONFIRMER)
                createdReservations.add({
                  'reservation_id': reservationId,
                  'seat_number': seatNumber,
                  'amount': amount,
                });

                // Utiliser les données de la première réservation pour sessionId, expiresAt, etc.
                if (sessionId == null) {
                  sessionId = reservationData?['session_id'];
                  expiresAt = reservationData?['expires_at'];
                  countdownSeconds = reservationData?['countdown_seconds'];
                }

                totalAmount += amount;
                debugPrint(
                    '✅ [ClientInfoScreen] Réservation créée pour siège $seatNumber (ID: $reservationId, Montant: $amount FCFA)');
                success = true;
              } else {
                debugPrint(
                    '❌ [ClientInfoScreen] Pas de reservation_id pour siège $seatNumber');
                failedSeats.add(seatNumber);
                failedSeatsReasons[seatNumber] =
                    t('client_info.no_reservation_id');
                break;
              }
            } else {
              lastError = result['message']?.toString() ??
                  t('client_info.unknown_error');
              debugPrint(
                  '❌ [ClientInfoScreen] Échec création réservation siège $seatNumber: $lastError');
              failedSeats.add(seatNumber);
              failedSeatsReasons[seatNumber] = lastError;
              break;
            }
          } catch (e) {
            debugPrint(
                '❌ [ClientInfoScreen] Exception lors de la création réservation siège $seatNumber: $e');
            lastError = 'Exception: ${e.toString()}';
            failedSeats.add(seatNumber);
            failedSeatsReasons[seatNumber] = lastError;
            break;
          }
        }
      }

      debugPrint(
          '📊 [ClientInfoScreen] Résumé: ${createdReservations.length} créée(s), ${failedSeats.length} échec(s)');
      debugPrint('   💰 Montant total: $totalAmount FCFA');

      // Fermer le loading
      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted && !_isDisposed) {
        setState(() {
          _isReserving = false;
        });
      }

      // Afficher le résultat et naviguer vers la page de paiement
      if (mounted && !_isDisposed) {
        if (createdReservations.isNotEmpty && failedSeats.isEmpty) {
          // Toutes les réservations ont été créées avec succès - aller vers la page de paiement
          debugPrint(
              '💳 [ClientInfoScreen] Navigation vers PaymentScreen avec ${createdReservations.length} réservation(s)');

          // Utiliser la première réservation pour les données communes
          final firstReservation = createdReservations[0];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                reservationId: firstReservation['reservation_id'],
                sessionId: sessionId ??
                    'mobile_${clientProfileId}_${DateTime.now().millisecondsSinceEpoch}',
                amount: totalAmount,
                depart: widget.depart,
                seatNumber: widget.selectedSeats
                    .first, // Pour compatibilité avec PaymentScreen actuel
                selectedSeats: widget.selectedSeats,
                expiresAt: expiresAt ??
                    DateTime.now()
                        .add(const Duration(minutes: 5))
                        .toIso8601String(),
                countdownSeconds: countdownSeconds ?? 300,
                reservations:
                    createdReservations, // Liste de toutes les réservations
              ),
            ),
          );
        } else if (createdReservations.isNotEmpty && failedSeats.isNotEmpty) {
          // Certaines réservations ont réussi, d'autres ont échoué
          // Proposer de continuer avec les réservations réussies ou réessayer
          _showPartialCreationDialog(
            createdReservations: createdReservations,
            failedSeats: failedSeats,
            failedSeatsReasons: failedSeatsReasons,
            hasRateLimitError: hasRateLimitError,
            totalAmount: totalAmount,
            sessionId: sessionId,
            expiresAt: expiresAt,
            countdownSeconds: countdownSeconds,
          );
        } else {
          // Toutes les créations ont échoué
          _showAllFailedDialog(
            failedSeats: failedSeats,
            failedSeatsReasons: failedSeatsReasons,
            hasRateLimitError: hasRateLimitError,
          );
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isReserving = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t("common.error")}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t('client_info.title')),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Résumé
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t("trips.seat")}${widget.selectedSeats.length > 1 ? 's' : ''} ${t("seats.selected")}: ${widget.selectedSeats.join(', ')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: t('client_info.full_name_label'),
                  prefixIcon: const Icon(Icons.person, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t('client_info.name_required');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _telephoneController,
                decoration: InputDecoration(
                  labelText: t('client_info.phone_label'),
                  hintText: t('client_info.phone_hint'),
                  prefixIcon: const Icon(Icons.phone, size: 20),
                  suffixIcon: _telephoneController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _telephoneController.clear();
                            });
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t('client_info.phone_required_error');
                  }
                  if (value.length < 8) {
                    return t('client_info.invalid_number');
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t('client_info.phone_hint'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isReserving ? null : _handleReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isReserving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          t('common.save'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isReserving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    t('common.cancel'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
}
