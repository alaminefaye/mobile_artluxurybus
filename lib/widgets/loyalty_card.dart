import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_loyalty_models.dart';
import '../providers/horaire_riverpod_provider.dart';

enum LoyaltyCardType { tickets, courriers, combined }

class LoyaltyCard extends ConsumerStatefulWidget {
  final LoyaltyClient client;
  final double screenWidth;
  final double screenHeight;
  final LoyaltyCardType cardType;
  final ValueNotifier<bool>? showingDeparturesNotifier;

  const LoyaltyCard({
    super.key,
    required this.client,
    required this.screenWidth,
    required this.screenHeight,
    required this.cardType,
    this.showingDeparturesNotifier,
  });

  @override
  ConsumerState<LoyaltyCard> createState() => _LoyaltyCardState();
}

class _LoyaltyCardState extends ConsumerState<LoyaltyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;
  Timer? _autoFlipTimer;
  Timer? _departureTimer;
  int _flipCount = 0;
  bool _showingDepartures = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    ));
    
    // Démarrer le timer pour le retournement automatique toutes les 5 secondes
    _startAutoFlip();
  }

  @override
  void dispose() {
    _autoFlipTimer?.cancel();
    _departureTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (!_controller.isAnimating && !_showingDepartures) {
      if (_isFlipped) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
      setState(() {
        _isFlipped = !_isFlipped;
        _flipCount++;
        
        // Après 8 flips (4 allers-retours complets), afficher les départs
        if (_flipCount >= 8) {
          _showingDepartures = true;
          _flipCount = 0;
          
          // Arrêter le timer de flip automatique
          _autoFlipTimer?.cancel();
          
          // Notifier le parent que les départs sont affichés
          debugPrint('🚀 [LoyaltyCard] Affichage du tableau des départs après 4 flips recto-verso - Notification envoyée');
          widget.showingDeparturesNotifier?.value = true;
          
          // Retour automatique après 1 minute
          _departureTimer?.cancel();
          _departureTimer = Timer(const Duration(minutes: 1), () {
            if (mounted) {
              setState(() {
                _showingDepartures = false;
                _isFlipped = false;
                _controller.reset();
              });
              // Notifier le parent que les départs sont masqués
              widget.showingDeparturesNotifier?.value = false;
              // Redémarrer le cycle de flips
              _startAutoFlip();
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si on affiche les départs, pas d'animation de flip
    if (_showingDepartures) {
      return _buildDeparturesBoard();
    }
    
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final isShowingFront = angle < math.pi / 2;
          
          // Calcul de la perspective et de l'échelle
          const perspective = 0.002; // Perspective plus prononcée
          final scale = (1.0 - (math.sin(angle) * 0.1)).clamp(0.9, 1.0); // Léger rétrécissement au milieu
          final shadowOpacity = (math.sin(angle) * 0.3).clamp(0.0, 0.3); // Ombre dynamique
          
          return Stack(
            children: [
              // Ombre dynamique
              Positioned(
                top: 4,
                left: 4,
                right: 4,
                bottom: 4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.screenWidth * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: shadowOpacity),
                        spreadRadius: 2,
                        blurRadius: 20,
                        offset: Offset(0, 8 + (math.sin(angle) * 10)),
                      ),
                    ],
                  ),
                ),
              ),
              // Carte avec animation
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, perspective)
                  ..scaleByVector3(Vector3(scale, scale, scale))
                  ..rotateY(isShowingFront ? angle : math.pi)
                  ..multiply(isShowingFront 
                      ? Matrix4.identity() 
                      : Matrix4.diagonal3Values(-1.0, 1.0, 1.0)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.screenWidth * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isShowingFront ? _buildFrontCard() : _buildBackCard(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      width: double.infinity,
      height: widget.screenHeight * 0.32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.screenWidth * 0.04),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A), // Noir profond
            Color(0xFF2D2D2D), // Gris foncé
            Color(0xFF1A1A1A),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            spreadRadius: 3,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Motif de carte de crédit
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: -50,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          
          // Contenu principal
          Padding(
            padding: EdgeInsets.all(widget.screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header avec logo et titre
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARTE FIDÉLITÉ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: widget.screenWidth * 0.025,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'ART LUXURY BUS',
                          style: TextStyle(
                            color: const Color(0xFFD4AF37), // Or
                            fontSize: widget.screenWidth * 0.035,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(widget.screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(widget.screenWidth * 0.02),
                      ),
                      child: Icon(
                        Icons.diamond,
                        color: const Color(0xFFD4AF37),
                        size: widget.screenWidth * 0.06,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: widget.screenHeight * 0.01),
                
                // Numéro de carte stylisé
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < 4; i++)
                      Text(
                        i == 0 ? widget.client.telephone.substring(0, 4) :
                        i == 1 ? '****' :
                        i == 2 ? '****' :
                        widget.client.telephone.substring(widget.client.telephone.length - 4),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.screenWidth * 0.045,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.0,
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: widget.screenHeight * 0.02),
                
                // Nom et points
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.client.nomComplet.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Membre depuis ${widget.client.memberSince ?? "2024"}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: widget.screenWidth * 0.025,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.screenWidth * 0.03,
                        vertical: widget.screenWidth * 0.015,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                        ),
                        borderRadius: BorderRadius.circular(widget.screenWidth * 0.03),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getDisplayPoints().toString(),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: widget.screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getPointsLabel(),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: widget.screenWidth * 0.02,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Indication de flip
          Positioned(
            bottom: widget.screenWidth * 0.02,
            right: widget.screenWidth * 0.02,
            child: Container(
              padding: EdgeInsets.all(widget.screenWidth * 0.01),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(widget.screenWidth * 0.01),
              ),
              child: Icon(
                Icons.flip,
                color: Colors.white.withValues(alpha: 0.6),
                size: widget.screenWidth * 0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    final displayPoints = _getDisplayPoints();
    
    return Container(
      width: double.infinity,
      height: widget.screenHeight * 0.32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.screenWidth * 0.04),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A), // Noir profond
            Color(0xFF2D2D2D), // Gris foncé
            Color(0xFF1A1A1A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            spreadRadius: 3,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.screenWidth * 0.05),
        child: Column(
          children: [
            // Titre
            Text(
              'CARTE FIDÉLITÉ',
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                fontSize: widget.screenWidth * 0.035,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'ART LUXURY BUS',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.screenWidth * 0.025,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.0,
              ),
            ),
            
            SizedBox(height: widget.screenHeight * 0.02),
            
            // Grille des 11 cases (2 rangées de 5 + 1 case cadeau)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Première rangée (5 cases)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) => _buildProgressCircle(index, displayPoints)),
                  ),
                  
                  SizedBox(height: widget.screenHeight * 0.015),
                  
                  // Deuxième rangée (5 cases)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) => _buildProgressCircle(index + 5, displayPoints)),
                  ),
                  
                  SizedBox(height: widget.screenHeight * 0.015),
                  
                  // Case cadeau gratuit (centrée)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProgressCircle(10, displayPoints), // 11ème case (index 10)
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: widget.screenHeight * 0.01),
            
            // Message de félicitations
            Text(
              displayPoints >= 10 ? 'Félicitations ! Vous pouvez obtenir un ${_getServiceType()} gratuit.' : 
              'Collectez ${10 - displayPoints} points de plus pour un ${_getServiceType()} gratuit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: widget.screenWidth * 0.025,
                fontStyle: FontStyle.italic,
              ),
            ),
            
            // Indication de retour
            Container(
              margin: EdgeInsets.only(top: widget.screenWidth * 0.02),
              padding: EdgeInsets.all(widget.screenWidth * 0.01),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(widget.screenWidth * 0.01),
              ),
              child: Icon(
                Icons.flip,
                color: Colors.white.withValues(alpha: 0.6),
                size: widget.screenWidth * 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCircle(int index, int displayPoints) {
    final isCompleted = index < displayPoints;
    final isFree = index == 10; // Le 11ème cercle (index 10) représente le cadeau
    final canGetFree = displayPoints >= 10; // Peut obtenir le cadeau si 10 points ou plus
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: isCompleted || (isFree && canGetFree) ? 1.0 : 0.0),
      builder: (context, value, child) {
        return Container(
          width: isFree ? widget.screenWidth * 0.09 : widget.screenWidth * 0.06, // Cases plus petites
          height: isFree ? widget.screenWidth * 0.09 : widget.screenWidth * 0.06,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isCompleted || (isFree && canGetFree))
                ? Color.lerp(Colors.grey.withValues(alpha: 0.3), const Color(0xFFD4AF37), value)
                : Colors.grey.withValues(alpha: 0.3),
            border: Border.all(
              color: (isCompleted || (isFree && canGetFree)) ? const Color(0xFFD4AF37) : Colors.grey.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isFree
                ? Icon(
                    canGetFree ? Icons.card_giftcard : Icons.card_giftcard_outlined,
                    color: canGetFree ? Colors.black : Colors.white.withValues(alpha: 0.6),
                    size: widget.screenWidth * 0.04,
                  )
                : isCompleted
                    ? Icon(
                        Icons.directions_bus_rounded, // Icône de bus au lieu de check
                        color: Colors.black,
                        size: widget.screenWidth * 0.03,
                      )
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: widget.screenWidth * 0.02,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
          ),
        );
      },
    );
  }

  // Tableau des départs style aéroport
  Widget _buildDeparturesBoard() {
    // Récupérer les horaires depuis le provider
    final horaires = ref.watch(prochainsDepartsProvider);
    
    // Convertir les horaires en format compatible avec le carrousel
    final departures = horaires.take(14).map((h) {
      // Déterminer le statut en français
      String statutText;
      switch (h.statut) {
        case 'a_l_heure':
          statutText = 'À l\'heure';
          break;
        case 'embarquement':
          statutText = 'Embarquement';
          break;
        case 'termine':
          statutText = 'Terminé';
          break;
        default:
          statutText = 'À l\'heure';
      }

      return {
        'destination': h.trajet.destination,
        'time': h.heure,
        'gate': h.busNumber ?? 'N/A',
        'status': statutText,
      };
    }).toList();

    // Si pas de données, afficher un message
    if (departures.isEmpty) {
      return Container(
        width: widget.screenWidth * 0.95,
        height: widget.screenHeight * 0.8,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade800, Colors.grey.shade900],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'Aucun départ disponible',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _DeparturesBoardCarousel(
      allDepartures: departures,
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
    );
  }

  void _startAutoFlip() {
    _autoFlipTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_controller.isAnimating) {
        _flip();
      }
    });
  }

  // Méthodes helper pour le type de carte spécifique
  int _getDisplayPoints() {
    switch (widget.cardType) {
      case LoyaltyCardType.tickets:
        return widget.client.pointsTickets;
      case LoyaltyCardType.courriers:
        return widget.client.pointsCourriers;
      case LoyaltyCardType.combined:
        return widget.client.totalPoints;
    }
  }

  String _getPointsLabel() {
    switch (widget.cardType) {
      case LoyaltyCardType.tickets:
        return 'TICKETS';
      case LoyaltyCardType.courriers:
        return 'COURRIERS';
      case LoyaltyCardType.combined:
        return 'POINTS';
    }
  }

  String _getServiceType() {
    switch (widget.cardType) {
      case LoyaltyCardType.tickets:
        return 'ticket';
      case LoyaltyCardType.courriers:
        return 'envoi de courrier';
      case LoyaltyCardType.combined:
        return 'service';
    }
  }
}

