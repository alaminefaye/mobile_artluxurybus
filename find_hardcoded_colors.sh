#!/bin/bash

# Script pour trouver les couleurs codées en dur dans les fichiers Dart

echo "🔍 Recherche des couleurs codées en dur dans l'application..."
echo ""

SCREENS_DIR="lib/screens"
WIDGETS_DIR="lib/widgets"

echo "📁 Analyse du dossier: $SCREENS_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Fonction pour compter les occurrences
count_issues() {
    local file=$1
    local pattern=$2
    grep -c "$pattern" "$file" 2>/dev/null || echo "0"
}

# Analyser chaque fichier .dart
total_files=0
files_with_issues=0

for file in $(find $SCREENS_DIR -name "*.dart" 2>/dev/null); do
    total_files=$((total_files + 1))
    
    white_bg=$(count_issues "$file" "backgroundColor.*Colors\.white")
    grey_bg=$(count_issues "$file" "backgroundColor.*Colors\.grey\[")
    white_color=$(count_issues "$file" "color.*Colors\.white[^.]")
    black_color=$(count_issues "$file" "color.*Colors\.black")
    grey_color=$(count_issues "$file" "color.*Colors\.grey\[")
    
    total_issues=$((white_bg + grey_bg + white_color + black_color + grey_color))
    
    if [ $total_issues -gt 0 ]; then
        files_with_issues=$((files_with_issues + 1))
        echo "📄 $(basename $file)"
        echo "   Chemin: $file"
        
        [ $white_bg -gt 0 ] && echo "   ⚠️  backgroundColor: Colors.white → $white_bg occurrence(s)"
        [ $grey_bg -gt 0 ] && echo "   ⚠️  backgroundColor: Colors.grey[...] → $grey_bg occurrence(s)"
        [ $white_color -gt 0 ] && echo "   ⚠️  color: Colors.white → $white_color occurrence(s)"
        [ $black_color -gt 0 ] && echo "   ⚠️  color: Colors.black → $black_color occurrence(s)"
        [ $grey_color -gt 0 ] && echo "   ⚠️  color: Colors.grey[...] → $grey_color occurrence(s)"
        
        echo "   📊 Total: $total_issues problème(s)"
        echo ""
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 RÉSUMÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Fichiers analysés: $total_files"
echo "⚠️  Fichiers avec problèmes: $files_with_issues"
echo ""

if [ $files_with_issues -gt 0 ]; then
    echo "💡 RECOMMANDATIONS:"
    echo "   1. Remplacer Colors.white (background) par Theme.of(context).scaffoldBackgroundColor"
    echo "   2. Remplacer Colors.white (card) par Theme.of(context).cardColor"
    echo "   3. Remplacer Colors.black87 par Theme.of(context).textTheme.bodyLarge?.color"
    echo "   4. Remplacer Colors.grey[600] par Theme.of(context).textTheme.bodyMedium?.color"
    echo ""
    echo "📖 Voir THEME_DARK_MODE_FIX.md pour plus de détails"
else
    echo "🎉 Aucun problème détecté ! Tous les écrans utilisent le thème correctement."
fi

echo ""
