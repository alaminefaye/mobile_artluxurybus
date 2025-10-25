#!/bin/bash

echo "🔍 Vérification des données du bus #1..."

curl -s "https://gestion-compagny.universaltechnologiesafrica.com/api/buses/1" | python3 -m json.tool | grep -A 20 "insurance_records"

echo ""
echo "✅ Vérification terminée"
