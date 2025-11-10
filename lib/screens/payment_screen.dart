import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/reservation_service.dart';
import '../services/translation_service.dart';
import '../utils/error_message_helper.dart';
import 'home_page.dart';
import 'my_trips_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int reservationId;
  final String sessionId;
  final double amount;
  final Map<String, dynamic> depart;
  final int seatNumber;
  final List<int>? selectedSeats;
  final String expiresAt;
  final int countdownSeconds;
  final List<Map<String, dynamic>>?
      reservations; // Liste de toutes les réservations à confirmer

  const PaymentScreen({
    super.key,
    required this.reservationId,
    required this.sessionId,
    required this.amount,
    required this.depart,
    required this.seatNumber,
    this.selectedSeats,
    required this.expiresAt,
    required this.countdownSeconds,
    this.reservations, // Liste optionnelle de toutes les réservations
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
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
    _loadClientPoints();
    
    // Désactiver le code promo si plusieurs sièges sont sélectionnés au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasMultipleSeats && _usePromoCode) {
        setState(() {
          _usePromoCode = false;
          _promoCode = '';
          _promoCodeValid = false;
          _promoCodeMessage = null;
        });
      }
    });
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

        setState(() {
          _clientPoints = client['points'] ?? 0;
          _clientBalance = balance;
          _isLoadingPoints = false;
        });
      } else {
        setState(() {
          _clientPoints = 0;
          _clientBalance = 0.0;
          _isLoadingPoints = false;
        });
      }
    } catch (e) {
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
        _promoCodeMessage = 'Les codes promotionnels ne peuvent être utilisés que pour un seul siège.';
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
      } else if (widget.selectedSeats != null && widget.selectedSeats!.length > 1) {
        reservationCount = widget.selectedSeats!.length;
      }
      
      final result = await ReservationService.verifyPromoCode(_promoCode, reservationCount: reservationCount);
      setState(() {
        _isVerifyingPromo = false;
        if (result['success'] == true) {
          // Vérifier à nouveau si plusieurs sièges (au cas où l'utilisateur aurait ajouté des sièges pendant la vérification)
          if (_hasMultipleSeats) {
            _promoCodeValid = false;
            _promoCodeMessage = 'Les codes promotionnels ne peuvent être utilisés que pour un seul siège.';
          } else {
            _promoCodeValid = true;
            _promoCodeMessage = result['message'] ?? t('payment.code_valid');
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
    double total = widget.amount;

    // Si plusieurs sièges sont sélectionnés, le code promo ne peut pas être utilisé
    if (_hasMultipleSeats) {
      // Si code promo est activé avec plusieurs sièges, ignorer le code promo
      if (_usePromoCode) {
        return total; // Ne pas appliquer de réduction
      }
    }

    // Si paiement avec points de fidélité (10 points = ticket gratuit)
    if (_useLoyaltyPoints && (_clientPoints ?? 0) >= 10) {
      return 0.0; // Ticket gratuit
    }

    // Si code promo valide et un seul siège, appliquer la réduction (pour l'instant 0 car pas de discount défini dans l'API)
    if (_usePromoCode && _promoCodeValid && !_hasMultipleSeats) {
      // TODO: Appliquer la réduction du code promo
      // total = total * (1 - discount);
      return 0.0; // Ticket gratuit avec code promo (pour l'instant)
    }

    return total;
  }

  String _getEmbarkDestination() {
    if (widget.depart.containsKey('trajet')) {
      final trajet = widget.depart['trajet'];
      if (trajet is Map) {
        return '${trajet['embarquement'] ?? ''} → ${trajet['destination'] ?? ''}';
      }
    }
    if (widget.depart.containsKey('embarquement') &&
        widget.depart.containsKey('destination')) {
      return '${widget.depart['embarquement']} → ${widget.depart['destination']}';
    }
    return t('payment.trip_not_available');
  }

  String _getDepartDateTime() {
    final date = widget.depart['date_depart'] ?? widget.depart['date'] ?? '';
    final heure = widget.depart['heure_depart'] ?? widget.depart['heure'] ?? '';
    if (date.isNotEmpty && heure.isNotEmpty) {
      return '${t('payment.date_prefix')} $date à $heure';
    }
    return t('payment.date_not_available');
  }

  @override
  Widget build(BuildContext context) {
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
                    widget.selectedSeats != null &&
                            widget.selectedSeats!.length > 1
                        ? '${t('payment.seats')} ${widget.selectedSeats!.join(', ')}'
                        : '${t('payment.seat')} ${widget.seatNumber}',
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
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _useLoyaltyPoints,
                        onChanged: hasEnoughPoints
                            ? (value) {
                                setState(() {
                                  _useLoyaltyPoints = value ?? false;
                                  if (_useLoyaltyPoints) {
                                    _selectedPaymentMethod = 'loyalty';
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isLoadingPoints
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
                                          ? Colors.green
                                          : Colors.orange,
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
                color: _hasMultipleSeats 
                    ? Colors.grey.withValues(alpha: 0.02)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasMultipleSeats
                      ? Colors.grey.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _usePromoCode,
                        onChanged: _hasMultipleSeats ? null : (value) {
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
                                    : null,
                              ),
                            ),
                            if (_hasMultipleSeats) ...[
                              const SizedBox(height: 4),
                              Text(
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
                            decoration: InputDecoration(
                              hintText: t('payment.enter_code'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
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
                          onPressed:
                              _isVerifyingPromo ? null : _verifyPromoCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
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
                              : Text(t('payment.verify')),
                        ),
                      ],
                    ),
                    if (_promoCodeMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _promoCodeValid
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _promoCodeValid
                                  ? Icons.check_circle
                                  : Icons.error,
                              color:
                                  _promoCodeValid ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _promoCodeMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _promoCodeValid
                                      ? Colors.green
                                      : Colors.red,
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
                color: _useBalance
                    ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _useBalance
                      ? AppTheme.primaryOrange
                      : Colors.grey.withValues(alpha: 0.3),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    color: _useBalance ? AppTheme.primaryOrange : Colors.grey,
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

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
          if (value != 'loyalty') {
            _useLoyaltyPoints = false;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryOrange.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryOrange
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryOrange.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
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
                              : Colors.grey[600],
                          size: 24,
                        );
                      },
                    )
                  : Icon(
                      icon,
                      color: isSelected
                          ? AppTheme.primaryOrange
                          : Colors.grey[600],
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
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
        SnackBar(
          content: const Text('Les codes promotionnels ne peuvent être utilisés que pour un seul siège. Veuillez désélectionner le code promo ou ne réserver qu\'un seul siège.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Si paiement avec points de fidélité
    if (_selectedPaymentMethod == 'loyalty' && _useLoyaltyPoints) {
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

        for (var reservation in reservationsToConfirm) {
          final reservationId = reservation['reservation_id'];

          try {
            final confirmResult =
                await ReservationService.confirmReservation(reservationId);

            if (confirmResult['success'] == true) {
              confirmedSeats
                  .add(reservation['seat_number'] ?? widget.seatNumber);
            } else {
              failedSeats.add(reservation['seat_number'] ?? widget.seatNumber);
            }

            // Délai entre chaque confirmation pour éviter le rate limit
            if (reservationsToConfirm.indexOf(reservation) <
                reservationsToConfirm.length - 1) {
              await Future.delayed(const Duration(seconds: 1));
            }
          } catch (e) {
            failedSeats.add(reservation['seat_number'] ?? widget.seatNumber);
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

    // Si paiement Wave
    if (_selectedPaymentMethod == 'wave') {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Traiter chaque réservation séparément
        final reservationsToPay = widget.reservations ??
            [
              {
                'reservation_id': widget.reservationId,
                'seat_number': widget.seatNumber
              }
            ];

        List<int> initiatedPayments = [];
        List<int> failedPayments = [];

        for (var reservation in reservationsToPay) {
          final reservationId = reservation['reservation_id'];

          try {
            // Initier le paiement Wave pour cette réservation
            final paymentResult =
                await ReservationService.initiateWavePayment(reservationId);

            if (paymentResult['success'] == true &&
                paymentResult['data'] != null) {
              final paymentUrl = paymentResult['data']['payment_url'];

              if (paymentUrl != null && paymentUrl.isNotEmpty) {
                initiatedPayments
                    .add(reservation['seat_number'] ?? widget.seatNumber);

                // Ouvrir l'URL de paiement Wave
                final uri = Uri.parse(paymentUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw Exception(
                      'Impossible d\'ouvrir la page de paiement Wave');
                }
              } else {
                failedPayments
                    .add(reservation['seat_number'] ?? widget.seatNumber);
              }
            } else {
              failedPayments
                  .add(reservation['seat_number'] ?? widget.seatNumber);
              // Afficher le message d'erreur détaillé
              final errorMsg = paymentResult['message'] ?? paymentResult['error'] ?? 'Erreur inconnue';
              debugPrint('❌ Paiement Wave échoué pour réservation $reservationId: $errorMsg');
              debugPrint('❌ Détails complets: ${paymentResult['details']}');
            }

            // Délai entre chaque paiement pour éviter le rate limit
            if (reservationsToPay.indexOf(reservation) <
                reservationsToPay.length - 1) {
              await Future.delayed(const Duration(seconds: 1));
            }
          } catch (e, stackTrace) {
            failedPayments.add(reservation['seat_number'] ?? widget.seatNumber);
            debugPrint('❌ Exception lors de l\'initiation du paiement Wave: $e');
            debugPrint('❌ Stack trace: $stackTrace');
          }
        }

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          if (initiatedPayments.isNotEmpty && failedPayments.isEmpty) {
            // Tous les paiements ont été initiés avec succès
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ Paiement Wave initié pour ${initiatedPayments.length} siège(s): ${initiatedPayments.join(", ")}. Veuillez compléter le paiement sur Wave.'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 5),
              ),
            );
            
            // Ne pas rediriger immédiatement - l'utilisateur doit compléter le paiement
            // Le webhook Wave confirmera la réservation après paiement réussi
            // L'utilisateur reviendra à l'app après le paiement via le callback URL
          } else if (initiatedPayments.isNotEmpty &&
              failedPayments.isNotEmpty) {
            // Certains paiements ont réussi, d'autres ont échoué
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '⚠️ Paiement initié pour ${initiatedPayments.length} siège(s), mais ${failedPayments.length} ont échoué. Veuillez réessayer pour les sièges: ${failedPayments.join(", ")}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            // Tous les paiements ont échoué - réessayer pour obtenir le message d'erreur
            String errorMessage = 'Impossible d\'initier le paiement Wave. Veuillez réessayer.';
            try {
              final testResult = await ReservationService.initiateWavePayment(widget.reservationId);
              if (testResult['message'] != null) {
                errorMessage = testResult['message'];
              } else if (testResult['error'] != null) {
                errorMessage = testResult['error'];
              }
            } catch (_) {
              // Ignorer si l'appel échoue
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ $errorMessage'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 7),
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
}
