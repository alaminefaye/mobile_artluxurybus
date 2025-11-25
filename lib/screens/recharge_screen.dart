import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/recharge_service.dart';
import '../models/recharge_transaction.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _montantFocusNode = FocusNode();
  String? _selectedModePaiement;
  bool _isLoading = false;
  double _currentSolde = 0.0;
  List<RechargeTransaction> _historique = [];
  bool _isLoadingHistorique = false;

  // Mode de paiement Wave
  final List<Map<String, dynamic>> _modesPaiement = [
    {
      'id': 'wave_money',
      'label': 'Wave',
      'color': Colors.teal,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Sélectionner Wave par défaut puisqu'il est le seul mode de paiement
    _selectedModePaiement = 'wave_money';
    _loadSolde();
    _loadHistorique();
  }

  void _moveCursorToEnd() {
    if (!mounted) return;
    final textLength = _montantController.text.length;
    if (textLength > 0) {
      _montantController.selection =
          TextSelection.collapsed(offset: textLength);
    }
  }

  @override
  void dispose() {
    _montantController.dispose();
    _montantFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSolde() async {
    if (!mounted) return;

    try {
      final result = await RechargeService.getSolde();

      if (!mounted) return;

      setState(() {
        if (result['success'] == true) {
          final soldeValue = result['solde'];
          if (soldeValue is double) {
            _currentSolde = soldeValue;
          } else if (soldeValue is int) {
            _currentSolde = soldeValue.toDouble();
          } else if (soldeValue is String) {
            _currentSolde = double.tryParse(soldeValue) ?? 0.0;
          } else {
            _currentSolde = 0.0;
          }
        } else {
          // En cas d'erreur, garder le solde à 0 mais ne pas crasher
          _currentSolde = 0.0;
          debugPrint(
              '⚠️ [RechargeScreen] Erreur lors du chargement du solde: ${result['message']}');
        }
      });
    } catch (e, stackTrace) {
      debugPrint(
          '❌ [RechargeScreen] Exception lors du chargement du solde: $e');
      debugPrint('❌ [RechargeScreen] Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _currentSolde = 0.0;
        });
      }
    }
  }

  Future<void> _loadHistorique() async {
    if (!mounted) return;

    setState(() {
      _isLoadingHistorique = true;
    });

    try {
      final result = await RechargeService.getHistorique(perPage: 10);

      if (!mounted) return;

      setState(() {
        _isLoadingHistorique = false;
        if (result['success'] == true) {
          _historique = result['data'] as List<RechargeTransaction>;
        } else {
          _historique = [];
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistorique = false;
          _historique = [];
        });
      }
    }
  }

  Future<void> _recharger() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedModePaiement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un mode de paiement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final montant =
        double.tryParse(_montantController.text.replaceAll(' ', '')) ?? 0.0;

    final result = await RechargeService.recharge(
      montant: montant,
      modePaiement: _selectedModePaiement!,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      // Afficher un message informatif
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Redirection vers Wave pour le paiement...',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

        // Ne pas fermer la page immédiatement, l'utilisateur va payer sur Wave
        // Le solde sera mis à jour automatiquement via le webhook après le paiement
        // On peut fermer la page après quelques secondes
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result['message'] ?? 'Erreur lors de la recharge',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recharger mon solde'),
        backgroundColor: isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          // Masquer le clavier quand on tape ailleurs
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carte du solde actuel
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue,
                        (isDark ? AppTheme.primaryOrange : AppTheme.primaryBlue)
                            .withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark
                                ? AppTheme.primaryOrange
                                : AppTheme.primaryBlue)
                            .withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Solde actuel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (() {
                          final s = _currentSolde.toStringAsFixed(0);
                          String formatted = '';
                          int digitCount = 0;
                          for (int i = s.length - 1; i >= 0; i--) {
                            if (digitCount > 0 && digitCount % 3 == 0) {
                              formatted = ' $formatted';
                            }
                            formatted = '${s[i]}$formatted';
                            digitCount++;
                          }
                          return '$formatted FCFA';
                        })(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Champ montant
                Text(
                  'Montant de la recharge',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _montantController,
                  focusNode: _montantFocusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      // Si le texte est vide, retourner tel quel
                      if (newValue.text.isEmpty) {
                        return const TextEditingValue(
                          text: '',
                          selection: TextSelection.collapsed(offset: 0),
                        );
                      }

                      // Supprimer tous les espaces
                      final digitsOnly = newValue.text.replaceAll(' ', '');

                      // Formater avec des espaces tous les 3 chiffres (de droite à gauche)
                      // Exemple: 10000 -> 10 000
                      String formatted = '';
                      int digitCount = 0;
                      for (int i = digitsOnly.length - 1; i >= 0; i--) {
                        if (digitCount > 0 && digitCount % 3 == 0) {
                          formatted = ' $formatted';
                        }
                        formatted = digitsOnly[i] + formatted;
                        digitCount++;
                      }

                      // Toujours placer le curseur à la fin après formatage
                      final newLength = formatted.length;
                      return TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: newLength),
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Ex: 10 000',
                    prefixIcon: const Icon(Icons.monetization_on),
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  ),
                  onTap: () {
                    // Placer le curseur à la fin quand on clique sur le champ
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _moveCursorToEnd();
                    });
                  },
                  onChanged: (value) {
                    // S'assurer que le curseur reste à la fin après chaque changement
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _moveCursorToEnd();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un montant';
                    }
                    final montant =
                        double.tryParse(value.replaceAll(' ', '')) ?? 0;
                    if (montant <= 0) {
                      return 'Le montant doit être supérieur à 0';
                    }
                    if (montant < 10) {
                      return 'Le montant minimum est de 10 FCFA';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Sélection du mode de paiement
                Text(
                  'Mode de paiement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Mode de paiement unique (Wave)
                Builder(
                  builder: (context) {
                    final mode = _modesPaiement[0];
                    final isSelected = _selectedModePaiement == mode['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedModePaiement = mode['id'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? mode['color'].withValues(alpha: 0.2)
                              : isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? mode['color']
                                : isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo Wave
                            Image.asset(
                              'assets/images/wave.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              mode['label'],
                              style: TextStyle(
                                color: isSelected
                                    ? mode['color']
                                    : (isDark ? Colors.white : Colors.black87),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                color: mode['color'],
                                size: 24,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Bouton de validation
                ElevatedButton(
                  onPressed: _isLoading ? null : _recharger,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline),
                            SizedBox(width: 8),
                            Text(
                              'Valider la recharge',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 16),

                // Message d'information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Le montant sera ajouté à votre solde après validation.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 📦 BOX HISTORIQUE DES PAIEMENTS
                Text(
                  'Historique des paiements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Box avec la liste des transactions
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isLoadingHistorique
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _historique.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucune recharge effectuée',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _historique.length > 5
                                  ? 5
                                  : _historique.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 24),
                              itemBuilder: (context, index) {
                                final transaction = _historique[index];
                                return _buildTransactionItem(
                                    transaction, isDark);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(RechargeTransaction transaction, bool isDark) {
    // Couleur et icône selon le statut
    Color statusColor;
    IconData statusIcon;

    switch (transaction.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Row(
      children: [
        // Icône de statut
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),

        // Informations de la transaction
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (() {
                  final s = transaction.montant.toStringAsFixed(0);
                  String formatted = '';
                  int digitCount = 0;
                  for (int i = s.length - 1; i >= 0; i--) {
                    if (digitCount > 0 && digitCount % 3 == 0) {
                      formatted = ' $formatted';
                    }
                    formatted = '${s[i]}$formatted';
                    digitCount++;
                  }
                  return '$formatted FCFA';
                })(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    transaction.date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    transaction.modePaiementLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
