import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/promo_code_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_message_helper.dart';
import '../services/translation_service.dart';

class PromoCodeManagementScreen extends StatefulWidget {
  const PromoCodeManagementScreen({super.key});

  @override
  State<PromoCodeManagementScreen> createState() =>
      _PromoCodeManagementScreenState();
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
  final ScrollController _scrollController = ScrollController();

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPromoCodes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            _errorMessage = result['message'] ??
                'Erreur lors du chargement des codes promo.';
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
        _loadPromoCodes();
      }
    }
  }

  Future<void> _createPromoCode() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text(
            'Créer un code promotionnel',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Nom du client *',
                    labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700]),
                    hintText: 'Entrez le nom du client',
                    hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: isDark ? AppTheme.primaryOrange : Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.primaryOrange.withValues(alpha: 0.5)
                              : Colors.grey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppTheme.primaryOrange, width: 2),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Description (optionnel)',
                    labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700]),
                    hintText: 'Description du code promo',
                    hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: isDark ? AppTheme.primaryOrange : Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.primaryOrange.withValues(alpha: 0.5)
                              : Colors.grey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppTheme.primaryOrange, width: 2),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.white,
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
                      locale: const Locale('fr', 'FR'),
                      helpText: 'Sélectionner une date d\'expiration',
                      cancelText: 'Annuler',
                      confirmText: 'OK',
                      builder: (context, child) {
                        if (isDark) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: AppTheme.primaryOrange,
                                onPrimary: Colors.white,
                                surface: Colors.grey[850]!,
                                onSurface: Colors.white,
                                secondary: AppTheme.primaryOrange,
                                onSecondary: Colors.white,
                                error: Colors.red,
                                onError: Colors.white,
                                brightness: Brightness.dark,
                              ),
                              dialogTheme: DialogThemeData(
                                backgroundColor: Colors.grey[900],
                              ),
                              scaffoldBackgroundColor: Colors.grey[900],
                              cardColor: Colors.grey[800]!,
                              dividerColor: Colors.grey[700]!,
                              primaryColor: AppTheme.primaryOrange,
                              textTheme: ThemeData.dark().textTheme.apply(
                                    bodyColor: Colors.white,
                                    displayColor: Colors.white,
                                  ),
                              datePickerTheme: DatePickerThemeData(
                                backgroundColor: Colors.grey[900]!,
                                headerBackgroundColor: AppTheme.primaryOrange,
                                headerForegroundColor: Colors.white,
                                dayStyle: const TextStyle(color: Colors.white),
                                weekdayStyle:
                                    const TextStyle(color: Colors.white),
                                yearStyle: const TextStyle(color: Colors.white),
                                todayBorder: const BorderSide(
                                    color: AppTheme.primaryOrange, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        } else {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppTheme.primaryOrange,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                                secondary: AppTheme.primaryOrange,
                                onSecondary: Colors.white,
                                error: Colors.red,
                                onError: Colors.white,
                                brightness: Brightness.light,
                              ),
                              dialogTheme: const DialogThemeData(
                                backgroundColor: Colors.white,
                              ),
                              scaffoldBackgroundColor: Colors.white,
                              datePickerTheme: DatePickerThemeData(
                                backgroundColor: Colors.white,
                                headerBackgroundColor: AppTheme.primaryOrange,
                                headerForegroundColor: Colors.white,
                                dayStyle: const TextStyle(color: Colors.black),
                                weekdayStyle:
                                    const TextStyle(color: Colors.black),
                                yearStyle: const TextStyle(color: Colors.black),
                                todayBorder: const BorderSide(
                                    color: AppTheme.primaryOrange, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        }
                      },
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date d\'expiration (optionnel)',
                      labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700]),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                isDark ? AppTheme.primaryOrange : Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: isDark
                                ? AppTheme.primaryOrange.withValues(alpha: 0.5)
                                : Colors.grey),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppTheme.primaryOrange, width: 2),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.white,
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color:
                            isDark ? AppTheme.primaryOrange : Colors.grey[700],
                      ),
                    ),
                    child: Text(
                      selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                          : 'Aucune date',
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                    ),
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
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
              ),
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
                content: Text(createResult['message'] ??
                    'Code promotionnel créé avec succès.'),
                backgroundColor: Colors.green,
              ),
            );
            _loadPromoCodes(refresh: true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(createResult['message'] ??
                    'Erreur lors de la création du code promo.'),
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
              content:
                  Text(ErrorMessageHelper.getOperationError('créer', error: e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _sharePromoCode(
      String code, String customerName, BuildContext shareContext) async {
    try {
      final message = 'Code promotionnel Art Luxury Bus\n\n'
          'Code: $code\n'
          'Client: $customerName\n\n'
          'Utilisez ce code lors de votre réservation pour bénéficier d\'un ticket gratuit !';

      // Obtenir la position pour le partage (nécessaire pour iPad)
      final RenderBox? box = shareContext.findRenderObject() as RenderBox?;
      Rect? sharePositionOrigin;

      if (box != null) {
        try {
          final Offset position = box.localToGlobal(Offset.zero);
          final Size size = box.size;

          // Vérifier que la position et la taille sont valides
          if (size.width > 0 && size.height > 0) {
            sharePositionOrigin = Rect.fromLTWH(
              position.dx,
              position.dy,
              size.width,
              size.height,
            );
          }
        } catch (e) {
          // Si l'obtention de la position échoue, on continue sans sharePositionOrigin
          debugPrint(
              'Erreur lors de l\'obtention de la position pour le partage: $e');
        }
      }

      await Share.share(
        message,
        subject: 'Code promotionnel Art Luxury Bus',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du partage. Veuillez réessayer.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Erreur lors du partage: $e');
    }
  }

  Future<void> _deletePromoCode(int id, String code) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Supprimer le code',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le code "$code" ?',
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
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
                content: Text(result['message'] ??
                    'Code promotionnel supprimé avec succès.'),
                backgroundColor: Colors.green,
              ),
            );
            _loadPromoCodes(refresh: true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ??
                    'Erreur lors de la suppression du code promo.'),
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
              content: Text(
                  ErrorMessageHelper.getOperationError('supprimer', error: e)),
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
        backgroundColor: isDark ? Colors.grey[900] : AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createPromoCode,
            tooltip: 'Créer un code',
            color: Colors.white,
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
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par code ou nom...',
                    hintStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[500]),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? AppTheme.primaryOrange : Colors.grey[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.primaryOrange.withValues(alpha: 0.5)
                              : Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.primaryOrange.withValues(alpha: 0.5)
                              : Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryOrange, width: 2),
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
                        initialValue: _statusFilter,
                        dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Statut',
                          labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.primaryOrange
                                        .withValues(alpha: 0.5)
                                    : Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.primaryOrange
                                        .withValues(alpha: 0.5)
                                    : Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryOrange, width: 2),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.white,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'Tous',
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'unused',
                            child: Text(
                              'Disponible',
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'used',
                            child: Text(
                              'Utilisé',
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black),
                            ),
                          ),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                              ),
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
                              controller: _scrollController,
                              itemCount: _promoCodes.length +
                                  ((_hasMore && _isLoading) ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _promoCodes.length) {
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
                                final customerName =
                                    promoCode['customer_name'] ?? '';
                                final createdAt = promoCode['created_at'] !=
                                        null
                                    ? DateTime.parse(promoCode['created_at'])
                                    : null;
                                final expiresAt = promoCode['expires_at'] !=
                                        null
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
                                  color:
                                      isDark ? Colors.grey[850] : Colors.white,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isUsed
                                          ? Colors.grey
                                          : AppTheme.primaryOrange,
                                      child: Icon(
                                        isUsed
                                            ? Icons.check_circle
                                            : Icons.local_offer,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      code,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isUsed
                                            ? (isDark
                                                ? Colors.grey[500]
                                                : Colors.grey)
                                            : (isDark
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Client: $customerName',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        if (createdAt != null)
                                          Text(
                                            'Créé: ${DateFormat('dd/MM/yyyy').format(createdAt)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.grey[500]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        if (expiresAt != null)
                                          Text(
                                            'Expire: ${DateFormat('dd/MM/yyyy').format(expiresAt)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.grey[500]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        if (isUsed && usedAt != null)
                                          Text(
                                            'Utilisé: ${DateFormat('dd/MM/yyyy').format(usedAt)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.grey[600]
                                                  : Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Builder(
                                      builder: (shareContext) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Bouton de partage
                                          IconButton(
                                            icon: Icon(
                                              Icons.share,
                                              color: isDark
                                                  ? AppTheme.primaryOrange
                                                  : AppTheme.primaryOrange,
                                            ),
                                            onPressed: () => _sharePromoCode(
                                                code,
                                                customerName,
                                                shareContext),
                                            tooltip: 'Partager le code',
                                          ),
                                          // Bouton de suppression (seulement si non utilisé)
                                          if (!isUsed)
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              color: Colors.red,
                                              onPressed: () => _deletePromoCode(
                                                promoCode['id'],
                                                code,
                                              ),
                                              tooltip: 'Supprimer le code',
                                            )
                                          else
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            ),
                                        ],
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
