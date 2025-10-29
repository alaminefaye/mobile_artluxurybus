/// Script de test pour vérifier la répétition des annonces
void main() {
  print('🧪 [TEST] Test de la répétition des annonces...');

  // Simuler une annonce active
  final now = DateTime.now();
  final annonce = {
    'id': 70,
    'titre': 'ANNONCE',
    'contenu': 'Ceci est un test d\'annonce vocale',
    'type': 'annonce',
    'appareil': 'mobile',
    'active': true,
    'isExpired': false,
    'dateDebut': now.subtract(const Duration(hours: 1)),
    'dateFin': now.add(const Duration(hours: 1)),
  };

  print('📝 [TEST] Annonce de test:');
  print('   - ID: ${annonce['id']}');
  print('   - Titre: ${annonce['titre']}');
  print('   - Type: ${annonce['type']}');
  print('   - Active: ${annonce['active']}');
  print('   - isExpired: ${annonce['isExpired']}');
  print('   - Date début: ${annonce['dateDebut']}');
  print('   - Date fin: ${annonce['dateFin']}');

  // Tester la logique isCurrentlyActive
  final isCurrentlyActive = _testIsCurrentlyActive(annonce, now);
  print('   - isCurrentlyActive: $isCurrentlyActive');
  print('   - isAnnonce: ${annonce['type'] == 'annonce'}');

  if (isCurrentlyActive && annonce['type'] == 'annonce') {
    print('   ✅ Cette annonce DEVRAIT être lue vocalement avec répétition');
    print('   🔄 Cycle: Lecture → Pause 5s → Lecture → Pause 5s → ...');
    print('   ⏹️ Arrêt automatique quand l\'annonce n\'est plus active');
  } else {
    print('   ❌ Cette annonce ne sera PAS lue vocalement');
  }

  print('\n🎉 [TEST] Test terminé !');
  print('\n📋 [INSTRUCTIONS] Pour tester:');
  print('1. Créez une annonce dans votre backoffice avec:');
  print('   - Type: annonce');
  print('   - Appareil: mobile ou votre device ID');
  print('   - Active: ✅');
  print('   - Date début: Maintenant');
  print('   - Date fin: Dans 1 heure');
  print('2. Relancez l\'application Flutter');
  print('3. L\'annonce devrait se répéter toutes les 5 secondes');
  print(
      '4. La boîte de dialogue devrait se fermer automatiquement quand l\'annonce n\'est plus active');
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

