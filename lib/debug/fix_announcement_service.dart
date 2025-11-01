import 'package:flutter/material.dart';
import '../services/announcement_manager.dart';
import '../services/device_info_service.dart';
import '../services/message_api_service.dart';
import '../models/message_model.dart';

class FixAnnouncementScreen extends StatefulWidget {
  const FixAnnouncementScreen({super.key});

  @override
  State<FixAnnouncementScreen> createState() => _FixAnnouncementScreenState();
}

class _FixAnnouncementScreenState extends State<FixAnnouncementScreen> {
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  final MessageApiService _messageService = MessageApiService();
  final AnnouncementManager _announcementManager = AnnouncementManager();
  
  String _deviceId = 'Chargement...';
  bool _isRunning = false;
  List<MessageModel> _activeAnnouncements = [];
  String _logs = '';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Récupérer l'ID de l'appareil
      final deviceId = await _deviceInfoService.getDeviceId();
      setState(() {
        _deviceId = deviceId;
      });
      _addLog('📱 Device ID: $deviceId');
      
      // Vérifier si l'AnnouncementManager est en cours d'exécution
      final isRunning = _announcementManager.isRunning;
      setState(() {
        _isRunning = isRunning;
      });
      _addLog(isRunning 
        ? '✅ AnnouncementManager est en cours d\'exécution' 
        : '⚠️ AnnouncementManager n\'est PAS en cours d\'exécution');
      
      // Charger les annonces actives
      await _loadActiveAnnouncements();
    } catch (e) {
      _addLog('❌ Erreur d\'initialisation: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadActiveAnnouncements() async {
    try {
      _addLog('🔄 Chargement des annonces actives...');
      
      // Récupérer toutes les annonces actives
      final messages = await _messageService.getActiveMessages();
      final announcements = messages.where((m) => 
        m.isAnnonce && 
        m.isCurrentlyActive).toList();
      
      setState(() {
        _activeAnnouncements = announcements;
      });
      
      _addLog('✅ ${announcements.length} annonce(s) active(s) trouvée(s)');
      
      // Analyser les annonces pour cet appareil
      final forThisDevice = announcements.where((m) => _isForThisDevice(m)).toList();
      _addLog('✅ ${forThisDevice.length} annonce(s) pour cet appareil');
      
      for (final announcement in forThisDevice) {
        _addLog('📢 Annonce #${announcement.id}: "${announcement.titre}"');
        _addLog('   - Appareil: ${announcement.appareil ?? 'tous'}');
        _addLog('   - Actif: ${announcement.isCurrentlyActive ? 'Oui' : 'Non'}');
      }
    } catch (e) {
      _addLog('❌ Erreur lors du chargement des annonces: $e');
    }
  }
  
  Future<void> _startAnnouncementManager() async {
    try {
      _addLog('🚀 Démarrage de l\'AnnouncementManager...');
      await _announcementManager.start();
      setState(() {
        _isRunning = true;
      });
      _addLog('✅ AnnouncementManager démarré avec succès');
    } catch (e) {
      _addLog('❌ Erreur lors du démarrage: $e');
    }
  }
  
  Future<void> _refreshAnnouncementManager() async {
    try {
      _addLog('🔄 Rafraîchissement de l\'AnnouncementManager...');
      await _announcementManager.refresh();
      _addLog('✅ AnnouncementManager rafraîchi avec succès');
    } catch (e) {
      _addLog('❌ Erreur lors du rafraîchissement: $e');
    }
  }
  
  Future<void> _stopAnnouncementManager() async {
    try {
      _addLog('⏹️ Arrêt de l\'AnnouncementManager...');
      await _announcementManager.stop();
      setState(() {
        _isRunning = false;
      });
      _addLog('✅ AnnouncementManager arrêté avec succès');
    } catch (e) {
      _addLog('❌ Erreur lors de l\'arrêt: $e');
    }
  }
  
  Future<void> _fixDeviceIdIssues() async {
    try {
      _addLog('🔧 Correction des problèmes d\'ID d\'appareil...');
      
      // Réinitialiser le cache du DeviceInfoService
      _deviceInfoService.clearCache();
      
      // Récupérer à nouveau l'ID de l'appareil
      final deviceId = await _deviceInfoService.getDeviceId();
      setState(() {
        _deviceId = deviceId;
      });
      _addLog('✅ ID d\'appareil actualisé: $deviceId');
      
      // Redémarrer l'AnnouncementManager
      await _stopAnnouncementManager();
      await _startAnnouncementManager();
      
      _addLog('✅ Correction terminée avec succès');
    } catch (e) {
      _addLog('❌ Erreur lors de la correction: $e');
    }
  }
  
  bool _isForThisDevice(MessageModel message) {
    final appareil = message.appareil?.trim();
    
    // Si pas d'appareil spécifié ou 'tous', l'annonce concerne tout le monde
    if (appareil == null || appareil.isEmpty || appareil.toLowerCase() == 'tous') {
      return true;
    }
    
    // Vérifier si c'est la catégorie 'mobile'
    if (appareil.toLowerCase() == 'mobile') {
      return true;
    }
    
    // Vérifier si c'est l'identifiant unique de CET appareil
    if (appareil == _deviceId) {
      return true;
    }
    
    // Vérifier si l'identifiant est dans une liste séparée par des virgules
    if (appareil.contains(',')) {
      final deviceIds = appareil.split(',').map((e) => e.trim()).toList();
      if (deviceIds.contains(_deviceId)) {
        return true;
      }
    }
    
    return false;
  }
  
  void _addLog(String log) {
    setState(() {
      _logs = '$log\n$_logs';
    });
    debugPrint(log);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.orange : Colors.blue;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correction Annonces'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initialize,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations de base
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informations', 
                          style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Device ID: $_deviceId'),
                        Text('AnnouncementManager actif: ${_isRunning ? 'Oui' : 'Non'}'),
                        Text('Annonces actives: ${_activeAnnouncements.length}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Actions', 
                          style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Démarrer AnnouncementManager'),
                              onPressed: _isRunning ? null : _startAnnouncementManager,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Rafraîchir AnnouncementManager'),
                              onPressed: _isRunning ? _refreshAnnouncementManager : null,
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.stop),
                              label: const Text('Arrêter AnnouncementManager'),
                              onPressed: _isRunning ? _stopAnnouncementManager : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.build),
                              label: const Text('Corriger problèmes Device ID'),
                              onPressed: _fixDeviceIdIssues,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Annonces actives
                if (_activeAnnouncements.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Annonces actives', 
                            style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _activeAnnouncements.length,
                            itemBuilder: (context, index) {
                              final announcement = _activeAnnouncements[index];
                              final isForThisDevice = _isForThisDevice(announcement);
                              
                              return ListTile(
                                title: Text(announcement.titre),
                                subtitle: Text('Appareil: ${announcement.appareil ?? 'tous'}'),
                                leading: Icon(
                                  Icons.campaign,
                                  color: isForThisDevice ? primaryColor : Colors.grey,
                                ),
                                trailing: isForThisDevice
                                  ? Icon(Icons.check_circle, color: Colors.green)
                                  : Icon(Icons.cancel, color: Colors.red),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Logs
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Logs', 
                          style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          width: double.infinity,
                          height: 200,
                          child: SingleChildScrollView(
                            child: Text(_logs, 
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
