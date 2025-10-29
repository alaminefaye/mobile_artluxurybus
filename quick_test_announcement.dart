/// Test rapide pour vérifier la logique des annonces
void main() {
  print('🧪 [QUICK TEST] Test rapide de la logique des annonces...');

  // Simuler l'annonce #70 qui est détectée mais pas active
  final now = DateTime.now();

  // Scénarios possibles pour l'annonce #70
  final scenarios = [
    {
      'name': 'Annonce inactive',
      'data': {
        'id': 70,
        'titre': 'ANNONCE',
        'type': 'annonce',
        'active': false,
        'isExpired': false,
        'dateDebut': null,
        'dateFin': null,
      }
    },
    {
      'name': 'Annonce expirée',
      'data': {
        'id': 70,
        'titre': 'ANNONCE',
        'type': 'annonce',
        'active': true,
        'isExpired': true,
        'dateDebut': null,
        'dateFin': null,
      }
    },
    {
      'name': 'Annonce avec date de fin passée',
      'data': {
        'id': 70,
        'titre': 'ANNONCE',
        'type': 'annonce',
        'active': true,
        'isExpired': false,
        'dateDebut': now.subtract(const Duration(hours: 2)),
        'dateFin': now.subtract(const Duration(hours: 1)),
      }
    },
    {
      'name': 'Annonce avec date de début future',
      'data': {
        'id': 70,
        'titre': 'ANNONCE',
        'type': 'annonce',
        'active': true,
        'isExpired': false,
        'dateDebut': now.add(const Duration(hours: 1)),
        'dateFin': now.add(const Duration(hours: 2)),
      }
    },
    {
      'name': 'Annonce active (devrait fonctionner)',
      'data': {
        'id': 70,
        'titre': 'ANNONCE',
        'type': 'annonce',
        'active': true,
        'isExpired': false,
        'dateDebut': now.subtract(const Duration(hours: 1)),
        'dateFin': now.add(const Duration(hours: 1)),
      }
    },
  ];

  for (var scenario in scenarios) {
    print('\n📝 [TEST] ${scenario['name']}:');
    final data = scenario['data'] as Map<String, dynamic>;

    print('   - ID: ${data['id']}');
    print('   - Titre: ${data['titre']}');
    print('   - Type: ${data['type']}');
    print('   - Active: ${data['active']}');
    print('   - isExpired: ${data['isExpired']}');
    print('   - Date début: ${data['dateDebut']}');
    print('   - Date fin: ${data['dateFin']}');

    final isCurrentlyActive = _testIsCurrentlyActive(data, now);
    print('   - isCurrentlyActive: $isCurrentlyActive');
    print('   - isAnnonce: ${data['type'] == 'annonce'}');

    if (isCurrentlyActive && data['type'] == 'annonce') {
      print('   ✅ Cette annonce DEVRAIT être lue vocalement');
    } else {
      print('   ❌ Cette annonce ne sera PAS lue vocalement');
    }
  }

  print('\n🎉 [QUICK TEST] Test terminé !');
}

bool _testIsCurrentlyActive(Map<String, dynamic> message, DateTime now) {
  if (message['active'] != true) {
    print('   📅 [LOGIC] Message non actif (active=false)');
    return false;
  }
  if (message['isExpired'] == true) {
    print('   📅 [LOGIC] Message expiré (isExpired=true)');
    return false;
  }

  final dateDebut = message['dateDebut'] as DateTime?;
  final dateFin = message['dateFin'] as DateTime?;

  if (dateDebut != null && now.isBefore(dateDebut)) {
    print(
        '   📅 [LOGIC] Message pas encore commencé (dateDebut: $dateDebut, now: $now)');
    return false;
  }
  if (dateFin != null && now.isAfter(dateFin)) {
    print('   📅 [LOGIC] Message terminé (dateFin: $dateFin, now: $now)');
    return false;
  }

  print(
      '   ✅ [LOGIC] Message actif (active: ${message['active']}, isExpired: ${message['isExpired']}, dateDebut: $dateDebut, dateFin: $dateFin)');
  return true;
}
