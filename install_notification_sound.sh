#!/bin/bash

# 🔊 Script d'installation du son de notification Pixabay
# Ce script vous aide à installer le fichier son téléchargé

echo "🔊 Installation du son de notification Art Luxury Bus"
echo "=================================================="
echo ""

# Vérifier que le fichier notification.mp3 existe
if [ ! -f "notification.mp3" ]; then
    echo "❌ Erreur: Le fichier 'notification.mp3' n'existe pas dans le répertoire actuel."
    echo ""
    echo "📥 Veuillez suivre ces étapes:"
    echo "   1. Allez sur: https://pixabay.com/fr/sound-effects/new-notification-1-398650/"
    echo "   2. Téléchargez le fichier MP3"
    echo "   3. Renommez-le en 'notification.mp3'"
    echo "   4. Placez-le dans ce dossier: $(pwd)"
    echo "   5. Relancez ce script"
    echo ""
    exit 1
fi

echo "✅ Fichier notification.mp3 trouvé!"
echo ""

# Créer le dossier raw pour Android s'il n'existe pas
echo "📂 Création du dossier Android raw..."
mkdir -p android/app/src/main/res/raw
echo "✅ Dossier créé: android/app/src/main/res/raw"
echo ""

# Copier le fichier dans le dossier raw Android
echo "📋 Copie du fichier pour Android..."
cp notification.mp3 android/app/src/main/res/raw/notification.mp3
echo "✅ Fichier copié: android/app/src/main/res/raw/notification.mp3"
echo ""

# Créer le dossier assets/sounds s'il n'existe pas
echo "📂 Création du dossier assets/sounds..."
mkdir -p assets/sounds
echo "✅ Dossier créé: assets/sounds"
echo ""

# Copier le fichier dans assets pour utilisation future
echo "📋 Copie du fichier dans assets..."
cp notification.mp3 assets/sounds/notification.mp3
echo "✅ Fichier copié: assets/sounds/notification.mp3"
echo ""

# Vérifier les fichiers copiés
echo "🔍 Vérification des fichiers..."
if [ -f "android/app/src/main/res/raw/notification.mp3" ]; then
    size_android=$(ls -lh android/app/src/main/res/raw/notification.mp3 | awk '{print $5}')
    echo "✅ Android: notification.mp3 ($size_android)"
else
    echo "❌ Erreur: Fichier Android non copié"
fi

if [ -f "assets/sounds/notification.mp3" ]; then
    size_assets=$(ls -lh assets/sounds/notification.mp3 | awk '{print $5}')
    echo "✅ Assets: notification.mp3 ($size_assets)"
else
    echo "❌ Erreur: Fichier assets non copié"
fi

echo ""
echo "🎉 Installation terminée avec succès!"
echo ""
echo "📱 Pour iOS:"
echo "   1. Ouvrez le projet dans Xcode: open ios/Runner.xcworkspace"
echo "   2. Faites glisser le fichier 'notification.mp3' dans le dossier Runner"
echo "   3. Cochez 'Copy items if needed' et 'Add to targets: Runner'"
echo ""
echo "🚀 Prochaines étapes:"
echo "   1. Exécutez: flutter clean"
echo "   2. Exécutez: flutter pub get"
echo "   3. Exécutez: flutter run"
echo ""
echo "🎵 Le son personnalisé sera maintenant utilisé pour toutes les notifications!"
