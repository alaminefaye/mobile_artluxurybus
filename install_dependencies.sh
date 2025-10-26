#!/bin/bash

echo "🔧 Installation des dépendances..."
echo ""

# Vérifier si Flutter est installé
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter n'est pas installé ou pas dans le PATH"
    echo "Veuillez installer Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter trouvé: $(flutter --version | head -n 1)"
echo ""

# Installer les dépendances
echo "📦 Installation des packages..."
flutter pub get

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Dépendances installées avec succès!"
    echo ""
    echo "📋 Packages installés:"
    echo "  - file_picker: ^8.0.0+1 (nouveau)"
    echo "  - image_picker: ^1.0.4"
    echo "  - http: ^1.5.0"
    echo "  - et plus..."
    echo ""
    echo "🚀 Prochaines étapes:"
    echo "  1. Faire un Hot Restart (Cmd+Shift+F5)"
    echo "  2. OU relancer l'app: flutter run"
    echo ""
else
    echo ""
    echo "❌ Erreur lors de l'installation des dépendances"
    exit 1
fi
