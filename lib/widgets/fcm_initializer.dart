import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/debug_logger.dart';

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
      DebugLogger.log('🔔 Initialisation FCM au démarrage...');
      
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();
      
      if (isLoggedIn) {
        // Vérifier et réparer FCM si nécessaire
        await authService.ensureFCMIsValid();
        DebugLogger.log('✅ FCM vérifié et initialisé');
      } else {
        DebugLogger.log('ℹ️ Utilisateur non connecté - FCM non initialisé');
      }
      
    } catch (e) {
      DebugLogger.error('❌ Erreur initialisation FCM', e);
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
