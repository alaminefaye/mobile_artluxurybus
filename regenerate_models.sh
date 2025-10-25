#!/bin/bash

echo "🔄 Régénération des modèles..."

# Aller dans le répertoire du projet
cd "$(dirname "$0")"

# Nettoyer les anciens fichiers générés
echo "🗑️  Suppression des anciens fichiers .g.dart..."
find lib -name "*.g.dart" -type f -delete

# Régénérer les fichiers
echo "⚙️  Génération des nouveaux fichiers..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "✅ Régénération terminée !"
