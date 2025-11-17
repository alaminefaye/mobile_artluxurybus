#!/bin/bash

# Script de build production AAB pour Google Play Console
# Ce script garantit un AAB signé en mode RELEASE (pas test/debug)

set -e

echo "🚀 BUILD AAB PRODUCTION POUR GOOGLE PLAY CONSOLE"
echo "=================================================="
echo ""

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Erreur: Ce script doit être exécuté depuis la racine du projet Flutter${NC}"
    exit 1
fi

# Vérifier que le keystore existe
KEYSTORE_PATH="/Users/mouhamadoulaminefaye/upload-keystore.jks"
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo -e "${RED}❌ Erreur: Keystore non trouvé à $KEYSTORE_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Keystore trouvé: $KEYSTORE_PATH${NC}"

# Vérifier les permissions du keystore
if [ ! -r "$KEYSTORE_PATH" ]; then
    echo -e "${RED}❌ Erreur: Impossible de lire le keystore (permissions)${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Keystore accessible${NC}"

# Vérifier que key.properties existe
if [ ! -f "android/key.properties" ]; then
    echo -e "${RED}❌ Erreur: Fichier android/key.properties non trouvé${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Vérifications préliminaires OK${NC}"
echo ""

# Obtenir la version depuis pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
echo -e "${YELLOW}📦 Version de l'app: $VERSION${NC}"
echo ""

# Étape 1: Nettoyage
echo "🧹 Étape 1/5: Nettoyage du projet..."
flutter clean
rm -rf build/

echo -e "${GREEN}✅ Nettoyage terminé${NC}"
echo ""

# Étape 2: Récupération des dépendances
echo "📦 Étape 2/5: Récupération des dépendances..."
flutter pub get

echo -e "${GREEN}✅ Dépendances installées${NC}"
echo ""

# Étape 3: Analyse du code
echo "🔍 Étape 3/5: Analyse du code..."
flutter analyze --no-fatal-infos || true

echo -e "${GREEN}✅ Analyse terminée${NC}"
echo ""

# Étape 4: Build AAB en mode RELEASE
echo "🏗️  Étape 4/5: Build de l'AAB en mode RELEASE..."
echo -e "${YELLOW}⚠️  IMPORTANT: Build en mode --release (PAS --debug)${NC}"
echo ""

flutter build appbundle \
    --release \
    --target-platform android-arm,android-arm64,android-x64 \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols

echo -e "${GREEN}✅ Build terminé${NC}"
echo ""

# Étape 5: Vérification du fichier AAB
echo "🔍 Étape 5/5: Vérification du fichier AAB..."
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

if [ ! -f "$AAB_PATH" ]; then
    echo -e "${RED}❌ Erreur: Fichier AAB non trouvé à $AAB_PATH${NC}"
    exit 1
fi

# Obtenir la taille du fichier
AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)

# Vérifier que l'AAB est bien signé (contient META-INF/*.RSA)
echo "🔐 Vérification de la signature..."
if unzip -l "$AAB_PATH" | grep -E "META-INF/.*\.RSA" | grep -v "base/root" > /dev/null; then
    CERT_NAME=$(unzip -l "$AAB_PATH" | grep -E "META-INF/.*\.RSA" | grep -v "base/root" | awk '{print $NF}')
    echo -e "${GREEN}✅ AAB correctement signé avec: $CERT_NAME${NC}"
else
    echo -e "${RED}❌ ATTENTION: AAB non signé ou signature invalide!${NC}"
    echo -e "${RED}   Cela causera l'erreur 'réservés aux tests' sur Google Play${NC}"
    exit 1
fi

# Vérifier qu'il n'utilise PAS la clé de debug Android
if unzip -l "$AAB_PATH" | grep -i "androiddebugkey" > /dev/null; then
    echo -e "${RED}❌ ERREUR CRITIQUE: AAB signé avec la clé DEBUG Android!${NC}"
    echo -e "${RED}   Google Play refuse les AAB signés avec androiddebugkey${NC}"
    exit 1
fi

# Vérifier que c'est bien une clé de production (pas DEBUG.RSA)
if unzip -l "$AAB_PATH" | grep -E "META-INF/DEBUG\.RSA" > /dev/null; then
    echo -e "${RED}❌ ERREUR: AAB signé avec clé DEBUG!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Signature vérifiée - Clé de production utilisée${NC}"

echo -e "${GREEN}✅ Fichier AAB créé avec succès!${NC}"
echo ""
echo "=================================================="
echo -e "${GREEN}✅ BUILD PRODUCTION RÉUSSI!${NC}"
echo "=================================================="
echo ""
echo "📍 Emplacement du fichier AAB:"
echo "   $AAB_PATH"
echo ""
echo "📊 Taille: $AAB_SIZE"
echo ""
echo "📝 Version: $VERSION"
echo ""
echo "🎯 PROCHAINES ÉTAPES:"
echo "   1. Connectez-vous à la Google Play Console"
echo "   2. Allez dans 'Tests internes' ou 'Production'"
echo "   3. Créez une nouvelle version"
echo "   4. Importez le fichier AAB:"
echo "      $AAB_PATH"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo "   - Ce fichier est signé avec votre clé de production"
echo "   - Ne partagez JAMAIS votre keystore ou key.properties"
echo "   - Conservez une copie de sauvegarde de votre keystore"
echo ""
echo -e "${GREEN}✅ Vous pouvez maintenant uploader ce fichier sur Google Play Console!${NC}"
echo ""
