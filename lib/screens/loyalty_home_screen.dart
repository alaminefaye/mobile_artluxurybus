import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/loyalty_provider.dart';
import '../models/simple_loyalty_models.dart';
import 'loyalty_check_screen.dart';

class LoyaltyHomeScreen extends ConsumerStatefulWidget {
  const LoyaltyHomeScreen({super.key});

  @override
  ConsumerState<LoyaltyHomeScreen> createState() => _LoyaltyHomeScreenState();
}

class _LoyaltyHomeScreenState extends ConsumerState<LoyaltyHomeScreen> {

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    final loyaltyState = ref.watch(loyaltyProvider);
    final client = loyaltyState.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programme Fidélité'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            // Si on a un client (dashboard), aller à la page de recherche
            // Sinon, retour normal
            if (client != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoyaltyCheckScreen()),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlue.withValues(alpha: 0.8),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Contenu principal sans header
              Expanded(
                child: client != null
                    ? _buildClientDashboard(client, screenWidth, screenHeight)
                    : _buildWelcomeSection(screenWidth, screenHeight),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildWelcomeSection(double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône principale responsive
          Container(
            width: screenWidth * 0.25,
            height: screenWidth * 0.25,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(screenWidth * 0.08),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  spreadRadius: 3,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              size: screenWidth * 0.12,
              color: Colors.white,
            ),
          ),

          SizedBox(height: screenHeight * 0.05),

          // Titre directement en blanc sur le fond
          Column(
            children: [
              Text(
                'Bienvenue dans votre',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Programme Fidélité',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.07,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.03),

          // Description responsive
          Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Cumulez des points à chaque voyage et bénéficiez de tickets et envois de courrier gratuits !',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: AppTheme.textDark,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                // Avantages responsives
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBenefit(
                      Icons.confirmation_number_rounded,
                      '10 Points',
                      'Ticket Gratuit',
                      AppTheme.primaryBlue,
                      screenWidth,
                    ),
                    _buildBenefit(
                      Icons.mail_rounded,
                      '10 Points',
                      'Courrier Gratuit',
                      AppTheme.primaryOrange,
                      screenWidth,
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.05),

          // Bouton d'action responsive
          Container(
            width: double.infinity,
            height: screenHeight * 0.065,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoyaltyCheckScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: screenWidth * 0.06,
                    color: Colors.white,
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Text(
                    'Vérifier mes points',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDashboard(LoyaltyClient client, double screenWidth, double screenHeight) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(loyaltyProvider.notifier).refreshClient();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de profil responsive
            _buildProfileCard(client, screenWidth, screenHeight),

            SizedBox(height: screenHeight * 0.03),

            // Cartes de points responsives
            Row(
              children: [
                Expanded(
                  child: _buildPointsCard(
                    title: 'Tickets',
                    points: client.pointsTickets,
                    maxPoints: 10,
                    progress: client.ticketsProgress,
                    color: AppTheme.primaryBlue,
                    icon: Icons.confirmation_number_rounded,
                    canGetFree: client.canGetFreeTicket,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: _buildPointsCard(
                    title: 'Courriers',
                    points: client.pointsCourriers,
                    maxPoints: 10,
                    progress: client.mailsProgress,
                    color: AppTheme.primaryOrange,
                    icon: Icons.mail_rounded,
                    canGetFree: client.canGetFreeMail,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.1), // Espace pour le scroll
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(LoyaltyClient client, double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Photo de profil et nom
          Row(
            children: [
              CircleAvatar(
                radius: screenWidth * 0.08,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person_rounded,
                  size: screenWidth * 0.08,
                  color: AppTheme.primaryBlue,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.nomComplet,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'Membre fidélité',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.025),

          // Statistiques
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                  AppTheme.primaryOrange.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  'Total Points',
                  '${client.pointsTickets + client.pointsCourriers}',
                  Icons.star_rounded,
                  screenWidth,
                ),
                _buildStat(
                  'Téléphone',
                  client.telephone,
                  Icons.phone_rounded,
                  screenWidth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard({
    required String title,
    required int points,
    required int maxPoints,
    required double progress,
    required Color color,
    required IconData icon,
    required bool canGetFree,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header avec icône
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: screenWidth * 0.07,
              ),
              if (canGetFree)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: screenWidth * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Text(
                    'GRATUIT !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.025,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: screenHeight * 0.015),

          // Points
          Text(
            '$points/$maxPoints',
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: screenHeight * 0.015),

          // Barre de progression
          Container(
            width: double.infinity,
            height: screenHeight * 0.01,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(screenHeight * 0.005),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(screenHeight * 0.005),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String points, String benefit, Color color, double screenWidth) {
    return Column(
      children: [
        Container(
          width: screenWidth * 0.12,
          height: screenWidth * 0.12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          child: Icon(
            icon,
            color: color,
            size: screenWidth * 0.06,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        Text(
          points,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          benefit,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: screenWidth * 0.025,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, IconData icon, double screenWidth) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryBlue,
          size: screenWidth * 0.05,
        ),
        SizedBox(height: screenWidth * 0.01),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.025,
            color: AppTheme.textDark.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
