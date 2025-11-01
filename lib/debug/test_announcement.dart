import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/device_info_service.dart';

class TestAnnouncementScreen extends StatefulWidget {
  const TestAnnouncementScreen({super.key});

  @override
  State<TestAnnouncementScreen> createState() => _TestAnnouncementScreenState();
}

class _TestAnnouncementScreenState extends State<TestAnnouncementScreen> {
  final TextEditingController _titleController = TextEditingController(text: 'Test Annonce');
  final TextEditingController _contentController = TextEditingController(text: 'Ceci est un test d\'annonce vocale');
  final TextEditingController _deviceIdController = TextEditingController();
  String _selectedAppareil = 'mobile';
  bool _isLoading = false;
  String _result = '';
  String _deviceId = '';
  
  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDeviceId() async {
    try {
      final deviceId = await DeviceInfoService().getDeviceId();
      setState(() {
        _deviceId = deviceId;
        _deviceIdController.text = deviceId;
      });
    } catch (e) {
      debugPrint('❌ Erreur récupération device ID: $e');
    }
  }
  
  Future<void> _sendTestAnnouncement() async {
    setState(() {
      _isLoading = true;
      _result = 'Envoi en cours...';
    });
    
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      
      if (token == null) {
        setState(() {
          _result = '❌ Erreur: Token d\'authentification non disponible';
          _isLoading = false;
        });
        return;
      }
      
      // Déterminer l'appareil cible
      String appareil;
      if (_selectedAppareil == 'specific') {
        appareil = _deviceIdController.text.trim();
      } else {
        appareil = _selectedAppareil;
      }
      
      // Préparer les données de l'annonce
      final data = {
        'titre': _titleController.text,
        'contenu': _contentController.text,
        'type': 'annonce',
        'appareil': appareil,
        'active': true,
        'date_debut': DateTime.now().toIso8601String(),
        'date_fin': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
      };
      
      // Envoyer la requête à l'API
      final response = await http.post(
        Uri.parse('https://skf-artluxurybus.com/api/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _result = '✅ Annonce créée avec succès!\n'
              'ID: ${jsonResponse['data']['id']}\n'
              'Appareil cible: $appareil';
        });
      } else {
        setState(() {
          _result = '❌ Erreur API: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ Exception: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.orange : Colors.blue;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Annonces'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Créer une annonce de test', 
              style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            
            // Informations appareil
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appareil actuel', 
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('ID: $_deviceId'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Formulaire
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre de l\'annonce',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Contenu
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Contenu de l\'annonce',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Type d'appareil
                    Text('Appareil cible:', 
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    
                    // Options d'appareil
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Mobile (tous)'),
                          selected: _selectedAppareil == 'mobile',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedAppareil = 'mobile';
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Tous appareils'),
                          selected: _selectedAppareil == 'tous',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedAppareil = 'tous';
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Cet appareil spécifique'),
                          selected: _selectedAppareil == 'specific',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedAppareil = 'specific';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // ID appareil spécifique
                    if (_selectedAppareil == 'specific')
                      TextField(
                        controller: _deviceIdController,
                        decoration: const InputDecoration(
                          labelText: 'ID de l\'appareil',
                          border: OutlineInputBorder(),
                          helperText: 'ID unique de l\'appareil cible',
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Bouton d'envoi
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendTestAnnouncement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              width: 24, 
                              height: 24, 
                              child: CircularProgressIndicator(color: Colors.white))
                          : const Text('ENVOYER L\'ANNONCE DE TEST'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Résultat
            if (_result.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Résultat', 
                        style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: double.infinity,
                        child: Text(_result),
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
