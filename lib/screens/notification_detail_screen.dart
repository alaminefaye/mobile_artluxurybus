import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../theme/app_theme.dart';
import '../providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_page.dart';
import 'my_trips_screen.dart';
import 'loyalty_home_screen.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  ConsumerState<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends ConsumerState<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Marquer comme lue automatiquement quand on ouvre les détails
    if (!widget.notification.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationProvider.notifier).markAsRead(widget.notification.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail notification'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmation(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône et statut
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Titre
            _buildTitle(),
            const SizedBox(height: 16),
            
            // Message principal
            _buildMessage(),
            const SizedBox(height: 24),
            
            // Informations supplémentaires
            if (widget.notification.data != null && widget.notification.data!.isNotEmpty)
              _buildAdditionalInfo(),
            
            const SizedBox(height: 24),
            
            // Bouton d'action selon le type de notification
            _buildActionButton(),
            
            const SizedBox(height: 24),
            
            // Informations de timing
            _buildTimingInfo(),
            
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getTypeColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getTypeIcon(),
            color: _getTypeColor(),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTypeLabel(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.notification.isRead 
                    ? Colors.green.withValues(alpha: 0.1)
                    : AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.notification.isRead ? 'Lu' : 'Non lu',
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.notification.isRead ? Colors.green[700] : AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.notification.title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }

  Widget _buildMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        widget.notification.message,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    final data = widget.notification.data!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations détaillées',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...data.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${_formatDataKey(entry.key)}:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildValueWithAction(entry.key, entry.value.toString()),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    // Bouton pour les notifications de ticket
    if (widget.notification.type == 'new_ticket') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _navigateToTickets,
          icon: const Icon(Icons.confirmation_number, color: Colors.white),
          label: const Text(
            'Voir le ticket',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      );
    }
    
    // Bouton pour les notifications de points de fidélité
    if (widget.notification.type == 'loyalty_point') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _navigateToLoyalty,
          icon: const Icon(Icons.card_giftcard, color: Colors.white),
          label: const Text(
            'Voir mes points',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      );
    }
    
    // Pas de bouton pour les autres types
    return const SizedBox.shrink();
  }

  void _navigateToTickets() {
    // Naviguer directement vers l'écran Mes Trajets
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MyTripsScreen(),
      ),
    );
  }

  void _navigateToLoyalty() {
    // Navigation vers l'écran de fidélité
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoyaltyHomeScreen(),
      ),
    );
  }

  Widget _buildTimingInfo() {
    final formatter = DateFormat('dd/MM/yyyy à HH:mm');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations temporelles',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Reçue le', formatter.format(widget.notification.createdAt)),
          if (widget.notification.readAt != null)
            _buildInfoRow('Lue le', formatter.format(widget.notification.readAt!)),
          _buildInfoRow('Il y a', widget.notification.getTimeAgo()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildValueWithAction(String key, String value) {
    // Vérifier si c'est un numéro de téléphone
    if (key.toLowerCase().contains('phone') || key.toLowerCase().contains('telephone')) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _makePhoneCall(value),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.phone,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
    
    // Vérifier si c'est la liste des bus (JSON)
    if (key.toLowerCase() == 'bus' && value.startsWith('[')) {
      try {
        final List<dynamic> busList = json.decode(value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: busList.map((bus) {
            final statut = bus['statut'] ?? '';
            final emoji = statut == 'overdue' ? '🔴' : statut == 'urgent' ? '🟠' : '🟡';
            final joursRestants = bus['jours_restants'] ?? 0;
            final texteJours = joursRestants < 0 
                ? '${joursRestants.abs()} jour(s) de retard' 
                : '$joursRestants jour(s) restant(s)';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '$emoji ${bus['immatriculation']} - $texteJours',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        );
      } catch (e) {
        // Si le parsing échoue, afficher tel quel
        return Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      }
    }
    
    // Pour les autres types de données, affichage normal
    return Text(
      value,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Nettoyer le numéro de téléphone (garder seulement les chiffres et le +)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Vérifier que le numéro n'est pas vide après nettoyage
      if (cleanNumber.isEmpty) {
        _showErrorMessage('Numéro de téléphone invalide');
        return;
      }
      
      // Créer l'URI pour l'appel
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
      
      // Vérifier si l'appareil peut faire des appels
      if (await canLaunchUrl(phoneUri)) {
        // Lancer l'appel
        final success = await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!success) {
          _showErrorMessage('Impossible d\'ouvrir l\'application de téléphone');
        }
      } else {
        // L'appareil ne peut pas faire d'appels (ex: simulateur, tablette sans téléphonie)
        _showInfoMessage('Appel vers $cleanNumber\n(Fonctionnalité disponible sur appareil réel)');
      }
    } catch (e) {
      // Erreur générale
      _showErrorMessage('Erreur lors de l\'appel téléphonique: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la notification'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette notification ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).deleteNotification(widget.notification.id);
              Navigator.pop(context); // Fermer la dialog
              Navigator.pop(context); // Retourner à la liste
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  IconData _getTypeIcon() {
    switch (widget.notification.getIconType()) {
      case 'feedback':
        return Icons.feedback_outlined;
      case 'status':
        return Icons.update;
      case 'offer':
        return Icons.local_offer;
      case 'travel':
        return Icons.schedule;
      case 'points':
        return Icons.card_giftcard;
      case 'alert':
        return Icons.warning_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getTypeColor() {
    switch (widget.notification.getIconType()) {
      case 'feedback':
        return Colors.blue;
      case 'status':
        return Colors.orange;
      case 'offer':
        return Colors.purple;
      case 'travel':
        return Colors.green;
      case 'points':
        return Colors.amber;
      case 'alert':
        return Colors.red;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _getTypeLabel() {
    switch (widget.notification.type.toLowerCase()) {
      case 'new_ticket':
        return 'Nouveau ticket';
      case 'loyalty_point':
        return 'Point de fidélité';
      case 'new_feedback':
        return 'Nouvelle suggestion';
      case 'feedback_status':
        return 'Changement de statut';
      case 'promotion':
      case 'offer':
        return 'Offre promotionnelle';
      case 'reminder':
      case 'travel':
        return 'Rappel de voyage';
      case 'loyalty':
      case 'points':
        return 'Programme fidélité';
      case 'alert':
      case 'urgent':
        return 'Alerte importante';
      default:
        return 'Notification';
    }
  }

  String _formatDataKey(String key) {
    switch (key.toLowerCase()) {
      // Tickets
      case 'ticket_id':
        return 'Ticket Id';
      case 'depart_id':
        return 'Depart Id';
      case 'seat_number':
        return 'Numéro siège';
      case 'embarquement':
        return 'Embarquement';
      case 'destination':
        return 'Destination';
      // Loyalty
      case 'points_earned':
        return 'Points gagnés';
      case 'total_points':
        return 'Total points';
      case 'client_profile_id':
        return 'Client ID';
      case 'description':
        return 'Description';
      // Feedback
      case 'feedback_id':
        return 'ID Suggestion';
      case 'customer_name':
        return 'Nom client';
      case 'customer_phone':
        return 'Téléphone client';
      case 'priority':
        return 'Priorité';
      case 'subject':
        return 'Sujet';
      case 'source':
        return 'Source';
      case 'created_at':
        return 'Créé le';
      case 'feedback_priority':
        return 'Priorité';
      case 'feedback_status':
        return 'Statut';
      case 'sent_by':
        return 'Envoyé par';
      case 'timestamp':
        return 'Horodatage';
      case 'promo_code':
        return 'Code promo';
      case 'discount':
        return 'Réduction';
      case 'valid_until':
        return 'Valide jusqu\'au';
      case 'departure_time':
        return 'Heure départ';
      case 'route':
        return 'Trajet';
      case 'maintenance_start':
        return 'Début maintenance';
      case 'maintenance_end':
        return 'Fin maintenance';
      // Vidanges
      case 'nombre_en_retard':
      case 'overdue_count':
        return 'En retard';
      case 'nombre_urgent':
      case 'urgent_count':
        return 'Urgent';
      case 'nombre_attention':
      case 'warning_count':
        return 'À surveiller';
      case 'nombre_total':
      case 'total_count':
        return 'Total';
      case 'bus':
        return 'Bus concernés';
      case 'horodatage':
        return 'Horodatage';
      // Vidange effectuée
      case 'bus_id':
        return 'ID Bus';
      case 'bus_immatriculation':
        return 'Immatriculation';
      case 'derniere_vidange':
        return 'Dernière vidange';
      case 'prochaine_vidange':
        return 'Prochaine vidange';
      case 'jours_restants':
        return 'Jours restants';
      default:
        // Remplacer les underscores par des espaces et mettre en forme
        return key.replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
            .join(' ');
    }
  }
}
