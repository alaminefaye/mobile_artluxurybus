#!/bin/bash

# Script de vérification de build pour Google Play Store
# Ce script vérifie que toutes les configurations sont correctes

echo "🔍 Vérification de la configuration de build..."
echo ""

# Couleurs pour le terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteur d'erreurs
ERRORS=0
WARNINGS=0

# 1. Vérifier le fichier pubspec.yaml
echo "1️⃣  Vérification de pubspec.yaml..."
VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
if [ -n "$VERSION" ]; then
    echo -e "${GREEN}✅ Version trouvée: $VERSION${NC}"
else
    echo -e "${RED}❌ Version non trouvée dans pubspec.yaml${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 2. Vérifier le fichier key.properties
echo ""
echo "2️⃣  Vérification de key.properties..."
if [ -f "android/key.properties" ]; then
    echo -e "${GREEN}✅ Fichier key.properties existe${NC}"
    
    STORE_FILE=$(grep "^storeFile=" android/key.properties | cut -d'=' -f2)
    if [ -f "$STORE_FILE" ]; then
        echo -e "${GREEN}✅ Keystore trouvé: $STORE_FILE${NC}"
    else
        echo -e "${RED}❌ Keystore non trouvé: $STORE_FILE${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}❌ Fichier key.properties non trouvé${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 3. Vérifier AndroidManifest.xml
echo ""
echo "3️⃣  Vérification de AndroidManifest.xml..."
if grep -q 'android:debuggable="false"' android/app/src/main/AndroidManifest.xml; then
    echo -e "${GREEN}✅ android:debuggable=\"false\" configuré${NC}"
else
    echo -e "${YELLOW}⚠️  android:debuggable=\"false\" non trouvé (sera géré par build.gradle)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# 4. Vérifier build.gradle.kts
echo ""
echo "4️⃣  Vérification de build.gradle.kts..."
if grep -q "isDebuggable = false" android/app/build.gradle.kts; then
    echo -e "${GREEN}✅ isDebuggable = false configuré${NC}"
else
    echo -e "${RED}❌ isDebuggable = false non trouvé${NC}"
    ERRORS=$((ERRORS + 1))
fi

if grep -q 'signingConfig = signingConfigs.getByName("release")' android/app/build.gradle.kts; then
    echo -e "${GREEN}✅ Configuration de signature release trouvée${NC}"
else
    echo -e "${RED}❌ Configuration de signature release non trouvée${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 5. Vérifier si le projet est propre
echo ""
echo "5️⃣  Vérification de l'état du projet..."
if [ -d "build" ]; then
    echo -e "${YELLOW}⚠️  Le répertoire build existe (exécutez 'flutter clean' pour un build propre)${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ Pas de répertoire build (projet propre)${NC}"
fi

# 6. Vérifier les dépendances Flutter
echo ""
echo "6️⃣  Vérification des dépendances Flutter..."
if [ -d ".dart_tool" ]; then
    echo -e "${GREEN}✅ Dépendances Flutter installées${NC}"
else
    echo -e "${YELLOW}⚠️  Dépendances Flutter non installées (exécutez 'flutter pub get')${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Résumé
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RÉSUMÉ DE LA VÉRIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 SUCCÈS ! Tout est correctement configuré.${NC}"
    echo ""
    echo "✨ Prochaines étapes :"
    echo "   1. flutter clean"
    echo "   2. flutter pub get"
    echo "   3. flutter build appbundle --release"
    echo "   4. Vérifier l'AAB : build/app/outputs/bundle/release/app-release.aab"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS avertissement(s) trouvé(s)${NC}"
    echo "Le build devrait fonctionner mais vérifiez les avertissements ci-dessus."
else
    echo -e "${RED}❌ $ERRORS erreur(s) trouvée(s)${NC}"
    echo -e "${YELLOW}⚠️  $WARNINGS avertissement(s) trouvé(s)${NC}"
    echo ""
    echo "Corrigez les erreurs avant de continuer."
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
