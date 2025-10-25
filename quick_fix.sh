#!/bin/bash
echo "🔄 Régénération rapide..."
cd "$(dirname "$0")"
flutter pub run build_runner build --delete-conflicting-outputs
echo "✅ Terminé!"
