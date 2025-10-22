#!/bin/bash

echo "🔧 Correction du problème de build Android"
echo "=========================================="
echo ""

# 1. Nettoyer le projet
echo "1️⃣ Nettoyage du projet..."
flutter clean

# 2. Récupérer les dépendances
echo ""
echo "2️⃣ Récupération des dépendances..."
flutter pub get

# 3. Nettoyer le cache Gradle
echo ""
echo "3️⃣ Nettoyage du cache Gradle..."
cd android
./gradlew clean
cd ..

# 4. Rebuilder
echo ""
echo "4️⃣ Rebuild du projet..."
flutter build apk --debug

echo ""
echo "✅ Terminé ! Vous pouvez maintenant lancer:"
echo "   flutter run"
