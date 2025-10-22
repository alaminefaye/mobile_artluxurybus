import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/loyalty_provider.dart';
import '../models/simple_loyalty_models.dart';
import '../widgets/loyalty_card.dart';
import 'loyalty_check_screen.dart';

class LoyaltyHomeScreen extends ConsumerStatefulWidget {
  const LoyaltyHomeScreen({super.key});

  @override
  ConsumerState<LoyaltyHomeScreen> createState() => _LoyaltyHomeScreenState();
}

class _LoyaltyHomeScreenState extends ConsumerState<LoyaltyHomeScreen> {
  LoyaltyCardType _selectedCardType = LoyaltyCardType.tickets;

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
        color: Colors.white,
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
            width: screenWidth * 0.18,
            height: screenWidth * 0.18,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(screenWidth * 0.06),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              size: screenWidth * 0.09,
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
                  fontSize: screenWidth * 0.04,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Programme Fidélité',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.055,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.03),

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

          SizedBox(height: screenHeight * 0.03),

          // Aperçu de la carte de fidélité
          _buildPreviewLoyaltyCard(screenWidth, screenHeight),

          SizedBox(height: screenHeight * 0.03),

          // Description responsive
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
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
            // Boutons de sélection
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCardType = LoyaltyCardType.tickets;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: screenWidth * 0.03,
                          horizontal: screenWidth * 0.04,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedCardType == LoyaltyCardType.tickets
                              ? AppTheme.primaryBlue
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.confirmation_number_rounded,
                              color: _selectedCardType == LoyaltyCardType.tickets
                                  ? Colors.white
                                  : AppTheme.primaryBlue,
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'TICKETS',
                              style: TextStyle(
                                color: _selectedCardType == LoyaltyCardType.tickets
                                    ? Colors.white
                                    : AppTheme.primaryBlue,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCardType = LoyaltyCardType.courriers;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: screenWidth * 0.03,
                          horizontal: screenWidth * 0.04,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedCardType == LoyaltyCardType.courriers
                              ? AppTheme.primaryOrange
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mail_rounded,
                              color: _selectedCardType == LoyaltyCardType.courriers
                                  ? Colors.white
                                  : AppTheme.primaryOrange,
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'COURRIERS',
                              style: TextStyle(
                                color: _selectedCardType == LoyaltyCardType.courriers
                                    ? Colors.white
                                    : AppTheme.primaryOrange,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Carte de fidélité interactive
            LoyaltyCard(
              client: client,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              cardType: _selectedCardType,
            ),

            SizedBox(height: screenHeight * 0.03),

            // Historique des transactions
            _buildTransactionHistory(screenWidth, screenHeight),

            SizedBox(height: screenHeight * 0.1), // Espace pour le scroll
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewLoyaltyCard(double screenWidth, double screenHeight) {
    // Client factice pour la prévisualisation
    const previewClient = LoyaltyClient(
      id: 0,
      nomComplet: 'Votre Nom',
      nom: 'Nom',
      prenom: 'Prénom',
      telephone: '****',
      pointsTickets: 3,
      pointsCourriers: 5,
      totalPoints: 8,
      canGetFreeTicket: false,
      canGetFreeMail: false,
      createdAt: '2024',
    );

    return SizedBox(
      height: screenHeight * 0.32,
      child: LoyaltyCard(
        client: previewClient,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        cardType: LoyaltyCardType.tickets,
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

  Widget _buildTransactionHistory(double screenWidth, double screenHeight) {
    // Générer des transactions factices pour la démo
    // En production, ceci viendrait de l'historique du client
    final List<Map<String, dynamic>> recentTransactions = [
      {
        'type': _selectedCardType == LoyaltyCardType.tickets ? 'ticket' : 'courrier',
        'description': _selectedCardType == LoyaltyCardType.tickets 
            ? 'Voyage Abidjan → Bouaké'
            : 'Envoi courrier Abidjan',
        'points': '+1',
        'date': '15 Oct 2024',
        'icon': _selectedCardType == LoyaltyCardType.tickets 
            ? Icons.directions_bus_rounded
            : Icons.mail_rounded,
      },
      {
        'type': _selectedCardType == LoyaltyCardType.tickets ? 'ticket' : 'courrier',
        'description': _selectedCardType == LoyaltyCardType.tickets 
            ? 'Voyage Bouaké → Yamoussoukro'
            : 'Envoi courrier Bouaké',
        'points': '+1',
        'date': '12 Oct 2024',
        'icon': _selectedCardType == LoyaltyCardType.tickets 
            ? Icons.directions_bus_rounded
            : Icons.mail_rounded,
      },
      {
        'type': _selectedCardType == LoyaltyCardType.tickets ? 'ticket' : 'courrier',
        'description': _selectedCardType == LoyaltyCardType.tickets 
            ? 'Voyage Yamoussoukro → Abidjan'
            : 'Envoi courrier Yamoussoukro',
        'points': '+1',
        'date': '10 Oct 2024',
        'icon': _selectedCardType == LoyaltyCardType.tickets 
            ? Icons.directions_bus_rounded
            : Icons.mail_rounded,
      },
      {
        'type': 'gratuit',
        'description': _selectedCardType == LoyaltyCardType.tickets 
            ? 'Ticket gratuit utilisé'
            : 'Courrier gratuit utilisé',
        'points': '-10',
        'date': '08 Oct 2024',
        'icon': Icons.card_giftcard,
      },
      {
        'type': _selectedCardType == LoyaltyCardType.tickets ? 'ticket' : 'courrier',
        'description': _selectedCardType == LoyaltyCardType.tickets 
            ? 'Voyage Abidjan → San-Pédro'
            : 'Envoi courrier San-Pédro',
        'points': '+1',
        'date': '05 Oct 2024',
        'icon': _selectedCardType == LoyaltyCardType.tickets 
            ? Icons.directions_bus_rounded
            : Icons.mail_rounded,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: _selectedCardType == LoyaltyCardType.tickets 
                      ? AppTheme.primaryBlue 
                      : AppTheme.primaryOrange,
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  'Historique récent',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des transactions
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            itemCount: 5,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey.withValues(alpha: 0.3),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final transaction = recentTransactions[index];
              final isPositive = transaction['points'].startsWith('+');
              
              return Padding(
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                child: Row(
                  children: [
                    // Icône
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: (transaction['type'] == 'gratuit' 
                            ? Colors.green 
                            : (_selectedCardType == LoyaltyCardType.tickets 
                                ? AppTheme.primaryBlue 
                                : AppTheme.primaryOrange))
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Icon(
                        transaction['icon'],
                        color: transaction['type'] == 'gratuit' 
                            ? Colors.green 
                            : (_selectedCardType == LoyaltyCardType.tickets 
                                ? AppTheme.primaryBlue 
                                : AppTheme.primaryOrange),
                        size: screenWidth * 0.05,
                      ),
                    ),
                    
                    SizedBox(width: screenWidth * 0.03),
                    
                    // Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction['description'],
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            transaction['date'],
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color: AppTheme.textDark.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Points
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.025,
                        vertical: screenWidth * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: Text(
                        '${transaction['points']} pts',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          SizedBox(height: screenWidth * 0.02),
        ],
      ),
    );
  }

}
