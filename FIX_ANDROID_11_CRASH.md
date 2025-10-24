# 🔧 Corrections pour Android 11+

## ✅ Modifications appliquées

### 1. **AndroidManifest.xml** - Permissions Android 11+
- ✅ Ajout des permissions de stockage avec `maxSdkVersion`
- ✅ Ajout de `QUERY_ALL_PACKAGES` pour package visibility
- ✅ Ajout de `POST_NOTIFICATIONS` pour Android 13+
- ✅ Configuration `requestLegacyExternalStorage` et `preserveLegacyExternalStorage`
- ✅ Support pour tous les types d'écrans (petit à extra-large)
- ✅ Ajout des queries pour caméra, galerie, et navigateurs web

### 2. **build.gradle.kts** - Configuration Build
- ✅ Activation de `multiDexEnabled`
- ✅ Ajout de la dépendance MultiDex
- ✅ Configuration ProGuard pour éviter le shrinking agressif
- ✅ Désactivation de minify et shrink en release

### 3. **main.dart** - Gestion d'erreurs
- ✅ Ajout de `FlutterError.onError` pour capturer toutes les erreurs
- ✅ Gestion d'erreur try-catch autour de l'initialisation Firebase
- ✅ L'app ne crashera plus si Firebase échoue

### 4. **notification_service.dart** - Robustesse
- ✅ Gestion d'erreur pour chaque étape d'initialisation
- ✅ Continue sans crasher même si Firebase n'est pas disponible
- ✅ Initialisation du stream controller dans tous les cas

## 🚀 Comment rebuilder l'APK

### Option 1 : Script automatique
```bash
./build_release_android11.sh
```

### Option 2 : Commandes manuelles
```bash
# Nettoyer
flutter clean

# Récupérer les dépendances
flutter pub get

# Builder l'APK
flutter build apk --release
```

## 🔍 Diagnostiquer le crash

Si l'app continue de crasher, utilisez le script de capture des logs :

```bash
./capture_crash_logs.sh
```

**Instructions :**
1. Branchez l'appareil Android via USB
2. Activez le mode développeur et le débogage USB
3. Lancez le script
4. Ouvrez l'application
5. Attendez le crash
6. Les logs seront dans `crash_logs.txt`

## 📱 Problèmes courants Android 11+

### Crash au démarrage
**Cause possible :** Firebase mal configuré
**Solution :** Vérifiez que `google-services.json` est présent dans `android/app/`

### Crash lors de l'utilisation de la caméra
**Cause :** Permissions non accordées au runtime
**Solution :** L'app doit demander les permissions avant d'utiliser la caméra

### Crash avec les notifications
**Cause :** Google Play Services manquant
**Solution :** Installez Google Play Services sur l'appareil de test

## 🎯 Checklist de déploiement

- [ ] `google-services.json` présent dans `android/app/`
- [ ] Version de compileSdk >= 34
- [ ] minSdk compatible (21 ou plus)
- [ ] MultiDex activé
- [ ] Permissions déclarées dans AndroidManifest.xml
- [ ] Test sur Android 11 (API 30) minimum
- [ ] Vérification des logs pour identifier les erreurs

## 📊 Configuration actuelle

- **minSdk :** 21 (Android 5.0)
- **targetSdk :** Latest (défini par Flutter)
- **compileSdk :** Latest (défini par Flutter)
- **MultiDex :** ✅ Activé
- **ProGuard :** Configuré mais minify désactivé
- **Large Heap :** ✅ Activé

## 🆘 Support

Si le problème persiste après ces corrections :
1. Capturez les logs avec `./capture_crash_logs.sh`
2. Vérifiez les erreurs dans `crash_logs.txt`
3. Recherchez les lignes contenant "FATAL" ou "AndroidRuntime"
4. Partagez ces logs pour diagnostic approfondi
