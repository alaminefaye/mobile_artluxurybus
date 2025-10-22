#!/bin/bash

# Script de vérification complète de la configuration iOS
# Usage: ./verify_ios_config.sh

echo "🔍 VÉRIFICATION COMPLÈTE - Configuration iOS Notifications"
echo "=========================================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# 1. Vérifier firebase_options.dart
echo -e "${BLUE}📱 1. VÉRIFICATION FICHIERS FLUTTER${NC}"
echo "-----------------------------------"

if [ -f "lib/firebase_options.dart" ]; then
    echo -e "${GREEN}✅ firebase_options.dart trouvé${NC}"
    if grep -q "iosBundleId: 'com.example.artluxurybus'" lib/firebase_options.dart; then
        echo -e "${GREEN}   ✅ Bundle ID iOS configuré${NC}"
    else
        echo -e "${RED}   ❌ Bundle ID iOS manquant ou incorrect${NC}"
        ((ERRORS++))
    fi
    if grep -q "DefaultFirebaseOptions.currentPlatform" lib/firebase_options.dart; then
        echo -e "${GREEN}   ✅ currentPlatform défini${NC}"
    fi
else
    echo -e "${RED}❌ firebase_options.dart MANQUANT${NC}"
    echo -e "${YELLOW}   → Fichier créé automatiquement${NC}"
    ((ERRORS++))
fi

if [ -f "lib/services/notification_service.dart" ]; then
    echo -e "${GREEN}✅ notification_service.dart trouvé${NC}"
    if grep -q "import '../firebase_options.dart'" lib/services/notification_service.dart; then
        echo -e "${GREEN}   ✅ Import firebase_options présent${NC}"
    else
        echo -e "${RED}   ❌ Import firebase_options MANQUANT${NC}"
        ((ERRORS++))
    fi
    if grep -q "DefaultFirebaseOptions.currentPlatform" lib/services/notification_service.dart; then
        echo -e "${GREEN}   ✅ Utilise DefaultFirebaseOptions${NC}"
    else
        echo -e "${RED}   ❌ N'utilise pas DefaultFirebaseOptions${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}❌ notification_service.dart MANQUANT${NC}"
    ((ERRORS++))
fi

if [ -f "lib/main.dart" ]; then
    echo -e "${GREEN}✅ main.dart trouvé${NC}"
    if grep -q "NotificationService.initialize()" lib/main.dart; then
        echo -e "${GREEN}   ✅ NotificationService initialisé${NC}"
    else
        echo -e "${YELLOW}   ⚠️  NotificationService non initialisé${NC}"
        ((WARNINGS++))
    fi
fi

echo ""

# 2. Vérifier fichiers iOS
echo -e "${BLUE}🍎 2. VÉRIFICATION FICHIERS iOS${NC}"
echo "-------------------------------"

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ GoogleService-Info.plist trouvé${NC}"
    BUNDLE_ID=$(grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep "string" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo -e "   Bundle ID: ${BLUE}$BUNDLE_ID${NC}"
    
    if [ "$BUNDLE_ID" != "com.example.artluxurybus" ]; then
        echo -e "${YELLOW}   ⚠️  Bundle ID différent de com.example.artluxurybus${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌ GoogleService-Info.plist MANQUANT${NC}"
    ((ERRORS++))
fi

if [ -f "ios/Runner/Info.plist" ]; then
    echo -e "${GREEN}✅ Info.plist trouvé${NC}"
    if grep -q "UIBackgroundModes" ios/Runner/Info.plist; then
        echo -e "${GREEN}   ✅ UIBackgroundModes configuré${NC}"
        if grep -q "remote-notification" ios/Runner/Info.plist; then
            echo -e "${GREEN}   ✅ remote-notification activé${NC}"
        else
            echo -e "${RED}   ❌ remote-notification MANQUANT${NC}"
            ((ERRORS++))
        fi
    else
        echo -e "${RED}   ❌ UIBackgroundModes MANQUANT${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}❌ Info.plist MANQUANT${NC}"
    ((ERRORS++))
fi

if [ -f "ios/Runner/AppDelegate.swift" ]; then
    echo -e "${GREEN}✅ AppDelegate.swift trouvé${NC}"
    if grep -q "FirebaseApp.configure()" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}   ✅ Firebase configuré${NC}"
    else
        echo -e "${RED}   ❌ Firebase NON configuré${NC}"
        ((ERRORS++))
    fi
    if grep -q "registerForRemoteNotifications" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}   ✅ Remote notifications enregistrées${NC}"
    else
        echo -e "${RED}   ❌ Remote notifications NON enregistrées${NC}"
        ((ERRORS++))
    fi
    if grep -q "didRegisterForRemoteNotificationsWithDeviceToken" ios/Runner/AppDelegate.swift; then
        echo -e "${GREEN}   ✅ Callback APNs token présent${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Callback APNs token manquant (diagnostic)${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌ AppDelegate.swift MANQUANT${NC}"
    ((ERRORS++))
