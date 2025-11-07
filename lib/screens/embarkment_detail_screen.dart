import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import '../models/embarkment_model.dart';
import '../services/embarkment_service.dart';
import '../theme/app_theme.dart';

class EmbarkmentDetailScreen extends StatefulWidget {
  final int departId;

  const EmbarkmentDetailScreen({
    super.key,
    required this.departId,
  });

  @override
  State<EmbarkmentDetailScreen> createState() => _EmbarkmentDetailScreenState();
}

class _EmbarkmentDetailScreenState extends State<EmbarkmentDetailScreen> {
  Map<String, dynamic>? _departData;
  List<ScannedTicket> _scannedTickets = [];
  bool _isLoading = true;
  bool _isLoadingTickets = false;
  String? _errorMessage;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadDepartDetails();
    _loadScannedTickets();
  }

  Future<void> _loadDepartDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await EmbarkmentService.getDepartDetails(widget.departId);
      
      if (result['success'] == true) {
        setState(() {
          _departData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadScannedTickets() async {
    setState(() {
      _isLoadingTickets = true;
    });

    try {
      final result = await EmbarkmentService.getScannedTickets(widget.departId);
      
      if (result['success'] == true) {
        final data = result['data'] as List<dynamic>;
        setState(() {
          _scannedTickets = data
              .map((json) => ScannedTicket.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoadingTickets = false;
        });
      } else {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingTickets = false;
      });
    }
  }

  Future<void> _scanQRCode() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    bool hasProcessed = false; // Variable pour éviter les traitements multiples

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AiBarcodeScanner(
            onDetect: (BarcodeCapture capture) {
              final String? scanned = capture.barcodes.firstOrNull?.displayValue;
              // Traiter seulement si on a un code scanné et qu'on n'a pas déjà traité
              if (scanned != null && scanned.isNotEmpty && !hasProcessed) {
                hasProcessed = true; // Marquer comme traité immédiatement
                Navigator.of(context).pop(); // Fermer le scanner
                // Traiter le QR code après un court délai pour s'assurer que le Navigator est fermé
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _processQRCode(scanned);
                  }
                });
              }
            },
          ),
        ),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _processQRCode(String qrCode) async {
    // Afficher un dialog de chargement
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Traitement du ticket...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Parser le QR code si c'est du JSON
      String codeToSend = qrCode.trim(); // Nettoyer les espaces
      
      // Essayer de parser comme JSON
      try {
        final Map<String, dynamic> qrData = json.decode(qrCode);
        // Chercher l'ID du ticket dans différents champs possibles
        if (qrData.containsKey('ticket_id')) {
          codeToSend = qrData['ticket_id'].toString();
        } else if (qrData.containsKey('id')) {
          codeToSend = qrData['id'].toString();
        } else if (qrData.containsKey('code')) {
          codeToSend = qrData['code'].toString();
        } else {
          // Si aucun champ connu, essayer de trouver une valeur numérique
          final values = qrData.values.where((v) => v != null).toList();
          if (values.isNotEmpty) {
            codeToSend = values.first.toString();
          }
        }
      } catch (e) {
        // Si ce n'est pas du JSON, utiliser la valeur brute
        codeToSend = qrCode.trim();
      }

      // Vérifier que le code n'est pas vide
      if (codeToSend.isEmpty) {
        throw Exception('Le QR code scanné est vide');
      }

      final result = await EmbarkmentService.scanTicket(
        departId: widget.departId,
        qrCode: codeToSend,
      );

      // Fermer le dialog de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Afficher le résultat
      if (mounted) {
        final success = result['success'] ?? false;
        final message = result['message'] ?? '';

        _showResultDialog(
          success: success,
          message: message,
        );

        // Recharger les données si succès
        if (success) {
          _loadDepartDetails();
          _loadScannedTickets();
        }
      }
    } catch (e) {
      // Fermer le dialog de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Afficher l'erreur
      if (mounted) {
        _showResultDialog(
          success: false,
          message: 'Erreur: ${e.toString()}',
        );
      }
    }
  }

  void _showResultDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success ? 'Succès' : 'Erreur',
                style: TextStyle(
                  color: success ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails d\'Embarquement'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadDepartDetails();
              _loadScannedTickets();
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDepartDetails,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _departData == null
                  ? Center(
                      child: Text(
                        'Aucune donnée disponible',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadDepartDetails();
                        await _loadScannedTickets();
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Statistiques en haut
                            _buildStatisticsCard(),
                            const SizedBox(height: 16),
                            
                            // Bouton Scanner
                            ElevatedButton.icon(
                              onPressed: _isScanning ? null : _scanQRCode,
                              icon: _isScanning
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.qr_code_scanner),
                              label: Text(_isScanning ? 'Scan en cours...' : 'Scanner un ticket'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Liste des tickets scannés
                            _buildScannedTicketsList(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStatisticsCard() {
    final depart = _departData;
    if (depart == null) return const SizedBox.shrink();

    final nombrePlaces = depart['nombre_places'] ?? depart['places_total'] ?? 0;
    final placesReservees = depart['places_reservees'] ?? depart['reservations_count'] ?? 0;
    final ticketsScannes = depart['tickets_scannes'] ?? depart['scanned_count'] ?? _scannedTickets.length;
    final bus = depart['bus'];
    final busNumber = bus != null ? (bus['registration_number'] ?? bus['numero'] ?? bus['numero_bus'] ?? 'N/A') : 'N/A';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bus: ',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  busNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Places',
                  '$nombrePlaces',
                  Icons.event_seat,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Réservées',
                  '$placesReservees',
                  Icons.bookmark,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Scannés',
                  '$ticketsScannes',
                  Icons.qr_code_scanner,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildScannedTicketsList() {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tickets Scannés',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                if (_isLoadingTickets)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    '${_scannedTickets.length}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _scannedTickets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_scanner_outlined,
                            size: 48,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun ticket scanné',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _scannedTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _scannedTickets[index];
                      return _buildTicketItem(ticket);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketItem(ScannedTicket ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.nomComplet,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.telephone,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
                if (ticket.siegeNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Siège: ${ticket.siegeNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ticket.scannedAtFormatted ?? ticket.scannedAt,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

