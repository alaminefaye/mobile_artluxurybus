import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../models/simple_loyalty_models.dart';

enum LoyaltyCardType { tickets, courriers, combined }

class LoyaltyCard extends StatefulWidget {
  final LoyaltyClient client;
  final double screenWidth;
  final double screenHeight;
  final LoyaltyCardType cardType;

  const LoyaltyCard({
    super.key,
    required this.client,
    required this.screenWidth,
    required this.screenHeight,
    required this.cardType,
  });

  @override
  State<LoyaltyCard> createState() => _LoyaltyCardState();
}

class _LoyaltyCardState extends State<LoyaltyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;
  Timer? _autoFlipTimer;

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
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (!_controller.isAnimating) {
      if (_isFlipped) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
      setState(() {
        _isFlipped = !_isFlipped;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
