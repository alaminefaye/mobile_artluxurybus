import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/loyalty_provider.dart';
import 'loyalty_home_screen.dart';

class LoyaltyRegisterScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  
  const LoyaltyRegisterScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<LoyaltyRegisterScreen> createState() => _LoyaltyRegisterScreenState();
}

class _LoyaltyRegisterScreenState extends ConsumerState<LoyaltyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(loyaltyProvider.notifier).registerClient(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      telephone: widget.phoneNumber,
      email: _emailController.text.trim().isEmpty 
        ? null 
        : _emailController.text.trim(),
    );

    if (success) {
      if (mounted) {
        // Naviguer directement vers LoyaltyHomeScreen avec le nouveau client
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoyaltyHomeScreen()),
          (route) => false, // Supprimer toute la pile de navigation
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Inscription réussie ! Bienvenue dans votre dashboard !',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription Fidélité'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 20),
                
                // Titre
                const Text(
                  'Rejoignez le programme',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Créez votre compte fidélité et commencez à gagner des points !',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Formulaire
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Numéro (lecture seule)
                      TextFormField(
                        initialValue: widget.phoneNumber,
                        enabled: false,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Numéro de téléphone',
                          labelStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(
                            Icons.phone_rounded,
                            color: AppTheme.primaryBlue,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Nom
                      TextFormField(
                        controller: _nomController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Nom *',
                          labelStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(
                            Icons.person_rounded,
                            color: AppTheme.primaryBlue,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Prénom
                      TextFormField(
                        controller: _prenomController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Prénom *',
                          labelStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: AppTheme.primaryBlue,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le prénom est requis';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Email (optionnel)
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Email (optionnel)',
                          labelStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppTheme.primaryBlue,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Format email invalide';
                            }
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Message d'erreur
                      if (loyaltyState.hasError) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  loyaltyState.error!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Bouton inscription
                      Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: AppTheme.buttonShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: loyaltyState.isRegistering ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: loyaltyState.isRegistering
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_add_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'S\'INSCRIRE',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Avantages du programme
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: AppTheme.primaryOrange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Vos avantages',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildAdvantage('1 voyage = 1 point fidélité'),
                      _buildAdvantage('10 points = 1 ticket gratuit'),
                      _buildAdvantage('10 points = 1 courrier gratuit'),
                      _buildAdvantage('Offres exclusives régulières'),
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

  Widget _buildAdvantage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
