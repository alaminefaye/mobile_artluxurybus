import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_announcement_provider.dart';

class VoiceSettingsScreen extends ConsumerStatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  ConsumerState<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends ConsumerState<VoiceSettingsScreen> {
  bool _isEnabled = true;
  int _repeatInterval = 5;
  double _volume = 0.9; // Volume légèrement réduit
  double _pitch = 0.95; // Tonalité légèrement plus grave
  double _rate = 0.48; // Vitesse légèrement ralentie

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = ref.read(voiceAnnouncementServiceProvider);
    
    final enabled = await service.isEnabled();
    final interval = await service.getRepeatInterval();
    
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _repeatInterval = interval;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(voiceAnnouncementServiceProvider);
    final notifier = ref.watch(voiceAnnouncementNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres Annonces Vocales',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte d'information
          Card(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFD4AF37),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Les annonces vocales répètent automatiquement les messages de type "Annonce" jusqu\'à ce qu\'ils ne soient plus actifs.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Activer/Désactiver
          Card(
            child: SwitchListTile(
              title: const Text(
                'Activer les annonces vocales',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Lire automatiquement les annonces'),
              value: _isEnabled,
              activeThumbColor: const Color(0xFFD4AF37),
              onChanged: (value) async {
                setState(() => _isEnabled = value);
                await notifier.setEnabled(value);
                
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Annonces vocales activées'
                          : 'Annonces vocales désactivées',
                    ),
                    backgroundColor: const Color(0xFFD4AF37),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Intervalle de répétition
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Intervalle de répétition',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_repeatInterval min',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Temps entre chaque répétition de l\'annonce',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: _repeatInterval.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    activeColor: const Color(0xFFD4AF37),
                    label: '$_repeatInterval minutes',
                    onChanged: (value) {
                      setState(() => _repeatInterval = value.toInt());
                    },
                    onChangeEnd: (value) async {
                      await notifier.setRepeatInterval(value.toInt());
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Volume
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Volume',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${(_volume * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    activeColor: const Color(0xFFD4AF37),
                    onChanged: (value) {
                      setState(() => _volume = value);
                    },
                    onChangeEnd: (value) async {
                      await service.setVolume(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pitch (Tonalité)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tonalité',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _pitch.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Grave (0.5) ← → Aigu (2.0)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: _pitch,
                    min: 0.5,
                    max: 2.0,
                    activeColor: const Color(0xFFD4AF37),
                    onChanged: (value) {
                      setState(() => _pitch = value);
                    },
                    onChangeEnd: (value) async {
                      await service.setPitch(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vitesse
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vitesse',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _rate.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Lent (0.0) ← → Rapide (1.0)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: _rate,
                    min: 0.0,
                    max: 1.0,
                    activeColor: const Color(0xFFD4AF37),
                    onChanged: (value) {
                      setState(() => _rate = value);
                    },
                    onChangeEnd: (value) async {
                      await service.setRate(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bouton de test
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.play_circle_outline,
                color: Color(0xFFD4AF37),
                size: 32,
              ),
              title: const Text(
                'Tester la voix',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Écouter un exemple d\'annonce'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await notifier.speakOnce(
                  'Annonce importante. Bienvenue sur Art Luxury Bus. '
                  'Ceci est un test des annonces vocales.',
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Arrêter toutes les annonces
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(
                Icons.stop_circle,
                color: Colors.red,
                size: 32,
              ),
              title: const Text(
                'Arrêter toutes les annonces',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              subtitle: const Text('Stopper la lecture en cours'),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: () async {
                await notifier.stopAllAnnouncements();
                
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Toutes les annonces ont été arrêtées'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Informations sur les annonces actives
          Consumer(
            builder: (context, ref, child) {
              final activeAnnouncements = ref.watch(activeVoiceAnnouncementsProvider);
              
              if (activeAnnouncements.isEmpty) {
                return const SizedBox.shrink();
              }

              return Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.campaign,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${activeAnnouncements.length} annonce(s) active(s)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...activeAnnouncements.map((announcement) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• ${announcement.titre}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      )),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