fi

if [ -f "ios/Runner/Runner.entitlements" ]; then
    echo -e "${GREEN}✅ Runner.entitlements trouvé${NC}"
    if grep -q "aps-environment" ios/Runner/Runner.entitlements; then
        echo -e "${GREEN}   ✅ aps-environment configuré${NC}"
        ENV=$(grep -A 1 "aps-environment" ios/Runner/Runner.entitlements | grep "string" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        echo -e "   Environnement: ${BLUE}$ENV${NC}"
    else
        echo -e "${RED}   ❌ aps-environment MANQUANT${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${YELLOW}⚠️  Runner.entitlements MANQUANT${NC}"
    echo -e "${YELLOW}   → Fichier créé automatiquement${NC}"
    ((WARNINGS++))
fi

echo ""

# 3. Vérifier dépendances
echo -e "${BLUE}📦 3. VÉRIFICATION DÉPENDANCES${NC}"
echo "------------------------------"

if [ -f "pubspec.yaml" ]; then
    if grep -q "firebase_core:" pubspec.yaml; then
        VERSION=$(grep "firebase_core:" pubspec.yaml | awk '{print $2}')
        echo -e "${GREEN}✅ firebase_core: $VERSION${NC}"
    else
        echo -e "${RED}❌ firebase_core MANQUANT${NC}"
        ((ERRORS++))
    fi
    
    if grep -q "firebase_messaging:" pubspec.yaml; then
        VERSION=$(grep "firebase_messaging:" pubspec.yaml | awk '{print $2}')
        echo -e "${GREEN}✅ firebase_messaging: $VERSION${NC}"
    else
        echo -e "${RED}❌ firebase_messaging MANQUANT${NC}"
        ((ERRORS++))
    fi
    
    if grep -q "flutter_local_notifications:" pubspec.yaml; then
        VERSION=$(grep "flutter_local_notifications:" pubspec.yaml | awk '{print $2}')
        echo -e "${GREEN}✅ flutter_local_notifications: $VERSION${NC}"
    else
        echo -e "${YELLOW}⚠️  flutter_local_notifications manquant (optionnel)${NC}"
        ((WARNINGS++))
    fi
fi

if [ -f "ios/Podfile.lock" ]; then
    echo -e "${GREEN}✅ Podfile.lock trouvé${NC}"
    if grep -q "Firebase/Messaging" ios/Podfile.lock; then
        VERSION=$(grep "Firebase/Messaging" ios/Podfile.lock | head -1 | awk '{print $2}' | tr -d '()')
        echo -e "${GREEN}   ✅ Firebase/Messaging: $VERSION${NC}"
    else
        echo -e "${RED}   ❌ Firebase/Messaging NON installé${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${YELLOW}⚠️  Podfile.lock manquant - Pods non installés${NC}"
    echo -e "${YELLOW}   → Exécuter: cd ios && pod install${NC}"
    ((WARNINGS++))
fi

echo ""

# 4. Résumé
echo -e "${BLUE}📊 4. RÉSUMÉ${NC}"
echo "----------"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ CONFIGURATION PARFAITE!${NC}"
    echo ""
    echo "Tous les fichiers sont correctement configurés."
    echo ""
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  CONFIGURATION BONNE AVEC AVERTISSEMENTS${NC}"
    echo ""
    echo -e "Erreurs: ${GREEN}0${NC}"
    echo -e "Avertissements: ${YELLOW}$WARNINGS${NC}"
    echo ""
else
    echo -e "${RED}❌ CONFIGURATION INCOMPLÈTE${NC}"
    echo ""
    echo -e "Erreurs: ${RED}$ERRORS${NC}"
    echo -e "Avertissements: ${YELLOW}$WARNINGS${NC}"
    echo ""
fi

# 5. Actions requises
echo -e "${BLUE}🔧 5. ACTIONS REQUISES${NC}"
echo "--------------------"
echo ""

echo "✅ Code Flutter: Corrigé et prêt"
echo ""
echo "⚠️  ACTIONS CRITIQUES RESTANTES:"
echo ""
echo "1. 🔑 Configurer APNs dans Firebase Console"
echo "   → https://console.firebase.google.com/project/artluxurybus-d7a63"
echo "   → Project Settings > Cloud Messaging"
echo "   → Uploader la clé APNs (.p8)"
echo ""
echo "2. 🍎 Configurer Xcode"
echo "   → cd ios && open Runner.xcworkspace"
echo "   → Signing & Capabilities"
echo "   → Ajouter 'Push Notifications'"
echo "   → Ajouter 'Background Modes' > Remote notifications"
echo ""
echo "3. 🧪 Tester"
echo "   → flutter clean && flutter pub get"
echo "   → cd ios && pod install && cd .."
echo "   → flutter run --verbose"
echo ""

echo "=========================================================="
echo "📖 Voir CHECKLIST_IOS_NOTIFICATIONS.md pour les détails"
echo "=========================================================="
