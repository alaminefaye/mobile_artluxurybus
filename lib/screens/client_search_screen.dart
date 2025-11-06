import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/client_registration_models.dart';
import '../services/client_registration_service.dart';
import '../theme/app_theme.dart';
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
    debugPrint('🔍 [ClientSearchScreen] Recherche client avec numéro: $telephone');

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

      if (client.hasAccount) {
        // Client a déjà un compte
        debugPrint('✅ [ClientSearchScreen] Client a déjà un compte, affichage dialog');
        _showAlreadyHasAccountDialog(client);
      } else {
        // Client existe mais n'a pas de compte
        debugPrint('ℹ️ [ClientSearchScreen] Client existe mais n\'a pas de compte, navigation vers CreateAccountScreen');
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
    showDialog(
      context: context,
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
            const Text('Compte existant'),
          ],
        ),
        content: Text(
          'Bonjour ${client.nomComplet}!\n\n'
          'Vous avez déjà un compte. Veuillez vous connecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer dialog
              Navigator.pop(context); // Retour à l'écran de connexion
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  void _showClientNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.orange),
            SizedBox(width: 8),
            Text('Nouveau client'),
          ],
        ),
        content: const Text(
          'Aucun client trouvé avec ce numéro.\n\n'
          'Souhaitez-vous créer un nouveau compte ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToRegisterNewClient();
            },
            child: const Text('Créer un compte'),
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
        title: const Text('Inscription'),
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
                        : Colors.blue).withValues(alpha: 0.1),
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
                const Text(
                  'Recherche de votre profil',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Description
                Text(
                  'Entrez votre numéro de téléphone pour vérifier si vous êtes déjà enregistré',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Champ téléphone
                TextFormField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : null,
                    ),
                    hintText: '+221 77 123 45 67',
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
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    if (value.length < 8) {
                      return 'Numéro de téléphone invalide';
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
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
                            : AppTheme.primaryBlue).withValues(alpha: 0.3),
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
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Rechercher',
                            style: TextStyle(
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
                  label: const Text('Créer un nouveau compte'),
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
                        : Colors.blue).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.primaryOrange 
                          : Colors.blue).withValues(alpha: 0.2),
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
                          'Si vous avez déjà voyagé avec nous, vos informations sont peut-être déjà enregistrées. Recherchez d\'abord votre profil.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppTheme.primaryOrange 
                                : Colors.blue[900],
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
