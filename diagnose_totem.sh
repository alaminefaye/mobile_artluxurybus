#!/bin/bash

echo "🔍 Diagnostic Totem Android"
echo "============================"
echo ""
echo "Ce script va vérifier les capacités du totem"
echo "Assurez-vous que le totem est connecté via USB ou réseau (ADB)"
echo ""

# Vérifier ADB
if ! command -v adb &> /dev/null; then
    echo "❌ ADB non trouvé. Installez Android SDK Platform-Tools"
    exit 1
fi

# Vérifier la connexion
echo "📱 Vérification de la connexion..."
DEVICES=$(adb devices | grep -w "device" | wc -l)
if [ $DEVICES -eq 0 ]; then
    echo "❌ Aucun appareil détecté"
    echo ""
    echo "Pour connexion USB:"
    echo "  1. Branchez le totem via USB"
    echo "  2. Activez le mode développeur"
    echo "  3. Activez le débogage USB"
    echo ""
    echo "Pour connexion WiFi/Réseau:"
    echo "  1. Trouvez l'IP du totem"
    echo "  2. Exécutez: adb connect [IP]:5555"
    exit 1
fi

echo "✅ Appareil connecté"
echo ""

# Informations de l'appareil
echo "📋 Informations du totem:"
echo "========================="
echo ""

echo "Modèle:"
adb shell getprop ro.product.model

echo ""
echo "Fabricant:"
adb shell getprop ro.product.manufacturer

echo ""
echo "Version Android:"
adb shell getprop ro.build.version.release

echo ""
echo "Niveau API:"
adb shell getprop ro.build.version.sdk

echo ""
echo "Architecture:"
adb shell getprop ro.product.cpu.abi

echo ""
echo "RAM totale:"
adb shell cat /proc/meminfo | grep MemTotal

echo ""
echo "Stockage disponible:"
adb shell df -h /data | tail -1 | awk '{print "Utilisé: " $3 " / " $2 " (Libre: " $4 ")"}'

echo ""
echo "🔍 Vérification des services critiques:"
echo "========================================="
echo ""

# Vérifier Google Play Services
echo -n "Google Play Services: "
if adb shell pm list packages | grep -q "com.google.android.gms"; then
    echo "✅ Installé"
    GMS_VERSION=$(adb shell dumpsys package com.google.android.gms | grep versionName | head -1 | awk -F= '{print $2}')
    echo "   Version: $GMS_VERSION"
else
    echo "❌ NON INSTALLÉ"
    echo "   ⚠️  Firebase ne fonctionnera pas!"
fi

echo ""
echo -n "Google Play Store: "
if adb shell pm list packages | grep -q "com.android.vending"; then
    echo "✅ Installé"
else
    echo "❌ Non installé"
fi

echo ""
echo "📶 État réseau:"
echo "==============="
echo ""

echo -n "WiFi: "
WIFI_STATE=$(adb shell dumpsys wifi | grep "Wi-Fi is" | head -1)
if [[ $WIFI_STATE == *"enabled"* ]]; then
    echo "✅ Activé"
    IP=$(adb shell ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    if [ ! -z "$IP" ]; then
        echo "   IP: $IP"
    fi
else
    echo "❌ Désactivé"
fi

echo ""
echo -n "Connexion Internet: "
if adb shell ping -c 1 8.8.8.8 &> /dev/null; then
    echo "✅ Fonctionnelle"
else
    echo "❌ Pas de connexion"
fi

echo ""
echo "🎯 Recommandations pour l'APK:"
echo "==============================="
echo ""

# Recommandations basées sur le diagnostic
if ! adb shell pm list packages | grep -q "com.google.android.gms"; then
    echo "⚠️  IMPORTANT: Pas de Google Play Services détecté"
    echo "   → Buildez sans Firebase (répondez 'o' au script build_totem_apk.sh)"
    echo "   → Les notifications push ne fonctionneront pas"
    echo ""
fi

API_LEVEL=$(adb shell getprop ro.build.version.sdk)
if [ "$API_LEVEL" -lt 30 ]; then
    echo "⚠️  Version Android < 11 détectée"
    echo "   → L'app est optimisée pour Android 11+"
    echo ""
fi

RAM_KB=$(adb shell cat /proc/meminfo | grep MemTotal | awk '{print $2}')
RAM_GB=$(echo "scale=1; $RAM_KB/1024/1024" | bc)
if (( $(echo "$RAM_GB < 2" | bc -l) )); then
    echo "⚠️  RAM faible détectée (${RAM_GB}GB)"
    echo "   → Limitez le nombre de médias chargés simultanément"
    echo ""
fi

echo "✅ Diagnostic terminé!"
echo ""
echo "Pour installer l'APK sur ce totem:"
echo "  ./build_totem_apk.sh"
echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
