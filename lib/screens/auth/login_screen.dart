import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_logo.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
// Models d'auth maintenant dans simple_auth_models.dart
import '../loyalty_home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Effacer les erreurs précédentes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _forgotPassword() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité temporairement désactivée'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // Logo moderne avec votre image
                const AppLogo(size: 100),
                
                const SizedBox(height: 40),
                
                // Titre avec sous-titre
                Text(
                  'Bienvenue !',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous à votre compte',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Carte de formulaire moderne
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Champ email moderne
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Adresse email',
                            labelStyle: const TextStyle(fontSize: 13),
                            hintText: 'exemple@email.com',
                            hintStyle: const TextStyle(fontSize: 14),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.email_outlined,
                                color: AppTheme.primaryBlue,
                                size: 18,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez saisir votre adresse email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Veuillez saisir une adresse email valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Champ mot de passe moderne
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle: const TextStyle(fontSize: 13),
                            hintText: 'Votre mot de passe',
                            hintStyle: const TextStyle(fontSize: 14),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                color: AppTheme.primaryBlue,
                                size: 18,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.primaryBlue,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez saisir votre mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Lien mot de passe oublié moderne
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryOrange,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Bouton de connexion moderne avec dégradé
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.buttonShadow,
                          ),
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Message d'erreur moderne
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                      border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: AppTheme.errorRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: const TextStyle(
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Section inscription moderne
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ? ',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigation vers l'écran d'inscription
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryOrange,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        child: const Text('S\'inscrire'),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Bouton "Pas maintenant"
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoyaltyHomeScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.skip_next_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      const Text('Pas maintenant'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
