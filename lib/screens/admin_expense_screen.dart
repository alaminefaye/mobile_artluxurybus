import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_expense_service.dart';
import '../models/admin_expense_model.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_helper.dart';

class AdminExpenseScreen extends StatefulWidget {
  const AdminExpenseScreen({super.key});

  @override
  State<AdminExpenseScreen> createState() => _AdminExpenseScreenState();
}

class _AdminExpenseScreenState extends State<AdminExpenseScreen> {
  List<AdminExpense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _typeFilter;
  DateTime? _dateStart;
  DateTime? _dateEnd;
  bool _allDates = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _expenseTypes = [
    {'value': 'eau', 'label': 'Eau'},
    {'value': 'surcrerie', 'label': 'Surcrerie'},
    {'value': 'achat_pieces', 'label': 'Achat pièces'},
    {'value': 'vidange', 'label': 'Vidange'},
    {'value': 'carburant', 'label': 'Carburant'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadExpenses();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _expenses = [];
        _hasMore = true;
      });
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AdminExpenseService.getAdminExpenses(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        typeDepense: _typeFilter,
        dateStart: _dateStart?.toIso8601String().split('T')[0],
        dateEnd: _dateEnd?.toIso8601String().split('T')[0],
        allDates: _allDates,
        page: _currentPage,
        perPage: 15,
      );

