#!/bin/bash
# Commandes à exécuter sur votre serveur Laravel

echo "🔧 Réparation serveur Laravel - Art Luxury Bus"
echo "=============================================="

# 1. Aller dans le répertoire du projet
cd /home2/sema9615/gestion-compagny

# 2. Installer/Publier Sanctum
echo "📦 Installation Laravel Sanctum..."
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

# 3. Migrer la base de données (créer table personal_access_tokens)
echo "🗄️ Migration base de données..."
php artisan migrate

# 4. Nettoyer les caches
echo "🧹 Nettoyage des caches..."
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# 5. Optimiser pour production
echo "⚡ Optimisation production..."
php artisan config:cache
php artisan route:cache

echo "✅ Réparation terminée !"
echo "🌐 Testez maintenant : https://gestion-compagny.universaltechnologiesafrica.com/api/ping"
