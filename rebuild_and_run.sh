#!/bin/bash

echo "🔄 Reconstruction complète de l'application..."
cd "$(dirname "$0")"

echo "📦 1. Régénération des modèles..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "🧹 2. Nettoyage du build..."
flutter clean

echo "📥 3. Récupération des dépendances..."
flutter pub get

echo "🔨 4. Compilation de l'APK..."
flutter build apk --debug

echo "✅ Terminé ! Vous pouvez maintenant installer l'APK ou lancer avec 'flutter run'"
