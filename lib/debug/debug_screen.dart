import 'package:flutter/material.dart';
import 'debug_notifications.dart';
import 'test_announcement.dart';
import 'fix_announcement_service.dart';
import '../services/device_info_service.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.orange : Colors.blue;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outils de débogage'),
        backgroundColor: isDark ? Colors.orange : Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Outils de diagnostic', 
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            
            // Notifications et annonces
            _buildDebugCard(
              context,
              title: 'Notifications et annonces',
              description: 'Tester et déboguer les notifications push et les annonces vocales',
              icon: Icons.notifications_active,
              color: primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationDebugger()),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Test d'annonces
            _buildDebugCard(
              context,
              title: 'Créer une annonce test',
              description: 'Envoyer une annonce de test avec des paramètres personnalisés',
              icon: Icons.campaign,
              color: primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestAnnouncementScreen()),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Correction des annonces
            _buildDebugCard(
              context,
              title: 'Corriger les annonces',
              description: 'Déboguer et résoudre les problèmes avec le service d\'annonces',
              icon: Icons.build,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FixAnnouncementScreen()),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Informations appareil
            _buildDebugCard(
              context,
              title: 'Informations appareil',
              description: 'Afficher les détails techniques de l\'appareil',
              icon: Icons.phone_android,
              color: primaryColor,
              onTap: () async {
                final deviceInfo = DeviceInfoService();
                await deviceInfo.printDeviceInfo();
                
                // Afficher un dialogue avec les informations
                final info = await deviceInfo.getDeviceInfo();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Informations appareil'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final entry in info.entries)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${entry.key}: ', 
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Expanded(child: Text('${entry.value}')),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDebugCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
