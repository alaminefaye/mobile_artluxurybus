import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/reservation_service.dart';
import '../services/translation_service.dart';
import '../utils/error_message_helper.dart';
import 'client_info_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> depart;

  const SeatSelectionScreen({
    super.key,
    required this.depart,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<int> _availableSeats = [];
  List<int> _pendingReservationSeats = []; // Sièges en cours de réservation en ligne (bloqués 5 min)
  List<int> _occupiedSeats = []; // Sièges vendus au guichet
  List<int> _selectedSeats = []; // Permettre plusieurs sièges (max 5)
  bool _isLoading = true;
  DateTime? _lastSeatsRefresh;
  bool _isDisposed = false;

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  // Pour les arrêts (si le départ a des segments)
  bool _hasSegments = false;
  List<Map<String, dynamic>> _stops = [];
  int? _selectedStopEmbark;
  int? _selectedStopDisembark;

  @override
  void initState() {
    super.initState();
    _loadAvailableSeats();
    // Rafraîchir les sièges toutes les 10 secondes
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 10), () {
      if (!_isDisposed && mounted) {
        _loadAvailableSeats(silent: true);
        _startPeriodicRefresh();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadAvailableSeats({bool silent = false}) async {
    if (_isDisposed || !mounted) return;

    // Si le départ a des arrêts, vérifier qu'ils sont sélectionnés
    if (_hasSegments &&
        (_selectedStopEmbark == null || _selectedStopDisembark == null)) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('seats.select_stops')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!silent) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
    }

    try {
      final result = await ReservationService.getAvailableSeats(
        widget.depart['id'],
        stopEmbarkId: _selectedStopEmbark,
        stopDisembarkId: _selectedStopDisembark,
      );

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final newAvailableSeats = List<int>.from(data['available_seats'] ?? []);
        final newPendingReservationSeats = List<int>.from(data['pending_reservation_seats'] ?? []); // Sièges en cours de réservation en ligne (bloqués 5 min)
        final newOccupiedSeats = List<int>.from(data['occupied_seats'] ?? []); // Sièges vendus au guichet

        // Vérifier si le départ a des segments
        final hasSegments = data['has_segments'] == true;
        final stopsData = data['stops'];
        final stops = stopsData != null
            ? (stopsData as List)
                .map((s) => Map<String, dynamic>.from(s))
                .toList()
            : <Map<String, dynamic>>[];

        if (mounted && !_isDisposed) {
          setState(() {
            // IMPORTANT: Conserver les sièges sélectionnés dans availableSeats s'ils ne sont pas occupés ni réservés par d'autres
            // Cela évite que les sièges sélectionnés disparaissent lors du rafraîchissement
            final seatsToKeep = _selectedSeats.where((seat) => 
              !newOccupiedSeats.contains(seat) && !newPendingReservationSeats.contains(seat) // Si le siège n'est ni occupé ni réservé par un autre utilisateur
            ).toList();
            
            // Ajouter les sièges sélectionnés à la liste des disponibles si ils n'y sont pas déjà
            final updatedAvailableSeats = List<int>.from(newAvailableSeats);
            for (var seat in seatsToKeep) {
              if (!updatedAvailableSeats.contains(seat)) {
                updatedAvailableSeats.add(seat);
                debugPrint('🔄 [SeatSelection] Siège $seat conservé dans availableSeats (sélectionné par l\'utilisateur)');
              }
            }
            updatedAvailableSeats.sort();
            
            _availableSeats = updatedAvailableSeats;
            _pendingReservationSeats = newPendingReservationSeats; // Sièges en cours de réservation en ligne (bloqués 5 min)
            _occupiedSeats = newOccupiedSeats; // Sièges vendus au guichet
            _lastSeatsRefresh = DateTime.now();
            _isLoading = false;

            // Mettre à jour les arrêts si disponibles
            if (hasSegments && stops.isNotEmpty && !_hasSegments) {
              _hasSegments = true;
              _stops = stops;

              // Pré-sélectionner les arrêts en fonction de l'embarquement et destination du départ
              final departEmbarquement = widget.depart['trajet']
                          ?['embarquement']
                      ?.toString()
                      .toLowerCase() ??
                  '';
              final departDestination = widget.depart['trajet']?['destination']
                      ?.toString()
                      .toLowerCase() ??
                  '';

              int? foundEmbarkStop;
              int? foundDisembarkStop;

              for (var stop in _stops) {
                final stopName = (stop['name'] ?? '').toString().toLowerCase();

                // Chercher l'arrêt correspondant à l'embarquement (recherche plus précise)
                if (foundEmbarkStop == null) {
                  if (stopName == departEmbarquement ||
                      stopName.contains(departEmbarquement) ||
                      departEmbarquement.contains(stopName)) {
                    foundEmbarkStop = stop['id'];
                  }
                }

                // Chercher l'arrêt correspondant à la destination (recherche plus précise)
                if (foundDisembarkStop == null) {
                  if (stopName == departDestination ||
                      stopName.contains(departDestination) ||
                      departDestination.contains(stopName)) {
                    foundDisembarkStop = stop['id'];
                  }
                }
              }

              // Si on a trouvé les arrêts, les pré-sélectionner
              if (foundEmbarkStop != null) {
                _selectedStopEmbark = foundEmbarkStop;
              } else if (_stops.isNotEmpty) {
                _selectedStopEmbark =
                    _stops.first['id']; // Sinon prendre le premier
              }

              if (foundDisembarkStop != null) {
                _selectedStopDisembark = foundDisembarkStop;
              } else if (_stops.isNotEmpty) {
                _selectedStopDisembark =
                    _stops.last['id']; // Sinon prendre le dernier
              }

              // S'assurer que l'embarquement est avant le débarquement
              if (_selectedStopEmbark != null &&
                  _selectedStopDisembark != null) {
                final embarkIndex =
                    _stops.indexWhere((s) => s['id'] == _selectedStopEmbark);
                final disembarkIndex =
                    _stops.indexWhere((s) => s['id'] == _selectedStopDisembark);
                if (embarkIndex >= 0 &&
                    disembarkIndex >= 0 &&
                    embarkIndex >= disembarkIndex) {
                  // Si l'embarquement est après le débarquement, prendre le suivant comme débarquement
                  if (disembarkIndex < _stops.length - 1) {
                    _selectedStopDisembark = _stops[disembarkIndex + 1]['id'];
                  } else {
                    _selectedStopDisembark = _stops.last['id'];
                  }
                }
              }
            }

            // Si on vient de détecter les arrêts et qu'ils sont pré-sélectionnés, recharger les sièges automatiquement
            if (_hasSegments &&
                _selectedStopEmbark != null &&
                _selectedStopDisembark != null) {
              // Recharger avec les arrêts pré-sélectionnés
              Future.microtask(() {
                if (mounted && !_isDisposed) {
                  _loadAvailableSeats(silent: true);
                }
              });
            }

            // IMPORTANT: Ne retirer les sièges sélectionnés QUE s'ils sont vraiment occupés ou réservés par D'AUTRES utilisateurs
            // Si un siège est dans _selectedSeats mais pas dans newOccupiedSeats ou newPendingReservationSeats,
            // c'est qu'il est réservé par l'utilisateur actuel. Donc on ne le retire PAS - l'utilisateur peut continuer à payer
            
            // Seulement retirer les sièges qui sont occupés (vendus au guichet) ou en cours de réservation par d'autres utilisateurs
            final seatsToRemove = _selectedSeats.where((seat) => 
              newOccupiedSeats.contains(seat) || newPendingReservationSeats.contains(seat)
            ).toList();
            
            if (seatsToRemove.isNotEmpty) {
              _selectedSeats.removeWhere((seat) => seatsToRemove.contains(seat));
              if (!silent && mounted) {
                // Afficher un dialog explicite pour informer l'utilisateur
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Siège(s) réservé(s)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ Le(s) siège(s) ${seatsToRemove.join(", ")} ${seatsToRemove.length > 1 ? "ont été" : "a été"} réservé(s) par un autre client.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Veuillez sélectionner ${seatsToRemove.length > 1 ? "d'autres sièges" : "un autre siège"} pour continuer.',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (_selectedSeats.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Sièges encore disponibles : ${_selectedSeats.join(", ")}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Si plus aucun siège n'est sélectionné, l'utilisateur devra en choisir d'autres
                          if (_selectedSeats.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Veuillez sélectionner ${seatsToRemove.length > 1 ? "d'autres sièges" : "un autre siège"} pour continuer.',
                                ),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(t('common.ok')),
                      ),
                    ],
                  ),
                );
              }
            }
            
            // Ne pas afficher d'avertissement pour les sièges sélectionnés qui ne sont plus dans les disponibles
            // car ils sont probablement réservés par l'utilisateur lui-même (en attente de paiement)
            // L'utilisateur peut continuer à finaliser son paiement
          });
        }
      } else {
        // Vérifier si c'est une erreur concernant les arrêts
        final details = result['details'];
        if (details != null && details['available_stops'] != null) {
          // Le départ a des arrêts mais ils ne sont pas sélectionnés
          final stopsData = details['available_stops'] as List;
          final stops =
              stopsData.map((s) => Map<String, dynamic>.from(s)).toList();
          if (mounted && !_isDisposed) {
            setState(() {
              _hasSegments = true;
              _stops = stops;
              _isLoading = false;
            });
          }
          if (!silent && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    result['message'] ?? t('seats.please_select_stops')),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
          });
        }
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  result['message'] ?? t('seats.loading_seats_error')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
      if (!silent && mounted) {
        final errorMessage = ErrorMessageHelper.getOperationError(
          'réserver',
          error: e,
          customMessage: 'Impossible de réserver le siège. Veuillez réessayer.',
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

  void _toggleSeat(int seatNumber) {
    // Si le siège est déjà sélectionné, permettre de le désélectionner
    if (_selectedSeats.contains(seatNumber)) {
      setState(() {
        _selectedSeats.remove(seatNumber);
        _selectedSeats.sort();
      });
      return;
    }

    // Empêcher la sélection de sièges occupés (vendus au guichet)
    if (_occupiedSeats.contains(seatNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Le siège $seatNumber est déjà vendu. Veuillez choisir un autre siège.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Empêcher la sélection de sièges en cours de réservation par d'autres utilisateurs
    if (_pendingReservationSeats.contains(seatNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⏳ Le siège $seatNumber est en cours de réservation par un autre client. Veuillez choisir un autre siège.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Vérifier les différents états du siège
    final isSeatAvailable = _availableSeats.contains(seatNumber);
    final isSeatOccupied = _occupiedSeats.contains(seatNumber);
    final isSeatPendingReservation = _pendingReservationSeats.contains(seatNumber);
    
    // Si le siège n'est pas disponible, vérifier pourquoi
    if (!isSeatAvailable) {
      // Vérifier si le siège est dans une plage valide
      final totalSeats = widget.depart['nombre_places'] ?? 0;
      if (seatNumber < 1 || seatNumber > totalSeats) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('seats.seat_not_available').replaceAll('{{seat}}', seatNumber.toString())),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // Si le siège n'est ni occupé ni en cours de réservation mais pas disponible,
      // c'est peut-être un problème de synchronisation - permettre quand même la sélection
      if (!isSeatOccupied && !isSeatPendingReservation) {
        debugPrint('⚠️ [SeatSelection] Siège $seatNumber pas dans availableSeats mais pas occupé/réservé - autorisation de sélection');
      }
    }

    // Vérifier la limite de 5 sièges
    if (_selectedSeats.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('seats.max_seats_reached')),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Ajouter le siège à la sélection
    setState(() {
      _selectedSeats.add(seatNumber);
      _selectedSeats.sort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t('seats.title')),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Légende en haut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Libre
                  _buildLegendItem(
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.white,
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[600]!
                        : Colors.grey.shade300,
                    t('seats.free'),
                  ),
                  const SizedBox(width: 12),
                  // Occupé (guichet)
                  _buildLegendItem(
                    Colors.red.withValues(alpha: 0.3), 
                    Colors.red, 
                    'Occupé (Guichet)',
                  ),
                  const SizedBox(width: 12),
                  // En cours de réservation (bloqué 5 min)
                  _buildLegendItem(
                    Colors.orange.withValues(alpha: 0.3), 
                    Colors.orange, 
                    '⏳ En cours de réservation',
                  ),
                  const SizedBox(width: 12),
                  // Sélectionné
                  _buildLegendItem(
                    Colors.green.withValues(alpha: 0.3), 
                    Colors.green, 
                    t('seats.selected_seat'),
                  ),
                ],
              ),
            ),
          ),

          // Sélection des arrêts (si le départ a des segments)
          if (_hasSegments && _stops.isNotEmpty) _buildStopsSelector(),

          // Grille de sièges
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : _buildSeatGrid(),
          ),

          // Informations en bas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.white,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_lastSeatsRefresh != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t('seats.last_update').replaceAll('{{time}}', _formatTime(_lastSeatsRefresh!)),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedSeats.isNotEmpty) ...[
                            Text(
                              t('seats.seats_selected').replaceAll('{{count}}', _selectedSeats.length.toString()).replaceAll('{{plural}}', _selectedSeats.length > 1 ? 's' : ''),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[300]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${_calculateTotalAmount()} FCFA',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ] else
                            Text(
                              t('seats.no_seat_selected'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[300]
                                    : Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                      ),
                      tooltip: 'Actualiser',
                      onPressed:
                          _isLoading ? null : () => _loadAvailableSeats(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedSeats.isEmpty ||
                            (_hasSegments &&
                                (_selectedStopEmbark == null ||
                                    _selectedStopDisembark == null))
                        ? null
                        : () {
                            // Vérifier que les sièges sélectionnés sont toujours disponibles
                            // Un siège est valide s'il n'est ni occupé ni en cours de réservation par d'autres
                            final validSeats = _selectedSeats.where((seat) => 
                              !_occupiedSeats.contains(seat) && !_pendingReservationSeats.contains(seat)
                            ).toList();
                            
                            if (validSeats.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t('seats.no_valid_seats'),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        t('seats.seats_reserved_select_others'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: t('common.ok'),
                                    textColor: Colors.white,
                                    onPressed: () {},
                                  ),
                                ),
                              );
                              return;
                            }
                            
                            if (validSeats.length != _selectedSeats.length) {
                              // Certains sièges ne sont plus valides - proposer de continuer avec les valides
                              final removedSeats = _selectedSeats.where((seat) => 
                                !validSeats.contains(seat)
                              ).toList();
                              
                              // Afficher un dialog pour confirmer
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Text(t('seats.unavailable_seats')),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t('seats.following_seats_unavailable'),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      ...removedSeats.map((seat) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text('• ${t("seats.seat").replaceAll("{{number}}", seat.toString())}'),
                                      )),
                                      const SizedBox(height: 12),
                                      Text(
                                        t('seats.continue_with_available').replaceAll('{{count}}', validSeats.length.toString()),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          t('seats.available_seats').replaceAll('{{seats}}', validSeats.join(", ")),
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(t('common.cancel')),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        // Mettre à jour la sélection et naviguer
                                        setState(() {
                                          _selectedSeats = validSeats;
                                        });
                                        
                                        debugPrint('🎫 [SeatSelection] Navigation vers ClientInfoScreen avec ${validSeats.length} siège(s): ${validSeats.join(", ")}');
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ClientInfoScreen(
                                              depart: widget.depart,
                                              selectedSeats: validSeats,
                                              stopEmbarkId: _selectedStopEmbark,
                                              stopDisembarkId: _selectedStopDisembark,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryOrange,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(t('seats.continue')),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // Tous les sièges sont valides, naviguer directement
                              debugPrint('🎫 [SeatSelection] Navigation vers ClientInfoScreen avec ${_selectedSeats.length} siège(s): ${_selectedSeats.join(", ")}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClientInfoScreen(
                                    depart: widget.depart,
                                    selectedSeats: _selectedSeats,
                                    stopEmbarkId: _selectedStopEmbark,
                                    stopDisembarkId: _selectedStopDisembark,
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      t('seats.continue'),
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
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      Color backgroundColor, Color borderColor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildStopsSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : AppTheme.primaryOrange.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: AppTheme.primaryOrange,
              ),
              const SizedBox(width: 6),
              Text(
                t('seats.select_your_stops'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedStopEmbark,
                  decoration: InputDecoration(
                    labelText: 'Embarquement',
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primaryOrange
                          : Colors.black87,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                  ),
                  dropdownColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.white,
                  items: _stops.map((stop) {
                    return DropdownMenuItem<int>(
                      value: stop['id'],
                      child: Text(
                        stop['name'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedStopDisembark,
                  decoration: InputDecoration(
                    labelText: 'Débarquement',
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primaryOrange
                          : Colors.black87,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                  ),
                  dropdownColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.white,
                  items: _stops.map((stop) {
                    final embarkIndex = _selectedStopEmbark != null
                        ? _stops
                            .indexWhere((s) => s['id'] == _selectedStopEmbark)
                        : -1;
                    final currentIndex =
                        _stops.indexWhere((s) => s['id'] == stop['id']);
                    // Ne permettre que les arrêts après l'embarquement
                    final isEnabled =
                        embarkIndex >= 0 && currentIndex > embarkIndex;

                    return DropdownMenuItem<int>(
                      value: stop['id'],
                      enabled: isEnabled,
                      child: Text(
                        stop['name'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isEnabled
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87)
                              : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    final totalSeats = widget.depart['nombre_places'] ?? 0;
    if (totalSeats == 0) {
      return Center(
        child: Text(
          t('seats.no_seats_available'),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey[700],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6, // 6 colonnes pour un meilleur espacement
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9, // Légèrement plus haut que large
        ),
        itemCount: totalSeats,
        itemBuilder: (context, index) {
          final seatNumber = index + 1;
          final isAvailable = _availableSeats.contains(seatNumber);
          final isOccupied = _occupiedSeats.contains(seatNumber);
          final isPendingReservation = _pendingReservationSeats.contains(seatNumber);
          final isSelected = _selectedSeats.contains(seatNumber);

          // Logique des couleurs avec priorités
          // PRIORITÉ 1: Siège sélectionné par l'utilisateur actuel (vert)
          // PRIORITÉ 2: Siège occupé/vendu au guichet (rouge)
          // PRIORITÉ 3: Siège en cours de réservation en ligne (orange avec icône horloge)
          // PRIORITÉ 4: Siège disponible (gris/blanc selon thème)
          
          Color seatColor;
          Color backgroundColor;
          Color borderColor;
          IconData seatIcon;
          double borderWidth;

          if (isSelected) {
            // Choisi par l'utilisateur actuel : vert vif
            seatColor = Colors.white;
            backgroundColor = Colors.green;
            borderColor = Colors.green.shade700;
            seatIcon = Icons.check_circle;
            borderWidth = 2.5;
          } else if (isOccupied) {
            // Occupé/vendu au guichet : rouge
            seatColor = Colors.white;
            backgroundColor = isDark ? Colors.red.shade900 : Colors.red.shade600;
            borderColor = Colors.red.shade700;
            seatIcon = Icons.block;
            borderWidth = 2;
          } else if (isPendingReservation) {
            // En cours de réservation en ligne (bloqué 5 min) : orange avec icône horloge
            seatColor = Colors.white;
            backgroundColor = isDark ? Colors.orange.shade900 : Colors.orange.shade600;
            borderColor = Colors.orange.shade700;
            seatIcon = Icons.access_time;
            borderWidth = 2;
          } else if (isAvailable) {
            // Libre : adapté au thème avec meilleur contraste
            seatColor = isDark ? Colors.grey[300]! : Colors.grey[800]!;
            backgroundColor = isDark ? Colors.grey[800]! : Colors.grey[50]!;
            borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
            seatIcon = Icons.event_seat;
            borderWidth = 1.5;
          } else {
            // Non disponible (cas rare) : gris foncé
            seatColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
            backgroundColor = isDark ? Colors.grey[900]! : Colors.grey[200]!;
            borderColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
            seatIcon = Icons.close;
            borderWidth = 1;
          }

          return GestureDetector(
            // Permettre la sélection si le siège n'est pas occupé ni en cours de réservation
            // OU s'il est déjà sélectionné (pour permettre la désélection)
            onTap: (isOccupied || (isPendingReservation && !isSelected))
                ? null
                : () => _toggleSeat(seatNumber),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : isPendingReservation
                        ? [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 0.5,
                            ),
                          ]
                        : [],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      seatIcon,
                      color: seatColor,
                      size: isSelected ? 20 : 16,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$seatNumber',
                      style: TextStyle(
                        color: seatColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: isSelected ? 13 : 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return t('seats.ago_seconds').replaceAll('{{seconds}}', diff.inSeconds.toString());
    } else if (diff.inMinutes < 60) {
      return t('seats.ago_minutes').replaceAll('{{minutes}}', diff.inMinutes.toString());
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _calculateTotalAmount() {
    if (_selectedSeats.isEmpty) return '0';
    final prixStr = widget.depart['prix']?.toString() ?? '0';
    final prix = double.tryParse(prixStr) ?? 0.0;
    final total = prix * _selectedSeats.length;
    return total.toStringAsFixed(0);
  }
}
