import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';
import '../models/expense_model.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_helper.dart';

class ExpenseManagementScreen extends StatefulWidget {
  final bool showPendingOnly;
  
  const ExpenseManagementScreen({super.key, this.showPendingOnly = false});

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> with SingleTickerProviderStateMixin {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _statusFilter;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  late bool _showPendingOnly;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _showPendingOnly = widget.showPendingOnly;
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.showPendingOnly ? 1 : 0,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _showPendingOnly = _tabController.index == 1;
        });
        _loadExpenses(refresh: true);
      }
    });
    _loadExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      Map<String, dynamic> result;
      
      if (_showPendingOnly) {
        result = await ExpenseService.getPendingExpenses(
          page: _currentPage,
          perPage: 15,
        );
      } else {
        result = await ExpenseService.getExpenses(
          search: _searchQuery.isEmpty ? null : _searchQuery,
          status: _statusFilter,
          page: _currentPage,
          perPage: 15,
        );
      }

      if (mounted) {
        if (result['success'] == true) {
          final data = result['data'];
          final List<dynamic> expensesJson = data['expenses'] ?? [];
          final pagination = data['pagination'] ?? {};

          final List<Expense> newExpenses = expensesJson
              .map((json) => Expense.fromJson(json))
              .toList();

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
            _errorMessage = result['message'] ?? 'Erreur lors du chargement des dépenses.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ErrorMessageHelper.getOperationError('charger', error: e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createExpense() async {
    final motifController = TextEditingController();
    final montantController = TextEditingController();
    final commentaireController = TextEditingController();
    String selectedType = 'divers';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Nouvelle dépense',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: motifController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Motif *',
                  labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange : Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange.withValues(alpha: 0.5) : Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Type *',
                  labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange : Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange.withValues(alpha: 0.5) : Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'divers', child: Text('Divers')),
                  DropdownMenuItem(value: 'ration', child: Text('Ration')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedType = value ?? 'divers';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: montantController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA) *',
                  labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange : Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange.withValues(alpha: 0.5) : Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentaireController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                  labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange : Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange.withValues(alpha: 0.5) : Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (motifController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le motif est obligatoire.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final montant = double.tryParse(montantController.text.trim());
              if (montant == null || montant <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le montant doit être un nombre positif.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, {
                'motif': motifController.text.trim(),
                'montant': montant,
                'type': selectedType,
                'commentaire': commentaireController.text.trim().isEmpty
                    ? null
                    : commentaireController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final createResult = await ExpenseService.createExpense(
          motif: result['motif'],
          montant: result['montant'],
          type: result['type'],
          commentaire: result['commentaire'],
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (createResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(createResult['message'] ?? 'Dépense créée avec succès.'),
                backgroundColor: Colors.green,
              ),
            );
            _loadExpenses(refresh: true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(createResult['message'] ?? 'Erreur lors de la création de la dépense.'),
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
              content: Text(ErrorMessageHelper.getOperationError('créer', error: e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _validateExpense(Expense expense) async {
    final commentaireController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Valider la dépense',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: commentaireController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Commentaire (optionnel)',
            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange : Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange.withValues(alpha: 0.5) : Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'commentaire': commentaireController.text.trim().isEmpty
                    ? null
                    : commentaireController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final validateResult = await ExpenseService.validateExpense(
          id: expense.id,
          commentaire: result['commentaire'],
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (validateResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(validateResult['message'] ?? 'Dépense validée avec succès.'),
                backgroundColor: Colors.green,
              ),
            );
            _loadExpenses(refresh: true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(validateResult['message'] ?? 'Erreur lors de la validation de la dépense.'),
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
              content: Text(ErrorMessageHelper.getOperationError('valider', error: e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectExpense(Expense expense) async {
    final commentaireController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Rejeter la dépense',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: commentaireController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Commentaire (obligatoire) *',
            labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange : Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange.withValues(alpha: 0.5) : Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentaireController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le commentaire est obligatoire pour rejeter une dépense.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, {
                'commentaire': commentaireController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final rejectResult = await ExpenseService.rejectExpense(
          id: expense.id,
          commentaire: result['commentaire'],
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (rejectResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(rejectResult['message'] ?? 'Dépense rejetée avec succès.'),
                backgroundColor: Colors.green,
              ),
            );
            _loadExpenses(refresh: true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(rejectResult['message'] ?? 'Erreur lors du rejet de la dépense.'),
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
              content: Text(ErrorMessageHelper.getOperationError('rejeter', error: e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'validee':
        return Colors.green;
      case 'rejetee':
        return Colors.red;
      case 'en_attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildExpenseCard(Expense expense) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? Colors.grey[800] : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    expense.motif,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(expense.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(expense.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    expense.statusLabel,
                    style: TextStyle(
                      color: _getStatusColor(expense.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 20,
                  color: AppTheme.primaryOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  '${NumberFormat('#,###', 'fr').format(expense.montant)} FCFA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  expense.typeLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.person,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expense.creator?.name ?? 'Inconnu',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(expense.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (expense.commentaire != null && expense.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Commentaire: ${expense.commentaire}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
            if (expense.isPending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _rejectExpense(expense),
                    child: const Text(
                      'Rejeter',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _validateExpense(expense),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Valider'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des dépenses'),
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryOrange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Toutes les dépenses'),
            Tab(text: 'En attente'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createExpense,
            tooltip: 'Créer une dépense',
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_showPendingOnly) ...[
            // Barre de recherche et filtres
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par motif, montant...',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500]),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? AppTheme.primaryOrange : Colors.grey[700],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange.withValues(alpha: 0.5) : Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange.withValues(alpha: 0.5) : Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchQuery == value) {
                          _loadExpenses(refresh: true);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _statusFilter,
                    dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Statut',
                      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange.withValues(alpha: 0.5) : Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppTheme.primaryOrange.withValues(alpha: 0.5) : Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                      DropdownMenuItem(value: 'validee', child: Text('Validée')),
                      DropdownMenuItem(value: 'rejetee', child: Text('Rejetée')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value;
                      });
                      _loadExpenses(refresh: true);
                    },
                  ),
                ],
              ),
            ),
          ],
          // Liste des dépenses
          Expanded(
            child: _isLoading && _expenses.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadExpenses(refresh: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _expenses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 64,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showPendingOnly
                                      ? 'Aucune dépense en attente'
                                      : 'Aucune dépense trouvée',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadExpenses(refresh: true),
                            child: ListView.builder(
                              itemCount: _expenses.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _expenses.length) {
                                  // Charger plus
                                  _loadExpenses();
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _buildExpenseCard(_expenses[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

