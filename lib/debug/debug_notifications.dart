import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/announcement_manager.dart';
import '../services/device_info_service.dart';
import '../services/message_api_service.dart';
import '../models/message_model.dart';

class NotificationDebugger extends StatefulWidget {
  const NotificationDebugger({super.key});

  @override
  State<NotificationDebugger> createState() => _NotificationDebuggerState();
}

class _NotificationDebuggerState extends State<NotificationDebugger> {
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  final MessageApiService _messageService = MessageApiService();
  final AnnouncementManager _announcementManager = AnnouncementManager();
  
  String _deviceId = 'Chargement...';
  String _deviceType = 'Chargement...';
  String _deviceName = 'Chargement...';
  List<MessageModel> _allMessages = [];
  List<MessageModel> _deviceSpecificMessages = [];
  List<MessageModel> _mobileMessages = [];
  String _logs = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadMessages();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceId = await _deviceInfoService.getDeviceId();
      final deviceType = await _deviceInfoService.getDeviceType();
      final deviceName = await _deviceInfoService.getDeviceName();
      
      setState(() {
        _deviceId = deviceId;
        _deviceType = deviceType;
        _deviceName = deviceName;
        _addLog('📱 Device ID: $deviceId');
        _addLog('📱 Type: $deviceType');
        _addLog('📱 Nom: $deviceName');
      });
    } catch (e) {
      _addLog('❌ Erreur device info: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      _addLog('🔄 Chargement des messages...');
      
      // Récupérer tous les messages actifs
      final allMessages = await _messageService.getActiveMessages();
      
      // Filtrer les messages pour mobile
      final mobileMessages = allMessages.where((m) => 
        m.appareil == 'mobile' || 
        m.appareil == 'tous' || 
        m.appareil == null || 
        m.appareil!.isEmpty).toList();
      
      // Filtrer les messages pour cet appareil spécifique
      final deviceSpecificMessages = allMessages.where((m) => 
        m.appareil == _deviceId ||
        (m.appareil != null && m.appareil!.contains(',') && 
         m.appareil!.split(',').map((e) => e.trim()).contains(_deviceId))).toList();
      
      setState(() {
        _allMessages = allMessages;
        _mobileMessages = mobileMessages;
        _deviceSpecificMessages = deviceSpecificMessages;
        
        _addLog('✅ ${allMessages.length} messages récupérés au total');
        _addLog('✅ ${mobileMessages.length} messages pour mobile');
        _addLog('✅ ${deviceSpecificMessages.length} messages pour cet appareil');
      });
    } catch (e) {
      _addLog('❌ Erreur chargement messages: $e');
    }
  }

  Future<void> _testLocalNotification() async {
    try {
      _addLog('🔔 Test notification locale...');
      await NotificationService.testNotification();
      _addLog('✅ Notification locale envoyée');
    } catch (e) {
      _addLog('❌ Erreur notification locale: $e');
    }
  }

  Future<void> _testAnnouncementPush() async {
    try {
      _addLog('🔊 Test notification d\'annonce...');
      await NotificationService.testAnnouncementPush();
      _addLog('✅ Notification d\'annonce simulée');
    } catch (e) {
      _addLog('❌ Erreur simulation annonce: $e');
    }
  }

  Future<void> _refreshAnnouncementManager() async {
    try {
      _addLog('🔄 Rafraîchissement AnnouncementManager...');
      await _announcementManager.refresh();
      _addLog('✅ AnnouncementManager rafraîchi');
    } catch (e) {
      _addLog('❌ Erreur rafraîchissement: $e');
    }
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Débogage Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadDeviceInfo();
              _loadMessages();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations sur l'appareil
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informations Appareil', 
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('ID: $_deviceId'),
                    Text('Type: $_deviceType'),
                    Text('Nom: $_deviceName'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Actions de test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Actions de test', 
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.notifications),
                          label: const Text('Tester notification locale'),
                          onPressed: _testLocalNotification,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.campaign),
                          label: const Text('Simuler notification annonce'),
                          onPressed: _testAnnouncementPush,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Rafraîchir AnnouncementManager'),
                          onPressed: _refreshAnnouncementManager,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Messages récupérés
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Messages récupérés', 
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Total: ${_allMessages.length}'),
                    Text('Pour mobile: ${_mobileMessages.length}'),
                    Text('Pour cet appareil: ${_deviceSpecificMessages.length}'),
                    const SizedBox(height: 16),
                    
                    // Liste des messages
                    if (_allMessages.isNotEmpty)
                      ExpansionTile(
                        title: const Text('Détails des messages'),
                        children: [
                          for (final message in _allMessages)
                            ListTile(
                              title: Text(message.titre),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type: ${message.type}'),
                                  Text('Appareil: ${message.appareil ?? 'tous'}'),
                                  Text('Actif: ${message.isCurrentlyActive ? 'Oui' : 'Non'}'),
                                ],
                              ),
                              leading: Icon(
                                message.isAnnonce ? Icons.campaign : Icons.notifications,
                                color: message.isCurrentlyActive 
                                  ? (isDark ? Colors.orange : Colors.blue) 
                                  : Colors.grey,
                              ),
                            ),
                        ],
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
