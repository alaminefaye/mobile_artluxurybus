#!/bin/bash

echo "🔍 Test API Laravel - Bus #1"
echo ""

# Récupérer le token (remplacez par votre vrai token)
TOKEN="YOUR_AUTH_TOKEN_HERE"

curl -s -H "Authorization: Bearer $TOKEN" \
     -H "Accept: application/json" \
     "https://gestion-compagny.universaltechnologiesafrica.com/api/buses/1" \
     | head -100

echo ""
echo "✅ Test terminé"
