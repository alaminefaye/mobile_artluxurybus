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

class _CaisseScreenState extends State<CaisseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
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
  final _rechargeNameController = TextEditingController();
  final _depenseNameController = TextEditingController();
  DateTime? _rechargeDay;
  DateTime? _depenseDay;

  final _money = NumberFormat.decimalPattern('fr');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _canManage = widget.canManage;
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _rechargeNameController.dispose();
    _depenseNameController.dispose();
    super.dispose();
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
        bottom: _loading || _error != null
            ? null
            : TabBar(
                controller: _tabs,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Solde'),
                  Tab(text: 'Recharges'),
                  Tab(text: 'Dépenses'),
                ],
              ),
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
              : TabBarView(
                  controller: _tabs,
                  children: [
                    RefreshIndicator(
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
                                  child: _actionButton(
                                    label: 'Recharger',
                                    icon: Icons.add,
                                    color: Colors.green,
                                    onPressed: _showRechargeDialog,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _actionButton(
                                    label: 'Dépense',
                                    icon: Icons.remove,
                                    color: Colors.orange,
                                    onPressed: _showDepenseDialog,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _statCard('Rechargé', _fcfa(_totalRecharge), Colors.green),
                            const SizedBox(width: 8),
                            _statCard('Dépensé', _fcfa(_totalDepense), Colors.red),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _statCard('Ce mois +', _fcfa(_rechargesMois), Colors.blue),
                            const SizedBox(width: 8),
                            _statCard('Ce mois -', _fcfa(_depensesMois), Colors.amber),
                          ],
                        ),
                      ),
                    ],
                      ),
                    ),
                    _operationList(
                      items: _filteredItems(
                        _recharges,
                        name: _rechargeNameController.text,
                        day: _rechargeDay,
                      ),
                      emptyLabel: _rechargeNameController.text.trim().isEmpty &&
                              _rechargeDay == null
                          ? 'Aucune recharge.'
                          : 'Aucun résultat pour ce filtre.',
                      isRecharge: true,
                      isDark: isDark,
                      nameController: _rechargeNameController,
                      selectedDay: _rechargeDay,
                      onDayChanged: (day) => setState(() => _rechargeDay = day),
                    ),
                    _operationList(
                      items: _filteredItems(
                        _depenses,
                        name: _depenseNameController.text,
                        day: _depenseDay,
                      ),
                      emptyLabel: _depenseNameController.text.trim().isEmpty &&
                              _depenseDay == null
                          ? 'Aucune dépense.'
                          : 'Aucun résultat pour ce filtre.',
                      isRecharge: false,
                      isDark: isDark,
                      nameController: _depenseNameController,
                      selectedDay: _depenseDay,
                      onDayChanged: (day) => setState(() => _depenseDay = day),
                    ),
                  ],
                ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

  List<dynamic> _filteredItems(
    List<dynamic> items, {
    required String name,
    required DateTime? day,
  }) {
    final query = name.trim().toLowerCase();
    return items.where((item) {
      if (day != null) {
        final created = DateTime.tryParse(item['created_at']?.toString() ?? '');
        if (created == null ||
            created.year != day.year ||
            created.month != day.month ||
            created.day != day.day) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        final creator = (item['creator_name'] ?? '').toString().toLowerCase();
        final motif = (item['motif'] ?? '').toString().toLowerCase();
        final description = (item['description'] ?? '').toString().toLowerCase();
        if (!creator.contains(query) &&
            !motif.contains(query) &&
            !description.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _operationList({
    required List<dynamic> items,
    required String emptyLabel,
    required bool isRecharge,
    required bool isDark,
    required TextEditingController nameController,
    required DateTime? selectedDay,
    required ValueChanged<DateTime?> onDayChanged,
  }) {
    final filters = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: nameController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        nameController.clear();
                        setState(() {});
                      },
                    ),
              filled: true,
              fillColor: isDark ? Colors.grey[850] : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDay ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      locale: const Locale('fr', 'FR'),
                      helpText: 'Filtrer par jour',
                    );
                    if (picked != null) onDayChanged(picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Jour',
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      selectedDay == null
                          ? 'Tous les jours'
                          : DateFormat('dd/MM/yyyy').format(selectedDay),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              if (selectedDay != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onDayChanged(null),
                ),
            ],
          ),
        ],
      ),
    );

    return Column(
      children: [
        filters,
        Expanded(
          child: RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    emptyLabel,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final createdAt =
                    DateTime.tryParse(item['created_at']?.toString() ?? '');
                final detail = isRecharge
                    ? (item['description'] ?? '').toString()
                    : [
                        (item['motif'] ?? '').toString(),
                        (item['description'] ?? '').toString(),
                      ].where((part) => part.isNotEmpty).join(' — ');
                final creator = (item['creator_name'] ?? '').toString();
                final subtitle = [
                  if (detail.isNotEmpty) detail,
                  if (creator.isNotEmpty) 'Par $creator',
                  if (createdAt != null)
                    DateFormat('dd/MM/yyyy').format(createdAt),
                ].join('\n');

                return Card(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          (isRecharge ? Colors.green : Colors.red)
                              .withValues(alpha: 0.15),
                      child: Icon(
                        isRecharge
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: isRecharge ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      isRecharge
                          ? _fcfa(item['montant'] ?? 0)
                          : '${item['motif'] ?? ''} · ${_fcfa(item['montant'] ?? 0)}',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: subtitle.isEmpty
                        ? null
                        : Text(
                            subtitle,
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                    trailing: _canManage
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(
                              label: isRecharge ? 'recharge' : 'dépense',
                              action: () => isRecharge
                                  ? CaisseService.deleteRecharge(_asId(item['id']))
                                  : CaisseService.deleteDepense(_asId(item['id'])),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
      ),
        ),
      ],
    );
  }
}
