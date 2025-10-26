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
  String? _selectedStation;
  String? _selectedRoute;
  
  final List<Map<String, dynamic>> _categories = [
    {'value': 'suggestion', 'label': 'Suggestion d\'amélioration', 'icon': Icons.lightbulb},
    {'value': 'probleme', 'label': 'Signaler un problème', 'icon': Icons.report_problem},
    {'value': 'service', 'label': 'Service client', 'icon': Icons.support_agent},
    {'value': 'securite', 'label': 'Sécurité', 'icon': Icons.security},
    {'value': 'confort', 'label': 'Confort', 'icon': Icons.airline_seat_recline_extra},
    {'value': 'autre', 'label': 'Autre', 'icon': Icons.more_horiz},
  ];

  final List<String> _stations = [
    'GARE DE BOUAKE',
    'GARE DE YAKRO',
    'GARE DE YOPOUGON',
  ];

  final List<String> _routes = [
    'Abidjan - Bouaké',
    'Abidjan - Yamoussoukro',
    'Bouaké - Yamoussoukro',
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
              const SizedBox(height: 16),
              
              // Sélection de catégorie
              _buildCategorySection(),
              const SizedBox(height: 16),
              
              // Informations personnelles
              _buildPersonalInfoSection(),
              const SizedBox(height: 16),
              
              // Détails de la suggestion/préoccupation
              _buildFeedbackSection(),
              const SizedBox(height: 16),
              
              // Informations de voyage
              _buildTravelInfoSection(),
              const SizedBox(height: 24),
              
              // Bouton d'envoi
              _buildSubmitButton(feedbackState),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.08),
            AppTheme.primaryOrange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.feedback_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Votre avis compte !',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Partagez vos idées pour améliorer nos services',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['value'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryBlue 
                      : (Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey.shade800 
                          : Colors.grey[50]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primaryBlue 
                        : (Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade700 
                            : Colors.grey[300]!),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'],
                      size: 14,
                      color: isSelected ? Colors.white : AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category['label'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        _buildCompactTextField(
          controller: _nameController,
          label: 'Nom complet',
          icon: Icons.person_outline,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nom requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildCompactTextField(
          controller: _phoneController,
          label: 'Téléphone',
          icon: Icons.phone_outlined,
          hint: '+225 XX XX XX XX XX',
          isRequired: true,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Téléphone requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildCompactTextField(
          controller: _emailController,
          label: 'Email (optionnel)',
          icon: Icons.email_outlined,
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        _buildCompactTextField(
          controller: _subjectController,
          label: 'Sujet',
          icon: Icons.subject_outlined,
          hint: 'Résumé de votre message',
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Sujet requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildCompactTextField(
          controller: _messageController,
          label: 'Message détaillé',
          icon: Icons.message_outlined,
          hint: 'Décrivez votre suggestion ou préoccupation...',
          isRequired: true,
          maxLines: 4,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Message requis';
            }
            if (value.length < 20) {
              return 'Message trop court (min 20 caractères)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTravelInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de voyage',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        _buildCompactDropdown(
          value: _selectedStation,
          items: _stations,
          label: 'Gare de départ',
          icon: Icons.location_on_outlined,
          onChanged: (value) {
            setState(() {
              _selectedStation = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildCompactDropdown(
          value: _selectedRoute,
          items: _routes,
          label: 'Itinéraire',
          icon: Icons.route_outlined,
          onChanged: (value) {
            setState(() {
              _selectedRoute = value;
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _seatController,
                label: 'Numéro de siège',
                icon: Icons.event_seat_outlined,
                hint: 'Ex: 12',
                isRequired: true,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Numéro de siège requis';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Doit être un nombre';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactTextField(
                controller: _departureController,
                label: 'N° de départ',
                icon: Icons.confirmation_number_outlined,
                hint: 'Ex: 001',
                isRequired: true,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Numéro de départ requis';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Doit être un nombre';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AsyncValue<String?> feedbackState) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: feedbackState.isLoading ? null : _submitFeedback,
        icon: feedbackState.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send_rounded, size: 18),
        label: Text(
          feedbackState.isLoading ? 'Envoi...' : 'Envoyer',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Méthode pour créer des champs de texte compacts
  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        validator: validator,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white70 : AppTheme.primaryBlue,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          errorStyle: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  // Méthode pour créer des dropdowns compacts
  Widget _buildCompactDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          prefixIcon: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white70 : AppTheme.primaryBlue,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        borderRadius: BorderRadius.circular(10),
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
      station: _selectedStation,
      route: _selectedRoute,
      // Champs obligatoires - toujours envoyés
      seatNumber: _seatController.text.trim(),
      departureNumber: _departureController.text.trim(),
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
      _selectedStation = null;
      _selectedRoute = null;
    });
    
    // Reset l'état du provider
    ref.read(feedbackSubmissionProvider.notifier).reset();
  }
}
