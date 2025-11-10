import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../widgets/loading_indicator.dart';
import '../models/client_registration_models.dart';
import '../services/client_registration_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../screens/home_page.dart';
import '../services/translation_service.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_helper.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  final ClientSearchData client;

  const CreateAccountScreen({
    super.key,
    required this.client,
  });

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _service = ClientRegistrationService();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedDate;

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  @override
  void initState() {
    super.initState();
    // Si le client a déjà une date de naissance, l'utiliser
    if (widget.client.dateNaissance != null) {
      try {
        _selectedDate = DateTime.parse(widget.client.dateNaissance!);
      } catch (e) {
        // Ignorer si le format est invalide
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.read(languageProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: currentLocale,
      helpText: t('create_account.birth_date_select'),
      cancelText: t('create_account.cancel'),
      confirmText: t('create_account.ok'),
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

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = CreateAccountRequest(
      clientId: widget.client.id,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      dateNaissance: _selectedDate?.toIso8601String().split('T')[0],
    );

    debugPrint('🔐 [CreateAccountScreen] Création compte pour client:');
    debugPrint('   - Client ID: ${widget.client.id}');
    debugPrint('   - Nom: ${widget.client.nomComplet}');
    debugPrint('   - Téléphone: ${widget.client.telephone}');

    final response = await _service.createAccountForExistingClient(request);

    if (!mounted) return;

    setState(() => _isLoading = false);

    debugPrint('🔐 [CreateAccountScreen] Réponse reçue:');
    debugPrint('   - success: ${response.success}');
    debugPrint('   - message: ${response.message}');
    debugPrint('   - data: ${response.data != null ? "présent" : "null"}');

    if (response.success && response.data != null) {
      debugPrint('✅ [CreateAccountScreen] Compte créé avec succès:');
      debugPrint('   - User ID: ${response.data!.user.id}');
      debugPrint('   - Email: ${response.data!.user.email}');
      debugPrint('   - Client ID: ${response.data!.client.id}');
      
      // Connexion automatique avec le token retourné par l'inscription
      debugPrint('🔐 [CreateAccountScreen] Connexion automatique avec token...');
      
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
        
        debugPrint('✅ [CreateAccountScreen] Connexion automatique réussie');
        
        if (!mounted) return;
        
        // Afficher message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${t('create_account.welcome')} ${widget.client.nomComplet}! 🎉'),
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
        debugPrint('❌ [CreateAccountScreen] Erreur lors de la connexion automatique: $e');
        if (!mounted) return;
        
        // Afficher l'erreur mais le compte est créé
        final errorMessage = ErrorMessageHelper.getUserFriendlyError(
          e,
          defaultMessage: 'Compte créé avec succès, mais impossible de vous connecter automatiquement. Veuillez vous connecter manuellement.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      // Afficher l'erreur
      debugPrint('❌ [CreateAccountScreen] Erreur lors de la création du compte: ${response.message}');
      final errorMessage = ErrorMessageHelper.getUserFriendlyError(
        response.message,
        defaultMessage: 'Impossible de créer le compte. Veuillez vérifier vos informations et réessayer.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('create_account.title')),
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
                // Carte informations client
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final primaryColor = isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue;
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  primaryColor.withValues(alpha: 0.3),
                                  primaryColor.withValues(alpha: 0.2),
                                ]
                              : [
                                  AppTheme.primaryBlue,
                                  AppTheme.primaryBlue.withValues(alpha: 0.8),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: isDark
                                ? AppTheme.primaryOrange.withValues(alpha: 0.2)
                                : Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.client.nomComplet,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.client.telephone,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                            ),
                          ),
                          if (widget.client.email != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.client.email!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark ? AppTheme.primaryOrange : Colors.white).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.client.points} ${t('create_account.loyalty_points')}',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                Text(
                  t('create_account.create_password'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  t('create_account.create_password_description'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 24),

                // Date de naissance (optionnelle)
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: t('create_account.birth_date'),
                      hintText: t('create_account.birth_date_hint'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      labelStyle: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryOrange
                            : AppTheme.primaryBlue,
                      ),
                      prefixIcon: Icon(
                        Icons.cake,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryOrange
                            : AppTheme.primaryBlue,
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryOrange
                            : AppTheme.primaryBlue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      isDense: true,
                    ),
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : t('create_account.birth_date_not_selected'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedDate != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    labelText: t('create_account.password'),
                    hintText: t('create_account.password_hint'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primaryOrange
                          : AppTheme.primaryBlue,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      size: 20,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primaryOrange
                          : AppTheme.primaryBlue,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryOrange
                            : AppTheme.primaryBlue,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryOrange
                            : AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('create_account.password_required');
                    }
                    if (value.length < 8) {
                      return t('create_account.password_min_length');
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
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    labelText: t('create_account.confirm_password'),
                    hintText: t('create_account.confirm_password_hint'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primaryOrange
                          : AppTheme.primaryBlue,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primaryOrange
                          : AppTheme.primaryBlue,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryOrange
                            : AppTheme.primaryBlue,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryOrange
                            : AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('create_account.confirm_password_required');
                    }
                    if (value != _passwordController.text) {
                      return t('create_account.passwords_not_match');
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Bouton créer compte
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
                                : AppTheme.primaryBlue)
                            .withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const LoadingIndicator(
                            size: 20,
                            strokeWidth: 2,
                          )
                        : Text(
                            t('create_account.create_button'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info anniversaire
                if (_selectedDate != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cake,
                          color: AppTheme.primaryOrange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t('create_account.birthday_message'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Avantages
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final primaryColor = isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue;
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withValues(alpha: 0.1),
                            primaryColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.card_giftcard, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Text(
                                t('create_account.advantages_title'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildAdvantageItem(
                            context,
                            Icons.star,
                            t('create_account.advantages_loyalty_title'),
                            t('create_account.advantages_loyalty_description'),
                            isDark,
                            primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildAdvantageItem(
                            context,
                            Icons.confirmation_number,
                            t('create_account.advantages_free_tickets_title'),
                            t('create_account.advantages_free_tickets_description'),
                            isDark,
                            primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildAdvantageItem(
                            context,
                            Icons.cake,
                            t('create_account.advantages_birthday_title'),
                            t('create_account.advantages_birthday_description'),
                            isDark,
                            primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildAdvantageItem(
                            context,
                            Icons.notifications_active,
                            t('create_account.advantages_notifications_title'),
                            t('create_account.advantages_notifications_description'),
                            isDark,
                            primaryColor,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvantageItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
    Color primaryColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppTheme.primaryOrange : Colors.blue[700],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
