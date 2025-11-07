import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/client_registration_models.dart';
import '../services/client_registration_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../screens/home_page.dart';

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
                  child: Text('Bienvenue ${widget.client.nomComplet}! 🎉'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compte créé mais erreur de connexion: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      // Afficher l'erreur
      debugPrint('❌ [CreateAccountScreen] Erreur lors de la création du compte: ${response.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer votre compte'),
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.client.nomComplet,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.client.telephone,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (widget.client.email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.client.email!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
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
                              '${widget.client.points} points fidélité',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Créez votre mot de passe',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Choisissez un mot de passe sécurisé pour protéger votre compte',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 24),

                // Date de naissance (optionnelle)
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date de naissance (optionnel)',
                      hintText: 'Sélectionnez votre date',
                      prefixIcon: const Icon(Icons.cake),
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Aucune date sélectionnée',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Minimum 8 caractères',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
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
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    hintText: 'Retapez votre mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
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
                    fillColor: Colors.grey[50],
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

                // Bouton créer compte
                ElevatedButton(
                  onPressed: _isLoading ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Créer mon compte',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Info anniversaire
                if (_selectedDate != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cake, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nous vous enverrons un cadeau spécial pour votre anniversaire! 🎉',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[900],
                            ),
                          ),
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
}