// Widget séparé pour gérer le carrousel des départs
class _DeparturesBoardCarousel extends StatefulWidget {
  final List<Map<String, String>> allDepartures;
  final double screenWidth;
  final double screenHeight;

  const _DeparturesBoardCarousel({
    required this.allDepartures,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<_DeparturesBoardCarousel> createState() => _DeparturesBoardCarouselState();
}

class _DeparturesBoardCarouselState extends State<_DeparturesBoardCarousel> with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  Timer? _carouselTimer;
  late AnimationController _busAnimationController;
  late Animation<double> _busAnimation;
  static const int _itemsPerPage = 7;
  static const Duration _pageDuration = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _startCarousel();
    
    // Animation du bus qui roule en continu de gauche à droite
    _busAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _busAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _busAnimationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _busAnimationController.dispose();
    super.dispose();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(_pageDuration, (timer) {
      if (mounted) {
        setState(() {
          final totalPages = (widget.allDepartures.length / _itemsPerPage).ceil();
          _currentPage = (_currentPage + 1) % totalPages;
        });
      }
    });
  }

  List<Map<String, String>> _getCurrentDepartures() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, widget.allDepartures.length);
    return widget.allDepartures.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final departures = _getCurrentDepartures();
    final totalPages = (widget.allDepartures.length / _itemsPerPage).ceil();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<int>(_currentPage),
        width: double.infinity,
        height: widget.screenHeight * 0.32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.screenWidth * 0.04),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF2D2D2D),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              spreadRadius: 3,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header style aéroport
            Container(
              padding: EdgeInsets.all(widget.screenWidth * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.screenWidth * 0.04),
                  topRight: Radius.circular(widget.screenWidth * 0.04),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'DÉPARTS',
                        style: TextStyle(
                          color: const Color(0xFFD4AF37),
                          fontSize: widget.screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(width: widget.screenWidth * 0.02),
                      // Bus animé qui roule de gauche à droite (dessin personnalisé)
                      SizedBox(
                        width: widget.screenWidth * 0.12,
                        height: widget.screenWidth * 0.06,
                        child: AnimatedBuilder(
                          animation: _busAnimation,
                          builder: (context, child) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Bus dessiné de profil
                                Positioned(
                                  left: (_busAnimation.value * widget.screenWidth * 0.12) - (widget.screenWidth * 0.05),
                                  child: CustomPaint(
                                    size: Size(widget.screenWidth * 0.08, widget.screenWidth * 0.04),
                                    painter: _BusPainter(color: const Color(0xFFD4AF37)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Indicateur de page
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.screenWidth * 0.02,
                          vertical: widget.screenWidth * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(widget.screenWidth * 0.02),
                        ),
                        child: Text(
                          '${_currentPage + 1}/$totalPages',
                          style: TextStyle(
                            color: const Color(0xFFD4AF37),
                            fontSize: widget.screenWidth * 0.025,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: widget.screenWidth * 0.02),
                      Text(
                        DateTime.now().toString().substring(11, 16),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.screenWidth * 0.03,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tableau des départs avec animation ligne par ligne
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: departures.length,
                itemBuilder: (context, index) {
                  final departure = departures[index];
                  final isBoarding = departure['status'] == 'Embarquement';
                  final isTermine = departure['status'] == 'Terminé';
                  
                  // Animation avec délai progressif pour chaque ligne (plus lent et visible)
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 600 + (index * 200)), // Plus lent: 200ms entre chaque ligne
                    curve: Curves.easeOutCubic, // Courbe fluide sans rebond pour éviter les valeurs > 1.0
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      // Clamp pour s'assurer que la valeur est toujours entre 0.0 et 1.0
                      final clampedValue = value.clamp(0.0, 1.0);
                      
                      return Transform.translate(
                        offset: Offset((1 - clampedValue) * 100, 0), // Glisse plus loin: 100px au lieu de 50px
                        child: Opacity(
                          opacity: clampedValue,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.screenWidth * 0.03,
                              vertical: widget.screenWidth * 0.02,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Heure
                                SizedBox(
                                  width: widget.screenWidth * 0.12,
                                  child: Text(
                                    departure['time']!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: widget.screenWidth * 0.032,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                
                                // Destination
                                Expanded(
                                  child: Text(
                                    departure['destination']!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: widget.screenWidth * 0.03,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                
                                // Porte
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.screenWidth * 0.02,
                                    vertical: widget.screenWidth * 0.01,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(widget.screenWidth * 0.01),
                                  ),
                                  child: Text(
                                    departure['gate']!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: widget.screenWidth * 0.025,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                
                                SizedBox(width: widget.screenWidth * 0.02),
                                
                                // Statut
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.screenWidth * 0.02,
                                    vertical: widget.screenWidth * 0.01,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isTermine 
                                        ? Colors.red.withValues(alpha: 0.2)
                                        : isBoarding
                                            ? Colors.green.withValues(alpha: 0.2)
                                            : Colors.blue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(widget.screenWidth * 0.01),
                                  ),
                                  child: Text(
                                    departure['status']!,
                                    style: TextStyle(
                                      color: isTermine 
                                          ? Colors.red
                                          : isBoarding
                                              ? Colors.green
                                              : Colors.blue,
                                      fontSize: widget.screenWidth * 0.022,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter personnalisé pour dessiner un bus de profil
class _BusPainter extends CustomPainter {
  final Color color;

  _BusPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;

    // Corps principal du bus (rectangle arrondi)
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(width * 0.15, height * 0.2, width * 0.7, height * 0.5),
      topLeft: Radius.circular(height * 0.15),
      topRight: Radius.circular(height * 0.15),
      bottomLeft: Radius.circular(height * 0.1),
      bottomRight: Radius.circular(height * 0.1),
    );
    canvas.drawRRect(bodyRect, paint);

    // Avant du bus (partie arrondie)
    final frontPath = Path()
      ..moveTo(width * 0.85, height * 0.3)
      ..lineTo(width * 0.95, height * 0.35)
      ..lineTo(width * 0.95, height * 0.65)
      ..lineTo(width * 0.85, height * 0.7)
      ..close();
    canvas.drawPath(frontPath, paint);

    // Fenêtres (rectangles plus clairs)
    final windowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Fenêtre avant
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.75, height * 0.3, width * 0.15, height * 0.25),
        Radius.circular(height * 0.05),
      ),
      windowPaint,
    );

    // Fenêtres latérales
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.55, height * 0.25, width * 0.15, height * 0.3),
        Radius.circular(height * 0.05),
      ),
      windowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.35, height * 0.25, width * 0.15, height * 0.3),
        Radius.circular(height * 0.05),
      ),
      windowPaint,
    );

    // Roues (cercles)
    final wheelPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = height * 0.08;

    canvas.drawCircle(
      Offset(width * 0.25, height * 0.85),
      height * 0.12,
      wheelPaint,
    );

    canvas.drawCircle(
      Offset(width * 0.75, height * 0.85),
      height * 0.12,
      wheelPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
