# 🔧 GUIDE - ERREURS RÉSEAU

## 🔴 Erreur Affichée

```
ClientException with SocketException: No route to host
(OS Error: No route to host, errno = 113)
```

**Traduction** : L'application ne peut pas se connecter à l'API.

---

## ✅ SOLUTIONS

### 1. **Vérifier la connexion Internet du téléphone**

#### Sur Android :
- Glissez vers le bas pour afficher les réglages rapides
- Vérifiez que le **WiFi** ou les **données mobiles** sont activés
- Testez dans un navigateur (Chrome) : ouvrir `google.com`

#### Sur iOS :
- Centre de contrôle (glisser depuis le coin)
- Vérifier WiFi ou données cellulaires activées
- Tester avec Safari

---

### 2. **Vérifier l'accès à l'API**

L'application se connecte à :
```
https://gestion-compagny.universaltechnologiesafrica.com/api
```

**Test depuis le téléphone** :
1. Ouvrir un navigateur
2. Aller sur : `https://gestion-compagny.universaltechnologiesafrica.com/api/ping`
3. ✅ Si ça affiche un JSON → L'API est accessible
4. ❌ Si erreur → Problème de connexion ou serveur down

---

### 3. **Cas Spécifiques**

#### A. WiFi connecté mais pas d'internet
- Redémarrer le routeur WiFi
- Oublier le réseau WiFi et se reconnecter
- Essayer avec les données mobiles

#### B. Données mobiles activées mais bloquées
- Vérifier que l'application a l'autorisation d'utiliser les données
- **Android** : Paramètres → Applications → Art Luxury Bus → Données mobiles
- **iOS** : Réglages → Données cellulaires → Art Luxury Bus

#### C. Pare-feu ou proxy
- Si vous êtes sur un réseau d'entreprise/école
- Le réseau peut bloquer l'accès à l'API
- Essayer avec un autre réseau WiFi ou 4G

#### D. Serveur API temporairement down
- Attendre quelques minutes
- Vérifier l'état du serveur sur un navigateur

---

## 🎨 Widget d'Erreur Amélioré

J'ai créé `network_error_widget.dart` qui :

✅ **Détecte automatiquement** les erreurs réseau
✅ **Affiche un message clair** : "Pas de connexion Internet"
✅ **Donne des conseils** pratiques
✅ **Bouton Réessayer** fonctionnel
✅ **Icône WiFi barré** pour identifier rapidement

---

## 📱 Intégration dans l'App

Pour utiliser le nouveau widget dans vos écrans :

```dart
import '../widgets/network_error_widget.dart';

// Dans votre widget
error: (error, stack) => NetworkErrorWidget(
  errorMessage: error.toString(),
  onRetry: () => ref.refresh(yourProvider),
),
```

---

## 🐛 Debug Avancé

Si le problème persiste, vérifier les logs :

```bash
flutter logs
```

Cherchez :
- `SocketException`
- `Connection refused`
- `Failed host lookup`
- `Connection timed out`

---

## 🔄 Mode Offline (Futur)

Pour améliorer l'expérience utilisateur, vous pourriez :

1. **Cacher les données** localement (SQLite/Hive)
2. **Mode offline** avec synchronisation ultérieure
3. **Indicateur de connexion** permanent dans l'app
4. **Queue de requêtes** à envoyer quand la connexion revient

---

## ✅ Checklist Dépannage

- [ ] WiFi ou données mobiles activés ?
- [ ] Connexion internet fonctionnelle (tester navigateur) ?
- [ ] API accessible depuis le téléphone ?
- [ ] Autorisation données mobiles pour l'app ?
- [ ] Pas de pare-feu/proxy bloquant ?
- [ ] Serveur API en ligne ?

---

## 📞 Support

Si aucune solution ne fonctionne :
1. Noter le message d'erreur exact
2. Tester l'API depuis un navigateur
3. Vérifier les logs du serveur Laravel
4. Contacter l'administrateur réseau si sur réseau professionnel

---

**💡 L'erreur "No route to host" = Problème de réseau 99% du temps !**
