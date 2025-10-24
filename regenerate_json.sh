#!/bin/bash

echo "🔄 Régénération des fichiers JSON..."
echo ""

# Vérifier si Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé ou pas dans le PATH"
    echo "Ajoutez Flutter à votre PATH ou lancez cette commande manuellement :"
    echo ""
    echo "  flutter pub run build_runner build --delete-conflicting-outputs"
    echo ""
    exit 1
fi

# Nettoyer les anciens fichiers
echo "🗑️  Nettoyage des anciens fichiers..."
flutter clean

# Récupérer les dépendances
echo "📦 Récupération des dépendances..."
flutter pub get

# Régénérer les fichiers .g.dart
echo "⚙️  Régénération des fichiers .g.dart..."
flutter pub run build_runner build --delete-conflicting-outputs

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Régénération terminée avec succès !"
    echo ""
    echo "Vous pouvez maintenant lancer l'app avec :"
    echo "  flutter run"
else
    echo ""
    echo "❌ Erreur lors de la régénération"
    exit 1
fi
