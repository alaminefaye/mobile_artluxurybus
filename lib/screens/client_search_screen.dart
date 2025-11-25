import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client_registration_models.dart';
import '../services/client_registration_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_indicator.dart';
import 'create_account_screen.dart';
import 'register_new_client_screen.dart';

class ClientSearchScreen extends StatefulWidget {
  const ClientSearchScreen({super.key});

  @override
  State<ClientSearchScreen> createState() => _ClientSearchScreenState();
}

class _ClientSearchScreenState extends State<ClientSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();
  final _service = ClientRegistrationService();

  bool _isLoading = false;
  String? _errorMessage;

  // Helper pour les traductions
  String t(String key) {
    return TranslationService().translate(key);
  }

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _searchClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final telephone = _telephoneController.text.trim();
    debugPrint(
        '🔍 [ClientSearchScreen] Recherche client avec numéro: $telephone');

    final response = await _service.searchClient(telephone);

    if (!mounted) return;

    setState(() => _isLoading = false);

    debugPrint('🔍 [ClientSearchScreen] Réponse reçue:');
    debugPrint('   - success: ${response.success}');
    debugPrint('   - found: ${response.found}');
    debugPrint('   - client: ${response.client != null ? "trouvé" : "null"}');

    if (response.success && response.found && response.client != null) {
      final client = response.client!;
      debugPrint('🔍 [ClientSearchScreen] Client trouvé:');
      debugPrint('   - ID: ${client.id}');
      debugPrint('   - Nom: ${client.nomComplet}');
      debugPrint('   - Téléphone: ${client.telephone}');
      debugPrint('   - hasAccount: ${client.hasAccount}');

      // Vérification explicite avec comparaison booléenne
      final hasAccount = client.hasAccount == true;
      debugPrint('🔍 [ClientSearchScreen] Vérification hasAccount:');
      debugPrint('   - client.hasAccount: ${client.hasAccount}');
      debugPrint(
          '   - client.hasAccount == true: ${client.hasAccount == true}');
      debugPrint('   - hasAccount (variable): $hasAccount');
      debugPrint('   - Type: ${client.hasAccount.runtimeType}');

      if (hasAccount) {
        // Client a déjà un compte
        debugPrint(
            '✅ [ClientSearchScreen] Client a déjà un compte, affichage dialog');
        debugPrint('   - Nom: ${client.nomComplet}');
        debugPrint('   - ID: ${client.id}');
        _showAlreadyHasAccountDialog(client);
      } else {
        // Client existe mais n'a pas de compte
        debugPrint(
            'ℹ️ [ClientSearchScreen] Client existe mais n\'a pas de compte, navigation vers CreateAccountScreen');
        _navigateToCreateAccount(client);
      }
    } else {
      // Client non trouvé
      debugPrint('❌ [ClientSearchScreen] Client non trouvé');
      debugPrint('   - Message: ${response.message}');
      _showClientNotFoundDialog();
    }
  }

  void _showAlreadyHasAccountDialog(ClientSearchData client) {
    debugPrint('📱 [ClientSearchScreen] Affichage du dialog "Compte existant"');
    debugPrint('   - Client: ${client.nomComplet}');
    debugPrint('   - Context: ${context.toString()}');

    // Utiliser un délai pour s'assurer que le contexte est valide
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        debugPrint(
            '❌ [ClientSearchScreen] Context non monté, impossible d\'afficher le dialog');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.primaryOrange
                    : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(t('client_search.client_has_account')),
            ],
          ),
          content: Text(
            '${t('client_search.client_has_account_message')}\n\n${client.nomComplet}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                debugPrint('📱 [ClientSearchScreen] Bouton OK cliqué');
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orange
                    : Colors.blue,
              ),
              child: Text(t('common.ok')),
            ),
            ElevatedButton(
              onPressed: () {
                debugPrint(
                    '📱 [ClientSearchScreen] Bouton "Se connecter" cliqué');
                Navigator.pop(context); // Fermer dialog
                Navigator.pop(context); // Retour à l'écran de connexion
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orange
                    : Colors.blue,
              ),
              child: Text(t('auth.login_button')),
            ),
          ],
        ),
      );
    });
  }

  void _showClientNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_add, color: Colors.orange),
            const SizedBox(width: 8),
            Text(t('client_search.client_not_found')),
          ],
        ),
        content: Text(
          t('client_search.client_not_found_message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.orange
                  : Colors.blue,
            ),
            child: Text(t('client_search.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToRegisterNewClient();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.orange
                  : Colors.blue,
            ),
            child: Text(t('client_search.create_account')),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateAccount(ClientSearchData client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAccountScreen(client: client),
      ),
    );
  }

  void _navigateToRegisterNewClient() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterNewClientScreen(
          initialPhone: _telephoneController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('client_search.title')),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Icône
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryOrange
                            : Colors.blue)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_android,
                    size: 60,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.primaryOrange
                        : Colors.blue,
                  ),
                ),

                const SizedBox(height: 32),

                // Titre
                Text(
                  t('client_search.search_client'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  t('client_search.phone_number_hint'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Champ téléphone
                TextFormField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: t('client_search.phone_number'),
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primaryOrange
                          : AppTheme.primaryBlue,
                    ),
                    hintText: t('client_search.phone_number_hint'),
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.phone,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.primaryOrange
                          : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('client_search.phone_required');
                    }
                    // Vérifier exactement 10 chiffres
                    if (value.length != 10) {
                      return t('client_search.phone_required');
                    }
                    // Vérifier que ce sont bien des chiffres
                    if (value.length != 10 ||
                        value.codeUnits.any((c) => c < 48 || c > 57)) {
                      return t('client_search.phone_required');
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Message d'erreur
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_errorMessage != null) const SizedBox(height: 24),

                // Bouton rechercher avec gradient
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.accentGradient
                        : AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.primaryOrange
                                : AppTheme.primaryBlue)
                            .withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _searchClient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const LoadingIndicator(
                            size: 20,
                            strokeWidth: 2,
                          )
                        : Text(
                            t('client_search.search'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OU',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 24),

                // Bouton inscription directe
                OutlinedButton.icon(
                  onPressed: _navigateToRegisterNewClient,
                  icon: const Icon(Icons.person_add),
                  label: Text(t('client_search.register_new_client')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryOrange
                            : Colors.blue)
                        .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.primaryOrange
                              : Colors.blue)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.primaryOrange
                            : Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t('client_search.phone_number_hint'),
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.primaryOrange
                                    : AppTheme.primaryBlue,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
