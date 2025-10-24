#!/bin/bash

echo "🔍 Capture des logs Android pour diagnostic"
echo "==========================================="
echo ""
echo "Instructions:"
echo "1. Branchez votre appareil Android via USB"
echo "2. Activez le mode développeur et le débogage USB"
echo "3. Installez l'APK sur l'appareil"
echo "4. Lancez cette commande AVANT d'ouvrir l'app"
echo "5. Ouvrez l'app et attendez le crash"
echo "6. Les logs seront sauvegardés dans crash_logs.txt"
echo ""
read -p "Appuyez sur Entrée pour commencer la capture des logs..."

# Vérifier si ADB est disponible
if ! command -v adb &> /dev/null; then
    echo "❌ ADB n'est pas installé ou pas dans le PATH"
    echo "   Installez Android SDK Platform-Tools"
    exit 1
fi

# Vérifier si un appareil est connecté
DEVICE=$(adb devices | grep -w "device" | head -1)
if [ -z "$DEVICE" ]; then
    echo "❌ Aucun appareil Android détecté"
    echo "   Branchez votre appareil et activez le débogage USB"
    exit 1
fi

echo "✅ Appareil détecté"
echo ""

# Nettoyer les anciens logs
adb logcat -c

echo "📝 Capture des logs en cours..."
echo "   Ouvrez maintenant l'application sur votre appareil"
echo "   Appuyez sur Ctrl+C pour arrêter la capture"
echo ""

# Capturer les logs et les sauvegarder
adb logcat -v time > crash_logs.txt &
LOGCAT_PID=$!

# Attendre l'interruption
trap "kill $LOGCAT_PID; echo ''; echo '✅ Logs sauvegardés dans crash_logs.txt'; echo '📧 Envoyez ce fichier pour analyse'; exit 0" INT

wait $LOGCAT_PID
