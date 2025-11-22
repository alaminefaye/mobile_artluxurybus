#!/bin/bash

echo "🔊 Configuration du son de notification pour iOS"
echo "================================================="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Vérifier que le fichier source existe
if [ ! -f "assets/sounds/notification.mp3" ]; then
    echo -e "${RED}❌ Erreur: Le fichier assets/sounds/notification.mp3 n'existe pas${NC}"
    exit 1
fi

# Copier le fichier dans le dossier Runner
echo -e "${BLUE}📋 Copie du fichier dans ios/Runner/${NC}"
cp assets/sounds/notification.mp3 ios/Runner/notification.mp3

# Vérifier que la copie a réussi
if [ -f "ios/Runner/notification.mp3" ]; then
    size=$(ls -lh ios/Runner/notification.mp3 | awk '{print $5}')
    echo -e "${GREEN}✅ Fichier copié: ios/Runner/notification.mp3 ($size)${NC}"
else
    echo -e "${RED}❌ Erreur: Impossible de copier le fichier${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Étapes suivantes à faire manuellement${NC}"
echo ""
echo "📱 Pour que le son fonctionne sur iOS, vous devez:"
echo ""
echo "1️⃣  Ouvrir le projet dans Xcode:"
echo -e "   ${BLUE}open ios/Runner.xcworkspace${NC}"
echo ""
echo "2️⃣  Dans Xcode:"
echo "   - Dans le navigateur de gauche, faites un clic droit sur le dossier 'Runner'"
echo "   - Sélectionnez 'Add Files to \"Runner\"...'"
echo "   - Naviguez vers le dossier ios/Runner/"
echo "   - Sélectionnez le fichier 'notification.mp3'"
echo "   - Cochez ✅ 'Copy items if needed'"
echo "   - Cochez ✅ 'Add to targets: Runner'"
echo "   - Cliquez sur 'Add'"
echo ""
echo "3️⃣  Vérifier que le fichier apparaît dans Xcode:"
echo "   - Le fichier devrait apparaître dans le dossier Runner"
echo "   - Dans Build Phases > Copy Bundle Resources, vérifiez que notification.mp3 est listé"
echo ""
echo "4️⃣  Rebuilder l'application:"
echo -e "   ${BLUE}flutter clean${NC}"
echo -e "   ${BLUE}flutter pub get${NC}"
echo -e "   ${BLUE}cd ios && pod install && cd ..${NC}"
echo -e "   ${BLUE}flutter run${NC}"
echo ""
echo -e "${GREEN}🎉 Une fois ces étapes terminées, le son fonctionnera sur iOS !${NC}"
