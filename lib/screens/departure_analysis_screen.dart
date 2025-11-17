import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Écran d'analyse des taux de remplissage des départs
class DepartureAnalysisScreen extends ConsumerStatefulWidget {
  const DepartureAnalysisScreen({super.key});

  @override
  ConsumerState<DepartureAnalysisScreen> createState() =>
      _DepartureAnalysisScreenState();
}

class _DepartureAnalysisScreenState
    extends ConsumerState<DepartureAnalysisScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<DepartureAnalysis> _departures = [];
  final _numberFormat = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _loadDepartureAnalysis();
  }

  Future<void> _loadDepartureAnalysis() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        setState(() {
          _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
          'https://skf-artluxurybus.com/api/dashboard/departure-analysis');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'] as List;
          setState(() {
            _departures =
                data.map((item) => DepartureAnalysis.fromJson(item)).toList();
            _isLoading = false;
          });
        } else {
          throw Exception(jsonResponse['message'] ?? 'Erreur serveur');
        }
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analyse des Départs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDepartureAnalysis,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingIndicator(),
            SizedBox(height: 16),
            Text('Chargement de l\'analyse...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadDepartureAnalysis,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_departures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun départ aujourd\'hui',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDepartureAnalysis,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _departures.length,
        itemBuilder: (context, index) {
          final departure = _departures[index];
          return _buildDepartureCard(departure, isDark);
        },
      ),
    );
  }

  Widget _buildDepartureCard(DepartureAnalysis departure, bool isDark) {
    final fillPercentage = departure.fillPercentage;
    Color percentageColor;

    if (fillPercentage >= 80) {
      percentageColor = Colors.green;
    } else if (fillPercentage >= 50) {
      percentageColor = Colors.orange;
    } else {
      percentageColor = Colors.red;
    }

    return Card(
      color: isDark ? Colors.grey.shade800 : null,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heure et trajet
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: isDark
                            ? AppTheme.primaryOrange
                            : AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        departure.departureTime,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark
                              ? AppTheme.primaryOrange
                              : AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    departure.route,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Immatriculation du bus
            Row(
              children: [
                Icon(
                  Icons.directions_bus,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  departure.busImmatriculation,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Prix
            Row(
              children: [
                Icon(
                  Icons.payments,
                  size: 18,
                  color: isDark ? Colors.greenAccent : Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_numberFormat.format(departure.prix.toInt())} FCFA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.greenAccent : Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Places
            Row(
              children: [
                Icon(
                  Icons.event_seat,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  '${departure.occupiedSeats} / ${departure.totalSeats} places',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barre de progression
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Taux de remplissage',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${fillPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: percentageColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fillPercentage / 100,
                    minHeight: 12,
                    backgroundColor:
                        isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(percentageColor),
                  ),
                ),
              ],
            ),

            // Statut
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: percentageColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: percentageColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getStatusText(fillPercentage),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: percentageColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(double percentage) {
    if (percentage >= 90) return 'Complet';
    if (percentage >= 80) return 'Presque complet';
    if (percentage >= 50) return 'Moyen';
    if (percentage >= 20) return 'Faible occupation';
    return 'Très faible occupation';
  }
}

/// Modèle pour l'analyse d'un départ
class DepartureAnalysis {
  final int id;
  final String departureTime;
  final String route;
  final String busNumber;
  final String busImmatriculation;
  final double prix;
  final int totalSeats;
  final int occupiedSeats;
  final double fillPercentage;

  DepartureAnalysis({
    required this.id,
    required this.departureTime,
    required this.route,
    required this.busNumber,
    required this.busImmatriculation,
    required this.prix,
    required this.totalSeats,
    required this.occupiedSeats,
    required this.fillPercentage,
  });

  factory DepartureAnalysis.fromJson(Map<String, dynamic> json) {
    // Parser le prix correctement (peut être String ou num)
    double parsedPrix = 0.0;
    if (json['prix'] != null) {
      if (json['prix'] is num) {
        parsedPrix = json['prix'].toDouble();
      } else if (json['prix'] is String) {
        parsedPrix = double.tryParse(json['prix']) ?? 0.0;
      }
    }

    return DepartureAnalysis(
      id: json['id'] ?? 0,
      departureTime: json['departure_time'] ?? '',
      route: json['route'] ?? '',
      busNumber: json['bus_number'] ?? '',
      busImmatriculation: json['bus_immatriculation'] ?? 'N/A',
      prix: parsedPrix,
      totalSeats: json['total_seats'] ?? 0,
      occupiedSeats: json['occupied_seats'] ?? 0,
      fillPercentage: (json['fill_percentage'] ?? 0.0).toDouble(),
    );
  }
}
