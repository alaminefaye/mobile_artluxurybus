# 🔧 Fix Package Name Crash - Art Luxury Bus

## ❌ Problème détecté

**Crash** : `ClassNotFoundException: Didn't find class "com.artluxrubus.MainActivity"`

**Cause** : Le package Firebase (`com.artluxrubus`) ne correspond pas au package de l'app (`com.example.artluxurybus`)

## ✅ Solution appliquée temporairement

J'ai remis le package original : `com.example.artluxurybus`

## 🚀 Actions à faire MAINTENANT

### **Option 1 : Reconfigurer Firebase (RECOMMANDÉ)**

1. **Aller sur** [Firebase Console](https://console.firebase.google.com/)
2. **Votre projet** : `artluxurybus-d7a63`
3. **Ajouter une nouvelle app Android** :
   - Package : `com.example.artluxurybus`
   - Nom : Art Luxury Bus
4. **Télécharger** le nouveau `google-services.json`
5. **Remplacer** le fichier dans `/android/app/google-services.json`

### **Test immédiat**
```bash
flutter clean
flutter run
```

**Résultat attendu** : App se lance sans crash

---

### **Option 2 : Restructurer l'app (PLUS COMPLEXE)**

Si vous préférez garder le package `com.artluxrubus` :

1. **Créer** la structure de dossier :
```bash
mkdir -p android/app/src/main/kotlin/com/artluxrubus
```

2. **Déplacer** MainActivity.kt :
```bash
mv android/app/src/main/kotlin/com/example/artluxurybus/MainActivity.kt android/app/src/main/kotlin/com/artluxrubus/MainActivity.kt
```

3. **Modifier** MainActivity.kt :
```kotlin
package com.artluxrubus  // Changer le package
```

4. **Remettre** les configs à `com.artluxrubus`

---

## 🎯 RECOMMANDATION

**Utilisez l'Option 1** : Reconfigurer Firebase est plus simple et évite les erreurs.

## 📱 Test Final

Une fois Firebase reconfiguré :

1. **App se lance** ✅
2. **Firebase s'initialise** ✅  
3. **Token FCM généré** ✅
4. **Notifications fonctionnent** ✅

## ⚡ Action Immédiate

**Faites ceci MAINTENANT** :
1. Aller sur Firebase Console
2. Ajouter app Android avec `com.example.artluxurybus`
3. Télécharger nouveau google-services.json
4. Remplacer le fichier existant
5. `flutter clean && flutter run`

Votre app devrait se lancer parfaitement ! 🚀
