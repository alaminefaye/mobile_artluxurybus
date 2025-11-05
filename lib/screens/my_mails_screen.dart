import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/mail_model.dart';
import '../services/mail_api_service.dart';
import '../theme/app_theme.dart';

class MyMailsScreen extends StatefulWidget {
  const MyMailsScreen({super.key});

  @override
  State<MyMailsScreen> createState() => _MyMailsScreenState();
}

class _MyMailsScreenState extends State<MyMailsScreen> {
  List<MailModel> _mails = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _sentCount = 0;
  int _receivedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMails();
  }

  Future<void> _loadMails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('📡 [MyMailsScreen] Chargement des courriers...');
      final response = await MailApiService.getMyMails();
      debugPrint('📡 [MyMailsScreen] Réponse reçue: count=${response.count}, sent=${response.sentCount}, received=${response.receivedCount}');
      
      setState(() {
        _mails = response.mails;
        _sentCount = response.sentCount;
        _receivedCount = response.receivedCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement courriers: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mes Courriers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMails,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMails,
        color: AppTheme.primaryOrange,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryOrange,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadMails,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_mails.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 80,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun courrier',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous n\'avez pas encore de courriers enregistrés.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Afficher un message informatif
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pour voir vos courriers, vous devez avoir un profil client associé à votre compte.'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Plus d\'informations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Header avec statistiques
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryOrange,
                  AppTheme.primaryOrange.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${_mails.length}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _mails.length > 1 ? 'Courriers' : 'Courrier',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Expédiés', _sentCount, Icons.send_rounded),
                    _buildStatItem('Reçus', _receivedCount, Icons.inbox_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Liste des courriers
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final mail = _mails[index];
              return _buildMailCard(mail);
            },
            childCount: _mails.length,
          ),
        ),

        // Espace en bas
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMailCard(MailModel mail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Utiliser les indicateurs isSent et isReceived de l'API, sinon fallback sur la logique
    final isSentMail = mail.isSent ?? 
                       (mail.clientProfile != null && mail.clientProfileId == mail.clientProfile?.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: mail.isCollected
            ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mail.isCollected
              ? Colors.green.withValues(alpha: 0.3)
              : AppTheme.primaryOrange.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showMailDetails(mail),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSentMail ? Icons.send_rounded : Icons.inbox_rounded,
                              size: 16,
                              color: isSentMail 
                                  ? AppTheme.primaryOrange 
                                  : AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isSentMail ? 'Expédié' : 'Reçu',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSentMail 
                                    ? AppTheme.primaryOrange 
                                    : AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mail.mailNumber,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: mail.isCollected
                                ? Colors.grey[600]
                                : Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vers ${mail.destination}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (mail.isCollected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Collecté',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Informations du courrier
              Row(
                children: [
                  // Expéditeur/Destinataire
                  Expanded(
                    child: _buildInfoItem(
                      icon: isSentMail ? Icons.person_outline_rounded : Icons.person_rounded,
                      label: isSentMail ? 'Destinataire' : 'Expéditeur',
                      value: isSentMail ? mail.recipientName : mail.senderName,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Montant
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.monetization_on_rounded,
                      label: 'Montant',
                      value: '${mail.amount.toStringAsFixed(0)} FCFA',
                      color: Colors.amber[700]!,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Type de colis et date
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Type',
                      value: mail.packageType,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: _formatDate(mail.createdAt),
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showMailDetails(MailModel mail) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MailDetailScreen(mail: mail),
      ),
    );
  }
}

/// Écran de détail d'un courrier
class MailDetailScreen extends StatelessWidget {
  final MailModel mail;

  const MailDetailScreen({super.key, required this.mail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du courrier'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Numéro de courrier
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping_rounded,
                      color: AppTheme.primaryOrange,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Numéro de courrier',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            mail.mailNumber,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informations expéditeur
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expéditeur',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Nom', mail.senderName),
                    _buildDetailRow('Téléphone', mail.senderPhone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informations destinataire
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destinataire',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Nom', mail.recipientName),
                    _buildDetailRow('Téléphone', mail.recipientPhone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informations du colis
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations du colis',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Destination', mail.destination),
                    _buildDetailRow('Type de colis', mail.packageType),
                    _buildDetailRow('Valeur déclarée', mail.packageValue),
                    _buildDetailRow('Montant', '${mail.amount.toStringAsFixed(0)} FCFA'),
                    _buildDetailRow('Agence de réception', mail.receivingAgency),
                    if (mail.description != null)
                      _buildDetailRow('Description', mail.description!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statut
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statut',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          mail.isCollected
                              ? Icons.check_circle_rounded
                              : Icons.pending_rounded,
                          color: mail.isCollected ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mail.isCollected ? 'Collecté' : 'En attente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: mail.isCollected ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    if (mail.isCollected && mail.collectedAt != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Date de collecte',
                        '${mail.collectedAt!.day}/${mail.collectedAt!.month}/${mail.collectedAt!.year} à ${mail.collectedAt!.hour}:${mail.collectedAt!.minute.toString().padLeft(2, '0')}',
                      ),
                      if (mail.collectorName != null)
                        _buildDetailRow('Collecté par', mail.collectorName!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dates',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Date d\'envoi',
                      '${mail.createdAt.day}/${mail.createdAt.month}/${mail.createdAt.year} à ${mail.createdAt.hour}:${mail.createdAt.minute.toString().padLeft(2, '0')}',
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

