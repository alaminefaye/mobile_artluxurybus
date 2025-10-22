import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_models.dart';
import '../services/attendance_api_service.dart';
import '../theme/app_theme.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends ConsumerState<AttendanceHistoryScreen> {
  List<AttendanceRecord> _attendances = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final attendances = await AttendanceApiService.getMyAttendances(
        perPage: 50,
        page: 1,
      );
      
      setState(() {
        _attendances = attendances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique de pointage'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendances,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadAttendances,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_attendances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun pointage',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Vous n\'avez pas encore effectué de pointage',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendances,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _attendances.length,
        itemBuilder: (context, index) {
          final attendance = _attendances[index];
          return _buildAttendanceCard(attendance);
        },
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord attendance) {
    Color statusColor;
    IconData statusIcon;
    
    if (attendance.isSuccess) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (attendance.isOutOfRange) {
      statusColor = Colors.orange;
      statusIcon = Icons.location_off;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    Color actionColor;
    IconData actionIcon;
    
    switch (attendance.actionType) {
      case 'entry':
        actionColor = Colors.green;
        actionIcon = Icons.login_rounded;
        break;
      case 'exit':
        actionColor = Colors.red;
        actionIcon = Icons.logout_rounded;
        break;
      case 'break':
        actionColor = Colors.orange;
        actionIcon = Icons.coffee_rounded;
        break;
      default:
        actionColor = Colors.grey;
        actionIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec statut et date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      attendance.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  attendance.scannedAt,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Informations du pointage
            _buildInfoRow(
              Icons.location_on,
              'Localisation',
              attendance.location,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              actionIcon,
              'Action',
              attendance.actionLabel,
              color: actionColor,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.straighten,
              'Distance',
              attendance.distance,
            ),
            
            // Raison d'échec si présente
            if (attendance.failureReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attendance.failureReason!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
