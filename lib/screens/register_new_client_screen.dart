import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/client_registration_models.dart';
import '../services/client_registration_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../screens/home_page.dart';

class RegisterNewClientScreen extends ConsumerStatefulWidget {
  final String? initialPhone;

  const RegisterNewClientScreen({
    super.key,
    this.initialPhone,
  });

  @override
  ConsumerState<RegisterNewClientScreen> createState() =>
      _RegisterNewClientScreenState();
}

class _RegisterNewClientScreenState extends ConsumerState<RegisterNewClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _service = ClientRegistrationService();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) {
      _telephoneController.text = widget.initialPhone!;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      helpText: 'Sélectionnez votre date de naissance',
      cancelText: 'Annuler',
      confirmText: 'OK',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: Colors.orange,
                    onPrimary: Colors.white,
                    surface: Theme.of(context).cardColor,
                    onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                  )
                : Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = RegisterClientRequest(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      telephone: _telephoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      dateNaissance: _selectedDate?.toIso8601String().split('T')[0],
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    final response = await _service.registerNewClient(request);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      // Connexion automatique avec le token retourné par l'inscription
      debugPrint('✅ [RegisterNewClientScreen] Inscription réussie, connexion automatique...');
      
      try {
        // Convertir UserData en format User pour AuthService
        final userData = {
          'id': response.data!.user.id,
          'name': response.data!.user.name,
          'email': response.data!.user.email,
          'role': response.data!.user.role,
          'permissions': response.data!.user.permissions,
        };
        
        // Sauvegarder directement le token retourné par l'inscription
        await _authService.saveAuthDataFromRegistration(
          token: response.data!.token,
          tokenType: response.data!.tokenType,
          userData: userData,
        );
        
        // Convertir UserData en User pour mettre à jour authProvider
        final user = User.fromJson(userData);
        
        // Mettre à jour authProvider pour que l'app reconnaisse l'authentification
        await ref.read(authProvider.notifier).updateAuthAfterRegistration(user: user);
        
        debugPrint('✅ [RegisterNewClientScreen] Connexion automatique réussie');

        if (!mounted) return;

        // Message de bienvenue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bienvenue ${response.data!.client.nomComplet}! 🎉',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Retour à l'écran principal (connexion réussie)
        // Naviguer directement vers HomePage puisque authProvider est mis à jour
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false, // Supprimer toutes les routes précédentes
        );
      } catch (e) {
        debugPrint('❌ [RegisterNewClientScreen] Erreur lors de la connexion automatique: $e');
        if (!mounted) return;
        
        // Afficher l'erreur mais l'inscription est réussie
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inscription réussie mais erreur de connexion: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      // Afficher l'erreur
      String errorMessage = response.message;
      
      // Afficher les erreurs de validation si présentes
      if (response.errors != null) {
        final errors = response.errors!.values.map((e) => e.toString()).join('\n');
        errorMessage = '$errorMessage\n$errors';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icône et titre
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.primaryOrange 
                        : Colors.blue).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add,
                    size: 40,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.primaryOrange 
                        : Colors.blue,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.primaryOrange 
                        : null,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Rejoignez Art Luxury Bus et profitez de nos avantages',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Nom
                TextFormField(
                  controller: _nomController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nom *',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    hintText: 'Votre nom de famille',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Prénom
                TextFormField(
                  controller: _prenomController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Prénom *',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    hintText: 'Votre prénom',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre prénom';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Téléphone
                TextFormField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Téléphone *',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    hintText: '+221 77 123 45 67',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.phone,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    if (value.length < 8) {
                      return 'Numéro de téléphone invalide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email (optionnel)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email (optionnel)',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    hintText: 'votre.email@exemple.com',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!value.contains('@')) {
                        return 'Email invalide';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Date de naissance
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date de naissance (optionnel)',
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.primaryOrange 
                            : null,
                      ),
                      hintText: 'Pour recevoir un cadeau d\'anniversaire 🎂',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.cake,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.primaryOrange 
                            : null,
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.primaryOrange 
                            : null,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[800] 
                          : Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Sélectionnez votre date',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? (Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Colors.black87)
                            : (Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[400] 
                                : Colors.grey[600]),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Sécurité',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 24),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe *',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    hintText: 'Minimum 8 caractères',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.primaryOrange 
                            : null,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 8) {
                      return 'Le mot de passe doit contenir au moins 8 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirmation mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe *',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    hintText: 'Retapez votre mot de passe',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.primaryOrange 
                            : null,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Bouton inscription avec gradient
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.accentGradient
                        : AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.primaryOrange 
                            : AppTheme.primaryBlue).withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? LoadingIndicator(
                            size: 20,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'S\'inscrire',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Avantages
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withValues(alpha: 0.1),
                        (Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.primaryOrange 
                            : Colors.blue).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : Colors.blue).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.card_giftcard, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Vos avantages',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildAdvantageItem(
                        Icons.star,
                        'Programme de fidélité',
                        'Gagnez des points à chaque voyage',
                      ),
                      const SizedBox(height: 12),
                      _buildAdvantageItem(
                        Icons.confirmation_number,
                        'Tickets gratuits',
                        '10 points = 1 voyage gratuit',
                      ),
                      const SizedBox(height: 12),
                      _buildAdvantageItem(
                        Icons.cake,
                        'Cadeau d\'anniversaire',
                        'Surprise spéciale le jour J',
                      ),
                      const SizedBox(height: 12),
                      _buildAdvantageItem(
                        Icons.notifications_active,
                        'Notifications',
                        'Restez informé de nos offres',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvantageItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.primaryOrange 
                : Colors.blue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            size: 20, 
            color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.primaryOrange 
                : Colors.blue[700],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