      if (mounted) {
        if (result['success'] == true) {
          final data = result['data'];
          final List<dynamic> expensesJson = data['admin_expenses'] ?? [];
          final pagination = data['pagination'] ?? {};

          final List<AdminExpense> newExpenses =
              expensesJson.map((json) => AdminExpense.fromJson(json)).toList();

          setState(() {
            if (refresh) {
              _expenses = newExpenses;
            } else {
              _expenses.addAll(newExpenses);
            }
            _currentPage = pagination['current_page'] ?? 1;
            _totalPages = pagination['last_page'] ?? 1;
            _hasMore = _currentPage < _totalPages;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                result['message'] ?? 'Erreur lors du chargement des dépenses.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              ErrorMessageHelper.getOperationError('charger', error: e);
          _isLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        setState(() {
          _currentPage++;
        });
        _loadExpenses();
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AdminExpenseFormDialog(),
    );

    if (result != null && result['success'] == true) {
      _loadExpenses(refresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Dépense créée avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(AdminExpense expense) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AdminExpenseFormDialog(expense: expense),
    );

    if (result != null && result['success'] == true) {
      _loadExpenses(refresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Dépense mise à jour avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteExpense(AdminExpense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la dépense'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${expense.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await AdminExpenseService.deleteAdminExpense(expense.id);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Dépense supprimée avec succès.'),
                backgroundColor: Colors.green,
              ),
            );
            _loadExpenses(refresh: true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Erreur lors de la suppression.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorMessageHelper.getOperationError('supprimer', error: e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses Admin'),
        backgroundColor: isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
            tooltip: 'Ajouter une dépense',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrer',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadExpenses(refresh: true),
        child: Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _loadExpenses(refresh: true);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _loadExpenses(refresh: true);
                },
              ),
            ),

            // Liste des dépenses
            Expanded(
              child: _isLoading && _expenses.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_errorMessage!,
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadExpenses(refresh: true),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : _expenses.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('Aucune dépense trouvée'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _expenses.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _expenses.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final expense = _expenses[index];
                                return _buildExpenseCard(expense);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(AdminExpense expense) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône type de dépense
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: expense.typeDepenseColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  expense.typeDepenseLabel[0],
                  style: TextStyle(
                    color: expense.typeDepenseColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Contenu principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expense.titre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expense.typeDepenseLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (expense.description != null && expense.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      expense.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(expense.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Montant et menu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${NumberFormat('#,##0').format(expense.montant)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 4),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog(expense);
                    } else if (value == 'delete') {
                      _deleteExpense(expense);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        typeFilter: _typeFilter,
        dateStart: _dateStart,
        dateEnd: _dateEnd,
        allDates: _allDates,
        expenseTypes: _expenseTypes,
        onApply: (type, start, end, allDates) {
          setState(() {
            _typeFilter = type;
            _dateStart = start;
            _dateEnd = end;
            _allDates = allDates;
          });
          _loadExpenses(refresh: true);
        },
      ),
    );
  }
}

// Dialog pour créer/modifier une dépense
class _AdminExpenseFormDialog extends StatefulWidget {
  final AdminExpense? expense;

  const _AdminExpenseFormDialog({this.expense});

  @override
  State<_AdminExpenseFormDialog> createState() => _AdminExpenseFormDialogState();
}

class _AdminExpenseFormDialogState extends State<_AdminExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _typeDepense;
  final _titreController = TextEditingController();
  final _montantController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, String>> _expenseTypes = [
    {'value': 'eau', 'label': 'Eau'},
    {'value': 'surcrerie', 'label': 'Surcrerie'},
    {'value': 'achat_pieces', 'label': 'Achat pièces'},
    {'value': 'vidange', 'label': 'Vidange'},
    {'value': 'carburant', 'label': 'Carburant'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _typeDepense = widget.expense!.typeDepense;
      _titreController.text = widget.expense!.titre;
      _montantController.text = widget.expense!.montant.toString();
      _descriptionController.text = widget.expense!.description ?? '';
    } else {
      _typeDepense = _expenseTypes.first['value']!;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _montantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final montant = double.tryParse(_montantController.text);
      if (montant == null || montant < 0) {
        throw Exception('Montant invalide');
      }

      Map<String, dynamic> result;
      if (widget.expense != null) {
        result = await AdminExpenseService.updateAdminExpense(
          id: widget.expense!.id,
          typeDepense: _typeDepense,
          titre: _titreController.text.trim(),
          montant: montant,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        result = await AdminExpenseService.createAdminExpense(
          typeDepense: _typeDepense,
          titre: _titreController.text.trim(),
          montant: montant,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          Navigator.pop(context, {
            'success': true,
            'message': result['message'],
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      title: Text(
        widget.expense != null ? 'Modifier la dépense' : 'Nouvelle dépense',
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type de dépense
              DropdownButtonFormField<String>(
                initialValue: _typeDepense,
                decoration: const InputDecoration(
                  labelText: 'Type de dépense',
                  border: OutlineInputBorder(),
                ),
                items: _expenseTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _typeDepense = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Titre
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Montant
              TextFormField(
                controller: _montantController,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le montant est obligatoire';
                  }
                  final montant = double.tryParse(value);
                  if (montant == null || montant < 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.expense != null ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }
}

// Dialog pour les filtres
class _FilterDialog extends StatefulWidget {
  final String? typeFilter;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final bool allDates;
  final List<Map<String, String>> expenseTypes;
  final Function(String?, DateTime?, DateTime?, bool) onApply;

  const _FilterDialog({
    required this.typeFilter,
    required this.dateStart,
    required this.dateEnd,
    required this.allDates,
    required this.expenseTypes,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late String? _typeFilter;
  late DateTime? _dateStart;
  late DateTime? _dateEnd;
  late bool _allDates;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.typeFilter;
    _dateStart = widget.dateStart;
    _dateEnd = widget.dateEnd;
    _allDates = widget.allDates;
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? (_dateStart ?? DateTime.now()) : (_dateEnd ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _dateStart = date;
        } else {
          _dateEnd = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type de dépense
            DropdownButtonFormField<String>(
              initialValue: _typeFilter,
              decoration: const InputDecoration(
                labelText: 'Type de dépense',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tous'),
                ),
                ...widget.expenseTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _typeFilter = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Toutes les dates
            CheckboxListTile(
              title: const Text('Toutes les dates'),
              value: _allDates,
              onChanged: (value) {
                setState(() {
                  _allDates = value ?? false;
                  if (_allDates) {
                    _dateStart = null;
                    _dateEnd = null;
                  }
                });
              },
            ),

            // Date de début
            if (!_allDates)
              ListTile(
                title: const Text('Date de début'),
                subtitle: Text(_dateStart != null
                    ? DateFormat('dd/MM/yyyy').format(_dateStart!)
                    : 'Non sélectionnée'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),

            // Date de fin
            if (!_allDates)
              ListTile(
                title: const Text('Date de fin'),
                subtitle: Text(_dateEnd != null
                    ? DateFormat('dd/MM/yyyy').format(_dateEnd!)
                    : 'Non sélectionnée'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _typeFilter = null;
              _dateStart = null;
              _dateEnd = null;
              _allDates = false;
            });
            widget.onApply(null, null, null, false);
            Navigator.pop(context);
          },
          child: const Text('Réinitialiser'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_typeFilter, _dateStart, _dateEnd, _allDates);
            Navigator.pop(context);
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}

