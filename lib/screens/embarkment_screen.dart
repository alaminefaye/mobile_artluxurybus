import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/embarkment_model.dart';
import '../services/embarkment_service.dart';
import '../theme/app_theme.dart';
import 'embarkment_detail_screen.dart';

class EmbarkmentScreen extends ConsumerStatefulWidget {
  const EmbarkmentScreen({super.key});

  @override
  ConsumerState<EmbarkmentScreen> createState() => _EmbarkmentScreenState();
}

class _EmbarkmentScreenState extends ConsumerState<EmbarkmentScreen> {
  List<EmbarkmentDepart> _departs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeparts();
  }

  Future<void> _loadDeparts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await EmbarkmentService.getDepartsForEmbarkment();
      
      if (result['success'] == true) {
        final data = result['data'] as List<dynamic>;
        setState(() {
          _departs = data
              .map((json) => EmbarkmentDepart.fromJson(json as Map<String, dynamic>))
              .toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion d\'Embarquement'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeparts,
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
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDeparts,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _departs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun départ disponible',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDeparts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _departs.length,
                        itemBuilder: (context, index) {
                          final depart = _departs[index];
                          return _buildDepartCard(depart);
                        },
                      ),
                    ),
    );
  }

  Widget _buildDepartCard(EmbarkmentDepart depart) {
    final isReady = depart.isReadyForEmbarkment;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isReady ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isReady ? AppTheme.primaryOrange : Colors.grey[300]!,
          width: isReady ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmbarkmentDetailScreen(departId: depart.id),
            ),
          ).then((_) {
            // Recharger la liste après retour
            _loadDeparts();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec badge "Prêt pour embarquement"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          depart.routeText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Départ #${depart.numeroDepart ?? depart.id}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isReady)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PRÊT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Informations du départ
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    depart.dateDepartFormatted ?? depart.dateDepart ?? 'N/A',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    depart.heureDepart ?? 'N/A',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              if (depart.bus != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions_bus, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Bus: ${depart.bus!.registrationNumber ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              
              // Statistiques
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Places',
                      '${depart.nombrePlaces}',
                      Icons.event_seat,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      'Réservées',
                      '${depart.placesReservees}',
                      Icons.bookmark,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      'Scannés',
                      '${depart.ticketsScannes}',
                      Icons.qr_code_scanner,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

