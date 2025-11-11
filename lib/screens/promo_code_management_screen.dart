import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/promo_code_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_helper.dart';
import '../services/translation_service.dart';

class PromoCodeManagementScreen extends StatefulWidget {
  const PromoCodeManagementScreen({super.key});

  @override
  State<PromoCodeManagementScreen> createState() => _PromoCodeManagementScreenState();
}

class _PromoCodeManagementScreenState extends State<PromoCodeManagementScreen> {
  List<dynamic> _promoCodes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _statusFilter;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  @override
  void initState() {
    super.initState();
    _loadPromoCodes();
  }

  Future<void> _loadPromoCodes({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _promoCodes = [];
        _hasMore = true;
      });
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PromoCodeService.getPromoCodes(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _statusFilter,
        page: _currentPage,
        perPage: 15,
      );

      if (mounted) {
        if (result['success'] == true) {
          final List<dynamic> newCodes = result['data'] ?? [];
          final pagination = result['pagination'] ?? {};

          setState(() {
            if (refresh) {
              _promoCodes = newCodes;
            } else {
              _promoCodes.addAll(newCodes);
            }
            _currentPage = pagination['current_page'] ?? 1;
            _totalPages = pagination['last_page'] ?? 1;
            _hasMore = _currentPage < _totalPages;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Erreur lors du chargement des codes promo.';
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

  Future<void> _createPromoCode() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Créer un code promotionnel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du client *',
                    hintText: 'Entrez le nom du client',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    hintText: 'Description du code promo',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date d\'expiration (optionnel)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                          : 'Aucune date',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le nom du client est obligatoire.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context, {
                  'customer_name': nameController.text.trim(),
                  'description': descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  'expires_at': selectedDate != null
                      ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                      : null,
                });
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final createResult = await PromoCodeService.createPromoCode(
          customerName: result['customer_name'],
          description: result['description'],
          expiresAt: result['expires_at'],
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (createResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(createResult['message'] ?? 'Code promotionnel créé avec succès.'),
                backgroundColor: Colors.green,
              ),
            );
            _loadPromoCodes(refresh: true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(createResult['message'] ?? 'Erreur lors de la création du code promo.'),
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

  Future<void> _deletePromoCode(int id, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le code'),
        content: Text('Êtes-vous sûr de vouloir supprimer le code "$code" ?'),
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

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await PromoCodeService.deletePromoCode(id);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Code promotionnel supprimé avec succès.'),
                backgroundColor: Colors.green,
              ),
            );
            _loadPromoCodes(refresh: true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Erreur lors de la suppression du code promo.'),
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
        title: const Text('Laisser-passer'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createPromoCode,
            tooltip: 'Créer un code',
          ),
        ],
      ),
      body: Column(
        children: [
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
                  decoration: InputDecoration(
                    hintText: 'Rechercher par code ou nom...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    // Délai pour éviter trop de requêtes
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchQuery == value) {
                        _loadPromoCodes(refresh: true);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Tous')),
                          DropdownMenuItem(value: 'unused', child: Text('Disponible')),
                          DropdownMenuItem(value: 'used', child: Text('Utilisé')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value;
                          });
                          _loadPromoCodes(refresh: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des codes promo
          Expanded(
            child: _isLoading && _promoCodes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadPromoCodes(refresh: true),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _promoCodes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun code promotionnel trouvé',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadPromoCodes(refresh: true),
                            child: ListView.builder(
                              itemCount: _promoCodes.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _promoCodes.length) {
                                  // Charger plus
                                  _loadPromoCodes();
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final promoCode = _promoCodes[index];
                                final isUsed = promoCode['is_used'] == true;
                                final code = promoCode['code'] ?? '';
                                final customerName = promoCode['customer_name'] ?? '';
                                final createdAt = promoCode['created_at'] != null
                                    ? DateTime.parse(promoCode['created_at'])
                                    : null;
                                final expiresAt = promoCode['expires_at'] != null
                                    ? DateTime.parse(promoCode['expires_at'])
                                    : null;
                                final usedAt = promoCode['used_at'] != null
                                    ? DateTime.parse(promoCode['used_at'])
                                    : null;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isUsed
                                          ? Colors.grey
                                          : AppTheme.primaryOrange,
                                      child: Icon(
                                        isUsed ? Icons.check_circle : Icons.local_offer,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      code,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isUsed ? Colors.grey : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Client: $customerName'),
                                        if (createdAt != null)
                                          Text(
                                            'Créé: ${DateFormat('dd/MM/yyyy').format(createdAt)}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        if (expiresAt != null)
                                          Text(
                                            'Expire: ${DateFormat('dd/MM/yyyy').format(expiresAt)}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        if (isUsed && usedAt != null)
                                          Text(
                                            'Utilisé: ${DateFormat('dd/MM/yyyy').format(usedAt)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: isUsed
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deletePromoCode(
                                              promoCode['id'],
                                              code,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

