import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_models.dart';
import '../services/attendance_api_service.dart';
import '../theme/app_theme.dart';
import 'attendance_history_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isProcessing = false;
  ActionType _selectedAction = ActionType.entry;

  Future<void> _scanBarcode() async {
    if (_isProcessing) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiBarcodeScanner(
          onDetect: (BarcodeCapture capture) {
            final String? scanned = capture.barcodes.firstOrNull?.displayValue;
            if (scanned != null && !_isProcessing) {
              Navigator.of(context).pop();
              _processQrCode(scanned);
            }
          },
        ),
      ),
    );
  }

  Future<void> _processQrCode(String qrCode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Parser le QR code si c'est du JSON
      String codeToSend = qrCode;
      try {
        final Map<String, dynamic> qrData = json.decode(qrCode);
        if (qrData.containsKey('code')) {
          codeToSend = qrData['code'];
        }
      } catch (e) {
        // Si ce n'est pas du JSON, utiliser la valeur brute
        codeToSend = qrCode;
      }
      // Afficher un dialog de chargement
      if (mounted) {
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
                    Text('Pointage en cours...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Obtenir la position GPS
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Envoyer au serveur
      final result = await AttendanceApiService.scanQrCode(
        qrCode: codeToSend,
        latitude: position.latitude,
        longitude: position.longitude,
        actionType: _selectedAction,
      );

      // Fermer le dialog de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Afficher le résultat
      if (mounted) {
        final success = result['success'] ?? false;
        final statusCode = result['statusCode'];
        final data = result['data'] as Map<String, dynamic>?;
        
        // Extraire le vrai message d'erreur
        String message;
        if (success) {
          message = data?['message'] ?? 'Pointage effectué';
        } else {
          // Chercher le message d'erreur dans plusieurs endroits possibles
          message = result['error'] as String? ??
              data?['data']?['failure_reason'] as String? ??
              (data?['errors'] is Map ? (data!['errors'] as Map).values.first.toString() : null) ??
              data?['message'] as String? ??
              'Erreur lors du pointage';
          
          // Ajouter le code HTTP si disponible
          if (statusCode != null && statusCode != 200) {
            message = '[$statusCode] $message';
          }
        }

        _showResultDialog(
          success: success,
          message: message,
          data: data,
        );
      }
    } catch (e) {
      // Fermer le dialog de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Afficher l'erreur
      if (mounted) {
        String errorMsg = e.toString();
        // Nettoyer le message d'erreur si c'est une exception
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }
        
        _showResultDialog(
          success: false,
          message: errorMsg,
          data: null,
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showResultDialog({
    required bool success,
    required String message,
    Map<String, dynamic>? data,
  }) {
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
                success ? 'Succès' : 'Échec',
                style: TextStyle(
                  color: success ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (data != null && data['data'] != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              if (data['data']['location'] != null) ...[
                _buildInfoRow(
                  'Localisation',
                  data['data']['location']['name'],
                ),
                const SizedBox(height: 4),
              ],
              if (data['data']['action_label'] != null) ...[
                _buildInfoRow(
                  'Action',
                  data['data']['action_label'],
                ),
                const SizedBox(height: 4),
              ],
              if (data['data']['distance'] != null) ...[
                _buildInfoRow(
                  'Distance',
                  data['data']['distance'],
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (success) {
                // Rediriger vers l'historique de pointage
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AttendanceHistoryScreen(),
                  ),
                );
              }
            },
            child: Text(success ? 'Voir l\'historique' : 'Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Scanner QR Code de Pointage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Appuyez sur le bouton ci-dessous pour ouvrir le scanner',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type de pointage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          ActionType.entry,
                          Icons.login_rounded,
                          'Entrée',
                          Colors.green,
                        ),
                        _buildActionButton(
                          ActionType.exit,
                          Icons.logout_rounded,
                          'Sortie',
                          Colors.red,
                        ),
                        _buildActionButton(
                          ActionType.break_,
                          Icons.coffee_rounded,
                          'Pause',
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Scan button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _scanBarcode,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.qr_code_scanner),
              label: Text(_isProcessing ? 'Traitement...' : 'Scanner QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    ActionType action,
    IconData icon,
    String label,
    Color color,
  ) {
    final isSelected = _selectedAction == action;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAction = action;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
