# 📺 Guide Rapide - Installation sur Totem Android 11

## 🎯 Votre Situation

Vous avez un **totem d'affichage numérique** (Digital Signage) avec :
- Format portrait (vertical)
- Android 11
- Utilisé pour affichage ETV (signalisation numérique)

## ✅ Corrections Appliquées

### 1. Mode Totem/Kiosque
- ✅ Écran toujours allumé (`FLAG_KEEP_SCREEN_ON`)
- ✅ Mode plein écran immersif (barres système cachées)
- ✅ Orientation verrouillée en portrait
- ✅ Compatibilité Android 11 avec `WindowInsetsController`

### 2. Gestion Robuste
- ✅ L'app continue de fonctionner même si Firebase échoue
- ✅ Gestion d'erreur pour Google Play Services manquant
- ✅ Optimisations mémoire pour grands écrans

## 🚀 Installation - 3 Étapes

### Étape 1 : Diagnostiquer le Totem

Branchez le totem via USB et exécutez :

```bash
./diagnose_totem.sh
```

Ce script vous dira :
- Si le totem a Google Play Services
- La version Android exacte
- La RAM disponible
- L'état de la connexion Internet

### Étape 2 : Builder l'APK

```bash
./build_totem_apk.sh
```

Le script vous demandera si vous voulez une version sans Firebase (si pas de Google Play Services).

### Étape 3 : Installer sur le Totem

**Option A - Via ADB (recommandé) :**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Option B - Via clé USB :**
1. Copiez `build/app/outputs/flutter-apk/app-release.apk` sur une clé USB
2. Branchez la clé sur le totem
3. Utilisez le gestionnaire de fichiers pour installer l'APK

## 🔍 Si l'App Crash Encore

### 1. Capturez les Logs

Branchez le totem et lancez :
```bash
./capture_crash_logs.sh
```

Puis ouvrez l'app sur le totem. Les logs seront dans `crash_logs.txt`.

### 2. Cherchez Ces Erreurs

Dans `crash_logs.txt`, cherchez :

- `FATAL EXCEPTION` → Erreur critique
- `ClassNotFoundException` → Bibliothèque manquante
- `SecurityException` → Permission refusée
- `UnsatisfiedLinkError` → Problème de compatibilité

### 3. Solutions Communes

**"Google Play Services not available"**
→ Rebuildez avec `./build_totem_apk.sh` et choisissez "o" (sans Firebase)

**"Permission denied"**
→ Accordez toutes les permissions dans les paramètres du totem

**"Out of memory"**
→ Le totem manque de RAM, réduisez la qualité des images/vidéos

## 📋 Checklist Déploiement

Avant de considérer que c'est terminé :

- [ ] APK installé avec succès
- [ ] App se lance sans crash
- [ ] Écran reste allumé (ne se met pas en veille)
- [ ] Mode plein écran (pas de barres système)
- [ ] Orientation portrait verrouillée
- [ ] Connexion Internet fonctionne dans l'app
- [ ] Test pendant au moins 30 minutes

## 🎨 Optimisations Visuelles (Optionnel)

### Adapter l'UI pour Grand Écran

Si besoin d'adapter l'interface pour le grand format du totem, modifiez les tailles dans Flutter :

```dart
// Dans vos widgets, détectez la taille d'écran
final screenHeight = MediaQuery.of(context).size.height;
final isLargeScreen = screenHeight > 1080;

// Adaptez les tailles
final fontSize = isLargeScreen ? 24.0 : 16.0;
final iconSize = isLargeScreen ? 48.0 : 32.0;
```

## 🔐 Mode Kiosque Complet (Optionnel)

Pour empêcher les utilisateurs de sortir de l'app :

1. **Installez une app Kiosk Launcher** depuis le Play Store :
   - Fully Kiosk Browser (recommandé)
   - SureLock
   - KioWare

2. **Configurez l'app comme launcher par défaut**

3. **Verrouillez avec un code PIN**

## 📞 Support

### Informations à Fournir en Cas de Problème

Si vous avez besoin d'aide, fournissez :

1. Le fichier `crash_logs.txt`
2. La sortie de `./diagnose_totem.sh`
3. Photos du message d'erreur sur le totem
4. Marque et modèle exact du totem

### Commandes Utiles

```bash
# Voir les logs en temps réel
adb logcat | grep artluxurybus

# Désinstaller l'ancienne version
adb uninstall com.example.artluxurybus

# Vérifier si l'app est installée
adb shell pm list packages | grep artluxurybus

# Lancer l'app via ADB
adb shell am start -n com.example.artluxurybus/.MainActivity

# Redémarrer le totem
adb reboot
```

## 🎉 C'est Tout !

Votre app est maintenant optimisée pour :
- ✅ Totems d'affichage Android 11
- ✅ Mode plein écran permanent
- ✅ Écran toujours allumé
- ✅ Fonctionnement avec ou sans Google Play Services
- ✅ Gestion robuste des erreurs

Bonne chance ! 🚀
