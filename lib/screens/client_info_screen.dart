import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/reservation_service.dart';
import '../providers/auth_provider.dart';

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

  Future<void> _handleReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_telephoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le numéro de téléphone est requis (points de fidélité)'),
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
        final searchResult = await ReservationService.searchOrCreateClientProfile(
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
              const SnackBar(
                content: Text('Client non trouvé. Veuillez créer un profil d\'abord.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      // Créer une réservation pour CHAQUE siège sélectionné
      List<int> reservedSeats = [];
      List<int> failedSeats = [];
      
      // Afficher un indicateur de chargement pour les réservations multiples
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Réservation de ${widget.selectedSeats.length} siège(s)...',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      }
      
      // Boucle pour réserver chaque siège
      for (int seatNumber in widget.selectedSeats) {
        final result = await ReservationService.createReservation(
          departId: widget.depart['id'],
          seatNumber: seatNumber,
          clientProfileId: clientProfileId!,
          stopEmbarkId: widget.stopEmbarkId,
          stopDisembarkId: widget.stopDisembarkId,
        );
        
        if (result['success'] == true) {
          final reservationData = result['data'];
          final reservationId = reservationData?['reservation_id'];
          
          if (reservationId != null) {
            // Confirmer la réservation immédiatement (mode test)
            final confirmResult = await ReservationService.confirmReservation(reservationId);
            
            if (confirmResult['success'] == true) {
              reservedSeats.add(seatNumber);
            } else {
              failedSeats.add(seatNumber);
            }
          } else {
            failedSeats.add(seatNumber);
          }
        } else {
          failedSeats.add(seatNumber);
        }
      }
      
      // Fermer le loading
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isReserving = false;
        });
      }
      
      // Afficher le résultat
      if (mounted && !_isDisposed) {
        if (reservedSeats.isNotEmpty) {
          // Au moins un siège réservé avec succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${reservedSeats.length} ticket(s) créé(s) avec succès!\n'
                '🎫 Siège(s): ${reservedSeats.join(', ')}'
                '${failedSeats.isNotEmpty ? '\n❌ Échec pour siège(s): ${failedSeats.join(', ')}' : ''}'
              ),
              backgroundColor: failedSeats.isEmpty ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
          
          // Retourner à l'écran précédent après un délai
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_isDisposed) {
              Navigator.pop(context);
            }
          });
        } else {
          // Toutes les réservations ont échoué
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ Échec de la réservation\n'
                'Aucun siège n\'a pu être réservé.\n'
                'Sièges: ${failedSeats.join(', ')}'
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
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
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations client'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
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
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Siège${widget.selectedSeats.length > 1 ? 's' : ''} sélectionné${widget.selectedSeats.length > 1 ? 's' : ''}: ${widget.selectedSeats.join(', ')}',
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
                  labelText: 'Nom complet',
                  prefixIcon: const Icon(Icons.person, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _telephoneController,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone *',
                  hintText: 'Les points de fidélité seront attribués à ce numéro',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le numéro de téléphone est requis';
                  }
                  if (value.length < 8) {
                    return 'Numéro invalide';
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
                        'Les points de fidélité seront attribués au numéro de téléphone spécifié',
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
                    backgroundColor: AppTheme.primaryBlue,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Valider',
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
                  child: const Text(
                    'Annuler',
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

