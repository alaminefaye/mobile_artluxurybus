#!/bin/bash

echo "🔄 Rebuild complet de l'application..."
echo ""

# Vérifier si Flutter est installé
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter n'est pas installé ou pas dans le PATH"
    exit 1
fi

echo "1️⃣ Nettoyage du build..."
flutter clean

echo ""
echo "2️⃣ Installation des dépendances..."
flutter pub get

echo ""
echo "3️⃣ Rebuild de l'application..."
echo "   Veuillez lancer manuellement: flutter run"
echo ""
echo "✅ Nettoyage terminé!"
echo ""
echo "🚀 IMPORTANT:"
echo "   1. Arrêtez l'application en cours (bouton Stop rouge)"
echo "   2. Relancez avec: flutter run"
echo "   3. OU appuyez sur F5 dans votre IDE"
echo ""
