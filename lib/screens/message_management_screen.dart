import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message_model.dart';
import '../models/horaire_model.dart';
import '../services/message_api_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';

class MessageManagementScreen extends ConsumerStatefulWidget {
  const MessageManagementScreen({super.key});

  @override
  ConsumerState<MessageManagementScreen> createState() =>
      _MessageManagementScreenState();
}

class _MessageManagementScreenState
    extends ConsumerState<MessageManagementScreen> {
  final MessageApiService _messageService = MessageApiService();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String _filterType = 'tous'; // 'tous', 'notification', 'annonce'
  String _filterActive =
      'tous'; // 'actifs', 'inactifs', 'tous' - Par défaut 'tous' pour voir toutes les annonces

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Pour la gestion, on veut voir TOUS les messages (actifs et inactifs)
      // Le filtre actif/inactif est juste pour l'affichage, pas pour la récupération
      // On ne filtre PAS par appareil pour voir tous les messages (mobile, ecran_tv, etc.)
      final result = await _messageService.getMessages(
        type: _filterType == 'tous' ? null : _filterType,
        active:
            null, // Toujours null pour voir tous les messages (actifs et inactifs)
        appareil:
            null, // null pour voir tous les appareils (mobile, ecran_tv, ecran_led, tous)
      );

      // Filtrer côté client selon le statut actif/inactif
      final data = result['data'];
      List<MessageModel> filteredMessages = [];

      if (data != null) {
        if (data is List<MessageModel>) {
          // Déjà une liste de MessageModel
          filteredMessages = data;
        } else if (data is List) {
          // Liste de Map, convertir en MessageModel
          filteredMessages = data
              .whereType<Map<String, dynamic>>()
              .map((json) => MessageModel.fromJson(json))
              .toList();
        }
      }

      if (_filterActive == 'actifs') {
        // Afficher uniquement les actifs
        filteredMessages = filteredMessages.where((m) => m.active).toList();
      } else if (_filterActive == 'inactifs') {
        // Afficher uniquement les inactifs
        filteredMessages = filteredMessages.where((m) => !m.active).toList();
      }
      // Si _filterActive == 'tous', on garde tous les messages

      if (mounted) {
        // Debug: afficher les statistiques
        debugPrint('📊 [MessageManagement] Messages récupérés:');
        debugPrint('   - Total: ${filteredMessages.length}');
        debugPrint(
            '   - Notifications: ${filteredMessages.where((m) => m.isNotification).length}');
        debugPrint(
            '   - Annonces: ${filteredMessages.where((m) => m.isAnnonce).length}');
        debugPrint(
            '   - Actifs: ${filteredMessages.where((m) => m.active).length}');
        debugPrint(
            '   - Inactifs: ${filteredMessages.where((m) => !m.active).length}');
        debugPrint(
            '   - Expirés: ${filteredMessages.where((m) => m.isExpired).length}');

        setState(() {
          _messages = filteredMessages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(MessageModel message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le message "${message.titre}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _messageService.deleteMessage(message.id);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Message supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessageForm({MessageModel? message}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessageFormScreen(
          message: message,
          onSaved: () {
            _loadMessages();
          },
        ),
      ),
    );
  }

  // Vérifier si l'utilisateur peut gérer les messages
  bool _canManageMessages(User? user) {
    if (user == null) return false;

    if (user.role != null) {
      final roleLower = user.role!.toLowerCase();
      return roleLower.contains('super admin') ||
          roleLower.contains('super_admin') ||
          roleLower == 'admin' ||
          roleLower.contains('administrateur') ||
          roleLower.contains('chef agence') ||
          roleLower.contains('chef_agence') ||
          roleLower.contains('accueil');
    }

    if (user.displayRole != null) {
      final displayRoleLower = user.displayRole!.toLowerCase();
      return displayRoleLower.contains('super admin') ||
          displayRoleLower.contains('super_admin') ||
          displayRoleLower == 'admin' ||
          displayRoleLower.contains('administrateur') ||
          displayRoleLower.contains('chef agence') ||
          displayRoleLower.contains('chef_agence') ||
          displayRoleLower.contains('accueil');
    }

    if (user.rolesList != null && user.rolesList!.isNotEmpty) {
      return user.rolesList!.any((r) {
        final roleStr = r.toString().toLowerCase();
        return roleStr.contains('super admin') ||
            roleStr.contains('super_admin') ||
            roleStr == 'admin' ||
            roleStr.contains('administrateur') ||
            roleStr.contains('chef agence') ||
            roleStr.contains('chef_agence') ||
            roleStr.contains('accueil');
      });
    }

    if (user.roles != null && user.roles!.isNotEmpty) {
      return user.roles!.any((r) {
        final roleStr = r.toString().toLowerCase();
        return roleStr.contains('super admin') ||
            roleStr.contains('super_admin') ||
            roleStr == 'admin' ||
            roleStr.contains('administrateur') ||
            roleStr.contains('chef agence') ||
            roleStr.contains('chef_agence') ||
            roleStr.contains('accueil');
      });
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Vérifier l'accès
    if (!authState.isAuthenticated || !_canManageMessages(user)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Accès refusé'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Vous n\'avez pas les permissions nécessaires',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seuls les Super Admin, Admin, Chef agence et Accueil peuvent gérer les messages',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestion des Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Theme.of(context).cardColor : Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'tous', child: Text('Tous')),
                      DropdownMenuItem(
                        value: 'notification',
                        child: Text('Notifications'),
                      ),
                      DropdownMenuItem(
                        value: 'annonce',
                        child: Text('Annonces'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filterType = value;
                        });
                        _loadMessages();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterActive,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'actifs',
                        child: Text('Actifs'),
                      ),
                      DropdownMenuItem(
                        value: 'inactifs',
                        child: Text('Inactifs'),
                      ),
                      DropdownMenuItem(
                        value: 'tous',
                        child: Text('Tous'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filterActive = value;
                        });
                        _loadMessages();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Liste des messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 80,
                              color:
                                  isDark ? Colors.grey[600] : Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun message trouvé',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _filterType == 'annonce'
                                    ? 'Essayez de changer le filtre "Statut" pour voir les annonces inactives ou expirées'
                                    : 'Essayez de changer les filtres pour voir plus de messages',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        color: AppTheme.primaryOrange,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageCard(message);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMessageForm(),
        backgroundColor: AppTheme.primaryOrange,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau message'),
      ),
    );
  }

  Widget _buildMessageCard(MessageModel message) {
    final isNotification = message.isNotification;
    final color = isNotification ? AppTheme.primaryOrange : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showMessageForm(message: message),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec type et statut
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isNotification ? Icons.notifications : Icons.campaign,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isNotification ? 'Notification' : 'Annonce',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge statut (actif/inactif)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: message.active
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.active ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        color: message.active ? Colors.green : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Badge expiré (pour les annonces)
                  if (message.isAnnonce && message.isExpired) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 12, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            'Expiré',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showMessageForm(message: message);
                      } else if (value == 'delete') {
                        _deleteMessage(message);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Titre
              Text(
                message.titre,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),

              // Contenu (preview)
              Text(
                message.contenu,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),

              // Informations supplémentaires
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (message.gare != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          message.gare!.nom,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  if (message.formattedPeriod.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          message.formattedPeriod,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageFormScreen extends StatefulWidget {
  final MessageModel? message;
  final VoidCallback onSaved;

  const MessageFormScreen({
    super.key,
    this.message,
    required this.onSaved,
  });

  @override
  State<MessageFormScreen> createState() => _MessageFormScreenState();
}

class _MessageFormScreenState extends State<MessageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();
  final _uuidController = TextEditingController();
  final MessageApiService _messageService = MessageApiService();

  String _selectedType = 'notification';
  String? _selectedAppareil = 'mobile';
  File? _imageFile; // Fichier image sélectionné
  String? _existingImageUrl; // URL de l'image existante (pour l'affichage)
  bool _shouldDeleteImage =
      false; // Indique si l'image existante doit être supprimée
  final _picker = ImagePicker();
  int? _selectedGareId;
  List<Gare> _gares = []; // Liste des gares disponibles
  bool _isLoadingGares = false;
  String? _uuid;
  bool _uuidAutoFilled =
      false; // Indique si l'UUID a été rempli automatiquement
  final Set<String> _customAppareils =
      {}; // Appareils personnalisés à ajouter au dropdown
  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _active = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGares();
    if (widget.message != null) {
      final msg = widget.message!;
      _titreController.text = msg.titre;
      _contenuController.text = msg.contenu;
      _selectedType = msg.type;
      _selectedAppareil = msg.appareil ?? 'mobile';
      // Si l'appareil du message n'est pas dans la liste standard, l'ajouter
      if (msg.appareil != null &&
          msg.appareil!.isNotEmpty &&
          !['mobile', 'ecran_tv', 'ecran_led', 'tous'].contains(msg.appareil)) {
        _customAppareils.add(msg.appareil!);
      }
      // Image uniquement pour les notifications
      if (msg.type == 'notification' &&
          msg.image != null &&
          msg.image!.isNotEmpty) {
        _existingImageUrl = msg.image;
        _imageFile = null; // Pas de fichier local, juste l'URL existante
        _shouldDeleteImage = false; // Pas de suppression par défaut
      } else {
        _existingImageUrl = null;
        _imageFile = null;
        _shouldDeleteImage = false;
      }
      // Gare, UUID, appareil uniquement pour les annonces
      if (msg.type == 'annonce') {
        _selectedGareId = msg.gareId;
        _uuid = msg.uuid;
        _uuidController.text = msg.uuid ?? '';
        _uuidAutoFilled = false; // Pas auto-rempli lors de l'édition
        _dateDebut = msg.dateDebut;
        _dateFin = msg.dateFin;
      } else {
        // Pour les notifications, réinitialiser ces champs
        _selectedGareId = null;
        _uuid = null;
        _uuidController.clear();
        _uuidAutoFilled = false;
        _dateDebut = null;
        _dateFin = null;
      }
      _active = msg.active;
    }
  }

  Future<void> _loadGares() async {
    setState(() {
      _isLoadingGares = true;
    });
    try {
      final gares = await _messageService.getGares();
      if (mounted) {
        setState(() {
          _gares = gares;
          _isLoadingGares = false;

          // Si on est en mode édition et que la gare sélectionnée n'existe pas dans la liste,
          // réinitialiser _selectedGareId
          if (widget.message != null &&
              _selectedGareId != null &&
              !gares.any((g) => g.id == _selectedGareId)) {
            debugPrint(
                '⚠️ Gare ID $_selectedGareId non trouvée dans la liste, réinitialisation');
            _selectedGareId = null;
          }
        });
        debugPrint('✅ ${gares.length} gares chargées');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGares = false;
        });
        debugPrint('❌ Erreur chargement gares: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des gares: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _contenuController.dispose();
    _uuidController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _existingImageUrl =
              null; // Réinitialiser l'URL existante si on sélectionne une nouvelle image
          _shouldDeleteImage = false; // Réinitialiser le flag de suppression
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(
    bool isStartDate,
  ) async {
    if (!mounted) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_dateDebut ?? DateTime.now())
          : (_dateFin ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && mounted) {
        final DateTime dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartDate) {
            _dateDebut = dateTime;
          } else {
            _dateFin = dateTime;
          }
        });
      }
    }
  }

  Future<void> _saveMessage() async {
    // Validation spécifique pour les annonces
    if (_selectedType == 'annonce') {
      if (_dateDebut == null || _dateFin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Les dates de début et de fin sont obligatoires pour les annonces'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!_dateFin!.isAfter(_dateDebut!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La date de fin doit être après la date de début'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (widget.message != null) {
        // Mise à jour
        result = await _messageService.updateMessage(
          id: widget.message!.id,
          titre: _titreController.text.trim(),
          contenu: _contenuController.text.trim(),
          type: _selectedType,
          // Image uniquement pour les notifications
          imageFile: _selectedType == 'notification' ? _imageFile : null,
          shouldDeleteImage: _selectedType == 'notification'
              ? (_shouldDeleteImage && _imageFile == null)
              : false,
          // Gare, appareil, UUID uniquement pour les annonces
          gareId: _selectedType == 'annonce' ? _selectedGareId : null,
          appareil: _selectedType == 'annonce' ? _selectedAppareil : null,
          uuid: _selectedType == 'annonce' ? _uuid : null,
          // Dates uniquement pour les annonces
          dateDebut: _selectedType == 'annonce' ? _dateDebut : null,
          dateFin: _selectedType == 'annonce' ? _dateFin : null,
          active: _active,
        );
      } else {
        // Création
        result = await _messageService.createMessage(
          titre: _titreController.text.trim(),
          contenu: _contenuController.text.trim(),
          type: _selectedType,
          // Image uniquement pour les notifications
          imageFile: _selectedType == 'notification' ? _imageFile : null,
          // Gare, appareil, UUID uniquement pour les annonces
          gareId: _selectedType == 'annonce' ? _selectedGareId : null,
          appareil: _selectedType == 'annonce' ? _selectedAppareil : null,
          uuid: _selectedType == 'annonce' ? _uuid : null,
          // Dates uniquement pour les annonces
          dateDebut: _selectedType == 'annonce' ? _dateDebut : null,
          dateFin: _selectedType == 'annonce' ? _dateFin : null,
          active: _active,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Message enregistré avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSaved();
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Erreur lors de l\'enregistrement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.message != null ? 'Modifier le message' : 'Nouveau message',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveMessage,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'notification',
                    child: Text('Notification'),
                  ),
                  DropdownMenuItem(
                    value: 'annonce',
                    child: Text('Annonce'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      // Si on passe à "notification", réinitialiser les champs spécifiques aux annonces
                      if (value == 'notification') {
                        _selectedGareId = null;
                        _selectedAppareil = 'mobile';
                        _uuid = null;
                        _uuidController.clear();
                        _uuidAutoFilled = false;
                        // Les annonces n'ont pas d'image, donc on garde l'image si on passe à notification
                      } else if (value == 'annonce') {
                        // Si on passe à "annonce", supprimer l'image (les annonces n'ont pas d'image)
                        _imageFile = null;
                        _existingImageUrl = null;
                        _shouldDeleteImage = false;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Titre
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contenu
              TextFormField(
                controller: _contenuController,
                decoration: const InputDecoration(
                  labelText: 'Contenu *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le contenu est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sélection d'image (uniquement pour les notifications)
              if (_selectedType == 'notification') ...[
                Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: _pickImage,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.image,
                                  color: AppTheme.primaryOrange),
                              const SizedBox(width: 12),
                              Text(
                                _selectedType == 'notification'
                                    ? 'Image de la notification'
                                    : 'Image de l\'annonce',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_imageFile != null) ...[
                            // Afficher la nouvelle image sélectionnée
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _imageFile!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _imageFile = null;
                                });
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Supprimer l\'image'),
                            ),
                          ] else if (_existingImageUrl != null &&
                              _existingImageUrl!.isNotEmpty) ...[
                            // Afficher l'image existante
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _existingImageUrl!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[300],
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: isDark
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Remplacer'),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _existingImageUrl = null;
                                      _shouldDeleteImage =
                                          true; // Marquer pour suppression
                                    });
                                  },
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  label: const Text('Supprimer',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                    width: 2,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(8),
                                color: isDark
                                    ? Colors.grey[900]
                                    : Colors.grey[100],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: isDark
                                          ? Colors.grey[600]
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Appuyez pour sélectionner une image',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Gare, Appareil et UUID (uniquement pour les annonces)
              if (_selectedType == 'annonce') ...[
                // Gare (optionnel)
                DropdownButtonFormField<int>(
                  initialValue: _selectedGareId != null &&
                          _gares.any((g) => g.id == _selectedGareId)
                      ? _selectedGareId
                      : null, // Ne pas utiliser la valeur si elle n'existe pas dans la liste
                  decoration: const InputDecoration(
                    labelText: 'Gare (optionnel)',
                    border: OutlineInputBorder(),
                    helperText: 'Sélectionner une gare pour cibler le message',
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Aucune gare (pour tous)'),
                    ),
                    // Utiliser toSet() pour éviter les doublons, puis mapper
                    ..._gares.map((g) => g.id).toSet().map((gareId) {
                      final gare = _gares.firstWhere((g) => g.id == gareId);
                      return DropdownMenuItem<int>(
                        value: gare.id,
                        child: Text(gare.nom),
                      );
                    }),
                  ],
                  onChanged: _isLoadingGares
                      ? null
                      : (value) {
                          setState(() {
                            _selectedGareId = value;
                            // Remplir automatiquement l'UUID et l'appareil de la gare sélectionnée
                            if (value != null) {
                              final selectedGare = _gares.firstWhere(
                                (gare) => gare.id == value,
                                orElse: () => _gares.first,
                              );
                              // Remplir l'UUID si la gare en a un
                              if (selectedGare.uuid != null &&
                                  selectedGare.uuid!.isNotEmpty) {
                                _uuid = selectedGare.uuid;
                                _uuidController.text = selectedGare.uuid!;
                                _uuidAutoFilled = true;
                              } else {
                                _uuid = null;
                                _uuidController.clear();
                                _uuidAutoFilled = false;
                              }
                              // Remplir l'appareil si la gare en a un
                              if (selectedGare.appareil != null &&
                                  selectedGare.appareil!.isNotEmpty) {
                                _selectedAppareil = selectedGare.appareil;
                                // Ajouter l'appareil personnalisé à la liste si nécessaire
                                if (!['mobile', 'ecran_tv', 'ecran_led', 'tous']
                                    .contains(selectedGare.appareil)) {
                                  _customAppareils.add(selectedGare.appareil!);
                                }
                              }
                            } else {
                              // Si aucune gare n'est sélectionnée, réinitialiser le flag
                              _uuidAutoFilled = false;
                              // Ne pas vider l'UUID manuellement saisi
                            }
                          });
                        },
                ),
                const SizedBox(height: 16),

                // Appareil (peut être une valeur personnalisée depuis la gare)
                DropdownButtonFormField<String>(
                  initialValue: _selectedAppareil,
                  decoration: const InputDecoration(
                    labelText: 'Appareil (optionnel)',
                    border: OutlineInputBorder(),
                    helperText:
                        'mobile, ecran_tv, ecran_led, tous, ou valeur personnalisée',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'mobile',
                      child: Text('Mobile'),
                    ),
                    const DropdownMenuItem(
                      value: 'ecran_tv',
                      child: Text('Écran TV'),
                    ),
                    const DropdownMenuItem(
                      value: 'ecran_led',
                      child: Text('Écran LED'),
                    ),
                    const DropdownMenuItem(
                      value: 'tous',
                      child: Text('Tous'),
                    ),
                    // Ajouter les appareils personnalisés (de la gare ou du message existant)
                    ..._customAppareils.map((appareil) {
                      // Trouver la gare correspondante si elle existe
                      final gare = _gares.firstWhere(
                        (g) => g.appareil == appareil,
                        orElse: () => Gare(id: 0, nom: '', appareil: appareil),
                      );
                      return DropdownMenuItem(
                        value: appareil,
                        child: Text(gare.nom.isNotEmpty
                            ? '$appareil (${gare.nom})'
                            : appareil),
                      );
                    }),
                    // Ajouter l'appareil de la gare sélectionnée s'il n'est pas déjà dans la liste
                    if (_selectedGareId != null)
                      ..._gares
                          .where((gare) =>
                              gare.id == _selectedGareId &&
                              gare.appareil != null &&
                              gare.appareil!.isNotEmpty &&
                              !['mobile', 'ecran_tv', 'ecran_led', 'tous']
                                  .contains(gare.appareil) &&
                              !_customAppareils.contains(gare.appareil))
                          .map((gare) => DropdownMenuItem(
                                value: gare.appareil,
                                child: Text('${gare.appareil} (${gare.nom})'),
                              )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAppareil = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // UUID (optionnel) - rempli automatiquement si une gare est sélectionnée
                TextFormField(
                  controller: _uuidController,
                  decoration: InputDecoration(
                    labelText: 'UUID (optionnel)',
                    border: const OutlineInputBorder(),
                    hintText: 'UUID de l\'appareil cible',
                    helperText: _uuidAutoFilled
                        ? 'Rempli automatiquement depuis la gare sélectionnée'
                        : 'Saisir manuellement ou sélectionner une gare',
                    suffixIcon: _uuidAutoFilled
                        ? const Icon(Icons.auto_awesome,
                            color: Colors.green, size: 20)
                        : null,
                  ),
                  readOnly:
                      _uuidAutoFilled, // Lecture seule si rempli automatiquement
                  onChanged: (value) {
                    setState(() {
                      _uuid = value.trim().isEmpty ? null : value.trim();
                      // Si l'utilisateur modifie manuellement, désactiver le flag
                      if (_uuidAutoFilled) {
                        _uuidAutoFilled = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Date de début (obligatoire pour annonces)
                InkWell(
                  onTap: () => _selectDate(true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date de début *',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      errorText: _dateDebut == null
                          ? 'La date de début est obligatoire pour les annonces'
                          : null,
                    ),
                    child: Text(
                      _dateDebut != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(_dateDebut!)
                          : 'Sélectionner une date',
                      style: TextStyle(
                        color: _dateDebut != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date de fin (obligatoire pour annonces)
                InkWell(
                  onTap: () => _selectDate(false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date de fin *',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      errorText: _dateFin == null
                          ? 'La date de fin est obligatoire pour les annonces'
                          : null,
                      helperText: _dateDebut != null &&
                              _dateFin != null &&
                              !_dateFin!.isAfter(_dateDebut!)
                          ? 'La date de fin doit être après la date de début'
                          : null,
                    ),
                    child: Text(
                      _dateFin != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(_dateFin!)
                          : 'Sélectionner une date',
                      style: TextStyle(
                        color: _dateFin != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Statut actif
              SwitchListTile(
                title: const Text('Message actif'),
                subtitle: const Text('Le message sera visible s\'il est actif'),
                value: _active,
                onChanged: (value) {
                  setState(() {
                    _active = value;
                  });
                },
                activeThumbColor: AppTheme.primaryOrange,
              ),
              const SizedBox(height: 24),

              // Bouton Enregistrer
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Enregistrer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
