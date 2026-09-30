import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final _authService = AuthService();
  List<Map<String, dynamic>> _accounts = [];
  bool _loading = true;
  String? _switchingEmail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _authService.rememberCurrentAccount();
    final accounts = await _authService.getSavedAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _loading = false;
    });
  }

  Future<void> _switchTo(String email) async {
    setState(() => _switchingEmail = email);
    final error = await ref.read(authProvider.notifier).switchAccount(email);
    if (!mounted) return;
    setState(() => _switchingEmail = null);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      await _load();
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addAccount() async {
    if (_accounts.length >= AuthService.maxAccounts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous pouvez enregistrer 3 comptes au maximum.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(addAccount: true),
      ),
    );
    if (added == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _remove(String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer le compte'),
        content: Text('Retirer $email de cet appareil ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final isCurrent =
        ref.read(authProvider).user?.email.toLowerCase() == email.toLowerCase();
    await ref.read(authProvider.notifier).removeAccount(email);
    if (!mounted) return;
    if (isCurrent) {
      Navigator.pop(context);
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = ref.watch(authProvider).user?.email.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comptes'),
        backgroundColor: isDark ? Colors.grey[900] : AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${_accounts.length}/${AuthService.maxAccounts} comptes',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                ..._accounts.map((account) {
                  final email = account['email']?.toString() ?? '';
                  final user = account['user'];
                  final name = user is Map
                      ? (user['name']?.toString() ?? email)
                      : email;
                  final role = user is Map ? user['role']?.toString() : null;
                  final isCurrent = email.toLowerCase() == currentEmail;
                  final busy = _switchingEmail == email;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryOrange,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text(
                        role == null || role.isEmpty ? email : '$email\n$role',
                      ),
                      isThreeLine: role != null && role.isNotEmpty,
                      trailing: busy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : isCurrent
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _remove(email),
                                ),
                      onTap: isCurrent || busy ? null : () => _switchTo(email),
                      onLongPress: () => _remove(email),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _accounts.length >= AuthService.maxAccounts
                      ? null
                      : _addAccount,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Ajouter un compte'),
                ),
              ],
            ),
    );
  }
}
