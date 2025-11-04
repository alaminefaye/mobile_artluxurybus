import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Widget qui initialise FCM au démarrage de l'application
class FCMInitializer extends StatefulWidget {
  final Widget child;

  const FCMInitializer({
    super.key,
    required this.child,
  });

  @override
  State<FCMInitializer> createState() => _FCMInitializerState();
}

class _FCMInitializerState extends State<FCMInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    try {
      // L'enregistrement FCM est géré automatiquement dans AuthService.login()
      // Aucune action supplémentaire nécessaire ici
    } catch (e) {
      // Erreur ignorée en production
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un écran de chargement pendant l'initialisation
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Initialisation des notifications...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Une fois initialisé, afficher l'app normale
    return widget.child;
  }
}
