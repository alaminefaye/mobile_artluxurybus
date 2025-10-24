#!/bin/bash

echo "🚀 Construction de l'APK pour Android 11+"
echo "=========================================="

# Nettoyer le projet
echo "🧹 Nettoyage du projet..."
flutter clean

# Récupérer les dépendances
echo "📦 Récupération des dépendances..."
flutter pub get

# Vérifier la configuration
echo "🔍 Vérification de la configuration..."
flutter doctor -v

# Construire l'APK en mode release
echo "🔨 Construction de l'APK..."
flutter build apk --release --target-platform android-arm,android-arm64,android-x64

# Vérifier si le build a réussi
if [ $? -eq 0 ]; then
    echo "✅ Build réussi!"
    echo ""
    echo "📱 APK disponible à:"
    echo "   build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "📊 Taille du fichier:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk
    echo ""
    echo "🎉 Vous pouvez maintenant installer cet APK sur votre appareil Android 11"
else
    echo "❌ Erreur lors du build"
    exit 1
fi
