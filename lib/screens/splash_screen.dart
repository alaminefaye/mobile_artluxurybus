import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../services/onboarding_service.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation du logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animation du texte
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Démarrer les animations
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // Navigation après animations
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      // Vérifier si l'onboarding a été complété
      final isOnboardingCompleted =
          await OnboardingService.isOnboardingCompleted();

      if (isOnboardingCompleted) {
        // Si l'onboarding est complété, aller vers AuthWrapper
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthWrapper(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        // Si c'est la première fois, aller vers l'onboarding
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OnboardingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlue.withValues(alpha: 0.9),
              AppTheme.primaryOrange.withValues(alpha: 0.8),
              AppTheme.primaryOrange,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Cercles décoratifs animés
            Positioned(
              top: -50,
              right: -50,
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _logoController.value * 2,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              bottom: -100,
              left: -80,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_textController.value * 1.5,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Points décoratifs flottants
            Positioned(
              top: 120,
              left: 50,
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -20 * _fadeAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value * 0.6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: 200,
              right: 80,
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 15 * _fadeAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value * 0.7,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              bottom: 150,
              right: 40,
              child: AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.5 + 0.5 * _logoAnimation.value,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Contenu principal
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo animé - parfaitement centré
                    AnimatedBuilder(
                      animation: _logoAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoAnimation.value,
                          child: Transform.rotate(
                            angle: (1 - _logoAnimation.value) * 0.5,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    spreadRadius: 8,
                                    blurRadius: 25,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'assets/images/logo.jpeg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 35),

                    // Texte animé - centré
                    AnimatedBuilder(
                      animation: _textAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - _textAnimation.value)),
                          child: Opacity(
                            opacity: _textAnimation.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Nom de l'application
                                const Text(
                                  'ART LUXURY BUS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 12.0,
                                        color: Colors.black26,
                                        offset: Offset(2, 4),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Slogan
                                AnimatedBuilder(
                                  animation: _fadeAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _fadeAnimation.value,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.25,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Text(
                                          'Service de transport de classe nationale',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.8,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    // Indicateur de chargement - centré
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Chargement...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
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
          ],
        ),
      ),
    );
  }
}
