import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/caisse_service.dart';
import '../theme/app_theme.dart';

class CaisseScreen extends StatefulWidget {
  final bool canManage;

  const CaisseScreen({super.key, required this.canManage});

  @override
  State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen> {
  bool _loading = true;
  String? _error;
  bool _canManage = false;
  double _solde = 0;
  double _totalRecharge = 0;
  double _totalDepense = 0;
  double _rechargesMois = 0;
  double _depensesMois = 0;
  List<dynamic> _recharges = [];
  List<dynamic> _depenses = [];

  final _money = NumberFormat.decimalPattern('fr');

  @override
  void initState() {
    super.initState();
    _canManage = widget.canManage;
    _load();
  }

  String _fcfa(num value) => '${_money.format(value)} FCFA';

  int _asId(dynamic id) => id is int ? id : int.parse(id.toString());

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await CaisseService.getDashboard();
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _canManage = result['can_manage'] == true;
        _solde = (data['solde'] as num?)?.toDouble() ?? 0;
        _totalRecharge = (data['total_recharge'] as num?)?.toDouble() ?? 0;
        _totalDepense = (data['total_depense'] as num?)?.toDouble() ?? 0;
        _rechargesMois = (data['recharges_mois'] as num?)?.toDouble() ?? 0;
        _depensesMois = (data['depenses_mois'] as num?)?.toDouble() ?? 0;
        _recharges = data['recharges'] as List<dynamic>? ?? [];
        _depenses = data['depenses'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['message']?.toString() ?? 'Impossible de charger la caisse.';
        _loading = false;
      });
    }
  }

  Future<void> _showRechargeDialog() async {
    final montantController = TextEditingController();
    final descriptionController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recharger la caisse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montantController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA) *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final montant = double.tryParse(montantController.text.trim());
              if (montant == null || montant < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Indiquez un montant valide.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (created != true || !mounted) return;
    final montant = double.parse(montantController.text.trim());
    final result = await CaisseService.createRecharge(
      montant: montant,
      description: descriptionController.text.trim(),
    );
    if (!mounted) return;
    _toast(result);
    if (result['success'] == true) _load();
  }

  Future<void> _showDepenseDialog() async {
    final motifController = TextEditingController();
    final montantController = TextEditingController();
    final descriptionController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrer une dépense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: motifController,
                decoration: const InputDecoration(
                  labelText: 'Motif *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: montantController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA) *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motifController.text.trim().isEmpty ||
                  double.tryParse(montantController.text.trim()) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le motif et le montant sont obligatoires.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (created != true || !mounted) return;
    final result = await CaisseService.createDepense(
      motif: motifController.text.trim(),
      montant: double.parse(montantController.text.trim()),
      description: descriptionController.text.trim(),
    );
    if (!mounted) return;
    _toast(result);
    if (result['success'] == true) _load();
  }

  Future<void> _delete({
    required String label,
    required Future<Map<String, dynamic>> Function() action,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer cette $label ?'),
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
    if (confirm != true || !mounted) return;
    final result = await action();
    if (!mounted) return;
    _toast(result);
    if (result['success'] == true) _load();
  }

  void _toast(Map<String, dynamic> result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Opération terminée.'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caisse de Fonctionnement'),
        backgroundColor: isDark ? Colors.grey[900] : AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2744),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'SOLDE ACTUEL DE LA CAISSE',
                              style: TextStyle(
                                color: Colors.white70,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _fcfa(_solde),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _showRechargeDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Recharger'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _showDepenseDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.remove),
                                    label: const Text('Dépense'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard('Rechargé', _fcfa(_totalRecharge), Colors.green),
                          const SizedBox(width: 8),
                          _statCard('Dépensé', _fcfa(_totalDepense), Colors.red),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statCard('Ce mois +', _fcfa(_rechargesMois), Colors.blue),
                          const SizedBox(width: 8),
                          _statCard('Ce mois -', _fcfa(_depensesMois), Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Recharges',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_recharges.isEmpty)
                        const Text('Aucune recharge.')
                      else
                        ..._recharges.map((item) => _operationTile(
                              title: _fcfa(item['montant'] ?? 0),
                              subtitle: [
                                if ((item['description'] ?? '').toString().isNotEmpty)
                                  item['description'],
                                if ((item['creator_name'] ?? '').toString().isNotEmpty)
                                  'Par ${item['creator_name']}',
                              ].join(' · '),
                              color: Colors.green,
                              onDelete: _canManage
                                  ? () => _delete(
                                        label: 'recharge',
                                        action: () => CaisseService.deleteRecharge(
                                          _asId(item['id']),
                                        ),
                                      )
                                  : null,
                            )),
                      const SizedBox(height: 16),
                      Text(
                        'Dépenses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_depenses.isEmpty)
                        const Text('Aucune dépense.')
                      else
                        ..._depenses.map((item) => _operationTile(
                              title: '${item['motif'] ?? ''} · ${_fcfa(item['montant'] ?? 0)}',
                              subtitle: [
                                if ((item['description'] ?? '').toString().isNotEmpty)
                                  item['description'],
                                if ((item['creator_name'] ?? '').toString().isNotEmpty)
                                  'Par ${item['creator_name']}',
                              ].where((part) => part.toString().isNotEmpty).join(' · '),
                              color: Colors.red,
                              onDelete: _canManage
                                  ? () => _delete(
                                        label: 'dépense',
                                        action: () => CaisseService.deleteDepense(
                                          _asId(item['id']),
                                        ),
                                      )
                                  : null,
                            )),
                    ],
                  ),
                ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _operationTile({
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onDelete,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            color == Colors.green ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
          ),
        ),
        title: Text(title),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: onDelete == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
      ),
    );
  }
}
