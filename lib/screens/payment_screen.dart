import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/reservation_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int reservationId;
  final String sessionId;
  final double amount;
  final Map<String, dynamic> depart;
  final int seatNumber;
  final List<int>? selectedSeats;
  final String expiresAt;
  final int countdownSeconds;

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
  bool _useBalance = false; // Pour le solde (design seulement)

  // Getter pour vérifier si le client a assez de points
  bool get hasEnoughPoints => (_clientPoints ?? 0) >= 10;

  @override
  void initState() {
    super.initState();
    _loadClientPoints();
  }

  Future<void> _loadClientPoints() async {
    try {
      final profileResult = await ReservationService.getMyProfile();
      if (profileResult['success'] == true && profileResult['client'] != null) {
        final client = profileResult['client'];
        setState(() {
          _clientPoints = client['points'] ?? 0;
          _isLoadingPoints = false;
        });
      } else {
        setState(() {
          _clientPoints = 0;
          _isLoadingPoints = false;
        });
      }
    } catch (e) {
      setState(() {
        _clientPoints = 0;
        _isLoadingPoints = false;
      });
    }
  }

  Future<void> _verifyPromoCode() async {
    if (_promoCode.isEmpty) {
      setState(() {
        _promoCodeMessage = 'Veuillez entrer un code';
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
      final result = await ReservationService.verifyPromoCode(_promoCode);
      setState(() {
        _isVerifyingPromo = false;
        if (result['success'] == true) {
          _promoCodeValid = true;
          _promoCodeMessage = result['message'] ?? 'Code valide';
        } else {
          _promoCodeValid = false;
          _promoCodeMessage = result['message'] ?? 'Code invalide';
        }
      });
    } catch (e) {
      setState(() {
        _isVerifyingPromo = false;
        _promoCodeValid = false;
        _promoCodeMessage = 'Erreur lors de la vérification';
      });
    }
  }

  double get _finalAmount {
    double total = widget.amount;
    
    // Si paiement avec points de fidélité (10 points = ticket gratuit)
    if (_useLoyaltyPoints && (_clientPoints ?? 0) >= 10) {
      return 0.0; // Ticket gratuit
    }
    
    // Si code promo valide, appliquer la réduction (pour l'instant 0 car pas de discount défini dans l'API)
    if (_usePromoCode && _promoCodeValid) {
      // TODO: Appliquer la réduction du code promo
      // total = total * (1 - discount);
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
    if (widget.depart.containsKey('embarquement') && widget.depart.containsKey('destination')) {
      return '${widget.depart['embarquement']} → ${widget.depart['destination']}';
    }
    return 'Trajet non disponible';
  }

  String _getDepartDateTime() {
    final date = widget.depart['date_depart'] ?? widget.depart['date'] ?? '';
    final heure = widget.depart['heure_depart'] ?? widget.depart['heure'] ?? '';
    if (date.isNotEmpty && heure.isNotEmpty) {
      return 'Date: $date à $heure';
    }
    return 'Date: Non disponible';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
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
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résumé de votre réservation',
                    style: TextStyle(
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
                        _finalAmount > 0 ? '${_finalAmount.toStringAsFixed(0)} FCFA' : 'GRATUIT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _finalAmount > 0 ? AppTheme.primaryOrange : Colors.green,
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
                    widget.selectedSeats != null && widget.selectedSeats!.length > 1
                        ? 'Sièges: ${widget.selectedSeats!.join(', ')}'
                        : 'Siège: ${widget.seatNumber}',
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
                        const Icon(Icons.access_time, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Expire le: ${widget.expiresAt}',
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
                        activeColor: AppTheme.primaryBlue,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payer avec mes points de fidélité',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isLoadingPoints
                                ? const Text(
                                    'Chargement...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Text(
                                    'Vous avez $_clientPoints point${_clientPoints != 1 ? 's' : ''}. '
                                    '${hasEnoughPoints ? '10 points = Ticket gratuit' : '10 points requis pour un ticket gratuit'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: hasEnoughPoints ? Colors.green : Colors.orange,
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

            // Option 2: Code promotionnel
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
                        value: _usePromoCode,
                        onChanged: (value) {
                          setState(() {
                            _usePromoCode = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryBlue,
                      ),
                      const Expanded(
                        child: Text(
                          'Utiliser un code promotionnel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.local_offer,
                        color: AppTheme.primaryOrange,
                        size: 24,
                      ),
                    ],
                  ),
                  if (_usePromoCode) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Entrez le code',
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
                          onPressed: _isVerifyingPromo ? null : _verifyPromoCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: _isVerifyingPromo
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Vérifier'),
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
                              _promoCodeValid ? Icons.check_circle : Icons.error,
                              color: _promoCodeValid ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _promoCodeMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _promoCodeValid ? Colors.green : Colors.red,
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

            // Option 3: Solde (design seulement)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _useBalance,
                    onChanged: null, // Désactivé pour l'instant
                    activeColor: AppTheme.primaryBlue,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payer avec mon solde',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Disponible prochainement',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.grey,
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
              subtitle: 'Paiement mobile via Wave',
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
                  backgroundColor: AppTheme.primaryBlue,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _finalAmount > 0
                            ? 'Payer ${_finalAmount.toStringAsFixed(0)} FCFA'
                            : 'Confirmer (Gratuit)',
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
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
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
                    ? AppTheme.primaryBlue.withValues(alpha: 0.2)
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
                          color: isSelected ? AppTheme.primaryBlue : Colors.grey[600],
                          size: 24,
                        );
                      },
                    )
                  : Icon(
                      icon,
                      color: isSelected ? AppTheme.primaryBlue : Colors.grey[600],
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
                          ? AppTheme.primaryBlue
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
                color: AppTheme.primaryBlue,
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
        const SnackBar(
          content: Text('Veuillez sélectionner un mode de paiement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Si paiement avec points de fidélité
    if (_selectedPaymentMethod == 'loyalty' && _useLoyaltyPoints) {
      if (!hasEnoughPoints) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous n\'avez pas assez de points (10 points requis)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      try {
        // Confirmer la réservation directement (les points seront déduits côté backend)
        final confirmResult = await ReservationService.confirmReservation(widget.reservationId);

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          if (confirmResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Ticket créé avec vos points de fidélité!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(confirmResult['message'] ?? 'Erreur lors du paiement'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
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
        // TODO: Implémenter l'intégration avec l'API Wave
        // Pour l'instant, on simule juste le processus
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          // Confirmer la réservation après paiement (simulation)
          final confirmResult = await ReservationService.confirmReservation(widget.reservationId);

          if (confirmResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Paiement réussi! Ticket créé.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(confirmResult['message'] ?? 'Erreur lors du paiement'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
