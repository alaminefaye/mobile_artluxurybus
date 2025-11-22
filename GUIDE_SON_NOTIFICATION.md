# 🔊 Guide d'intégration du son de notification Pixabay

## ✅ Configuration déjà effectuée

Les modifications suivantes ont déjà été appliquées au code :

- ✅ `pubspec.yaml` mis à jour pour inclure `assets/sounds/`
- ✅ `notification_service.dart` configuré pour utiliser le son personnalisé
- ✅ `debug_notifications.dart` configuré avec le son personnalisé
- ✅ Dossier `android/app/src/main/res/raw` créé
- ✅ Script d'installation `install_notification_sound.sh` créé

---

## 📥 Étape 1 : Télécharger le fichier son

1. Allez sur : https://pixabay.com/fr/sound-effects/new-notification-1-398650/
2. Cliquez sur le bouton **"Téléchargement gratuit"** 
3. Téléchargez le fichier MP3
4. Renommez-le en **`notification.mp3`**

---

## 📂 Étape 2 : Placer le fichier aux bons emplacements

### Pour Android :

Copiez le fichier dans :
```
android/app/src/main/res/raw/notification.mp3
```

**Note :** Le dossier `raw` a déjà été créé. Il faut juste y copier le fichier.

### Pour iOS :

1. Ouvrez le projet dans Xcode :
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Dans Xcode :
   - Cliquez droit sur le dossier `Runner` 
   - Sélectionnez **Add Files to "Runner"...**
   - Choisissez votre fichier `notification.mp3`
   - Cochez **"Copy items if needed"**
   - Cochez **"Add to targets: Runner"**
   - Cliquez sur **Add**

---

## 🔧 Étape 3 : Mettre à jour pubspec.yaml

Le fichier `pubspec.yaml` a déjà été mis à jour pour inclure le dossier sounds dans les assets.

---

## ✅ Vérification

Après avoir placé les fichiers :

### Android
```bash
ls -la android/app/src/main/res/raw/
# Vous devriez voir : notification.mp3
```

### iOS
Dans Xcode, vérifiez que `notification.mp3` apparaît dans :
- Runner > Resources (dans la navigation de gauche)

---

## 🚀 Rebuild de l'application

Une fois les fichiers en place, rebuilder l'app :

```bash
flutter clean
flutter pub get
flutter run
## 📢 Étape 2 : Installer le fichier son (Méthode automatique)

1. **Téléchargez** le fichier depuis Pixabay (voir étape 1)
2. **Renommez-le** en `notification.mp3`
3. **Placez-le** dans le dossier du projet : `/Users/mouhamadoulaminefaye/Desktop/PROJETS DEV/mobile_dev/artluxurybus/`
4. **Exécutez** le script d'installation :

```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
./install_notification_sound.sh
```

Le script va automatiquement :
- ✅ Copier le fichier dans `android/app/src/main/res/raw/`
- ✅ Copier le fichier dans `assets/sounds/`
- ✅ Vérifier que tout est en place

---

## 📢 Ou : Installation manuelle

### Pour Android :

## 🎵 Le son sera utilisé pour :

- ✅ Notifications push (messages, annonces)
- ✅ Notifications locales
- ✅ Canal Android "Art Luxury Bus Notifications"

Le code a déjà été modifié pour utiliser automatiquement ce son personnalisé !
