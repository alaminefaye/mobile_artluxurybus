#!/bin/bash

# Script pour builder iOS en mode release avec recompilation native complète
# Usage: ./build_ios_release.sh

echo "🚀 Début du build iOS Release avec recompilation native..."

# 1. Nettoyer le projet
echo "🧹 Nettoyage du projet..."
flutter clean

# 2. Récupérer les dépendances
echo "📦 Récupération des dépendances..."
flutter pub get

# 3. Installer les pods (force la recompilation native)
echo "🔧 Installation des CocoaPods..."
cd ios
pod install --repo-update
cd ..

# 4. Build iOS en mode release (recompile tout le natif)
echo "🏗️ Build iOS Release..."
flutter build ios --release --no-codesign

# 5. Archiver avec xcodebuild (alternative à Xcode GUI)
echo "📦 Création de l'archive..."
cd ios
xcodebuild archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

cd ..

echo "✅ Build terminé !"
echo "📂 Archive créée dans: ios/build/Runner.xcarchive"
echo ""
echo "Pour créer l'IPA, ouvrez Xcode:"
echo "  open ios/Runner.xcworkspace"
echo "  Product → Archive → Distribute App"
