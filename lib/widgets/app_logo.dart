import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  
  const AppLogo({
    super.key,
    this.size = 120,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo image
        Container(
          width: size,
          height: size * 0.7, // Ratio du logo
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              '12.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        
        if (showText) ...[
          SizedBox(height: size * 0.15),
          // Texte de l'application
          Text(
            'Art Luxury Bus',
            style: TextStyle(
              fontSize: size * 0.18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFFF1BD92) // AppTheme.primaryOrange
                  : Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: size * 0.05),
          Text(
            'Transport de Luxe',
            style: TextStyle(
              fontSize: size * 0.12,
              color: Colors.grey[600],
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );
  }
}
