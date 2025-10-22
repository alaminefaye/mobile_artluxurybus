import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'auth/login_screen.dart';
import 'loyalty_home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlue.withValues(alpha: 0.8),
              AppTheme.primaryOrange.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Logo en haut
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const AppLogo(size: 80, showText: false),
                ),
                
                const SizedBox(height: 30),
                
                // Illustration principale moderne
                Expanded(
                  flex: 4,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                        height: isSmallScreen ? screenHeight * 0.18 : screenHeight * 0.22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              spreadRadius: 8,
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Fond décoratif avec patterns
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryBlue.withValues(alpha: 0.05),
                                      AppTheme.primaryOrange.withValues(alpha: 0.05),
                                      Colors.white,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Cercles décoratifs responsives
                            Positioned(
                              top: screenHeight * 0.03,
                              right: screenWidth * 0.05,
                              child: Container(
                                width: screenWidth * 0.15,
                                height: screenWidth * 0.15,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: screenHeight * 0.04,
                              left: screenWidth * 0.08,
                              child: Container(
                                width: screenWidth * 0.12,
                                height: screenWidth * 0.12,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),

                            // Contenu principal centré
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Logo Art Luxury Bus
                                  Center(
                                    child: Container(
                                      width: screenWidth * 0.20,
                                      height: screenWidth * 0.20,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(35),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                                            spreadRadius: 3,
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(35),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Image.asset(
                                            '12.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.04),

                                  // Features avec meilleur design
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildModernFeature(Icons.schedule_rounded, 'Ponctuel', AppTheme.primaryOrange, screenWidth),
                                        _buildModernFeature(Icons.verified_user_rounded, 'Sécurisé', AppTheme.primaryBlue, screenWidth),
                                        _buildModernFeature(Icons.star_rounded, 'Luxe', AppTheme.primaryOrange, screenWidth),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.025),

                                  // Ligne décorative responsive
                                  Container(
                                    width: screenWidth * 0.15,
                                    height: screenHeight * 0.005,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.accentGradient,
                                      borderRadius: BorderRadius.circular(2),
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
                ),

                const SizedBox(height: 40),

                // Titre et description
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Transport de Luxe',
                          style: TextStyle(
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Service de transport de classe\nnationale.\nLignes : Abidjan 🚌 Bouaké 🚌\nYamoussoukro',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.white,
                              height: 1.4,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Boutons d'action modernes
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          // Bouton Login responsive
                          Container(
                            width: double.infinity,
                            height: screenHeight * 0.055,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.white.withValues(alpha: 0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  spreadRadius: 3,
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                        const LoginScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(1.0, 0.0),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        )),
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 600),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: AppTheme.primaryBlue,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_bus_filled_rounded,
                                    size: screenWidth * 0.045,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'CONNEXION',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.02),

                          // Bouton Signup responsive
                          Container(
                            width: double.infinity,
                            height: screenHeight * 0.055,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text('Inscription bientôt disponible !'),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.primaryOrange,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.person_add_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'INSCRIPTION',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Bouton "Pas maintenant"
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      const LoyaltyHomeScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 500),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.skip_next_rounded,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pas maintenant',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
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
                
                SizedBox(height: screenHeight * 0.015),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFeature(IconData icon, String label, Color color, double screenWidth) {
    final size = screenWidth * 0.09; // Taille responsive réduite
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(size * 0.3),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: size * 0.5,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: screenWidth * 0.022,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
