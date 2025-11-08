import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/loyalty_provider.dart';
import '../services/translation_service.dart';
import 'loyalty_register_screen.dart';
import 'loyalty_home_screen.dart';

class LoyaltyCheckScreen extends ConsumerStatefulWidget {
  const LoyaltyCheckScreen({super.key});

  @override
  ConsumerState<LoyaltyCheckScreen> createState() => _LoyaltyCheckScreenState();
}

class _LoyaltyCheckScreenState extends ConsumerState<LoyaltyCheckScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  bool _isKeyboardVisible = false;

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() {
      setState(() {
        _isKeyboardVisible = _phoneFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _checkPoints() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('loyalty.enter_phone_error')),
        ),
      );
      return;
    }

    final success = await ref.read(loyaltyProvider.notifier).checkClientPoints(
      _phoneController.text.trim(),
    );

    if (success) {
      if (mounted) {
        // Remplacer la page actuelle par loyalty_home qui affichera le dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoyaltyHomeScreen()),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t('loyalty.points_found'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      // Client non trouvé, proposer l'inscription
      if (mounted) {
        _showRegistrationDialog();
      }
    }
  }

  void _showRegistrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_add, 
              color: AppTheme.primaryOrange,
              size: 20,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                t('loyalty.account_not_found'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          t('loyalty.no_account_found'),
          style: TextStyle(height: 1.4, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              t('common.cancel'),
              style: TextStyle(fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoyaltyRegisterScreen(
                    phoneNumber: _phoneController.text.trim(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              t('loyalty.register'),
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    final loyaltyState = ref.watch(loyaltyProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Effacer la session si elle existe
          ref.read(loyaltyProvider.notifier).reset();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('loyalty.check_points')),
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.primaryOrange 
              : AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark 
                ? [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                  ]
                : [
                    AppTheme.primaryBlue,
                    AppTheme.primaryBlue.withValues(alpha: 0.9),
                    AppTheme.primaryBlue.withValues(alpha: 0.6),
                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Espacement adaptatif selon le clavier
                SizedBox(height: _isKeyboardVisible ? screenHeight * 0.02 : screenHeight * 0.04),
                
                // Titre principal en blanc (plus petit si clavier visible)
                Text(
                  t('loyalty.search_account').replaceAll(' ', '\n'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _isKeyboardVisible ? screenWidth * 0.06 : screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                
                // Espacement adaptatif
                SizedBox(height: _isKeyboardVisible ? screenHeight * 0.015 : screenHeight * 0.02),
                
                // Description en blanc (masquée si clavier visible pour économiser l'espace)
                if (!_isKeyboardVisible) ...[
                  Text(
                    t('loyalty.enter_phone_to_check'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.06),
                ] else ...[
                  SizedBox(height: screenHeight * 0.03),
                ],
                
                // Boîte blanche contenant le champ
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Theme.of(context).cardColor 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        spreadRadius: 2,
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Champ de saisie moderne
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[800] 
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    enabled: !loyaltyState.isLoading,
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => _checkPoints(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: t('loyalty.phone_number'),
                      labelStyle: const TextStyle(fontSize: 13),
                      hintText: '0123456789',
                      hintStyle: const TextStyle(fontSize: 14),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppTheme.primaryOrange 
                              : AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.phone_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                // Bouton de recherche moderne (toujours visible)
                Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.dark 
                          ? [
                              AppTheme.primaryOrange,
                              AppTheme.primaryOrange.withValues(alpha: 0.8),
                            ]
                          : [
                              AppTheme.primaryBlue,
                              AppTheme.primaryBlue.withValues(alpha: 0.8),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.primaryOrange 
                            : AppTheme.primaryBlue).withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: loyaltyState.isLoading ? null : _checkPoints,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: loyaltyState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t('loyalty.search'),
                                style: const TextStyle(
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

                // Note d'information (masquée si clavier visible)
                if (!_isKeyboardVisible) ...[
                  SizedBox(height: screenHeight * 0.05),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: screenWidth * 0.045,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            t('loyalty.use_same_number'),
                            style: TextStyle(
                              fontSize: screenWidth * 0.032,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Espace supplémentaire pour éviter que le clavier masque le bouton
                SizedBox(height: _isKeyboardVisible ? screenHeight * 0.02 : 0),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
