# 🎯 GUIDE D'INTÉGRATION - FAB ET ACTIONS

## ✅ CE QUI EST TERMINÉ

1. ✅ **Service API** - Toutes les méthodes CRUD
2. ✅ **4 Formulaires créés** :
   - `technical_visit_form_screen.dart`
   - `insurance_form_screen.dart`
   - `breakdown_form_screen.dart`
   - `vidange_form_screen.dart`

## 📝 IMPORTS À AJOUTER

Au début de `bus_detail_screen.dart`, ajoutez :

```dart
import 'technical_visit_form_screen.dart';
import 'insurance_form_screen.dart';
import 'breakdown_form_screen.dart';
import 'vidange_form_screen.dart';
```

## 🔧 MODIFICATIONS PAR ONGLET

### 1. VISITES TECHNIQUES

Remplacez la méthode `_buildTechnicalVisitsTab` par :

```dart
Widget _buildTechnicalVisitsTab(WidgetRef ref) {
  final visitsAsync = ref.watch(technicalVisitsProvider(widget.busId));
  
  return Stack(
    children: [
      Column(
        children: [
          // Filtres (déjà existants)
          Builder(
            builder: (context) => Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      'Période',
                      ['Aujourd\'hui', 'Ce mois', 'Année'],
                      _selectedTechPeriod,
                      (value) {
                        if (value != null && mounted) {
                          setState(() {
                            _selectedTechPeriod = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterDropdown(
                      'Année',
                      ['2025', '2024', '2023'],
                      _selectedTechYear,
                      (value) {
                        if (value != null && mounted) {
                          setState(() {
                            _selectedTechYear = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Liste filtrée
          Expanded(
            child: visitsAsync.when(
              data: (response) {
                final filteredData = _filterTechnicalVisits(response.data);
                
                if (filteredData.isEmpty) {
                  return _buildEmptyState(
                    _selectedTechPeriod.isNotEmpty || _selectedTechYear.isNotEmpty
                        ? 'Aucune visite pour cette période'
                        : 'Aucune visite technique enregistrée'
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final visit = filteredData[index];
                    final isExpiring = visit.expiryDate.isBefore(
                      DateTime.now().add(const Duration(days: 30)),
                    );
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isExpiring ? Colors.red : Colors.green).withValues(alpha: 0.1),
                          child: Icon(
                            Icons.fact_check,
                            color: isExpiring ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text('Visite du ${_formatDate(visit.visitDate)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expire le ${_formatDate(visit.expiryDate)}'),
                            Text(
                              'Résultat: ${visit.result}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Supprimer'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) => _handleVisitAction(value as String, visit),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
      
      // Bouton FAB
      Positioned(
        right: 16,
        bottom: 16,
        child: FloatingActionButton(
          heroTag: 'visit_fab',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TechnicalVisitFormScreen(busId: widget.busId),
              ),
            );
          },
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add),
        ),
      ),
    ],
  );
}
```

### 2. MÉTHODES D'ACTION À AJOUTER

Ajoutez ces méthodes à la fin de la classe `_BusDetailScreenState` :

```dart
// Actions Visites Techniques
Future<void> _handleVisitAction(String action, TechnicalVisit visit) async {
  if (action == 'edit') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicalVisitFormScreen(
          busId: widget.busId,
          visit: visit,
        ),
      ),
    );
  } else if (action == 'delete') {
    final confirm = await _showDeleteConfirmation('cette visite technique');
    if (confirm == true) {
      try {
        await BusApiService().deleteTechnicalVisit(widget.busId, visit.id);
        ref.invalidate(technicalVisitsProvider(widget.busId));
        if (mounted) {
          _showSuccessSnackBar('Visite supprimée');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Erreur: $e');
        }
      }
    }
  }
}

// Actions Assurances
Future<void> _handleInsuranceAction(String action, InsuranceRecord insurance) async {
  if (action == 'edit') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InsuranceFormScreen(
          busId: widget.busId,
          insurance: insurance,
        ),
      ),
    );
  } else if (action == 'delete') {
    final confirm = await _showDeleteConfirmation('cette assurance');
    if (confirm == true) {
      try {
        await BusApiService().deleteInsurance(widget.busId, insurance.id);
        ref.invalidate(insuranceHistoryProvider(widget.busId));
        if (mounted) {
          _showSuccessSnackBar('Assurance supprimée');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Erreur: $e');
        }
      }
    }
  }
}

// Actions Pannes
Future<void> _handleBreakdownAction(String action, BusBreakdown breakdown) async {
  if (action == 'edit') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BreakdownFormScreen(
          busId: widget.busId,
          breakdown: breakdown,
        ),
      ),
    );
  } else if (action == 'delete') {
    final confirm = await _showDeleteConfirmation('cette panne');
    if (confirm == true) {
      try {
        await BusApiService().deleteBreakdown(widget.busId, breakdown.id);
        ref.invalidate(breakdownsProvider(widget.busId));
        if (mounted) {
          _showSuccessSnackBar('Panne supprimée');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Erreur: $e');
        }
      }
    }
  }
}

// Actions Vidanges
Future<void> _handleVidangeAction(String action, BusVidange vidange) async {
  if (action == 'edit') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VidangeFormScreen(
          busId: widget.busId,
          vidange: vidange,
        ),
      ),
    );
  } else if (action == 'delete') {
    final confirm = await _showDeleteConfirmation('cette vidange');
    if (confirm == true) {
      try {
        await BusApiService().deleteVidange(widget.busId, vidange.id);
        ref.invalidate(vidangesProvider(widget.busId));
        if (mounted) {
          _showSuccessSnackBar('Vidange supprimée');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Erreur: $e');
        }
      }
    }
  }
}

// Helpers
Future<bool?> _showDeleteConfirmation(String item) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmer'),
      content: Text('Supprimer $item ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

void _showSuccessSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}

void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}
```

## 🚀 PATTERN POUR LES 3 AUTRES ONGLETS

Appliquez le même pattern pour :
- **Assurances** : Remplacez `visit` par `insurance`, utilisez `_handleInsuranceAction`
- **Pannes** : Remplacez `visit` par `breakdown`, utilisez `_handleBreakdownAction`
- **Vidanges** : Remplacez `visit` par `vidange`, utilisez `_handleVidangeAction`

## ✅ RÉSULTAT FINAL

Chaque onglet aura :
- ✅ Bouton FAB pour créer
- ✅ Menu 3 points sur chaque item (éditer/supprimer)
- ✅ Confirmation avant suppression
- ✅ Messages de succès/erreur
- ✅ Rafraîchissement automatique de la liste

---

**L'implémentation est presque terminée ! Il ne reste que l'intégration dans bus_detail_screen.dart ! 🎉**
