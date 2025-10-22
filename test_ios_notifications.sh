#!/bin/bash

# Script de diagnostic pour les notifications iOS
# Usage: ./test_ios_notifications.sh

echo "🧪 DIAGNOSTIC NOTIFICATIONS iOS - Art Luxury Bus"
echo "================================================"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Vérifier les fichiers de configuration
echo "📋 1. VÉRIFICATION DES FICHIERS DE CONFIGURATION"
echo "------------------------------------------------"

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ GoogleService-Info.plist trouvé${NC}"
    BUNDLE_ID=$(grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep "string" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo "   Bundle ID: $BUNDLE_ID"
else
    echo -e "${RED}❌ GoogleService-Info.plist MANQUANT${NC}"
fi

if [ -f "ios/Runner/Info.plist" ]; then
    echo -e "${GREEN}✅ Info.plist trouvé${NC}"
    if grep -q "UIBackgroundModes" ios/Runner/Info.plist; then
        echo -e "${GREEN}   ✅ UIBackgroundModes configuré${NC}"
    else
        echo -e "${RED}   ❌ UIBackgroundModes MANQUANT${NC}"
    fi
else
    echo -e "${RED}❌ Info.plist MANQUANT${NC}"
fi

if [ -f "ios/Runner/Runner.entitlements" ]; then
    echo -e "${GREEN}✅ Runner.entitlements trouvé${NC}"
    if grep -q "aps-environment" ios/Runner/Runner.entitlements; then
        echo -e "${GREEN}   ✅ aps-environment configuré${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Runner.entitlements MANQUANT (créé automatiquement)${NC}"
fi

if [ -f "ios/Runner/AppDelegate.swift" ]; then
    echo -e "${GREEN}✅ AppDelegate.swift trouvé${NC}"
    if grep -q "FirebaseApp.configure()" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}   ✅ Firebase configuré${NC}"
    fi
    if grep -q "registerForRemoteNotifications" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}   ✅ Remote notifications enregistrées${NC}"
    fi
else
    echo -e "${RED}❌ AppDelegate.swift MANQUANT${NC}"
fi

echo ""

# 2. Vérifier les dépendances
echo "📦 2. VÉRIFICATION DES DÉPENDANCES"
echo "----------------------------------"

if [ -f "pubspec.yaml" ]; then
    if grep -q "firebase_messaging" pubspec.yaml; then
        echo -e "${GREEN}✅ firebase_messaging dans pubspec.yaml${NC}"
    else
        echo -e "${RED}❌ firebase_messaging MANQUANT${NC}"
    fi
    
    if grep -q "firebase_core" pubspec.yaml; then
        echo -e "${GREEN}✅ firebase_core dans pubspec.yaml${NC}"
    else
        echo -e "${RED}❌ firebase_core MANQUANT${NC}"
    fi
    
    if grep -q "flutter_local_notifications" pubspec.yaml; then
        echo -e "${GREEN}✅ flutter_local_notifications dans pubspec.yaml${NC}"
    else
        echo -e "${YELLOW}⚠️  flutter_local_notifications manquant (optionnel)${NC}"
    fi
fi

if [ -f "ios/Podfile" ]; then
    echo -e "${GREEN}✅ Podfile trouvé${NC}"
    PLATFORM=$(grep "platform :ios" ios/Podfile | sed "s/.*'\(.*\)'.*/\1/")
    echo "   iOS Platform: $PLATFORM"
    if [ ! -z "$PLATFORM" ]; then
        if (( $(echo "$PLATFORM >= 13.0" | bc -l) )); then
            echo -e "${GREEN}   ✅ Version iOS >= 13.0${NC}"
        else
            echo -e "${YELLOW}   ⚠️  Version iOS < 13.0 (recommandé: >= 13.0)${NC}"
        fi
    fi
fi

echo ""

# 3. Instructions de configuration
echo "🔧 3. ÉTAPES DE CONFIGURATION REQUISES"
echo "---------------------------------------"
echo ""
echo "A. Configuration Apple Developer:"
echo "   1. Créer une clé APNs sur developer.apple.com"
echo "   2. Télécharger le fichier .p8"
echo "   3. Noter le Key ID et Team ID"
echo ""
echo "B. Configuration Firebase Console:"
echo "   1. Aller sur console.firebase.google.com"
echo "   2. Project Settings > Cloud Messaging"
echo "   3. Uploader la clé APNs (.p8)"
echo "   4. Entrer Key ID et Team ID"
echo ""
echo "C. Configuration Xcode:"
echo "   1. Ouvrir: cd ios && open Runner.xcworkspace"
echo "   2. Sélectionner Runner > Signing & Capabilities"
echo "   3. Ajouter 'Push Notifications'"
echo "   4. Ajouter 'Background Modes' > Remote notifications"
echo "   5. Lier le fichier Runner.entitlements"
echo ""

# 4. Commandes utiles
echo "🛠️  4. COMMANDES UTILES"
echo "----------------------"
echo ""
echo "Nettoyer et rebuilder:"
echo "  flutter clean && flutter pub get"
echo "  cd ios && pod deintegrate && pod install && cd .."
echo ""
echo "Lancer en mode debug avec logs:"
echo "  flutter run --verbose"
echo ""
echo "Voir les logs Xcode en temps réel:"
echo "  xcrun simctl spawn booted log stream --predicate 'eventMessage contains \"notification\"' --level=debug"
echo ""

# 5. Checklist finale
echo "✅ 5. CHECKLIST FINALE"
echo "----------------------"
echo ""
echo "Configuration Apple:"
echo "  [ ] Certificat APNs créé (.p8)"
echo "  [ ] Key ID et Team ID notés"
echo "  [ ] Bundle ID enregistré: $BUNDLE_ID"
echo ""
echo "Configuration Firebase:"
echo "  [ ] Clé APNs uploadée"
echo "  [ ] Key ID et Team ID configurés"
echo "  [ ] GoogleService-Info.plist à jour"
echo ""
echo "Configuration Xcode:"
echo "  [ ] Push Notifications activé"
echo "  [ ] Background Modes activé"
echo "  [ ] Runner.entitlements lié"
echo "  [ ] Signing configuré"
echo ""
echo "Tests:"
echo "  [ ] App compile sans erreur"
echo "  [ ] Permissions acceptées sur iPhone"
echo "  [ ] Token FCM visible dans logs"
echo "  [ ] Token APNs visible dans logs"
echo "  [ ] Notification test reçue"
echo ""
echo "================================================"
echo "📖 Voir IOS_NOTIFICATIONS_FIX.md pour plus de détails"
echo "================================================"
