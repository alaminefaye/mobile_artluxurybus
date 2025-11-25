import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../theme/app_theme.dart';
import '../providers/notification_provider.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';
import '../utils/error_message_helper.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'my_trips_screen.dart';
import 'loyalty_home_screen.dart';
import 'my_mails_screen.dart';
import 'admin/feedback_list_screen.dart';
import 'expense_management_screen.dart';

import '../services/expense_service.dart';
import '../services/job_application_api_service.dart';
import 'admin/job_application_detail_screen.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  @override
  void initState() {
    super.initState();
    // Marquer comme lue automatiquement quand on ouvre les détails
    if (!widget.notification.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(notificationProvider.notifier)
            .markAsRead(widget.notification.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t('notification_detail.title')),
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

            // Image (si disponible dans les données)
            if (widget.notification.data != null &&
                widget.notification.data!.containsKey('image') &&
                widget.notification.data!['image'] != null &&
                widget.notification.data!['image'].toString().isNotEmpty)
              _buildNotificationImage(),

            // Informations supplémentaires
            if (widget.notification.data != null &&
                widget.notification.data!.isNotEmpty)
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

  // Fonction helper pour obtenir la couleur primaire selon le thème
  // Orange en mode dark, bleu en mode light
  Color _getNotificationPrimaryColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue;
  }

  Widget _buildHeader() {
    final primaryColor = _getNotificationPrimaryColor();
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
                      : primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.notification.isRead
                      ? t('notification_detail.read')
                      : t('notification_detail.unread'),
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.notification.isRead
                        ? Colors.green[700]
                        : primaryColor,
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

  /// Traduire le titre et le message d'une notification basé sur son type et ses données
  Map<String, String> _translateNotification(NotificationModel notification) {
    final type = notification.type.toLowerCase();
    final data = notification.data ?? {};

    String translatedTitle = notification.title;
    String translatedMessage = notification.message;

    // Utiliser la même logique que dans home_page.dart
    switch (type) {
      case 'new_ticket':
      case 'ticket_created':
        translatedTitle = t('notifications.new_ticket_title');
        String route = '';
        if (data.containsKey('destination') &&
            data.containsKey('embarquement')) {
          route = '${data['embarquement']} → ${data['destination']}';
        } else if (data.containsKey('trajet')) {
          final trajet = data['trajet'];
          if (trajet is Map) {
            route =
                '${trajet['embarquement'] ?? ''} → ${trajet['destination'] ?? ''}';
          }
        }
        if (route.isEmpty) {
          final message = notification.message;
          final lowerMsg = message.toLowerCase();
          final idxPour = lowerMsg.indexOf('pour ');
          final idxAEte = lowerMsg.indexOf('a été', idxPour + 5);
          if (idxPour != -1 && idxAEte != -1) {
            route = message.substring(idxPour + 5, idxAEte).trim();
          }
        }
        translatedMessage = t('notifications.new_ticket_message')
            .replaceAll('{{route}}', route);
        break;

      case 'loyalty_point':
      case 'points':
      case 'loyalty':
        translatedTitle = t('notifications.loyalty_point_title');
        int points = 1;
        if (data.containsKey('points_earned')) {
          points = int.tryParse(data['points_earned'].toString()) ?? 1;
        } else if (data.containsKey('points')) {
          points = int.tryParse(data['points'].toString()) ?? 1;
        }
        translatedMessage = t('notifications.loyalty_point_message')
            .replaceAll('{{points}}', points.toString());
        break;

      case 'new_mail_sender':
      case 'mail_created':
        translatedTitle = t('notifications.mail_created_title');
        String destination = data['destination']?.toString() ?? '';
        String number =
            data['mail_number']?.toString() ?? data['number']?.toString() ?? '';
        translatedMessage = t('notifications.mail_created_message')
            .replaceAll('{{destination}}', destination)
            .replaceAll('{{number}}', number);
        break;

      case 'new_mail_recipient':
      case 'mail_received':
        translatedTitle = t('notifications.mail_received_title');
        String sender =
            data['sender']?.toString() ?? data['expediteur']?.toString() ?? '';
        String destination = data['destination']?.toString() ?? '';
        String number =
            data['mail_number']?.toString() ?? data['number']?.toString() ?? '';
        translatedMessage = t('notifications.mail_received_message')
            .replaceAll('{{sender}}', sender)
            .replaceAll('{{destination}}', destination)
            .replaceAll('{{number}}', number);
        break;

      case 'mail_collected':
        translatedTitle = t('notifications.mail_collected_title');
        String number =
            data['mail_number']?.toString() ?? data['number']?.toString() ?? '';
        translatedMessage = t('notifications.mail_collected_message')
            .replaceAll('{{number}}', number);
        break;

      case 'departure_time_changed':
      case 'departure_modified':
      case 'departure_updated':
        translatedTitle = t('notifications.departure_changed_title');
        String route = data['route']?.toString() ?? '';
        String time = data['new_time']?.toString() ??
            data['heure_depart']?.toString() ??
            '';
        translatedMessage = t('notifications.departure_changed_message')
            .replaceAll('{{route}}', route)
            .replaceAll('{{time}}', time);
        break;

      default:
        // Pour les autres types, utiliser les textes originaux
        break;
    }

    return {
      'title': translatedTitle,
      'message': translatedMessage,
    };
  }

  Widget _buildTitle() {
    final translated = _translateNotification(widget.notification);
    return Text(
      translated['title'] ?? widget.notification.title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }

  Widget _buildMessage() {
    final translated = _translateNotification(widget.notification);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        translated['message'] ?? widget.notification.message,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildNotificationImage() {
    final imageUrl = widget.notification.data!['image']?.toString() ?? '';
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[300],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.grey, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Impossible de charger l\'image',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    final data = widget.notification.data!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('notification_detail.detailed_info'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final primaryColor = _getNotificationPrimaryColor();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...data.entries
                      .where((entry) =>
                          entry.key.toLowerCase() !=
                          'image') // Exclure l'image de cette section
                      .map((entry) => Padding(
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
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _buildValueWithAction(
                                      entry.key, entry.value.toString()),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    // Bouton pour les notifications de ticket
    if (widget.notification.type == 'new_ticket') {
      final primaryColor = _getNotificationPrimaryColor();
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _navigateToTickets,
          icon: const Icon(Icons.confirmation_number, color: Colors.white),
          label: Text(
            t('notification_detail.view_ticket'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
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
          label: Text(
            t('notification_detail.view_points'),
            style: const TextStyle(
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

    // Bouton pour les notifications de courrier
    if (widget.notification.type == 'new_mail_sender' ||
        widget.notification.type == 'new_mail_recipient' ||
        widget.notification.type == 'mail_collected' ||
        widget.notification.type == 'mail_created' ||
        widget.notification.type == 'mail_received') {
      final primaryColor = _getNotificationPrimaryColor();
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _navigateToMails,
          icon: const Icon(Icons.mail, color: Colors.white),
          label: Text(
            t('notification_detail.view_mail'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      );
    }

    // Bouton pour les notifications de modification de départ
    if (widget.notification.type == 'departure_time_changed' ||
        widget.notification.type == 'departure_modified' ||
        widget.notification.type == 'departure_updated' ||
        widget.notification.type == 'departure_cancelled') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _navigateToTrips,
          icon: const Icon(Icons.directions_bus, color: Colors.white),
          label: Text(
            t('notification_detail.view_trips'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      );
    }

    // Bouton pour les notifications de suggestions/préoccupations
    if (widget.notification.type == 'new_feedback' ||
        widget.notification.type == 'urgent_feedback') {
      final feedbackId = int.tryParse(
          widget.notification.data?['feedback_id']?.toString() ?? '');
      final primaryColor = _getNotificationPrimaryColor();
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FeedbackListScreen(
                  initialFeedbackId: feedbackId,
                ),
              ),
            );
          },
          icon: const Icon(Icons.feedback, color: Colors.white),
          label: const Text(
            'Ouvrir la suggestion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      );
    }

    // Boutons pour les notifications de dépense
    if (widget.notification.type == 'expense_pending' ||
        widget.notification.type == 'new_expense') {
      return Column(
        children: [
          // Bouton Valider la dépense
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _validateExpenseFromNotification(),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'Valider la dépense',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Bouton Voir les dépenses en attente
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _navigateToPendingExpenses,
              icon: const Icon(Icons.pending_actions),
              label: const Text(
                'Voir les dépenses en attente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Bouton pour les notifications de candidatures
    if (widget.notification.type == 'new_job_application') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _viewJobApplicationDetails(),
          icon: const Icon(Icons.folder_open, color: Colors.white),
          label: const Text(
            'Voir le dossier complet',
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

    // Pas de bouton pour les autres types
    return const SizedBox.shrink();
  }

  void _navigateToMails() {
    // Import nécessaire pour MyMailsScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          // Utiliser le nom complet du package pour éviter les erreurs
          return const MyMailsScreen();
        },
      ),
    );
  }

  void _navigateToTrips() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MyTripsScreen(),
      ),
    );
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

  Future<void> _viewJobApplicationDetails() async {
    // Récupérer l'ID de la candidature depuis les données de notification
    final data = widget.notification.data;
    if (data == null || !data.containsKey('job_application_id')) {
      _showErrorMessage('ID de candidature introuvable');
      return;
    }

    final jobApplicationId =
        int.tryParse(data['job_application_id'].toString());
    if (jobApplicationId == null) {
      _showErrorMessage('ID de candidature invalide');
      return;
    }

    // Afficher un indicateur de chargement
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Récupérer les détails de la candidature
      final details = await JobApplicationApiService.details(jobApplicationId);

      if (!mounted) return;
      Navigator.pop(context); // Fermer l'indicateur de chargement

      // Ouvrir la page de détails
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobApplicationDetailScreen(details: details),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fermer l'indicateur de chargement
      _showErrorMessage(
        ErrorMessageHelper.getOperationError('charger', error: e),
      );
    }
  }

  void _navigateToPendingExpenses() {
    // Navigation vers l'écran des dépenses en attente
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const ExpenseManagementScreen(showPendingOnly: true),
      ),
    );
  }

  Future<void> _validateExpenseFromNotification() async {
    // Récupérer l'ID de la dépense depuis les données de notification
    final data = widget.notification.data;
    if (data == null || !data.containsKey('expense_id')) {
      _showErrorMessage('ID de dépense introuvable');
      return;
    }

    final expenseId = int.tryParse(data['expense_id'].toString());
    if (expenseId == null) {
      _showErrorMessage('ID de dépense invalide');
      return;
    }

    // Afficher un dialog de confirmation avec possibilité d'ajouter un commentaire
    final commentaireController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Valider la dépense',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous valider cette dépense ?',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentaireController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Commentaire (optionnel)',
                labelStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.primaryOrange.withValues(alpha: 0.5)
                        : Colors.grey,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: AppTheme.primaryOrange, width: 2),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'commentaire': commentaireController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (!mounted) return;
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final validateResult = await ExpenseService.validateExpense(
          id: expenseId,
          commentaire: result['commentaire'],
        );

        if (mounted) {
          if (!context.mounted) return;
          Navigator.pop(context); // Fermer l'indicateur de chargement

          if (validateResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  validateResult['message'] ?? 'Dépense validée avec succès.',
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Retourner à l'écran précédent après validation
            Navigator.pop(context);
          } else {
            _showErrorMessage(
              validateResult['message'] ??
                  'Erreur lors de la validation de la dépense.',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          if (context.mounted) {
            Navigator.pop(context); // Fermer l'indicateur de chargement
          }
          _showErrorMessage(
            ErrorMessageHelper.getOperationError('valider', error: e),
          );
        }
      }
    }
  }

  Widget _buildTimingInfo() {
    // Utiliser le format de date selon la langue
    final locale = ref.watch(languageProvider);
    final datePattern = locale.languageCode == 'fr'
        ? 'dd/MM/yyyy à HH:mm'
        : 'MM/dd/yyyy at HH:mm';
    final formatter = DateFormat(datePattern);

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
            t('notification_detail.timing_info'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(t('notification_detail.received_on'),
              formatter.format(widget.notification.createdAt)),
          if (widget.notification.readAt != null)
            _buildInfoRow(t('notification_detail.read_on'),
                formatter.format(widget.notification.readAt!)),
          _buildInfoRow(t('notification_detail.time_ago'),
              _formatTimeAgo(widget.notification)),
        ],
      ),
    );
  }

  String _formatTimeAgo(NotificationModel notification) {
    final locale = ref.watch(languageProvider);
    final now = DateTime.now();
    final difference = now.difference(notification.createdAt);

    if (locale.languageCode == 'fr') {
      if (difference.inDays > 0) {
        return 'Il y a ${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return 'Il y a ${difference.inMinutes}m';
      } else {
        return 'Maintenant';
      }
    } else {
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Now';
      }
    }
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
    if (key.toLowerCase().contains('phone') ||
        key.toLowerCase().contains('telephone')) {
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
            final emoji = statut == 'overdue'
                ? '🔴'
                : statut == 'urgent'
                    ? '🟠'
                    : '🟡';
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
      final cleanNumber = phoneNumber.split('').where((c) {
        final code = c.codeUnitAt(0);
        return c == '+' || (code >= 48 && code <= 57);
      }).join();

      // Vérifier que le numéro n'est pas vide après nettoyage
      if (cleanNumber.isEmpty) {
        _showErrorMessage(t('notification_detail.invalid_phone'));
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
        _showInfoMessage(
            'Appel vers $cleanNumber\n(Fonctionnalité disponible sur appareil réel)');
      }
    } catch (e) {
      // Erreur générale
      final errorMessage = ErrorMessageHelper.getOperationError(
        'appeler',
        error: e,
        customMessage: 'Impossible de passer l\'appel. Veuillez réessayer.',
      );
      _showErrorMessage(errorMessage);
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
    final primaryColor = _getNotificationPrimaryColor();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('notification_detail.delete_title')),
        content: Text(t('notification_detail.delete_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('auth.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(notificationProvider.notifier)
                  .deleteNotification(widget.notification.id);
              Navigator.pop(context); // Fermer la dialog
              Navigator.pop(context); // Retourner à la liste
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('notification_detail.delete'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (widget.notification.getIconType()) {
      case 'ticket':
        return Icons.confirmation_number;
      case 'mail':
        return Icons.mail;
      case 'points':
        return Icons.card_giftcard;
      case 'feedback':
        return Icons.feedback_outlined;
      case 'status':
        return Icons.update;
      case 'offer':
        return Icons.local_offer;
      case 'travel':
        return Icons.schedule;
      case 'alert':
        return Icons.warning_outlined;
      default:
        // Vérifier si c'est une notification de dépense
        if (widget.notification.type == 'expense_pending' ||
            widget.notification.type == 'new_expense') {
          return Icons.attach_money;
        }
        return Icons.notifications_outlined;
    }
  }

  Color _getTypeColor() {
    final primaryColor = _getNotificationPrimaryColor();
    switch (widget.notification.getIconType()) {
      case 'ticket':
        return primaryColor;
      case 'mail':
        return primaryColor;
      case 'points':
        return Colors.amber;
      case 'feedback':
        return primaryColor;
      case 'status':
        return Colors.orange;
      case 'offer':
        return Colors.purple;
      case 'travel':
        return Colors.green;
      case 'alert':
        return Colors.red;
      default:
        // Vérifier si c'est une notification de dépense
        if (widget.notification.type == 'expense_pending' ||
            widget.notification.type == 'new_expense') {
          return Colors.orange;
        }
        return primaryColor;
    }
  }

  String _getTypeLabel() {
    switch (widget.notification.type.toLowerCase()) {
      case 'new_ticket':
        return t('notification_detail.type_new_ticket');
      case 'loyalty_point':
        return t('notification_detail.type_loyalty_point');
      case 'new_feedback':
        return t('notification_detail.type_new_feedback');
      case 'feedback_status':
        return t('notification_detail.type_feedback_status');
      case 'promotion':
      case 'offer':
        return t('notification_detail.type_promotion');
      case 'reminder':
      case 'travel':
        return t('notification_detail.type_reminder');
      case 'loyalty':
      case 'points':
        return t('notification_detail.type_loyalty');
      case 'alert':
      case 'urgent':
        return t('notification_detail.type_alert');
      case 'new_mail_sender':
      case 'mail_created':
        return t('notification_detail.type_new_mail_sender');
      case 'new_mail_recipient':
      case 'mail_received':
        return t('notification_detail.type_new_mail_recipient');
      case 'mail_collected':
        return t('notification_detail.type_mail_collected');
      case 'departure_time_changed':
      case 'departure_modified':
      case 'departure_updated':
        return t('notification_detail.type_departure_changed');
      case 'departure_cancelled':
        return t('notification_detail.type_departure_cancelled');
      case 'reservation_confirmed':
        return t('notification_detail.type_reservation_confirmed');
      case 'reservation_cancelled':
        return t('notification_detail.type_reservation_cancelled');
      case 'vidange_alert':
        return t('notification_detail.type_vidange_alert');
      case 'vidange_completed':
        return t('notification_detail.type_vidange_completed');
      case 'vidange_updated':
        return t('notification_detail.type_vidange_updated');
      case 'expense_pending':
      case 'new_expense':
        return 'Nouvelle dépense';
      case 'breakdown_new':
      case 'new_breakdown':
        return t('notification_detail.type_breakdown_new');
      case 'breakdown_updated':
      case 'breakdown_modified':
        return t('notification_detail.type_breakdown_updated');
      case 'breakdown_status':
      case 'breakdown_status_changed':
        return t('notification_detail.type_breakdown_status');
      case 'message_notification':
      case 'system_message':
        return t('notification_detail.type_message_notification');
      case 'system':
        return t('notification_detail.type_system');
      default:
        return t('notification_detail.type_default');
    }
  }

  String _formatDataKey(String key) {
    switch (key.toLowerCase()) {
      // Tickets
      case 'ticket_id':
        return t('notification_detail.data_ticket_id');
      case 'depart_id':
        return t('notification_detail.data_depart_id');
      case 'seat_number':
        return t('notification_detail.data_seat_number');
      case 'embarquement':
        return t('notification_detail.data_embarquement');
      case 'destination':
        return t('notification_detail.data_destination');
      // Loyalty
      case 'points_earned':
        return t('notification_detail.data_points_earned');
      case 'total_points':
        return t('notification_detail.data_total_points');
      case 'client_profile_id':
        return t('notification_detail.data_client_profile_id');
      case 'description':
        return t('notification_detail.data_description');
      // Feedback
      case 'feedback_id':
        return t('notification_detail.data_feedback_id');
      case 'customer_name':
        return t('notification_detail.data_customer_name');
      case 'customer_phone':
        return t('notification_detail.data_customer_phone');
      case 'priority':
        return t('notification_detail.data_priority');
      case 'subject':
        return t('notification_detail.data_subject');
      case 'source':
        return t('notification_detail.data_source');
      case 'created_at':
        return t('notification_detail.data_created_at');
      case 'feedback_priority':
        return t('notification_detail.data_feedback_priority');
      case 'feedback_status':
        return t('notification_detail.data_feedback_status');
      case 'sent_by':
        return t('notification_detail.data_sent_by');
      case 'timestamp':
        return t('notification_detail.data_timestamp');
      case 'promo_code':
        return t('notification_detail.data_promo_code');
      case 'discount':
        return t('notification_detail.data_discount');
      case 'valid_until':
        return t('notification_detail.data_valid_until');
      case 'departure_time':
        return t('notification_detail.data_departure_time');
      case 'route':
        return t('notification_detail.data_route');
      case 'maintenance_start':
        return t('notification_detail.data_maintenance_start');
      case 'maintenance_end':
        return t('notification_detail.data_maintenance_end');
      // Vidanges
      case 'nombre_en_retard':
      case 'overdue_count':
        return t('notification_detail.data_overdue');
      case 'nombre_urgent':
      case 'urgent_count':
        return t('notification_detail.data_urgent');
      case 'nombre_attention':
      case 'warning_count':
        return t('notification_detail.data_warning');
      case 'nombre_total':
      case 'total_count':
        return t('notification_detail.data_total');
      case 'bus':
        return t('notification_detail.data_bus');
      case 'horodatage':
        return t('notification_detail.data_timestamp');
      // Vidange effectuée
      case 'bus_id':
        return t('notification_detail.data_bus_id');
      case 'bus_immatriculation':
        return t('notification_detail.data_bus_immatriculation');
      case 'derniere_vidange':
        return t('notification_detail.data_derniere_vidange');
      case 'prochaine_vidange':
        return t('notification_detail.data_prochaine_vidange');
      case 'jours_restants':
        return t('notification_detail.data_jours_restants');
      // Courrier
      case 'mail_number':
      case 'number':
        return t('notification_detail.data_mail_number');
      case 'sender':
      case 'expediteur':
        return t('notification_detail.data_sender');
      case 'recipient':
      case 'destinataire':
        return t('notification_detail.data_recipient');
      // Départ
      case 'new_time':
        return t('notification_detail.data_new_time');
      case 'old_time':
        return t('notification_detail.data_old_time');
      case 'count':
        return t('notification_detail.data_count');
      // Dépenses
      case 'expense_id':
        return 'Expense Id';
      case 'expense_status':
        return 'Expense Status';
      case 'expense_montant':
        return 'Expense Montant';
      case 'expense_type':
        return 'Expense Type';
      case 'expense_motif':
        return 'Expense Motif';
      case 'created_by':
        return 'Created By';
      case 'creator_name':
        return 'Creator Name';
      default:
        // Remplacer les underscores par des espaces et mettre en forme
        return key
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : '')
            .join(' ');
    }
  }
}
