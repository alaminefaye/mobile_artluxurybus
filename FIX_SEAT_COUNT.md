# Fix: Problème de capacité/sièges du bus

## Problème identifié
Le backend Laravel utilise le champ **`seat_count`** mais le modèle Flutter cherchait **`capacity`**.

## Correction apportée
J'ai modifié le modèle `Bus` dans `lib/models/bus_models.dart` pour mapper correctement `seat_count` vers `capacity`.

### Changement effectué (ligne 71-72):
```dart
@JsonKey(name: 'seat_count')
final int? capacity;
```

## Étapes pour finaliser la correction

### 1. Régénérer les fichiers de sérialisation JSON
Ouvrez un terminal dans le projet et exécutez:
```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter pub run build_runner build --delete-conflicting-outputs
```

**OU** si vous utilisez Android Studio/VSCode:
- Ouvrez le terminal intégré
- Exécutez la commande ci-dessus

### 2. Vérifier que ça fonctionne
Après avoir régénéré les fichiers:
1. Relancez l'application
2. Allez sur la page des détails d'un bus
3. Le nombre de sièges devrait maintenant s'afficher correctement

### 3. Si vous voyez toujours "N/A" ou "0 places"
Cela signifie que les données ne sont pas dans la base de données. Vérifiez côté backend:

#### Vérifier la base de données Laravel:
```sql
SELECT id, registration_number, seat_count, status FROM buses LIMIT 10;
```

Si `seat_count` est NULL ou 0, ajoutez des données:
```sql
UPDATE buses SET seat_count = 43 WHERE registration_number = 'Premium 3883';
UPDATE buses SET seat_count = 43 WHERE registration_number = 'Premium 3884';
-- etc.
```

### 4. Structure attendue de l'API
L'API devrait maintenant retourner:
```json
{
  "id": 1,
  "registration_number": "Premium 3883",
  "seat_count": 43,
  "status": "available",
  "description": null,
  "created_at": "2025-10-22T03:00:00.000000Z",
  "updated_at": "2025-10-22T03:00:00.000000Z"
}
```

Et Flutter le mappera automatiquement à:
```dart
Bus(
  id: 1,
  registrationNumber: "Premium 3883",
  capacity: 43,  // ← Automatiquement mappé depuis seat_count
  status: "available",
  ...
)
```

## Résumé des fichiers modifiés
1. ✅ `lib/models/bus_models.dart` - Ajout du mapping `@JsonKey(name: 'seat_count')`
2. ⏳ `lib/models/bus_models.g.dart` - À régénérer avec build_runner
3. ✅ `lib/screens/bus/bus_detail_screen.dart` - Affichage corrigé

## Commande rapide pour tout régénérer
```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus && \
flutter pub run build_runner build --delete-conflicting-outputs && \
flutter run
```

---

**Note**: Si le problème persiste après la régénération, vérifiez les logs de l'API pour voir exactement ce qui est envoyé depuis le backend.
