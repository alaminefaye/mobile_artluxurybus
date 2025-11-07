import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../theme/app_theme.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  List<Trip> _trips = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await TripService.getMyTrips();
      setState(() {
        _trips = response.trips;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement trajets: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mes Trajets',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTrips,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        color: AppTheme.primaryBlue,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryBlue,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTrips,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 80,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun trajet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous n\'avez pas encore de trajets enregistrés.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Header avec statistiques
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.primaryBlue.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${_trips.length}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _trips.length > 1 ? 'Trajets' : 'Trajet',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Liste des trajets
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final trip = _trips[index];
              return _buildTripCard(trip);
            },
            childCount: _trips.length,
          ),
        ),

        // Espace en bas
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }

  Widget _buildTripCard(Trip trip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: trip.isCancelled
            ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: trip.isCancelled
              ? Colors.red.withValues(alpha: 0.3)
              : AppTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTripDetails(trip),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec badge annulé
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.routeText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: trip.isCancelled
                                ? Colors.grey[600]
                                : Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        if (trip.depart?.numeroDepart != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Départ #${trip.depart!.numeroDepart}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trip.isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            size: 14,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Annulé',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Informations du voyage
              Row(
                children: [
                  // Date et heure
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: trip.formattedDate,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Heure de départ
                  if (trip.depart?.heureDepart != null)
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.access_time_rounded,
                        label: 'Départ',
                        value: trip.depart!.heureDepart!,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Siège et prix
              Row(
                children: [
                  if (trip.siegeNumber != null)
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.event_seat_rounded,
                        label: 'Siège',
                        value: '#${trip.siegeNumber}',
                        color: Colors.green,
                      ),
                    ),
                  if (trip.siegeNumber != null) const SizedBox(width: 12),
                  if (trip.prix != null)
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.monetization_on_rounded,
                        label: 'Prix',
                        value: '${trip.prix!.toStringAsFixed(0)} FCFA',
                        color: Colors.amber[700]!,
                      ),
                    ),
                ],
              ),

              // Arrêts d'embarquement/débarquement
              if (trip.embarkStop != null || trip.disembarkStop != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if (trip.embarkStop != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Embarquement: ${trip.embarkStop!.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (trip.disembarkStop != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppTheme.primaryOrange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Débarquement: ${trip.disembarkStop!.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],

              // Badges supplémentaires
              if (trip.isLoyaltyReward || trip.isPassthrough) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (trip.isLoyaltyReward)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.card_giftcard_rounded,
                              size: 12,
                              color: Colors.purple[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Points fidélité',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (trip.isPassthrough)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 12,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Transit',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTripDetails(Trip trip) {
    // GlobalKey pour obtenir la position du bouton de partage (iOS)
    final GlobalKey shareButtonKey = GlobalKey();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle avec bouton fermer et partager
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton Partager avec GlobalKey pour iOS
                      IconButton(
                        key: shareButtonKey,
                        icon: const Icon(Icons.share_rounded),
                        onPressed: () => _shareTicket(trip, shareButtonKey, context),
                        color: AppTheme.primaryBlue,
                        tooltip: 'Partager le ticket',
                      ),
                      // Bouton Fermer
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.grey[700],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Carte d'embarquement (Boarding Pass)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Screenshot(
                  controller: _screenshotController,
                  child: _buildBoardingPass(trip),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareTicket(Trip trip, GlobalKey? shareButtonKey, BuildContext context) async {
    try {
      // Afficher un indicateur de chargement
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Génération de l\'image...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Capturer le screenshot
      final imageBytes = await _screenshotController.capture();

      if (imageBytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la capture de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Sauvegarder temporairement l'image
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/ticket_${trip.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // Partager l'image
      if (!mounted) return;
      
      // Sur iOS, il faut spécifier sharePositionOrigin
      if (Platform.isIOS && shareButtonKey?.currentContext != null) {
        final RenderBox? renderBox = shareButtonKey!.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          
          await Share.shareXFiles(
            [XFile(imagePath)],
            text: 'Mon ticket de voyage - ART LUXURY BUS\n${trip.routeText}',
            subject: 'Ticket de voyage',
            sharePositionOrigin: Rect.fromLTWH(
              position.dx,
              position.dy,
              size.width,
              size.height,
            ),
          );
        } else {
          // Fallback si on ne peut pas obtenir la position
          await Share.shareXFiles(
            [XFile(imagePath)],
            text: 'Mon ticket de voyage - ART LUXURY BUS\n${trip.routeText}',
            subject: 'Ticket de voyage',
          );
        }
      } else {
        // Android ou si pas de position disponible
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Mon ticket de voyage - ART LUXURY BUS\n${trip.routeText}',
          subject: 'Ticket de voyage',
        );
      }

      // Supprimer le fichier temporaire après un délai
      Future.delayed(const Duration(seconds: 5), () {
        try {
          imageFile.deleteSync();
        } catch (e) {
          debugPrint('Erreur suppression fichier: $e');
        }
      });
    } catch (e) {
      debugPrint('❌ Erreur partage ticket: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBoardingPass(Trip trip) {
    var fromCity =
        trip.embarquement ?? trip.depart?.trajet?.embarquement ?? 'N/A';
    var toCity = trip.destination ?? trip.depart?.trajet?.destination ?? 'N/A';

    // Remplacer Yamoussoukro par YAKRO et mettre en majuscules
    if (toCity.toLowerCase().contains('yamoussoukro')) {
      toCity = 'YAKRO';
    } else {
      toCity = toCity.toUpperCase();
    }

    // Mettre la ville de départ en majuscules
    fromCity = fromCity.toUpperCase();

    final date = trip.depart?.dateDepartFormatted ?? trip.formattedDate;
    final time = trip.depart?.heureDepart ?? 'N/A';
    final seatNumber = trip.siegeNumber?.toString() ?? 'N/A';
    final ticketNumber = trip.depart?.numeroDepart ?? trip.id.toString();

    // Données pour le QR code
    final qrData = 'TICKET|${trip.id}|${trip.telephone}|${date}|${seatNumber}';

    // Détecter si c'est un laisser-passer
    final isLaisserPasser = trip.isPassthrough || trip.isLoyaltyReward || (trip.prix != null && trip.prix == 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLaisserPasser
            ? Border.all(
                color: Colors.orange,
                width: 3,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isLaisserPasser
                ? Colors.orange.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Filigrane pour laisser-passer
          if (isLaisserPasser)
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CustomPaint(
                    painter: WatermarkPainter(),
                  ),
                ),
              ),
            ),
          
          // Contenu du ticket
          Column(
            children: [
              // Section Header (Blanc)
              _buildBoardingHeader(trip, isLaisserPasser),

              // Section FROM/TO (Blanc avec design)
              _buildRouteSection(fromCity, toCity, date, time, isLaisserPasser),

              // Bandeau "BOARDING PASS" ou "LAISSER PASSER"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isLaisserPasser
                      ? LinearGradient(
                          colors: [
                            Colors.orange.shade600,
                            Colors.orange.shade800,
                          ],
                        )
                      : null,
                  color: isLaisserPasser ? null : AppTheme.primaryBlue,
                ),
                child: Center(
                  child: Text(
                    isLaisserPasser ? 'LAISSER PASSER' : 'TICKET D\'EMBARQUEMENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: isLaisserPasser
                          ? [
                              Shadow(
                                color: Colors.orange.shade900,
                                blurRadius: 4,
                                offset: const Offset(1, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),

              // Section Informations (Bleu/Orange selon le type)
              _buildInfoSection(trip, seatNumber, ticketNumber, isLaisserPasser),

              // Ligne pointillée de séparation (style boarding pass)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: List.generate(
                    60,
                    (index) => Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: index % 3 == 0
                              ? (isLaisserPasser
                                  ? Colors.orange.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.6))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // QR Code Section
              _buildQRSection(qrData, trip.id, isLaisserPasser),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoardingHeader(Trip trip, bool isLaisserPasser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo et nom
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: isLaisserPasser
                      ? LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        )
                      : null,
                  color: isLaisserPasser ? null : AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: isLaisserPasser
                      ? [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ART LUXURY BUS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          // Badge classe ou GRATUIT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: isLaisserPasser
                  ? LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.orange.shade600,
                      ],
                    )
                  : null,
              color: isLaisserPasser ? null : AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isLaisserPasser
                  ? [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              isLaisserPasser ? 'GRATUIT' : 'STANDARD',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection(
      String fromCity, String toCity, String date, String time, bool isLaisserPasser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isLaisserPasser ? Colors.orange : AppTheme.primaryBlue,
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          // Labels DE: et À:
          Row(
            children: [
              Text(
                'DE:',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'À:',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Villes alignées sur la même ligne
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ville de départ
              Expanded(
                child: Text(
                  fromCity,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Flèche
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: isLaisserPasser ? Colors.orange : AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              // Ville d'arrivée
              Expanded(
                child: Text(
                  toCity,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date et heure du départ
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Trip trip, String seatNumber, String ticketNumber, bool isLaisserPasser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLaisserPasser
              ? [
                  Colors.orange.shade600,
                  Colors.orange.shade800,
                ]
              : [
                  AppTheme.primaryBlue,
                  AppTheme.accentBlue,
                ],
        ),
      ),
      child: Column(
        children: [
          // Ligne 1: Passenger Name et Flight
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nom du Passager',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.nomComplet.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Départ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#$ticketNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ligne 2: Seat et Gate
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Siège',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seatNumber != 'N/A' ? seatNumber : '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (trip.depart?.bus?.registrationNumber != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.depart!.bus!.registrationNumber!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Prix ou badge LAISSER PASSER
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLaisserPasser ? 'Type' : 'Prix',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isLaisserPasser)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'GRATUIT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (trip.prix != null)
                      Text(
                        '${trip.prix!.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      )
                    else
                      Text(
                        '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection(String qrData, int ticketId, bool isLaisserPasser) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLaisserPasser
              ? [
                  Colors.orange.shade600,
                  Colors.orange.shade800,
                ]
              : [
                  AppTheme.primaryBlue,
            AppTheme.accentBlue,
          ],
        ),
      ),
      child: Column(
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 160.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ticket #$ticketId',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// CustomPainter pour le filigrane "LAISSER PASSER"
class WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: 'LAISSER\nPASSER',
      style: TextStyle(
        fontSize: 60,
        fontWeight: FontWeight.bold,
        color: Colors.orange.withValues(alpha: 0.15),
        letterSpacing: 4,
        height: 1.2,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: size.width);

    // Calculer la position pour centrer le texte
    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    // Dessiner le texte en diagonale
    canvas.save();
    canvas.translate(offset.dx + textPainter.width / 2, offset.dy + textPainter.height / 2);
    canvas.rotate(-0.5); // Rotation de -30 degrés environ
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(WatermarkPainter oldDelegate) => false;
}
