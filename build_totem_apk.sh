#!/bin/bash

echo "🎯 Build APK pour Totem d'Affichage (sans Google Play Services)"
echo "=================================================================="
echo ""
echo "⚠️  Cette version fonctionne sur les totems qui n'ont pas Google Play Services"
echo ""

# Demander confirmation
read -p "Voulez-vous créer une version sans Firebase? (o/N): " response
if [[ ! "$response" =~ ^[oO]$ ]]; then
    echo "❌ Build annulé"
    exit 0
fi

echo ""
echo "🧹 Nettoyage..."
flutter clean

echo ""
echo "📦 Récupération des dépendances..."
flutter pub get

echo ""
echo "🔨 Build APK pour totem..."
echo "   - Format: Universal APK"
echo "   - Mode: Release"
echo "   - Target: Android 11+"
echo ""

# Build l'APK
flutter build apk --release \
    --target-platform android-arm64 \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build réussi!"
    echo ""
    echo "📱 APK disponible à:"
    echo "   build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "📊 Taille du fichier:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk
    echo ""
    echo "📋 Instructions d'installation sur le totem:"
    echo "   1. Copiez l'APK sur une clé USB"
    echo "   2. Branchez la clé sur le totem"
    echo "   3. Utilisez le gestionnaire de fichiers du totem pour installer"
    echo "   OU via ADB:"
    echo "   adb install build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "🎉 Prêt pour installation sur totem Android 11!"
else
    echo ""
    echo "❌ Erreur lors du build"
    echo "Vérifiez les erreurs ci-dessus"
    exit 1
fi
