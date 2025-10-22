#!/bin/bash

echo "🔧 Régénération des fichiers de sérialisation JSON..."
echo ""

# Aller dans le répertoire du projet
cd "$(dirname "$0")"

echo "📂 Répertoire: $(pwd)"
echo ""

# Régénérer les fichiers .g.dart
echo "⚙️ Exécution de build_runner..."
flutter pub run build_runner build --delete-conflicting-outputs

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Régénération réussie!"
    echo ""
    echo "🚀 Relance de l'application..."
    echo ""
    flutter run
else
    echo ""
    echo "❌ Erreur lors de la régénération"
    echo "Vérifiez les erreurs ci-dessus"
    exit 1
fi
