import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/loyalty_provider.dart';
import '../providers/horaire_riverpod_provider.dart';
import '../models/simple_loyalty_models.dart';
import '../widgets/loyalty_card.dart';
import '../widgets/ad_banner.dart';
import '../services/translation_service.dart';
import 'loyalty_check_screen.dart';

class LoyaltyHomeScreen extends ConsumerStatefulWidget {
  const LoyaltyHomeScreen({super.key});

  @override
  ConsumerState<LoyaltyHomeScreen> createState() => _LoyaltyHomeScreenState();
}

class _LoyaltyHomeScreenState extends ConsumerState<LoyaltyHomeScreen> {
  LoyaltyCardType _selectedCardType = LoyaltyCardType.tickets;
  Future<LoyaltyProfileResponse?>? _profileFuture;
  final ValueNotifier<bool> _showingDepartures = ValueNotifier<bool>(false);
  int _adBannerKey = 0; // Pour forcer le rafraîchissement de la bannière pub

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  @override
  void initState() {
    super.initState();
    // Déclencher le chargement du profil après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loyaltyState = ref.read(loyaltyProvider);
      debugPrint('🟢 [LoyaltyHomeScreen] initState - Client exists: ${loyaltyState.client != null}');
      
      if (loyaltyState.client != null) {
        final notifier = ref.read(loyaltyProvider.notifier);
        setState(() {
          _profileFuture = notifier.getClientProfile();
        });
      } else {
        debugPrint('⚠️ [LoyaltyHomeScreen] No client in state, cannot load profile');
      }
    });
  }

  @override
  void dispose() {
    // Nettoyer les données quand on quitte définitivement la page
    debugPrint('🔴 [LoyaltyHomeScreen] dispose - Clearing client data');
    _showingDepartures.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    final loyaltyState = ref.watch(loyaltyProvider);
    final client = loyaltyState.client;

    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          // Toujours effacer la session lors du retour
          debugPrint('🔵 [LoyaltyHomeScreen] PopScope - Clearing session and exiting');
          ref.read(loyaltyProvider.notifier).reset();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('loyalty.title')),
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.primaryOrange 
              : AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              // Toujours déconnecter et revenir en arrière
              debugPrint('🔵 [LoyaltyHomeScreen] Back button - Clearing session and exiting');
              ref.read(loyaltyProvider.notifier).reset();
              Navigator.of(context).pop();
            },
          ),
        ),
      body: Container(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).scaffoldBackgroundColor 
            : Colors.white,
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
      ),
    );
  }


  Widget _buildWelcomeSection(double screenWidth, double screenHeight) {
    return RefreshIndicator(
      onRefresh: () async {
        // Rafraîchir les publicités en recréant le widget
        debugPrint('🔄 [LoyaltyHomeScreen] Actualisation des publicités');
        setState(() {
          _adBannerKey++; // Change la clé pour recréer le widget
        });
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: Theme.of(context).brightness == Brightness.dark 
          ? AppTheme.primaryOrange 
          : AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Publicité en haut
          ClipRRect(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            child: AdBanner(key: ValueKey(_adBannerKey)),
          ),

          SizedBox(height: screenHeight * 0.03),

          // Bouton d'action responsive
          Container(
            width: double.infinity,
            height: screenHeight * 0.065,
            decoration: BoxDecoration(
              gradient: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.accentGradient 
                  : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              boxShadow: [
                BoxShadow(
                  color: (Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.primaryOrange 
                      : AppTheme.primaryBlue).withValues(alpha: 0.3),
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
                    t('loyalty.check_points'),
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

          // Description responsive - Masquée complètement quand le tableau des départs est affiché
          ValueListenableBuilder<bool>(
            valueListenable: _showingDepartures,
            builder: (context, showingDepartures, child) {
              debugPrint('📦 [LoyaltyHomeScreen] Boxes - showingDepartures: $showingDepartures');
              if (showingDepartures) {
                debugPrint('🚫 [LoyaltyHomeScreen] Masquage des boxes');
                return const SizedBox.shrink(); // Masquer tout le container
              }
              debugPrint('✅ [LoyaltyHomeScreen] Affichage des boxes');
              return Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Theme.of(context).cardColor 
                      : Colors.white,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBenefit(
                      Icons.confirmation_number_rounded,
                      '10 ${t("loyalty.points")}',
                      t('loyalty.free_ticket'),
                      Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : AppTheme.primaryBlue,
                      screenWidth,
                    ),
                    _buildBenefit(
                      Icons.mail_rounded,
                      '10 ${t("loyalty.points")}',
                      t('loyalty.free_mail'),
                      AppTheme.primaryOrange,
                      screenWidth,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildClientDashboard(LoyaltyClient client, double screenWidth, double screenHeight) {
    return RefreshIndicator(
      onRefresh: () async {
        // Rafraîchir le profil client
        final loyaltyNotifier = ref.read(loyaltyProvider.notifier);
        await loyaltyNotifier.refreshClient();
        setState(() { 
          _profileFuture = loyaltyNotifier.getClientProfile();
          _adBannerKey++; // Rafraîchir aussi les publicités
        });
        await _profileFuture;
        
        // Rafraîchir les horaires
        final horaireNotifier = ref.read(horaireProvider.notifier);
        await horaireNotifier.refresh();
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
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Theme.of(context).cardColor 
                    : Colors.white,
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
                              ? (Theme.of(context).brightness == Brightness.dark 
                                  ? AppTheme.primaryOrange 
                                  : AppTheme.primaryBlue)
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
                                  : (Theme.of(context).brightness == Brightness.dark 
                                      ? AppTheme.primaryOrange 
                                      : AppTheme.primaryBlue),
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              t('loyalty.tickets_tab'),
                              style: TextStyle(
                                color: _selectedCardType == LoyaltyCardType.tickets
                                    ? Colors.white
                                    : (Theme.of(context).brightness == Brightness.dark 
                                        ? AppTheme.primaryOrange 
                                        : AppTheme.primaryBlue),
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
                              t('loyalty.mails_tab'),
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
              showingDeparturesNotifier: _showingDepartures,
            ),

            // Boxes "10 Points" - Masquées complètement quand le tableau des départs est affiché
            ValueListenableBuilder<bool>(
              valueListenable: _showingDepartures,
              builder: (context, showingDepartures, child) {
                if (showingDepartures) {
                  debugPrint('🚫 [Client] Masquage des boxes 10 Points');
                  return const SizedBox.shrink(); // Pas d'espace du tout
                }
                return Column(
                  children: [
                    SizedBox(height: screenHeight * 0.03),
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Theme.of(context).cardColor 
                            : Colors.white,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildBenefit(
                            Icons.confirmation_number_rounded,
                            '10 ${t("loyalty.points")}',
                            t('loyalty.free_ticket'),
                            Theme.of(context).brightness == Brightness.dark 
                                ? AppTheme.primaryOrange 
                                : AppTheme.primaryBlue,
                            screenWidth,
                          ),
                          _buildBenefit(
                            Icons.mail_rounded,
                            '10 ${t("loyalty.points")}',
                            t('loyalty.free_mail'),
                            AppTheme.primaryOrange,
                            screenWidth,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                  ],
                );
              },
            ),

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
        showingDeparturesNotifier: _showingDepartures,
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
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : color,
          ),
        ),
        Text(
          benefit,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: screenWidth * 0.025,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withValues(alpha: 0.8) 
                : AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistory(double screenWidth, double screenHeight) {
    if (_profileFuture == null) {
      // Afficher un loader la toute première fois, le fetch est lancé en initState
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Theme.of(context).cardColor 
              : Colors.white,
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
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<LoyaltyProfileResponse?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Theme.of(context).cardColor 
                  : Colors.white,
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
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.history == null) {
          // Debug logs
          debugPrint('🔴 LOYALTY HISTORY ERROR:');
          debugPrint('  - hasError: ${snapshot.hasError}');
          debugPrint('  - error: ${snapshot.error}');
          debugPrint('  - data is null: ${snapshot.data == null}');
          debugPrint('  - history is null: ${snapshot.data?.history == null}');
          if (snapshot.data != null) {
            debugPrint('  - success: ${snapshot.data!.success}');
            debugPrint('  - message: ${snapshot.data!.message}');
          }
          
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Theme.of(context).cardColor 
                  : Colors.white,
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
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Row(
              children: [
                Icon(
                  Icons.history, 
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white.withValues(alpha: 0.6) 
                      : AppTheme.textDark.withValues(alpha: 0.6),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    t('loyalty.no_history_found'),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withValues(alpha: 0.7) 
                          : AppTheme.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final history = snapshot.data!.history!;
        final isTickets = _selectedCardType == LoyaltyCardType.tickets;
        final items = isTickets ? history.recentTickets : history.recentMails;
        
        // Debug logs
        debugPrint('✅ LOYALTY HISTORY LOADED:');
        debugPrint('  - Card Type: ${isTickets ? "TICKETS" : "COURRIERS"}');
        debugPrint('  - Recent Tickets: ${history.recentTickets.length}');
        debugPrint('  - Recent Mails: ${history.recentMails.length}');
        debugPrint('  - Total Tickets Count: ${history.totalTicketsCount}');
        debugPrint('  - Total Mails Count: ${history.totalMailsCount}');
        debugPrint('  - Items to display: ${items.length}');

        return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).cardColor 
            : Colors.white,
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
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.primaryOrange 
                      : (_selectedCardType == LoyaltyCardType.tickets 
                          ? AppTheme.primaryBlue 
                          : AppTheme.primaryOrange),
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  t('loyalty.recent_history'),
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des transactions
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Text(
                t('loyalty.no_recent_activity'),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white.withValues(alpha: 0.6) 
                      : AppTheme.textDark.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey.withValues(alpha: 0.3),
                height: 1,
              ),
              itemBuilder: (context, index) {
                if (isTickets) {
                  final t = items[index] as LoyaltyTicket;
                  final desc = 'Voyage ${t.embarquement} → ${t.destination}';
                  final date = t.createdAt.isNotEmpty ? t.createdAt : t.dateDepart;
                  final isLoyalty = t.isLoyaltyReward;
                  return _historyRow(
                    screenWidth,
                    icon: isLoyalty ? Icons.card_giftcard_rounded : Icons.directions_bus_rounded,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.primaryOrange 
                        : AppTheme.primaryBlue,
                    description: desc,
                    date: date,
                    pointsLabel: isLoyalty ? 'GRATUIT' : '+1 pts',
                    badgeColor: isLoyalty ? Colors.purple : Colors.green,
                  );
                } else {
                  final m = items[index] as LoyaltyMail;
                  final destinataireText = m.destinataire.isNotEmpty ? m.destinataire : t('loyalty.recipient');
                  final desc = t('loyalty.mail_for').replaceAll('{{recipient}}', destinataireText).replaceAll('{{destination}}', m.villeDestination);
                  final date = m.createdAt;
                  final isLoyalty = m.isLoyaltyMail;
                  return _historyRow(
                    screenWidth,
                    icon: isLoyalty ? Icons.card_giftcard_rounded : Icons.mail_rounded,
                    color: AppTheme.primaryOrange,
                    description: desc,
                    date: date,
                    pointsLabel: isLoyalty ? 'GRATUIT' : '+1 pts',
                    badgeColor: isLoyalty ? Colors.purple : Colors.green,
                  );
                }
              },
            ),
          
          SizedBox(height: screenWidth * 0.02),
        ],
      ),
    );
      },
    );
  }

  Widget _historyRow(double screenWidth, {required IconData icon, required Color color, required String description, required String date, required String pointsLabel, Color? badgeColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Icon(icon, color: color, size: screenWidth * 0.05),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : AppTheme.textDark,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white.withValues(alpha: 0.7) 
                        : AppTheme.textDark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.025,
              vertical: screenWidth * 0.01,
            ),
            decoration: BoxDecoration(
              color: badgeColor ?? Colors.green,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
            child: Text(
              pointsLabel,
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
  }

}
