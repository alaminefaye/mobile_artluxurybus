import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/feedback_provider.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _stationController = TextEditingController();
  final _routeController = TextEditingController();
  final _seatController = TextEditingController();
  final _departureController = TextEditingController();

  String _selectedCategory = 'suggestion';
  
  final List<Map<String, dynamic>> _categories = [
    {'value': 'suggestion', 'label': 'Suggestion d\'amélioration', 'icon': Icons.lightbulb},
    {'value': 'probleme', 'label': 'Signaler un problème', 'icon': Icons.report_problem},
    {'value': 'service', 'label': 'Service client', 'icon': Icons.support_agent},
    {'value': 'securite', 'label': 'Sécurité', 'icon': Icons.security},
    {'value': 'confort', 'label': 'Confort', 'icon': Icons.airline_seat_recline_extra},
    {'value': 'autre', 'label': 'Autre', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _stationController.dispose();
    _routeController.dispose();
    _seatController.dispose();
    _departureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedbackState = ref.watch(feedbackSubmissionProvider);
    
    // Écouter les changements d'état pour afficher des messages
    ref.listen(feedbackSubmissionProvider, (previous, next) {
      next.whenOrNull(
        data: (message) {
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Reset le formulaire après succès
            _resetForm();
          }
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestions & Préoccupations'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête informatif
              _buildInfoHeader(),
              const SizedBox(height: 24),
              
              // Sélection de catégorie
              _buildCategorySection(),
              const SizedBox(height: 24),
              
              // Informations personnelles
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              
              // Détails de la suggestion/préoccupation
              _buildFeedbackSection(),
              const SizedBox(height: 24),
              
              // Informations de voyage (optionnel)
              _buildTravelInfoSection(),
              const SizedBox(height: 32),
              
              // Bouton d'envoi
              _buildSubmitButton(feedbackState),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryOrange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre avis compte !',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Partagez vos suggestions et préoccupations pour améliorer nos services.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de retour',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['value'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryBlue 
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primaryBlue 
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'],
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category['label'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de contact',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom complet *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir votre nom';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Téléphone *',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            hintText: '+225 XX XX XX XX XX',
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir votre numéro';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email (optionnel)',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre message',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _subjectController,
          decoration: const InputDecoration(
            labelText: 'Sujet *',
            prefixIcon: Icon(Icons.subject),
            border: OutlineInputBorder(),
            hintText: 'Résumé de votre message',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir un sujet';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _messageController,
          decoration: const InputDecoration(
            labelText: 'Message détaillé *',
            prefixIcon: Icon(Icons.message),
            border: OutlineInputBorder(),
            hintText: 'Décrivez en détail votre suggestion ou préoccupation...',
          ),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir votre message';
            }
            if (value.length < 20) {
              return 'Votre message doit faire au moins 20 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTravelInfoSection() {
    return ExpansionTile(
      title: Text(
        'Informations de voyage (optionnel)',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
      subtitle: const Text('Si votre message concerne un trajet spécifique'),
      leading: const Icon(Icons.directions_bus),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _stationController,
                decoration: const InputDecoration(
                  labelText: 'Gare de départ',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _routeController,
                decoration: const InputDecoration(
                  labelText: 'Itinéraire',
                  prefixIcon: Icon(Icons.route),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Abidjan → Bouaké',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _seatController,
                      decoration: const InputDecoration(
                        labelText: 'Siège',
                        prefixIcon: Icon(Icons.event_seat),
                        border: OutlineInputBorder(),
                        hintText: 'Ex: 12A',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _departureController,
                      decoration: const InputDecoration(
                        labelText: 'N° Départ',
                        prefixIcon: Icon(Icons.confirmation_number),
                        border: OutlineInputBorder(),
                        hintText: 'Ex: D-001',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AsyncValue<String?> feedbackState) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: feedbackState.isLoading ? null : _submitFeedback,
        icon: feedbackState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send),
        label: Text(
          feedbackState.isLoading ? 'Envoi en cours...' : 'Envoyer ma suggestion',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _submitFeedback() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final feedbackNotifier = ref.read(feedbackSubmissionProvider.notifier);
    
    feedbackNotifier.submitFeedback(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      email: _emailController.text.trim().isNotEmpty 
          ? _emailController.text.trim() 
          : null,
      station: _stationController.text.trim().isNotEmpty 
          ? _stationController.text.trim() 
          : null,
      route: _routeController.text.trim().isNotEmpty 
          ? _routeController.text.trim() 
          : null,
      seatNumber: _seatController.text.trim().isNotEmpty 
          ? _seatController.text.trim() 
          : null,
      departureNumber: _departureController.text.trim().isNotEmpty 
          ? _departureController.text.trim() 
          : null,
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();
    _stationController.clear();
    _routeController.clear();
    _seatController.clear();
    _departureController.clear();
    
    setState(() {
      _selectedCategory = 'suggestion';
    });
    
    // Reset l'état du provider
    ref.read(feedbackSubmissionProvider.notifier).reset();
  }
}
