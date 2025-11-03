# Fix Rate Limiting (HTTP 429) - ArtLuxuryBus

## Problème identifié

L'application faisait **trop de requêtes API**, causant des erreurs 429 (Too Many Attempts) et le crash de l'application.

### Analyse des logs
```
I/flutter: ❌ Erreur API pour "mobile": 429 - {"message": "Too Many Attempts."}
```

**Causes principales:**
1. `AnnouncementManager` vérifiait les annonces **toutes les 10 secondes** (2 requêtes × 6 fois/min = 12 req/min)
2. `HoraireProvider` rafraîchissait les horaires **toutes les 30 secondes** (2 req/min)
3. **Total: ~14 requêtes/minute** → Rate limiting déclenché

## Solutions implémentées

### 1. AnnouncementManager (announcement_manager.dart)

#### ✅ Intervalle augmenté: 10s → 60s
```dart
// Avant: Timer.periodic(const Duration(seconds: 10), ...)
// Après:  Timer.periodic(Duration(seconds: _backoffSeconds), ...)
```

#### ✅ Throttling ajouté (minimum 30s entre requêtes)
```dart
if (_lastApiCall != null) {
  final timeSinceLastCall = DateTime.now().difference(_lastApiCall!);
  if (timeSinceLastCall.inSeconds < 30) {
    return; // Skip cette vérification
  }
}
```

#### ✅ Backoff exponentiel en cas d'erreur 429
```dart
if (e.toString().contains('429') || e.toString().contains('Too Many')) {
  _backoffSeconds = (_backoffSeconds * 2).clamp(60, 300); // Max 5 minutes
  _restartTimerWithNewInterval();
}
```

#### ✅ Réinitialisation du backoff en cas de succès
```dart
if (_backoffSeconds > 60) {
  _backoffSeconds = 60;
  _restartTimerWithNewInterval();
}
```

### 2. HoraireProvider (horaire_provider.dart)

#### ✅ Intervalle augmenté: 30s → 90s
```dart
// Avant: Duration(seconds: 30)
// Après:  Duration(seconds: 90)
```

### 3. HoraireRiverpodProvider (horaire_riverpod_provider.dart)

#### ✅ Intervalle augmenté: 30s → 90s
```dart
// Avant: const Duration(seconds: 30)
// Après:  const Duration(seconds: 90)
```

## Résultat attendu

### Avant
- Annonces: 12 req/min
- Horaires: 2 req/min
- **Total: ~14 req/min**

### Après
- Annonces: 1 req/min (avec throttling = max 2 req/min)
- Horaires: 0.67 req/min
- **Total: ~2.67 req/min**

### Réduction: **81% de requêtes en moins**

## En cas d'erreur 429

Le système réagit maintenant automatiquement:
1. Détecte l'erreur 429
2. Double l'intervalle de vérification
3. Attend jusqu'à 5 minutes max entre vérifications
4. Réinitialise progressivement en cas de succès

## Test recommandé

1. Lancer l'application
2. Observer les logs:
   ```
   🔄 [AnnouncementManager] Vérification des annonces...
   ⏸️ [AnnouncementManager] Throttling - dernière requête il y a Xs
   ```
3. Vérifier qu'il n'y a plus d'erreurs 429
4. Confirmer que les annonces fonctionnent toujours correctement

## Notes

- Les annonces seront détectées dans les 60 secondes (au lieu de 10s)
- Les horaires se rafraîchissent toutes les 90 secondes (au lieu de 30s)
- Ces intervalles sont un bon compromis entre réactivité et respect du rate limit
- En production, ajuster si nécessaire selon les limites du serveur
