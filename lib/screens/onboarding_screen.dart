import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/onboarding_service.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart' as theme_provider;
import '../theme/app_theme.dart';
import '../services/translation_service.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    // S'assurer que les traductions sont bien chargées avant de naviguer
    final currentLanguage = ref.read(languageProvider);
    final translationService = TranslationService();

    debugPrint(
        '🔄 [Onboarding] _completeOnboarding - Langue: ${currentLanguage.languageCode}');
    debugPrint('   - Traductions chargées: ${translationService.isLoaded}');
    debugPrint(
        '   - Locale service: ${translationService.currentLocale.languageCode}');

    // Toujours recharger les traductions pour s'assurer qu'elles sont à jour
    debugPrint('🔄 [Onboarding] Rechargement des traductions...');
    await translationService.loadTranslations(currentLanguage);

    debugPrint(
        '✅ [Onboarding] Traductions rechargées: ${translationService.isLoaded}');
    debugPrint(
        '   - Locale après chargement: ${translationService.currentLocale.languageCode}');

    // Attendre un délai pour s'assurer que tout est prêt
    await Future.delayed(const Duration(milliseconds: 200));

    await OnboardingService.completeOnboarding();

    // Vérifier une dernière fois que les traductions sont chargées
    final finalCheck = TranslationService();
    if (!finalCheck.isLoaded || finalCheck.currentLocale != currentLanguage) {
      debugPrint(
          '⚠️ [Onboarding] Dernière vérification - rechargement nécessaire');
      await finalCheck.loadTranslations(currentLanguage);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mounted) {
      debugPrint(
          '✅ [Onboarding] Navigation vers LoginScreen avec langue: ${currentLanguage.languageCode}');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Indicateur de progression
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.primaryOrange
                              : AppTheme.primaryBlue)
                          : Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildLanguagePage(),
                  _buildThemePage(),
                  _buildWelcomePage(),
                ],
              ),
            ),

            // Bouton suivant/passer
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        t('common.back'),
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.primaryOrange
                              : AppTheme.primaryBlue,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.primaryOrange
                              : AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == 2
                          ? t('onboarding.get_started')
                          : t('common.next'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 1: Sélection de la langue
  Widget _buildLanguagePage() {
    final currentLanguage = ref.watch(languageProvider);
    final languageNotifier = ref.read(languageProvider.notifier);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.language,
                size: 40,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            Text(
              t('onboarding.select_language'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.primaryOrange
                    : AppTheme.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              t('onboarding.select_language_description'),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7) ??
                    Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Options de langue
            _buildLanguageOption(
              locale: const Locale('fr', 'FR'),
              name: 'Français',
              flag: '🇫🇷',
              isSelected: currentLanguage.languageCode == 'fr',
              onTap: () async {
                await languageNotifier.setLanguage(const Locale('fr', 'FR'));
                if (mounted) {
                  setState(() {}); // Forcer le rebuild
                }
              },
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              locale: const Locale('en', 'US'),
              name: 'English',
              flag: '🇬🇧',
              isSelected: currentLanguage.languageCode == 'en',
              onTap: () async {
                await languageNotifier.setLanguage(const Locale('en', 'US'));
                if (mounted) {
                  setState(() {}); // Forcer le rebuild
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required Locale locale,
    required String name,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.primaryOrange.withValues(alpha: 0.2)
                  : AppTheme.primaryBlue.withValues(alpha: 0.1))
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.primaryOrange
                    : AppTheme.primaryBlue)
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primaryOrange
                          : AppTheme.primaryBlue)
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.primaryOrange
                    : AppTheme.primaryBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Page 2: Sélection du thème
  Widget _buildThemePage() {
    final currentTheme = ref.watch(theme_provider.themeModeProvider);
    final themeNotifier = ref.read(theme_provider.themeModeProvider.notifier);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.palette,
                size: 40,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            Text(
              t('onboarding.select_theme'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.primaryOrange
                    : AppTheme.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              t('onboarding.select_theme_description'),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7) ??
                    Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Options de thème
            _buildThemeOption(
              mode: theme_provider.ThemeMode.light,
              name: t('onboarding.theme_light'),
              icon: Icons.light_mode,
              description: t('onboarding.theme_light_description'),
              isSelected: currentTheme == theme_provider.ThemeMode.light,
              onTap: () async {
                await themeNotifier
                    .setThemeMode(theme_provider.ThemeMode.light);
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              mode: theme_provider.ThemeMode.dark,
              name: t('onboarding.theme_dark'),
              icon: Icons.dark_mode,
              description: t('onboarding.theme_dark_description'),
              isSelected: currentTheme == theme_provider.ThemeMode.dark,
              onTap: () async {
                await themeNotifier.setThemeMode(theme_provider.ThemeMode.dark);
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              mode: theme_provider.ThemeMode.system,
              name: t('onboarding.theme_system'),
              icon: Icons.brightness_auto,
              description: t('onboarding.theme_system_description'),
              isSelected: currentTheme == theme_provider.ThemeMode.system,
              onTap: () async {
                await themeNotifier
                    .setThemeMode(theme_provider.ThemeMode.system);
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required theme_provider.ThemeMode mode,
    required String name,
    required IconData icon,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryOrange.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.3
                      : 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryOrange
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryOrange.withValues(alpha: 0.2)
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryOrange
                    : Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryOrange
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryOrange,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Page 3: Page de bienvenue
  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryOrange
                            : AppTheme.primaryBlue)
                        .withValues(alpha: 0.15),
                    spreadRadius: 6,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Titre
            Text(
              t('onboarding.welcome_title'),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.primaryOrange
                    : AppTheme.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              t('onboarding.welcome_description'),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7) ??
                    Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Points de fonctionnalités
            _buildFeatureItem(
              icon: Icons.directions_bus,
              text: t('onboarding.feature_transport'),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              icon: Icons.card_giftcard,
              text: t('onboarding.feature_loyalty'),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              icon: Icons.notifications,
              text: t('onboarding.feature_notifications'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
  }) {
    final primaryColor = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.primaryOrange
        : AppTheme.primaryBlue;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }
}
