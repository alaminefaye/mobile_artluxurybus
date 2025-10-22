import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/location_provider.dart';

class LocationDisplayWidget extends ConsumerWidget {
  final Color iconColor;
  final Color textColor;
  final double fontSize;
  final bool showDropdownIcon;

  const LocationDisplayWidget({
    super.key,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.fontSize = 14,
    this.showDropdownIcon = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);

    return GestureDetector(
      onTap: () => _handleLocationTap(context, ref, locationState),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône de localisation avec animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _getLocationIcon(locationState),
              color: iconColor,
              size: 16,
              key: ValueKey(_getLocationIcon(locationState)),
            ),
          ),
          const SizedBox(width: 4),
          
          // Indicateur de chargement ou nom de localisation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: locationState.isLoading
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Text(
                  _getDisplayText(locationState),
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  key: ValueKey(_getDisplayText(locationState)),
                ),
          ),
          
          if (showDropdownIcon) ...[
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: locationState.isLoading ? 0.5 : 0,
              duration: const Duration(milliseconds: 500),
              child: Icon(
                locationState.isLoading ? Icons.refresh : Icons.keyboard_arrow_down,
                color: iconColor,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getLocationIcon(LocationState state) {
    if (state.isLoading) return Icons.refresh;
    if (!state.hasPermission) return Icons.location_off;
    return Icons.location_on;
  }

  String _getDisplayText(LocationState state) {
    if (state.error != null && state.locationName == 'Côte d\'Ivoire') {
      return 'Localisation indisponible';
    }
    return state.locationName;
  }

  void _handleLocationTap(BuildContext context, WidgetRef ref, LocationState state) {
    if (state.isLoading) return;

    if (!state.hasPermission) {
      _showPermissionDialog(context, ref);
    } else {
      ref.read(locationProvider.notifier).refreshLocation();
      
      // Feedback visuel pour l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Actualisation de la localisation...'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.blue.shade600,
        ),
      );
    }
  }

  void _showPermissionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.orange),
              SizedBox(width: 8),
              Text('Localisation requise'),
            ],
          ),
          content: const Text(
            'Pour vous offrir une meilleure expérience, Art Luxury Bus souhaite accéder à votre localisation afin de vous proposer les services les plus proches de vous.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(locationProvider.notifier).requestPermissions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Autoriser'),
            ),
          ],
        );
      },
    );
  }
}