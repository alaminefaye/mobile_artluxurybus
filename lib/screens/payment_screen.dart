import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/reservation_service.dart';
import '../services/translation_service.dart';
import '../services/trip_service.dart';
import '../models/trip_model.dart';
import '../utils/error_message_helper.dart';
import 'home_page.dart';
import 'my_trips_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int? reservationId; // Optionnel si ouvert depuis deep link
  final String? sessionId; // Optionnel si ouvert depuis deep link
  final double? amount; // Optionnel si ouvert depuis deep link
  final Map<String, dynamic>? depart; // Optionnel si ouvert depuis deep link
  final int? seatNumber; // Optionnel si ouvert depuis deep link
  final List<int>? selectedSeats;
  final String? expiresAt; // Optionnel si ouvert depuis deep link
  final int? countdownSeconds; // Optionnel si ouvert depuis deep link
  final List<Map<String, dynamic>>?
      reservations; // Liste de toutes les réservations à confirmer
  final String?
      paymentGroupId; // ID du groupe de paiement pour paiement multiple

  // Paramètres pour deep link de paiement réussi
  final String? paymentStatus; // 'success', 'error', 'pending'
  final String? paymentMessage;
  final int? ticketId; // ID du ticket créé après paiement réussi

  const PaymentScreen({
    super.key,
    this.reservationId, // Optionnel si ouvert depuis deep link
    this.sessionId, // Optionnel si ouvert depuis deep link
    this.amount, // Optionnel si ouvert depuis deep link
    this.depart, // Optionnel si ouvert depuis deep link
    this.seatNumber, // Optionnel si ouvert depuis deep link
    this.selectedSeats,
    this.expiresAt, // Optionnel si ouvert depuis deep link
    this.countdownSeconds, // Optionnel si ouvert depuis deep link
    this.reservations, // Liste optionnelle de toutes les réservations
    this.paymentGroupId, // ID du groupe de paiement
    this.paymentStatus, // Statut du paiement si ouvert depuis deep link
    this.paymentMessage, // Message du paiement
    this.ticketId, // ID du ticket créé
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with WidgetsBindingObserver {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _useLoyaltyPoints = false;
  bool _usePromoCode = false;
  String _promoCode = '';
  bool _isVerifyingPromo = false;
  String? _promoCodeMessage;
  bool _promoCodeValid = false;
  int? _clientPoints;
  bool _isLoadingPoints = true;
  bool _useBalance = false;
  double _clientBalance = 0.0; // Solde du client
  bool _hasCheckedPaymentStatus =
      false; // Pour éviter de vérifier plusieurs fois
  DateTime? _lastAppResumeTime; // Pour éviter de vérifier trop souvent

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  // Getter pour vérifier si le client a assez de points
  bool get hasEnoughPoints => (_clientPoints ?? 0) >= 10;

  // Getter pour vérifier si le client a assez de solde
  bool get hasEnoughBalance => _clientBalance >= _finalAmount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addObserver(this); // Écouter les changements d'état de l'app
    _loadClientPoints();

    // Désactiver le code promo et les points de fidélité si plusieurs sièges sont sélectionnés au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasMultipleSeats) {
        setState(() {
          if (_usePromoCode) {
            _usePromoCode = false;
            _promoCode = '';
            _promoCodeValid = false;
            _promoCodeMessage = null;
          }
          if (_useLoyaltyPoints) {
            _useLoyaltyPoints = false;
            if (_selectedPaymentMethod == 'loyalty') {
              _selectedPaymentMethod = null;
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Retirer l'observateur
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Quand l'app revient au premier plan après avoir été en arrière-plan
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();

      // Éviter de vérifier trop souvent (au moins 3 secondes entre les vérifications)
      if (_lastAppResumeTime == null ||
          now.difference(_lastAppResumeTime!) > const Duration(seconds: 3)) {
        _lastAppResumeTime = now;

        // Si on a ouvert Wave (isProcessing était true) et qu'on n'a pas encore vérifié le statut
        // Attendre un peu pour laisser le webhook traiter le paiement
        if (_isProcessing || widget.reservationId != null) {
          Future.delayed(const Duration(seconds: 2), () {
            _checkPaymentStatus();
          });
        }
      }
    }
  }

  /// Vérifier le statut du paiement en interrogeant le backend
  Future<void> _checkPaymentStatus() async {
    if (_hasCheckedPaymentStatus || widget.depart == null) {
      return; // Déjà vérifié ou pas de départ
    }

    debugPrint(
        '🔍 [PaymentScreen] Vérification statut paiement après retour de Wave');

    try {
      // Récupérer les trajets du client
      final tripsResult = await TripService.getMyTrips();

      if (tripsResult.trips.isNotEmpty) {
        final departId = widget.depart!['id'] as int?;
        if (departId == null) return;

        // Chercher des tickets récents pour ce départ (créés dans les 5 dernières minutes)
        final now = DateTime.now();
        final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

        // Fonction helper pour parser dateAchat
        DateTime? parseDateAchat(String dateAchat) {
          try {
            // Essayer de parser différents formats de date
            if (dateAchat.contains('T')) {
              return DateTime.parse(dateAchat);
            } else if (dateAchat.contains(' ')) {
              // Format: "2025-11-10 23:30:00"
              return DateTime.parse(dateAchat.replaceAll(' ', 'T'));
            } else {
              // Format: "2025-11-10"
              return DateTime.parse(dateAchat);
            }
          } catch (e) {
            debugPrint(
                '❌ [PaymentScreen] Erreur parsing date: $dateAchat - $e');
            return null;
          }
        }

        // Si on a un payment_group_id avec plusieurs réservations
        if (widget.paymentGroupId != null && widget.reservations != null) {
          final expectedSeats = widget.reservations!
              .map((r) => r['seat_number'] as int?)
              .where((s) => s != null)
              .toSet();

          // Compter les tickets trouvés pour ce départ et ces sièges
          int foundTickets = 0;
          for (var trip in tripsResult.trips) {
            final tripDepartId = trip.depart?.id;
            final tripSeatNumber = trip.siegeNumber;
            final dateAchatParsed = parseDateAchat(trip.dateAchat);

            if (tripDepartId == departId &&
                tripSeatNumber != null &&
                expectedSeats.contains(tripSeatNumber) &&
                dateAchatParsed != null &&
                dateAchatParsed.isAfter(fiveMinutesAgo)) {
              foundTickets++;
              debugPrint(
                  '✅ [PaymentScreen] Ticket trouvé: siège $tripSeatNumber, créé à $dateAchatParsed');
            }
          }

          // Si on a trouvé tous les tickets attendus
          if (foundTickets >= expectedSeats.length) {
            _hasCheckedPaymentStatus = true;
            debugPrint(
                '✅ [PaymentScreen] Tous les paiements ont réussi ($foundTickets/${expectedSeats.length} tickets), navigation vers Mes Trajets');

            if (mounted) {
              // Naviguer directement vers Mes Trajets
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const HomePage(
                      initialTabIndex: 1), // Onglet "Mes Trajets"
                ),
                (route) => route.isFirst,
              );
            }
          } else {
            debugPrint(
                '⏳ [PaymentScreen] Tickets trouvés: $foundTickets/${expectedSeats.length}, attente...');
          }
        } else if (widget.seatNumber != null) {
          // Vérifier une seule réservation
          final seatNumber = widget.seatNumber!;

          // Chercher un ticket récent pour ce siège et ce départ
          Trip? matchingTrip;
          for (var trip in tripsResult.trips) {
            final tripDepartId = trip.depart?.id;
            final tripSeatNumber = trip.siegeNumber;
            final dateAchatParsed = parseDateAchat(trip.dateAchat);

            if (tripDepartId == departId &&
                tripSeatNumber == seatNumber &&
                dateAchatParsed != null &&
                dateAchatParsed.isAfter(fiveMinutesAgo)) {
              matchingTrip = trip;
              break;
            }
          }

          if (matchingTrip != null) {
            _hasCheckedPaymentStatus = true;
            debugPrint(
                '✅ [PaymentScreen] Ticket trouvé pour siège $seatNumber, paiement réussi, navigation vers Mes Trajets');

            if (mounted) {
              // Naviguer directement vers Mes Trajets
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const HomePage(
                      initialTabIndex: 1), // Onglet "Mes Trajets"
                ),
                (route) => route.isFirst,
              );
            }
          } else {
            debugPrint(
                '⏳ [PaymentScreen] Ticket pas encore trouvé pour siège $seatNumber, attente...');
          }
        }
      }
    } catch (e) {
      debugPrint(
          '❌ [PaymentScreen] Erreur lors de la vérification du statut: $e');
    }
  }

  Future<void> _loadClientPoints() async {
    try {
      final profileResult = await ReservationService.getMyProfile();
      if (profileResult['success'] == true && profileResult['client'] != null) {
        final client = profileResult['client'];

        // Convertir le solde en double (gère String et num)
        double balance = 0.0;
        final soldeValue = client['solde'] ?? 0.0;
        if (soldeValue is num) {
          balance = soldeValue.toDouble();
        } else if (soldeValue is String) {
          balance = double.tryParse(soldeValue) ?? 0.0;
        } else {
          balance = 0.0;
        }

        // Récupérer les points (peut être 'points' ou 'points_tickets')
        int? pointsValue;
        if (client['points'] != null) {
          if (client['points'] is int) {
            pointsValue = client['points'];
          } else if (client['points'] is num) {
            pointsValue = (client['points'] as num).toInt();
          } else {
            pointsValue = int.tryParse(client['points'].toString());
          }
        } else if (client['points_tickets'] != null) {
          if (client['points_tickets'] is int) {
            pointsValue = client['points_tickets'];
          } else if (client['points_tickets'] is num) {
            pointsValue = (client['points_tickets'] as num).toInt();
          } else {
            pointsValue = int.tryParse(client['points_tickets'].toString());
          }
        }

        pointsValue = pointsValue ?? 0;

        setState(() {
          _clientPoints = pointsValue;
          _clientBalance = balance;
          _isLoadingPoints = false;
        });

        // Debug pour vérifier les points récupérés
        debugPrint('💳 [PaymentScreen] ✅ Points récupérés: $_clientPoints');
        debugPrint('💳 [PaymentScreen] ✅ Solde récupéré: $_clientBalance');
        debugPrint('💳 [PaymentScreen] ✅ Client ID: ${client['id']}');
        debugPrint('💳 [PaymentScreen] ✅ Téléphone: ${client['telephone']}');
        debugPrint(
            '💳 [PaymentScreen] ✅ Données client: points=${client['points']}, points_tickets=${client['points_tickets']}');
      } else {
        debugPrint('💳 [PaymentScreen] ❌ Échec récupération profil');
        debugPrint('💳 [PaymentScreen] ❌ Message: ${profileResult['message']}');
        debugPrint('💳 [PaymentScreen] ❌ Exists: ${profileResult['exists']}');
        if (profileResult['status_code'] == 404) {
          debugPrint(
              '💳 [PaymentScreen] ❌ ERREUR: Profil client non trouvé - L\'utilisateur n\'a pas de ClientProfile lié à son compte');
          debugPrint(
              '💳 [PaymentScreen] ❌ User ID: ${profileResult['user_id']}');
        }
        setState(() {
          _clientPoints = 0;
          _clientBalance = 0.0;
          _isLoadingPoints = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint(
          '💳 [PaymentScreen] ❌ Exception lors du chargement des points: $e');
      debugPrint('💳 [PaymentScreen] ❌ Stack trace: $stackTrace');
      setState(() {
        _clientPoints = 0;
        _clientBalance = 0.0;
        _isLoadingPoints = false;
      });
    }
  }

  // Vérifier si plusieurs sièges sont sélectionnés
  bool get _hasMultipleSeats {
    if (widget.reservations != null && widget.reservations!.length > 1) {
      return true;
    }
    if (widget.selectedSeats != null && widget.selectedSeats!.length > 1) {
      return true;
    }
    return false;
  }

  Future<void> _verifyPromoCode() async {
    // Vérifier d'abord si plusieurs sièges sont sélectionnés
    if (_hasMultipleSeats) {
      setState(() {
        _isVerifyingPromo = false;
        _promoCodeValid = false;
        _promoCodeMessage =
            'Les codes promotionnels ne peuvent être utilisés que pour un seul siège.';
      });
      return;
    }

    if (_promoCode.isEmpty) {
      setState(() {
        _promoCodeMessage = t('payment.enter_code_error');
        _promoCodeValid = false;
      });
      return;
    }

    setState(() {
      _isVerifyingPromo = true;
      _promoCodeMessage = null;
      _promoCodeValid = false;
    });

    try {
      // Déterminer le nombre de réservations
      int reservationCount = 1;
      if (widget.reservations != null) {
        reservationCount = widget.reservations!.length;
      } else if (widget.selectedSeats != null &&
          widget.selectedSeats!.length > 1) {
        reservationCount = widget.selectedSeats!.length;
      }

      final result = await ReservationService.verifyPromoCode(_promoCode,
          reservationCount: reservationCount);
      setState(() {
        _isVerifyingPromo = false;
        if (result['success'] == true) {
          // Vérifier à nouveau si plusieurs sièges (au cas où l'utilisateur aurait ajouté des sièges pendant la vérification)
          if (_hasMultipleSeats) {
            _promoCodeValid = false;
            _promoCodeMessage =
                'Les codes promotionnels ne peuvent être utilisés que pour un seul siège.';
          } else {
            _promoCodeValid = true;
            _promoCodeMessage = result['message'] ?? t('payment.code_valid');
            // Activer automatiquement le code promo comme méthode de paiement
            _usePromoCode = true;
            _selectedPaymentMethod = 'promo';
            // Désactiver les autres méthodes
            _useLoyaltyPoints = false;
            _useBalance = false;
          }
        } else {
          _promoCodeValid = false;
          _promoCodeMessage = result['message'] ?? t('payment.code_invalid');
        }
      });
    } catch (e) {
      setState(() {
        _isVerifyingPromo = false;
        _promoCodeValid = false;
        _promoCodeMessage = t('payment.verification_error');
      });
    }
  }

  double get _finalAmount {
    // Calculer le montant total à partir de toutes les réservations
    // C'est plus fiable que d'utiliser seulement widget.amount
    double total = 0.0;

    // Récupérer le prix du départ comme fallback
    double departPrice = 0.0;
    if (widget.depart != null && widget.depart!.isNotEmpty) {
      final priceValue =
          widget.depart!['prix'] ?? widget.depart!['prix_depart'] ?? 0.0;
      if (priceValue is num) {
        departPrice = priceValue.toDouble();
      } else if (priceValue is String) {
        departPrice = double.tryParse(priceValue) ?? 0.0;
      }
    }

    if (widget.reservations != null && widget.reservations!.isNotEmpty) {
      // Calculer le total à partir de toutes les réservations
      for (var reservation in widget.reservations!) {
        double amount = 0.0;
        final amountValue = reservation['amount'];

        // Si le montant n'est pas défini dans la réservation, utiliser le prix du départ
        if (amountValue == null || amountValue == 0.0) {
          amount = departPrice;
        } else if (amountValue is num) {
          amount = amountValue.toDouble();
        } else if (amountValue is String) {
          amount = double.tryParse(amountValue) ?? departPrice;
        } else {
          amount = departPrice;
        }

        total += amount;
      }
    } else {
      // Fallback : utiliser widget.amount si pas de réservations
      // Si widget.amount est 0 ou null, utiliser le prix du départ
      total = (widget.amount != null && widget.amount! > 0)
          ? widget.amount!
          : departPrice;
    }

    // Si plusieurs sièges sont sélectionnés, le code promo ne peut pas être utilisé
    if (_hasMultipleSeats) {
      // Si code promo est activé avec plusieurs sièges, ignorer le code promo
      if (_usePromoCode) {
        return total; // Ne pas appliquer de réduction
      }
    }

    // Si paiement avec points de fidélité (10 points = ticket gratuit)
    // UNIQUEMENT pour un seul siège (comme le code promo)
    if (_useLoyaltyPoints && (_clientPoints ?? 0) >= 10 && !_hasMultipleSeats) {
      return 0.0; // Ticket gratuit
    }

    // Si code promo valide et un seul siège, créer un laisser-passer (ticket gratuit)
    if (_usePromoCode && _promoCodeValid && !_hasMultipleSeats) {
      return 0.0; // Ticket gratuit (laisser-passer) avec code promo
    }

    return total;
  }

  String _getEmbarkDestination() {
    // Priorité: utiliser les arrêts choisis renvoyés par l'API dans les réservations
    if (widget.reservations != null && widget.reservations!.isNotEmpty) {
      final first = widget.reservations!.first;
      final depart = first['depart'];
      if (depart is Map && depart.isNotEmpty) {
        final emb = depart['embarquement'];
        final dest = depart['destination'];
        if (emb != null &&
            dest != null &&
            emb.toString().isNotEmpty &&
            dest.toString().isNotEmpty) {
          return '$emb → $dest';
        }
      }
    }
    if (widget.depart == null || widget.depart!.isEmpty) {
      return 'Trajet non disponible';
    }
    if (widget.depart!.containsKey('trajet')) {
      final trajet = widget.depart!['trajet'];
      if (trajet is Map) {
        return '${trajet['embarquement'] ?? ''} → ${trajet['destination'] ?? ''}';
      }
    }
    if (widget.depart!.containsKey('embarquement') &&
        widget.depart!.containsKey('destination')) {
      return '${widget.depart!['embarquement']} → ${widget.depart!['destination']}';
    }
    return t('payment.trip_not_available');
  }

  String _getDepartDateTime() {
    // Priorité: utiliser la date/heure renvoyées par l'API dans les réservations
    if (widget.reservations != null && widget.reservations!.isNotEmpty) {
      final first = widget.reservations!.first;
      final depart = first['depart'];
      if (depart is Map && depart.isNotEmpty) {
        final dynamic dateValue = depart['date'] ?? depart['date_depart'] ?? '';
        final dynamic heureValue =
            depart['heure'] ?? depart['heure_depart'] ?? '';
        final String dateStr = dateValue?.toString() ?? '';
        final String heureStr = heureValue?.toString() ?? '';
        if (dateStr.isNotEmpty && heureStr.isNotEmpty) {
          return '${t('payment.date_prefix')} $dateStr à $heureStr';
        }
      }
    }
    if (widget.depart == null || widget.depart!.isEmpty) {
      return 'Date non disponible';
    }
    final date = widget.depart!['date_depart'] ?? widget.depart!['date'] ?? '';
    final heure =
        widget.depart!['heure_depart'] ?? widget.depart!['heure'] ?? '';
    if (date.isNotEmpty && heure.isNotEmpty) {
      return '${t('payment.date_prefix')} $date à $heure';
    }
    return t('payment.date_not_available');
  }

  // Obtenir l'affichage des sièges (tous les sièges réservés)
  String _getSeatsDisplay() {
    // Priorité 1: Utiliser les réservations si disponibles (plus fiable)
    if (widget.reservations != null && widget.reservations!.isNotEmpty) {
      final seats = widget.reservations!
          .map((r) => r['seat_number']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      if (seats.length > 1) {
        return '${t('payment.seats')} ${seats.join(', ')}';
      } else if (seats.isNotEmpty) {
        return '${t('payment.seat')} ${seats.first}';
      }
    }

    // Priorité 2: Utiliser selectedSeats si disponible
    if (widget.selectedSeats != null && widget.selectedSeats!.isNotEmpty) {
      if (widget.selectedSeats!.length > 1) {
        return '${t('payment.seats')} ${widget.selectedSeats!.join(', ')}';
      } else {
        return '${t('payment.seat')} ${widget.selectedSeats!.first}';
      }
    }

    // Fallback: Utiliser seatNumber si disponible
    if (widget.seatNumber != null) {
      return '${t('payment.seat')} ${widget.seatNumber}';
    }
    return t('payment.seat_not_available');
  }

  @override
  Widget build(BuildContext context) {
    // Si on vient d'un deep link de paiement réussi, afficher l'écran de succès
    if (widget.paymentStatus == 'success') {
      return _buildPaymentSuccessScreen(context);
    }

    // Si on vient d'un deep link d'erreur, afficher l'écran d'erreur
    if (widget.paymentStatus == 'error') {
      return _buildPaymentErrorScreen(context);
    }

    // Si on vient d'un deep link de paiement en attente, afficher l'écran d'attente
    if (widget.paymentStatus == 'pending') {
      return _buildPaymentPendingScreen(context);
    }

    // Sinon, afficher l'écran de paiement normal
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t('payment.title')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé de la réservation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('payment.reservation_summary'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getEmbarkDestination(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _finalAmount > 0
                            ? '${_finalAmount.toStringAsFixed(0)} FCFA'
                            : t('payment.free'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _finalAmount > 0
                              ? AppTheme.primaryOrange
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDepartDateTime(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSeatsDisplay(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${t('payment.expires_at')} ${widget.expiresAt}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Option 1: Points de fidélité
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _useLoyaltyPoints,
                        onChanged: (hasEnoughPoints && !_hasMultipleSeats)
                            ? (value) {
                                setState(() {
                                  _useLoyaltyPoints = value ?? false;
                                  if (_useLoyaltyPoints) {
                                    _selectedPaymentMethod = 'loyalty';
                                    // Désactiver le code promo si on active les points de fidélité
                                    _usePromoCode = false;
                                    _promoCode = '';
                                    _promoCodeValid = false;
                                  }
                                });
                              }
                            : null,
                        activeColor: AppTheme.primaryOrange,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('payment.pay_with_loyalty'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _hasMultipleSeats
                                    ? Colors.grey
                                    : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _hasMultipleSeats
                                ? const Text(
                                    'Uniquement pour un seul siège',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : _isLoadingPoints
                                    ? Text(
                                        t('payment.loading'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : Text(
                                        '${t('payment.you_have_points').replaceAll('{{points}}', '$_clientPoints')} '
                                        '${hasEnoughPoints ? t('payment.free_ticket_with_points') : t('payment.points_required')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: hasEnoughPoints
                                              ? (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.green[400]
                                                  : Colors.green[700])
                                              : (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.orange[400]
                                                  : Colors.orange[700]),
                                        ),
                                      ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.stars,
                        color: hasEnoughPoints ? Colors.amber : Colors.grey,
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Option 2: Code promotionnel (uniquement pour un seul siège)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? (_hasMultipleSeats
                        ? Colors.grey[900]?.withValues(alpha: 0.5)
                        : Colors.grey[900])
                    : (_hasMultipleSeats
                        ? Colors.grey.withValues(alpha: 0.02)
                        : Colors.grey.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? (_hasMultipleSeats
                          ? Colors.grey[700]!.withValues(alpha: 0.5)
                          : Colors.grey[700]!)
                      : (_hasMultipleSeats
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _usePromoCode,
                        onChanged: _hasMultipleSeats
                            ? null
                            : (value) {
                                setState(() {
                                  _usePromoCode = value ?? false;
                                  // Réinitialiser le code si on désactive avec plusieurs sièges
                                  if (!_usePromoCode) {
                                    _promoCode = '';
                                    _promoCodeValid = false;
                                    _promoCodeMessage = null;
                                  }
                                });
                              },
                        activeColor: AppTheme.primaryOrange,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('payment.use_promo_code'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _hasMultipleSeats
                                    ? Colors.grey
                                    : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87),
                              ),
                            ),
                            if (_hasMultipleSeats) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Uniquement pour un seul siège',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.local_offer,
                        color: _hasMultipleSeats
                            ? Colors.grey
                            : AppTheme.primaryOrange,
                        size: 24,
                      ),
                    ],
                  ),
                  if (_hasMultipleSeats && _usePromoCode) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Les codes promotionnels ne peuvent être utilisés que pour un seul siège.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_usePromoCode && !_hasMultipleSeats) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: t('payment.enter_code'),
                              hintStyle: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryOrange,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _promoCode = value;
                                _promoCodeValid = false;
                                _promoCodeMessage = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isVerifyingPromo || _promoCode.isEmpty
                              ? null
                              : _verifyPromoCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isVerifyingPromo || _promoCode.isEmpty
                                    ? Colors.grey
                                    : AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[300],
                            disabledForegroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[600]
                                    : Colors.grey[500],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isVerifyingPromo
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  t('payment.verify'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (_promoCodeMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _promoCodeValid
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.1))
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _promoCodeValid
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.red.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _promoCodeValid
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: _promoCodeValid
                                  ? Colors.green[400]
                                  : Colors.red[400],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _promoCodeMessage!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _promoCodeValid
                                      ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.green[300]
                                          : Colors.green[700])
                                      : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.red[300]
                                          : Colors.red[700]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Option 3: Solde
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? (_useBalance
                        ? AppTheme.primaryOrange.withValues(alpha: 0.15)
                        : Colors.grey[900])
                    : (_useBalance
                        ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _useBalance
                      ? AppTheme.primaryOrange
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey.withValues(alpha: 0.3)),
                  width: _useBalance ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _useBalance,
                    onChanged: (value) {
                      setState(() {
                        _useBalance = value ?? false;
                        if (_useBalance) {
                          _selectedPaymentMethod = 'balance';
                          // Désactiver les autres méthodes
                          _useLoyaltyPoints = false;
                          _usePromoCode = false;
                          _promoCode = '';
                          _promoCodeValid = false;
                          _promoCodeMessage = null;
                        } else if (_selectedPaymentMethod == 'balance') {
                          _selectedPaymentMethod = null;
                        }
                      });
                    },
                    activeColor: AppTheme.primaryOrange,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('payment.pay_with_balance'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLoadingPoints
                              ? t('payment.loading')
                              : hasEnoughBalance
                                  ? t('payment.balance_available').replaceAll(
                                      '{{balance}}',
                                      _clientBalance.toStringAsFixed(0))
                                  : t('payment.insufficient_balance')
                                      .replaceAll('{{balance}}',
                                          _clientBalance.toStringAsFixed(0))
                                      .replaceAll('{{required}}',
                                          _finalAmount.toStringAsFixed(0)),
                          style: TextStyle(
                            fontSize: 12,
                            color: _isLoadingPoints
                                ? Colors.grey
                                : hasEnoughBalance
                                    ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.green[400]
                                        : Colors.green[700])
                                    : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.red[400]
                                        : Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    color: _useBalance
                        ? AppTheme.primaryOrange
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[600]
                            : Colors.grey),
                    size: 24,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Option 4: Wave (seule méthode de paiement disponible)
            _buildPaymentMethodOption(
              icon: Icons.account_balance_wallet,
              imagePath: 'assets/images/wave_icon.png',
              title: 'Wave',
              subtitle: t('payment.wave_payment'),
              value: 'wave',
            ),

            const SizedBox(height: 32),

            // Bouton de paiement
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPaymentMethod == null || _isProcessing
                    ? null
                    : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
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
                        _finalAmount > 0
                            ? t('payment.pay_amount').replaceAll(
                                '{{amount}}', _finalAmount.toStringAsFixed(0))
                            : t('payment.confirm_free'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required IconData icon,
    String? imagePath,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
          // Désactiver les autres méthodes de paiement
          if (value != 'loyalty') {
            _useLoyaltyPoints = false;
          }
          if (value != 'promo') {
            _usePromoCode = false;
            _promoCode = '';
            _promoCodeValid = false;
            _promoCodeMessage = null;
          }
          if (value != 'balance') {
            _useBalance = false;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppTheme.primaryOrange.withValues(alpha: 0.15)
                  : AppTheme.primaryOrange.withValues(alpha: 0.1))
              : (isDark ? Colors.grey[900] : Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryOrange
                : (isDark
                    ? Colors.grey[700]!
                    : Colors.grey.withValues(alpha: 0.3)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? AppTheme.primaryOrange.withValues(alpha: 0.25)
                        : AppTheme.primaryOrange.withValues(alpha: 0.2))
                    : (isDark
                        ? Colors.grey[800]!.withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: imagePath != null
                  ? Image.asset(
                      imagePath,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        // Si l'image n'existe pas, utiliser l'icône par défaut
                        return Icon(
                          icon,
                          color: isSelected
                              ? AppTheme.primaryOrange
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          size: 24,
                        );
                      },
                    )
                  : Icon(
                      icon,
                      color: isSelected
                          ? AppTheme.primaryOrange
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryOrange
                          : (isDark
                              ? Colors.white70
                              : Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryOrange,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    debugPrint('💳 [PaymentScreen] _processPayment appelé');
    debugPrint(
        '💳 [PaymentScreen] _selectedPaymentMethod: $_selectedPaymentMethod');
    debugPrint('💳 [PaymentScreen] _usePromoCode: $_usePromoCode');
    debugPrint('💳 [PaymentScreen] _promoCodeValid: $_promoCodeValid');
    debugPrint('💳 [PaymentScreen] _promoCode: $_promoCode');
    debugPrint('💳 [PaymentScreen] _hasMultipleSeats: $_hasMultipleSeats');

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('payment.select_payment_method')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier que le code promo n'est pas utilisé avec plusieurs sièges
    if (_usePromoCode && _hasMultipleSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Les codes promotionnels ne peuvent être utilisés que pour un seul siège. Veuillez désélectionner le code promo ou ne réserver qu\'un seul siège.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Si paiement avec code promotionnel
    if (_selectedPaymentMethod == 'promo' && _usePromoCode && _promoCodeValid) {
      debugPrint('💳 [PaymentScreen] ✅ Traitement du paiement avec code promo');
      // Vérifier que ce n'est pas pour plusieurs sièges
      if (_hasMultipleSeats) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Les codes promotionnels ne peuvent être utilisés que pour un seul siège.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Vérifier que le code promo est valide
      if (!_promoCodeValid || _promoCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Veuillez vérifier votre code promotionnel avant de continuer.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      try {
        // Confirmer toutes les réservations
        final reservationsToConfirm = widget.reservations ??
            (widget.reservationId != null
                ? [
                    {
                      'reservation_id': widget.reservationId,
                      'seat_number': widget.seatNumber
                    }
                  ]
                : []);

        List<int> confirmedSeats = [];
        List<int> failedSeats = [];

        for (var reservation in reservationsToConfirm) {
          final reservationId = reservation['reservation_id'];

          try {
            // Envoyer le code promo
            String? promoCodeToSend;
            if (_usePromoCode &&
                _promoCodeValid &&
                !_hasMultipleSeats &&
                _promoCode.isNotEmpty &&
                reservationsToConfirm.length == 1) {
              promoCodeToSend = _promoCode;
            }

            debugPrint(
                '💳 [PaymentScreen] Confirmation réservation avec code promo: $promoCodeToSend');
            final confirmResult = await ReservationService.confirmReservation(
                reservationId,
                promoCode: promoCodeToSend,
                useLoyaltyPoints: false);

            debugPrint(
                '💳 [PaymentScreen] Résultat confirmation: ${confirmResult['success']}');
            debugPrint(
                '💳 [PaymentScreen] Message: ${confirmResult['message']}');

            if (confirmResult['success'] == true) {
              confirmedSeats
                  .add(reservation['seat_number'] ?? widget.seatNumber ?? 0);
              debugPrint(
                  '💳 [PaymentScreen] ✅ Réservation confirmée avec succès');
            } else {
              failedSeats
                  .add(reservation['seat_number'] ?? widget.seatNumber ?? 0);
              debugPrint(
                  '💳 [PaymentScreen] ❌ Échec confirmation: ${confirmResult['message']}');
            }

            // Délai entre chaque confirmation pour éviter le rate limit
            if (reservationsToConfirm.indexOf(reservation) <
                reservationsToConfirm.length - 1) {
              await Future.delayed(const Duration(seconds: 1));
            }
          } catch (e) {
            failedSeats
                .add(reservation['seat_number'] ?? widget.seatNumber ?? 0);
          }
        }

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          if (confirmedSeats.isNotEmpty && failedSeats.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('payment.tickets_created')
                    .replaceAll('{{count}}', '${confirmedSeats.length}')
                    .replaceAll('{{seats}}', confirmedSeats.join(", "))),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            // Rediriger vers HomePage puis ouvrir Mes Trajets
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );

                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const MyTripsScreen()),
                    );
                  }
                });
              }
            });
          } else if (confirmedSeats.isNotEmpty && failedSeats.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('payment.some_tickets_created')
                    .replaceAll('{{success}}', '${confirmedSeats.length}')
                    .replaceAll('{{failed}}', '${failedSeats.length}')),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('payment.reservation_failed')),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          final errorMessage = ErrorMessageHelper.getOperationError(
            'envoyer',
            error: e,
            customMessage:
                'Impossible de confirmer le paiement. Veuillez réessayer.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Si paiement avec points de fidélité
    if (_selectedPaymentMethod == 'loyalty' && _useLoyaltyPoints) {
      // Vérifier que ce n'est pas pour plusieurs sièges
      if (_hasMultipleSeats) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Les points de fidélité ne peuvent être utilisés que pour un seul siège.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (!hasEnoughPoints) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('payment.not_enough_points')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      try {
        // Confirmer toutes les réservations
        final reservationsToConfirm = widget.reservations ??
            [
              {'reservation_id': widget.reservationId}
            ];

        List<int> confirmedSeats = [];
        List<int> failedSeats = [];

        // IMPORTANT: Les points de fidélité ne peuvent être utilisés que pour UN SEUL siège
        // Si plusieurs réservations, on ne peut pas utiliser les points de fidélité
        bool canUseLoyaltyPoints = _useLoyaltyPoints &&
            (_clientPoints ?? 0) >= 10 &&
            !_hasMultipleSeats &&
            reservationsToConfirm.length ==
                1; // Seulement si une seule réservation

        for (var reservation in reservationsToConfirm) {
          final reservationId = reservation['reservation_id'];

          try {
            // Envoyer le code promo si valide et un seul siège
            String? promoCodeToSend;
            if (_usePromoCode &&
                _promoCodeValid &&
                !_hasMultipleSeats &&
                _promoCode.isNotEmpty &&
                reservationsToConfirm.length == 1) {
              promoCodeToSend = _promoCode;
            }

            // Envoyer useLoyaltyPoints si le paiement est avec points de fidélité
            // UNIQUEMENT pour un seul siège (comme le code promo)
            bool useLoyaltyPoints = canUseLoyaltyPoints &&
                reservationsToConfirm.indexOf(reservation) ==
                    0; // Seulement pour la première (et unique) réservation

            final confirmResult = await ReservationService.confirmReservation(
                reservationId,
                promoCode: promoCodeToSend,
                useLoyaltyPoints: useLoyaltyPoints);

            if (confirmResult['success'] == true) {
              confirmedSeats
                  .add(reservation['seat_number'] ?? widget.seatNumber ?? 0);
            } else {
              failedSeats
                  .add(reservation['seat_number'] ?? widget.seatNumber ?? 0);
            }

            // Délai entre chaque confirmation pour éviter le rate limit
            if (reservationsToConfirm.indexOf(reservation) <
                reservationsToConfirm.length - 1) {
              await Future.delayed(const Duration(seconds: 1));
            }
          } catch (e) {
            failedSeats
                .add(reservation['seat_number'] ?? widget.seatNumber ?? 0);
          }
        }

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          if (confirmedSeats.isNotEmpty && failedSeats.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('payment.tickets_created')
                    .replaceAll('{{count}}', '${confirmedSeats.length}')
                    .replaceAll('{{seats}}', confirmedSeats.join(", "))),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            // Rediriger vers HomePage puis ouvrir Mes Trajets
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );

                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const MyTripsScreen()),
                    );
                  }
                });
              }
            });
          } else if (confirmedSeats.isNotEmpty && failedSeats.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('payment.some_tickets_created')
                    .replaceAll('{{success}}', '${confirmedSeats.length}')
                    .replaceAll('{{failed}}', '${failedSeats.length}')),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('payment.reservation_failed')),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          final errorMessage = ErrorMessageHelper.getOperationError(
            'envoyer',
            error: e,
            customMessage:
                'Impossible de confirmer le paiement. Veuillez réessayer.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Si paiement avec solde
    if (_selectedPaymentMethod == 'balance' && _useBalance) {
      // Vérifier que le client a assez de solde
      if (_clientBalance < _finalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Solde insuffisant. Votre solde actuel est de ${_clientBalance.toStringAsFixed(0)} FCFA, mais le montant requis est de ${_finalAmount.toStringAsFixed(0)} FCFA.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      try {
        // Confirmer toutes les réservations
        final reservationsToConfirm = widget.reservations ??
            (widget.reservationId != null
                ? [
                    {
                      'reservation_id': widget.reservationId,
                      'seat_number': widget.seatNumber
                    }
                  ]
                : []);

        List<int> confirmedSeats = [];
        List<int> failedSeats = [];

        for (var reservation in reservationsToConfirm) {
          final reservationId = reservation['reservation_id'];

          try {
            // Envoyer useBalance pour payer avec le solde
            final confirmResult = await ReservationService.confirmReservation(
                reservationId,
                promoCode: null,
                useLoyaltyPoints: false,
                useBalance: true);

            debugPrint(
                '💳 [PaymentScreen] Résultat confirmation avec solde: ${confirmResult['success']}');
            debugPrint(
                '💳 [PaymentScreen] Message: ${confirmResult['message']}');

            if (confirmResult['success'] == true) {
              confirmedSeats
                  .add(reservation['seat_number'] ?? widget.seatNumber ?? 0);
              debugPrint(
                  '💳 [PaymentScreen] ✅ Réservation confirmée avec succès (paiement par solde)');
            } else {
              failedSeats
                  .add(reservation['seat_number'] ?? widget.seatNumber ?? 0);
              debugPrint(
                  '💳 [PaymentScreen] ❌ Échec confirmation: ${confirmResult['message']}');
            }

            // Délai entre chaque confirmation pour éviter le rate limit
            if (reservationsToConfirm.indexOf(reservation) <
                reservationsToConfirm.length - 1) {
              await Future.delayed(const Duration(seconds: 1));
            }
          } catch (e) {
            failedSeats
                .add(reservation['seat_number'] ?? widget.seatNumber ?? 0);
            debugPrint('💳 [PaymentScreen] ❌ Exception: $e');
          }
        }

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          if (confirmedSeats.isNotEmpty && failedSeats.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('payment.tickets_created')
                    .replaceAll('{{count}}', '${confirmedSeats.length}')
                    .replaceAll('{{seats}}', confirmedSeats.join(", "))),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            // Rediriger vers HomePage puis ouvrir Mes Trajets
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );

                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const MyTripsScreen()),
                    );
                  }
                });
              }
            });
          } else if (confirmedSeats.isNotEmpty && failedSeats.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('payment.some_tickets_created')
                    .replaceAll('{{success}}', '${confirmedSeats.length}')
                    .replaceAll('{{failed}}', '${failedSeats.length}')),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('payment.reservation_failed')),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          final errorMessage = ErrorMessageHelper.getOperationError(
            'envoyer',
            error: e,
            customMessage:
                'Impossible de confirmer le paiement. Veuillez réessayer.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Si paiement Wave
    if (_selectedPaymentMethod == 'wave') {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Traiter chaque réservation séparément
        final reservationsToPay = widget.reservations ??
            (widget.reservationId != null && widget.seatNumber != null
                ? [
                    {
                      'reservation_id': widget.reservationId,
                      'seat_number': widget.seatNumber
                    }
                  ]
                : []);

        // Vérifier qu'on a au moins une réservation à payer
        if (reservationsToPay.isEmpty) {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Aucune réservation à payer. Veuillez réessayer.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // IMPORTANT: Calculer le montant de la première réservation uniquement
        // Ne pas envoyer le montant total de toutes les réservations
        // Chaque réservation doit être payée individuellement pour éviter les bugs
        final firstReservation = reservationsToPay[0];
        final firstReservationId = firstReservation['reservation_id'];

        if (firstReservationId == null) {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Erreur: ID de réservation manquant. Veuillez réessayer.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Calculer le montant de la première réservation uniquement
        double firstReservationAmount = 0.0;
        if (firstReservation['amount'] != null) {
          final amountValue = firstReservation['amount'];
          if (amountValue is num) {
            firstReservationAmount = amountValue.toDouble();
          } else if (amountValue is String) {
            firstReservationAmount = double.tryParse(amountValue) ?? 0.0;
          }
        }

        // Si le montant n'est pas défini, utiliser le prix du départ
        if (firstReservationAmount == 0.0 &&
            widget.depart != null &&
            widget.depart!.isNotEmpty) {
          final priceValue =
              widget.depart!['prix'] ?? widget.depart!['prix_depart'] ?? 0.0;
          if (priceValue is num) {
            firstReservationAmount = priceValue.toDouble();
          } else if (priceValue is String) {
            firstReservationAmount = double.tryParse(priceValue) ?? 0.0;
          }
        }

        // Appliquer code promo ou points de fidélité si applicable
        if (_usePromoCode && _promoCodeValid && !_hasMultipleSeats) {
          firstReservationAmount = 0.0; // Ticket gratuit avec code promo
        } else if (_useLoyaltyPoints && (_clientPoints ?? 0) >= 10) {
          firstReservationAmount = 0.0; // Ticket gratuit avec points
        }

        try {
          // Calculer le montant total de toutes les réservations
          final totalAmountToPay = _finalAmount;

          debugPrint(
              '💳 [PaymentScreen] Initiation paiement Wave pour réservation $firstReservationId');
          debugPrint(
              '💳 [PaymentScreen] Montant total: $totalAmountToPay FCFA');
          debugPrint(
              '💳 [PaymentScreen] Nombre de réservations: ${reservationsToPay.length}');
          if (widget.paymentGroupId != null) {
            debugPrint(
                '💳 [PaymentScreen] Payment Group ID: ${widget.paymentGroupId}');
          }

          // IMPORTANT: Ajouter un délai de 2 secondes avant d'initier le paiement Wave
          // pour éviter le rate limiting juste après la création des réservations
          debugPrint(
              '⏳ [PaymentScreen] Attente de 2 secondes avant d\'initier le paiement Wave...');
          await Future.delayed(const Duration(seconds: 2));

          // Initier le paiement Wave avec le montant total et le payment_group_id
          // Cela permettra de payer toutes les réservations du groupe en une seule fois
          // Avec retry automatique en cas de rate limiting (max 3 tentatives)
          final paymentResult = await ReservationService.initiateWavePayment(
            firstReservationId,
            totalAmount: totalAmountToPay > 0 ? totalAmountToPay : null,
            paymentGroupId: widget.paymentGroupId,
            maxRetries: 3, // 3 tentatives avec backoff exponentiel
          );

          if (paymentResult['success'] == true &&
              paymentResult['data'] != null) {
            final paymentUrl = paymentResult['data']['payment_url'];

            if (paymentUrl != null && paymentUrl.isNotEmpty) {
              // Ouvrir l'URL de paiement Wave
              final uri = Uri.parse(paymentUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);

                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                  });

                  // Afficher un message de succès
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        reservationsToPay.length > 1
                            ? '✅ Paiement Wave initié pour ${reservationsToPay.length} siège(s) (${totalAmountToPay.toStringAsFixed(0)} FCFA). Veuillez compléter le paiement sur Wave.'
                            : '✅ Paiement Wave initié (${totalAmountToPay.toStringAsFixed(0)} FCFA). Veuillez compléter le paiement sur Wave.',
                      ),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } else {
                throw Exception(
                    'Impossible d\'ouvrir la page de paiement Wave');
              }
            } else {
              throw Exception('URL de paiement Wave non reçue');
            }
          } else {
            // Afficher le message d'erreur détaillé
            final errorMsg = paymentResult['message'] ??
                paymentResult['error'] ??
                'Erreur inconnue';
            debugPrint(
                '❌ Paiement Wave échoué pour réservation $firstReservationId: $errorMsg');
            debugPrint('❌ Détails complets: ${paymentResult['details']}');

            if (mounted) {
              setState(() {
                _isProcessing = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Erreur: $errorMsg'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Exception lors de l\'initiation du paiement Wave: $e');
          debugPrint('❌ Stack trace: $stackTrace');

          if (mounted) {
            setState(() {
              _isProcessing = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Erreur: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          final errorMessage = ErrorMessageHelper.getOperationError(
            'initier le paiement',
            error: e,
            customMessage:
                'Impossible d\'initier le paiement Wave. Veuillez réessayer.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Écran de succès après paiement réussi (depuis deep link)
  Widget _buildPaymentSuccessScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Paiement réussi'),
        elevation: 0,
        automaticallyImplyLeading: false, // Pas de bouton retour
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icône de succès
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),

              // Titre
              Text(
                '✅ Paiement réussi !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                widget.paymentMessage ??
                    'Votre réservation a été confirmée avec succès. Vous recevrez une notification avec les détails de votre ticket.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Informations de la réservation (si disponibles)
              if (widget.depart != null && widget.depart!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getEmbarkDestination(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getDepartDateTime(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getSeatsDisplay(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 48),

              // Bouton pour aller aux trajets
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Naviguer vers la page des trajets et fermer toutes les pages précédentes
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomePage(
                            initialTabIndex: 1), // Onglet "Mes Trajets"
                      ),
                      (route) =>
                          route.isFirst, // Garder seulement la page d'accueil
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Voir mes trajets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton pour retourner à l'accueil
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Retourner à l'accueil
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  child: Text(
                    'Retour à l\'accueil',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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

  /// Écran d'erreur après paiement échoué (depuis deep link)
  Widget _buildPaymentErrorScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Erreur de paiement'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icône d'erreur
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),

              // Titre
              Text(
                '❌ Erreur de paiement',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                widget.paymentMessage ??
                    'Une erreur est survenue lors du paiement. Veuillez réessayer.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Bouton pour retourner à l'accueil
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  /// Écran d'attente après paiement en cours (depuis deep link)
  Widget _buildPaymentPendingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Paiement en cours'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icône d'attente
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  color: Colors.orange,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),

              // Titre
              Text(
                '⏳ Paiement en cours de traitement',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                widget.paymentMessage ??
                    'Votre paiement est en cours de traitement. Vous recevrez une notification une fois confirmé.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Bouton pour retourner à l'accueil
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
