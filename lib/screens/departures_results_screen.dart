import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import 'seat_selection_screen.dart';
import '../services/depart_service.dart';

class DeparturesResultsScreen extends StatefulWidget {
  final List<dynamic> departs;
  final String embarquement;
  final String destination;
  final String date;

  const DeparturesResultsScreen({
    super.key,
    required this.departs,
    required this.embarquement,
    required this.destination,
    required this.date,
  });

  @override
  State<DeparturesResultsScreen> createState() =>
      _DeparturesResultsScreenState();
}

class _DeparturesResultsScreenState extends State<DeparturesResultsScreen> {
  late List<dynamic> _departs;

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  @override
  void initState() {
    super.initState();
    _departs = widget.departs;
  }

  Future<void> _refreshDeparts() async {
    try {
      final result = await DepartService.searchDeparts(
        embarquement: widget.embarquement,
        destination: widget.destination,
        dateDepart: widget.date,
      );

      if (result['success'] == true) {
        setState(() {
          _departs = result['data'] ?? [];
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? t('departures.refresh_error')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('departures.refresh_error')),
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
        title: Text(t('departures.results_title')),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDeparts,
        child: _departs.isEmpty
            ? _buildEmptyState(context)
            : _buildResultsList(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                t('departures.no_departures'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('departures.modify_criteria'),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return Column(
      children: [
        // En-tête avec les critères de recherche
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.embarquement} → ${widget.destination}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[600],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${t("departures.date")}: ${widget.date}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_departs.length} ${_departs.length == 1 ? t("departures.departure") : t("departures.departures")}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Liste des résultats avec pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshDeparts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _departs.length,
              itemBuilder: (context, index) {
                final depart = _departs[index];
                return _buildDepartCard(context, depart);
              },
            ),
          ),
        ),
      ],
    );
  }

  bool _isDepartTimePassed(Map<String, dynamic> depart) {
    try {
      final dateDepart = depart['date_depart'] as String?;
      final heureDepart = depart['heure_depart'] as String?;

      if (dateDepart == null || heureDepart == null) {
        return false;
      }

      // Parser la date et l'heure
      final dateTimeStr = '$dateDepart $heureDepart';
      final departDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(dateTimeStr);

      // Ajouter 30 minutes
      final departDateTimePlus30 = departDateTime.add(
        const Duration(minutes: 30),
      );

      // Comparer avec l'heure actuelle
      return DateTime.now().isAfter(departDateTimePlus30);
    } catch (e) {
      // En cas d'erreur de parsing, on considère que le départ n'est pas passé
      return false;
    }
  }

  Color _getButtonColor(Map<String, dynamic> depart) {
    final isActive = depart['is_active'] == true;
    final placesDisponibles = depart['places_disponibles'] ?? 0;
    final isTimePassed = _isDepartTimePassed(depart);

    if (!isActive) {
      return Colors.grey[400]!;
    } else if (isTimePassed) {
      return Colors.grey[400]!;
    } else if (placesDisponibles <= 0) {
      return Colors.grey[400]!;
    } else {
      return Colors.orange;
    }
  }

  String _getButtonText(Map<String, dynamic> depart) {
    final isActive = depart['is_active'] == true;
    final placesDisponibles = depart['places_disponibles'] ?? 0;
    final isTimePassed = _isDepartTimePassed(depart);

    if (!isActive) {
      return t('departures.only_at_counter');
    } else if (isTimePassed) {
      return t('departures.departure_completed');
    } else if (placesDisponibles <= 0) {
      return t('departures.departure_full');
    } else {
      return t('departures.select');
    }
  }

  Widget _buildDepartCard(BuildContext context, Map<String, dynamic> depart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap:
            (depart['is_active'] == true &&
                (depart['places_disponibles'] ?? 0) > 0 &&
                !_isDepartTimePassed(depart))
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeatSelectionScreen(depart: depart),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Départ ${depart['numero_depart'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${depart['prix']} FCFA',
                      style: TextStyle(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${depart['trajet']['embarquement']} → ${depart['trajet']['destination']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${depart['heure_depart']} - ${depart['date_depart']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event_seat,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${depart['places_disponibles']}/${depart['nombre_places']} disponible${depart['places_disponibles'] > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (depart['bus'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.directions_bus,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bus: ${depart['bus']['numero'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _getButtonColor(depart),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getButtonText(depart),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
