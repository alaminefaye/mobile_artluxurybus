# 🔔 Guide Test Notifications Push - Art Luxury Bus

## 🎯 Problème : Notifications dans l'app mais pas de push réelles

Je vois que votre app affiche les notifications dans l'interface, mais vous ne recevez pas les **vraies notifications push** sur votre téléphone.

## ⚡ **Actions IMMÉDIATES à faire :**

### **1. Créer le projet Firebase**
1. **Aller sur** [Firebase Console](https://console.firebase.google.com/)
2. **Créer nouveau projet** : `art-luxury-bus`
3. **Activer Analytics** (optionnel)

### **2. Ajouter l'app Android**
1. **Cliquer** "Ajouter une application" → Android 🤖
2. **Package Android** : `com.example.artluxurybus`
3. **Nom de l'app** (optionnel) : `Art Luxury Bus`
4. **Certificat SHA-1** : Laisser vide pour le moment

### **3. Télécharger google-services.json**
1. **Télécharger** le fichier `google-services.json`
2. **Le placer EXACTEMENT ici** : `/android/app/google-services.json`

⚠️ **TRÈS IMPORTANT** : Le fichier doit être à la racine du dossier `app`, pas dans un sous-dossier !

### **4. Rebuild l'application**
```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter clean
flutter pub get
flutter run
```

## 🔍 **Test étape par étape**

### **Test 1 : Vérifier les logs Firebase**
Après avoir lancé l'app, chercher dans les logs :
```
✅ Firebase initialisé
📱 Token FCM: eQg7Z2mKTR6...
✅ Permissions accordées
✅ Token enregistré sur le serveur
```

**Si pas de token FCM** → Le fichier `google-services.json` n'est pas au bon endroit.

### **Test 2 : Notification locale**
1. **Se connecter en tant qu'admin** dans l'app
2. **Appuyer sur "Tester les Notifications"** (dans le dashboard admin)  
3. **Résultat attendu** : Notification immédiate sur le téléphone

### **Test 3 : Firebase Console**
1. **Dans Firebase Console** → Cloud Messaging
2. **"Envoyer votre premier message"**
3. **Titre** : "Test Art Luxury Bus"
4. **Message** : "Ceci est un test"
5. **Cibler** : Votre application Android
6. **Envoyer maintenant**

### **Test 4 : Backend Laravel**
Une fois Firebase configuré, tester votre backend :
```bash
curl -X GET https://gestion-compagny.universaltechnologiesafrica.com/api/notifications/test-config \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 📱 **Configuration requise sur le téléphone**

### **Permissions Android**  
- ✅ **Notifications** activées pour Art Luxury Bus
- ✅ **Auto-start** activé (paramètres batterie)
- ✅ **Pas d'optimisation batterie** pour l'app

### **Vérifier les paramètres**
1. **Paramètres** → Apps → Art Luxury Bus → Notifications → **Activé**
2. **Paramètres** → Batterie → Optimisation → Art Luxury Bus → **Ne pas optimiser**

## 🐛 **Problèmes courants**

### **1. "Firebase not initialized"**
**Solution** : Fichier `google-services.json` manquant ou mal placé

### **2. "Token FCM null"**  
**Solution** : Refaire `flutter clean && flutter run`

### **3. "Permissions denied"**
**Solution** : Désinstaller l'app complètement, puis réinstaller

### **4. Notifications seulement en foreground**
**Solution** : Configurer AndroidManifest.xml (déjà fait dans votre projet)

## ⚡ **Plan d'action MAINTENANT**

### **Ordre d'exécution :**

1. **Créer projet Firebase** (5 min)
2. **Télécharger google-services.json** (1 min)  
3. **Placer le fichier** dans `/android/app/` (1 min)
4. **Flutter clean && run** (2 min)
5. **Tester notification locale** (bouton admin)
6. **Tester depuis Firebase Console**

### **Résultat attendu :**
- ✅ **Logs Firebase** : Token FCM visible
- ✅ **Notification locale** : Fonctionne immédiatement
- ✅ **Firebase Console** : Notification reçue sur téléphone
- ✅ **Backend Laravel** : Peut envoyer des notifications

## 📞 **Si ça ne marche toujours pas**

### **Logs à vérifier :**
```bash
flutter logs | grep -i firebase
flutter logs | grep -i notification
adb logcat | grep -i firebase
```

### **Tester sur :**
- ✅ **Émulateur Android** (pour debug)
- ✅ **Téléphone physique** (test réel)

La configuration est maintenant prête côté code. Il ne reste plus qu'à :
1. **Créer le projet Firebase**
2. **Télécharger google-services.json**
3. **Le placer au bon endroit**

Une fois fait, les notifications push devraient fonctionner parfaitement ! 🚀
