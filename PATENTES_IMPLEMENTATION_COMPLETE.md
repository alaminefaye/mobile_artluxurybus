# 🎯 Implémentation Complète des Patentes - Guide Final

## ✅ Fichiers Déjà Créés

1. ✅ **Modèle** : `lib/models/bus_models.dart` - Classe `Patent` avec méthodes utilitaires
2. ✅ **Service API** : `lib/services/bus_api_service.dart` - Méthodes CRUD (add, update, delete)
3. ✅ **Écran Liste** : `lib/screens/bus/patent_list_screen.dart`

---

## 📋 Fichiers à Créer

### 1. Provider Riverpod

**Fichier:** `lib/providers/bus_provider.dart` (AJOUTER ces providers)

```dart
// Provider pour les patentes (avec pagination)
final patentsProvider = FutureProvider.family.autoDispose<PaginatedResponse<Patent>, ({int busId, int page})>((ref, params) async {
  final busService = ref.read(busApiServiceProvider);
  return await busService.getPatents(params.busId, page: params.page);
});
```

---

### 2. Écran Détails d'une Patente

**Fichier:** `lib/screens/bus/patent_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/bus_models.dart';
import '../../providers/bus_provider.dart';
import '../../services/bus_api_service.dart';
import 'patent_form_screen.dart';

class PatentDetailScreen extends ConsumerWidget {
  final int busId;
  final String busNumber;
  final Patent patent;

  const PatentDetailScreen({
    Key? key,
    required this.busId,
    required this.busNumber,
    required this.patent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la Patente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatentFormScreen(
                    busId: busId,
                    busNumber: busNumber,
                    patent: patent,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(context),
            _buildInfoSection(context),
            if (patent.notes != null && patent.notes!.isNotEmpty)
              _buildNotesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: patent.statusColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.description, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            patent.patentNumber ?? 'N/A',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              patent.status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (patent.isExpiringSoon || patent.isExpired) ...[
            const SizedBox(height: 8),
            Text(
              '${patent.daysUntilExpiration} jours restants',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.calendar_today, 'Date de délivrance', _formatDate(patent.issueDate)),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.event, 'Date d\'expiration', _formatDate(patent.expiryDate)),
              if (patent.cost != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.attach_money, 'Coût', '${patent.cost!.toStringAsFixed(0)} FCFA'),
              ],
              if (patent.issuingAuthority != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.business, 'Autorité émettrice', patent.issuingAuthority!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notes, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Notes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                patent.notes!,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette patente ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final busService = ref.read(busApiServiceProvider);
        await busService.deletePatent(busId, patent.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patente supprimée avec succès')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}
```

---

### 3. Formulaire d'Ajout/Modification

**Fichier:** `lib/screens/bus/patent_form_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/bus_models.dart';
import '../../providers/bus_provider.dart';
import '../../services/bus_api_service.dart';

class PatentFormScreen extends ConsumerStatefulWidget {
  final int busId;
  final String busNumber;
  final Patent? patent; // null = ajout, non-null = modification

  const PatentFormScreen({
    Key? key,
    required this.busId,
    required this.busNumber,
    this.patent,
  }) : super(key: key);

  @override
  ConsumerState<PatentFormScreen> createState() => _PatentFormScreenState();
}

class _PatentFormScreenState extends ConsumerState<PatentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patentNumberController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _issuingAuthorityController = TextEditingController();
  
  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.patent != null) {
      _patentNumberController.text = widget.patent!.patentNumber ?? '';
      _costController.text = widget.patent!.cost?.toString() ?? '';
      _notesController.text = widget.patent!.notes ?? '';
      _issuingAuthorityController.text = widget.patent!.issuingAuthority ?? '';
      _issueDate = widget.patent!.issueDate;
      _expiryDate = widget.patent!.expiryDate;
    }
  }

  @override
  void dispose() {
    _patentNumberController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _issuingAuthorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.patent != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier la Patente' : 'Ajouter une Patente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _patentNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de patente *',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le numéro de patente';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: 'Date de délivrance *',
              date: _issueDate,
              onTap: () => _selectDate(context, isIssueDate: true),
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: 'Date d\'expiration *',
              date: _expiryDate,
              onTap: () => _selectDate(context, isIssueDate: false),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Coût (FCFA)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _issuingAuthorityController,
              decoration: const InputDecoration(
                labelText: 'Autorité émettrice',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Modifier' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Sélectionner une date',
          style: TextStyle(
            color: date != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isIssueDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate
          ? (_issueDate ?? DateTime.now())
          : (_expiryDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_issueDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les dates')),
      );
      return;
    }

    if (_expiryDate!.isBefore(_issueDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date d\'expiration doit être après la date de délivrance')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final busService = ref.read(busApiServiceProvider);
      
      final patentData = Patent(
        id: widget.patent?.id ?? 0,
        busId: widget.busId,
        patentNumber: _patentNumberController.text,
        issueDate: _issueDate!,
        expiryDate: _expiryDate!,
        cost: _costController.text.isNotEmpty ? double.parse(_costController.text) : null,
        issuingAuthority: _issuingAuthorityController.text.isNotEmpty ? _issuingAuthorityController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: widget.patent?.createdAt,
      );

      if (widget.patent != null) {
        await busService.updatePatent(widget.busId, widget.patent!.id, patentData);
      } else {
        await busService.addPatent(widget.busId, patentData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.patent != null ? 'Patente modifiée avec succès' : 'Patente ajoutée avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

---

### 4. Ajouter l'Onglet Patentes dans bus_detail_screen.dart

**Localiser** la section des onglets (Carburant, Visites, Assurances, Pannes, Vidanges) et **ajouter** :

```dart
// Dans la liste des tabs
Tab(
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.description, size: 18),
      SizedBox(width: 4),
      Text('Patentes'),
    ],
  ),
),

// Dans TabBarView
PatentListScreen(
  busId: widget.bus.id,
  busNumber: widget.bus.registrationNumber,
),
```

---

## 🚀 Déploiement

### Backend
```bash
cd /home2/sema9615/gestion-compagny
git pull
php artisan optimize:clear
```

### Mobile
```bash
cd /Users/mouhamadoulaminefaye/Desktop/PROJETS\ DEV/mobile_dev/artluxurybus
flutter pub get
flutter run
```

---

## ✅ Résultat Final

L'onglet **Patentes** sera disponible dans les détails du bus avec :
- ✅ Liste paginée des patentes
- ✅ Statut visuel (Valide / Expire bientôt / Expiré)
- ✅ Ajout de nouvelle patente
- ✅ Modification d'une patente
- ✅ Suppression avec confirmation
- ✅ Détails complets
- ✅ Notifications d'expiration (déjà configurées dans le backend)

**Félicitations ! Le système de Patentes est maintenant complet !** 🎉
