import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/reservation_service.dart';
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
  List<int> _reservedSeats = [];
  List<int> _selectedSeats = []; // Permettre plusieurs sièges (max 5)
  bool _isLoading = true;
  DateTime? _lastSeatsRefresh;
  bool _isDisposed = false;

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
          const SnackBar(
            content: Text(
                'Veuillez sélectionner les arrêts d\'embarquement et de débarquement'),
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
        final newReservedSeats = List<int>.from(data['reserved_seats'] ?? []);

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
            _availableSeats = newAvailableSeats;
            _reservedSeats = newReservedSeats;
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

            // Retirer les sièges qui ne sont plus disponibles de la sélection
            _selectedSeats
                .removeWhere((seat) => !newAvailableSeats.contains(seat));
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
                    result['message'] ?? 'Veuillez sélectionner les arrêts'),
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
                  result['message'] ?? 'Erreur lors du chargement des sièges'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSeat(int seatNumber) {
    if (_reservedSeats.contains(seatNumber)) return;

    setState(() {
      if (_selectedSeats.contains(seatNumber)) {
        _selectedSeats.remove(seatNumber);
      } else {
        if (_selectedSeats.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous ne pouvez sélectionner que 5 sièges maximum'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (_availableSeats.contains(seatNumber)) {
          _selectedSeats.add(seatNumber);
          _selectedSeats.sort();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélection des sièges'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Légende en haut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLegendItem(Colors.white, Colors.grey.shade300, 'Libre'),
                  const SizedBox(width: 12),
                  _buildLegendItem(
                      Colors.red.withValues(alpha: 0.2), Colors.red, 'Occupé'),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.green, Colors.green, 'Sélectionné'),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.blue.withValues(alpha: 0.2),
                      Colors.blue, 'Réservé'),
                ],
              ),
            ),
          ),

          // Sélection des arrêts (si le départ a des segments)
          if (_hasSegments && _stops.isNotEmpty) _buildStopsSelector(),

          // Grille de sièges
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildSeatGrid(),
          ),

          // Informations en bas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
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
                        Icon(Icons.refresh, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Dernière mise à jour: ${_formatTime(_lastSeatsRefresh!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
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
                              '${_selectedSeats.length} siège${_selectedSeats.length > 1 ? 's' : ''} sélectionné${_selectedSeats.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${_calculateTotalAmount()} FCFA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ] else
                            Text(
                              'Aucun siège sélectionné',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
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
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continuer',
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
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildStopsSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Text(
                'Sélectionnez vos arrêts',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedStopEmbark,
                  decoration: InputDecoration(
                    labelText: 'Embarquement',
                    labelStyle: const TextStyle(fontSize: 12),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                  items: _stops.map((stop) {
                    return DropdownMenuItem<int>(
                      value: stop['id'],
                      child: Text(
                        stop['name'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStopEmbark = value;
                      // Réinitialiser le débarquement si nécessaire
                      if (value != null && _selectedStopDisembark != null) {
                        final embarkIndex =
                            _stops.indexWhere((s) => s['id'] == value);
                        final disembarkIndex = _stops.indexWhere(
                            (s) => s['id'] == _selectedStopDisembark);
                        if (embarkIndex >= 0 &&
                            disembarkIndex >= 0 &&
                            embarkIndex >= disembarkIndex) {
                          _selectedStopDisembark = null;
                        }
                      }
                      _selectedSeats
                          .clear(); // Réinitialiser la sélection de sièges
                    });
                    _loadAvailableSeats();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedStopDisembark,
                  decoration: InputDecoration(
                    labelText: 'Débarquement',
                    labelStyle: const TextStyle(fontSize: 12),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
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
                          color: isEnabled ? null : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStopDisembark = value;
                      _selectedSeats
                          .clear(); // Réinitialiser la sélection de sièges
                    });
                    _loadAvailableSeats();
                  },
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
      return const Center(
        child: Text('Aucun siège disponible'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              7, // Encore plus de colonnes pour des sièges plus petits
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          childAspectRatio: 1,
        ),
        itemCount: totalSeats,
        itemBuilder: (context, index) {
          final seatNumber = index + 1;
          final isAvailable = _availableSeats.contains(seatNumber);
          final isReserved = _reservedSeats.contains(seatNumber);
          final isSelected = _selectedSeats.contains(seatNumber);

          // Logique des couleurs
          Color seatColor;
          Color backgroundColor;
          Color borderColor;

          if (isReserved) {
            // Réservé ou laisser passer : bleu
            seatColor = Colors.blue;
            backgroundColor = Colors.blue.withValues(alpha: 0.2);
            borderColor = Colors.blue;
          } else if (isSelected) {
            // Choisi : vert
            seatColor = Colors.green;
            backgroundColor = Colors.green;
            borderColor = Colors.green;
          } else if (isAvailable) {
            // Libre : blanc
            seatColor = Colors.black87;
            backgroundColor = Colors.white;
            borderColor = Colors.grey.shade300;
          } else {
            // Occupé : rouge
            seatColor = Colors.red;
            backgroundColor = Colors.red.withValues(alpha: 0.2);
            borderColor = Colors.red;
          }

          return GestureDetector(
            onTap: isReserved || !isAvailable
                ? null
                : () => _toggleSeat(seatNumber),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isReserved
                          ? Icons.block
                          : !isAvailable
                              ? Icons.close
                              : isSelected
                                  ? Icons.check_circle
                                  : Icons.event_seat,
                      color: seatColor,
                      size: 12,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$seatNumber',
                      style: TextStyle(
                        color: seatColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 9,
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
      return 'Il y a ${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes}min';
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
