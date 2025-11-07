import 'package:flutter/material.dart';

/// Widget helper pour afficher un indicateur de chargement
/// avec couleur adaptative selon le thème (orange en mode sombre)
class LoadingIndicator extends StatelessWidget {
  final double? size;
  final double strokeWidth;

  const LoadingIndicator({
    super.key,
    this.size,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.orange : Theme.of(context).colorScheme.primary;

    if (size != null) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return CircularProgressIndicator(
      strokeWidth: strokeWidth,
      valueColor: AlwaysStoppedAnimation<Color>(color),
    );
  }
}

/// Widget helper pour un indicateur de chargement centré
class CenteredLoadingIndicator extends StatelessWidget {
  final double? size;
  final double strokeWidth;

  const CenteredLoadingIndicator({
    super.key,
    this.size,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingIndicator(
        size: size,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

