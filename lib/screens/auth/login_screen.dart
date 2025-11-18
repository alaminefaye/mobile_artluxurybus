import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_logo.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart' as theme_provider;
import '../../providers/language_provider.dart';
import '../../services/translation_service.dart';
import '../../main.dart'; // Pour accéder à AuthWrapper
// Models d'auth maintenant dans simple_auth_models.dart
import '../public_screen.dart';
import '../client_search_screen.dart';

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
  bool _translationsLoaded = false;

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  @override
  void initState() {
    super.initState();

    // Charger les traductions de manière asynchrone
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTranslations();
    });

    // Effacer les erreurs précédentes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  Future<void> _loadTranslations() async {
    final locale = ref.read(languageProvider);
    final translationService = TranslationService();

    debugPrint(
        '🔄 [LoginScreen] _loadTranslations - Langue: ${locale.languageCode}');
    debugPrint('   - Traductions chargées: ${translationService.isLoaded}');
    debugPrint(
        '   - Locale service: ${translationService.currentLocale.languageCode}');
    debugPrint('   - Locale provider: ${locale.languageCode}');

    // Toujours recharger pour s'assurer que les traductions sont à jour
    debugPrint(
        '🔄 [LoginScreen] Chargement des traductions pour ${locale.languageCode}...');
    await translationService.loadTranslations(locale);

    debugPrint(
        '✅ [LoginScreen] Traductions chargées: ${translationService.isLoaded}');
    debugPrint(
        '   - Locale après chargement: ${translationService.currentLocale.languageCode}');

    // Tester une traduction
    final testTranslation = translationService.translate('auth.welcome');
    debugPrint(
        '🧪 [LoginScreen] Test traduction après chargement: "$testTranslation"');

    // Vérifier que les traductions sont bien chargées (comparer uniquement le languageCode)
    if (translationService.isLoaded &&
        translationService.currentLocale.languageCode == locale.languageCode) {
      // Vérifier que la traduction est correcte
      if (locale.languageCode == 'en' &&
          testTranslation.contains('Bienvenue')) {
        debugPrint(
            '⚠️ [LoginScreen] PROBLÈME DÉTECTÉ: Traduction française alors que langue = anglais !');
        // Forcer un rechargement
        await translationService.reloadTranslations(locale);
        final newTest = translationService.translate('auth.welcome');
        debugPrint('🧪 [LoginScreen] Test après rechargement: "$newTest"');
      }

      debugPrint(
          '✅ [LoginScreen] Traductions prêtes pour ${locale.languageCode}');
      if (mounted) {
        setState(() {
          _translationsLoaded = true;
        });
        // Forcer un rebuild supplémentaire pour s'assurer que tout est à jour
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      debugPrint('⚠️ [LoginScreen] Traductions pas prêtes après chargement');
    }
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
          SnackBar(
            content: Text(t('auth.login_success')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        // Naviguer vers AuthWrapper qui redirigera automatiquement selon le rôle
        // PDG -> AdminDashboard, Courrier -> ManagementHub, etc.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const AuthWrapper(),
              ),
              (route) => false,
            );
          }
        });
      }
    }
  }

  void _forgotPassword() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('auth.forgot_password_feature_disabled')),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showThemeDialog() {
    final themeNotifier = ref.read(theme_provider.themeModeProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(t('auth.appearance')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: theme_provider.ThemeMode.values.map((mode) {
              return ListTile(
                leading: Icon(
                  themeNotifier.getIcon(mode),
                  color: isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
                ),
                title: Text(themeNotifier.getDisplayName(mode)),
                trailing: ref.watch(theme_provider.themeModeProvider) == mode
                    ? Icon(
                        Icons.check,
                        color: isDark
                            ? AppTheme.primaryOrange
                            : AppTheme.primaryBlue,
                      )
                    : null,
                onTap: () {
                  themeNotifier.setThemeMode(mode);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    // Écouter les changements de langue - cela déclenchera un rebuild automatique
    final locale = ref.watch(languageProvider);

    // Vérifier si les traductions sont chargées pour la langue actuelle
    // Comparer uniquement le languageCode car les countryCode peuvent différer
    final translationService = TranslationService();
    final isTranslationsReady = translationService.isLoaded &&
        translationService.currentLocale.languageCode == locale.languageCode;

    debugPrint(
        '🔍 [LoginScreen] build - Langue provider: ${locale.languageCode}, Service: ${translationService.currentLocale.languageCode}, Prêt: $isTranslationsReady, Flag: $_translationsLoaded');

    // Si les traductions ne sont pas prêtes, charger et attendre
    if (!isTranslationsReady || !_translationsLoaded) {
      if (!_translationsLoaded) {
        // Première fois, charger les traductions
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadTranslations();
        });
      } else {
        // La langue a changé, recharger les traductions
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          debugPrint(
              '🔄 [LoginScreen] Langue changée, rechargement des traductions...');
          await translationService.loadTranslations(locale);
          if (mounted) {
            setState(() {
              _translationsLoaded = true;
            });
          }
        });
      }

      // Afficher un loader si les traductions ne sont pas encore chargées
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Écouter les changements de langue pour recharger les traductions
    ref.listen(languageProvider, (previous, next) async {
      if (previous?.languageCode != next.languageCode && mounted) {
        debugPrint(
            '🔄 [LoginScreen] Langue changée via listener: ${previous?.languageCode} -> ${next.languageCode}');
        await translationService.loadTranslations(next);
        if (mounted) {
          setState(() {
            _translationsLoaded = true;
          });
        }
      }
    });

    // Tester une traduction pour vérifier
    final testTranslation = translationService.translate('auth.welcome');
    debugPrint(
        '🧪 [LoginScreen] Test traduction "auth.welcome": "$testTranslation"');
    debugPrint(
        '🧪 [LoginScreen] Locale service: ${translationService.currentLocale.languageCode}');
    debugPrint('🧪 [LoginScreen] Locale provider: ${locale.languageCode}');

    // Si la traduction test est en français alors qu'on est en anglais, forcer le rechargement
    if (locale.languageCode == 'en' && testTranslation.contains('Bienvenue')) {
      debugPrint(
          '⚠️ [LoginScreen] DÉTECTÉ: Traduction en français alors que la langue est anglaise !');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        debugPrint('🔄 [LoginScreen] Rechargement forcé des traductions...');
        await translationService.reloadTranslations(locale);
        if (mounted) {
          setState(() {
            _translationsLoaded = true;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Contenu principal
            SingleChildScrollView(
              child: Column(
                children: [
                  // Espace transparent en haut pour le bouton Ignorer (ne bloque pas les clics)
                  const SizedBox(height: 60),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo moderne avec votre image
                        const AppLogo(size: 100),

                        const SizedBox(height: 40),

                        // Titre avec sous-titre
                        Text(
                          t('auth.welcome'),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppTheme.primaryOrange
                                    : AppTheme.primaryBlue,
                                fontSize: 22,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t('auth.connect_to_account'),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                        ),

                        const SizedBox(height: 40),

                        // Carte de formulaire moderne
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Champ email ou téléphone
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: t('auth.email_or_phone'),
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppTheme.primaryOrange
                                          : AppTheme.primaryBlue,
                                    ),
                                    hintText: t('auth.email_or_phone_hint'),
                                    hintStyle: const TextStyle(fontSize: 14),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppTheme.primaryOrange
                                                : AppTheme.primaryBlue)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.email_outlined,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppTheme.primaryOrange
                                            : AppTheme.primaryBlue,
                                        size: 18,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return t('auth.email_or_phone_required');
                                    }
                                    // Accepter email OU téléphone (pas de validation stricte)
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Champ mot de passe moderne
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: t('auth.password'),
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppTheme.primaryOrange
                                          : AppTheme.primaryBlue,
                                    ),
                                    hintText: t('auth.password_hint'),
                                    hintStyle: const TextStyle(fontSize: 14),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppTheme.primaryOrange
                                                : AppTheme.primaryBlue)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.lock_outline,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppTheme.primaryOrange
                                            : AppTheme.primaryBlue,
                                        size: 18,
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppTheme.primaryOrange
                                            : AppTheme.primaryBlue,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return t('auth.password_required');
                                    }
                                    if (value.length < 6) {
                                      return t('auth.password_min_length');
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
                                    child: Text(t('auth.forgot_password')),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Bouton de connexion moderne avec dégradé
                                Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppTheme.accentGradient
                                        : AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (Theme.of(context).brightness ==
                                                    Brightness.dark
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
                                    onPressed:
                                        authState.isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
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
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Text(
                                            t('auth.login_button'),
                                            style: const TextStyle(
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
                              border: Border.all(
                                  color:
                                      AppTheme.errorRed.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed
                                        .withValues(alpha: 0.2),
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
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${t('auth.no_account')} ',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withValues(alpha: 0.7),
                                  fontSize: 15,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigation vers l'écran d'inscription client
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ClientSearchScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryOrange,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                child: Text(t('auth.register')),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bouton Thème en haut à gauche
            Positioned(
              top: 12,
              left: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showThemeDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.primaryOrange
                                : AppTheme.primaryBlue)
                            .withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primaryOrange
                          : AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),

            // Bouton Ignorer en haut à droite (DOIT ÊTRE APRÈS le ScrollView pour être au-dessus)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    debugPrint('🔍 Bouton Ignorer cliqué');
                    try {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const PublicScreen(),
                        ),
                      );
                      debugPrint('✅ Navigation vers PublicScreen lancée');
                    } catch (e) {
                      debugPrint('❌ Erreur navigation: $e');
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.skip_next_rounded,
                          size: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.primaryOrange
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t('auth.skip'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? AppTheme.primaryOrange
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
