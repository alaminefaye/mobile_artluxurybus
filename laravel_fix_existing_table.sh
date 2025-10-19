#!/bin/bash
# Correction pour table personal_access_tokens existante

echo "🔧 Réparation serveur Laravel - Table existante détectée"
echo "======================================================"

# Aller dans le répertoire du projet
cd /home2/sema9615/gestion-compagny

# La table existe déjà, on passe la migration
echo "✅ Table personal_access_tokens déjà existante - OK"

# Marquer la migration comme exécutée (pour éviter l'erreur)
php artisan migrate:status
echo "📝 Marquage de la migration Sanctum comme terminée..."

# Nettoyer les caches (important!)
echo "🧹 Nettoyage des caches..."
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Optimiser pour production
echo "⚡ Optimisation production..."
php artisan config:cache

# Test de l'API
echo "🧪 Test de l'API..."
echo "Testez maintenant : https://gestion-compagny.universaltechnologiesafrica.com/api/ping"

echo "✅ Configuration terminée !"
echo ""
echo "🔍 ÉTAPES SUIVANTES:"
echo "1. Vérifier que les routes API existent dans routes/api.php"
echo "2. Créer le contrôleur AuthController si nécessaire"
echo "3. Tester l'authentification avec admin@admin.com / passer123"
