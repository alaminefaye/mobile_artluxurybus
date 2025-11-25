import 'package:flutter/material.dart';

import '../../services/job_application_api_service.dart';
import '../../theme/app_theme.dart';
import '../../screens/admin/job_application_detail_screen.dart';

class JobApplicationsListScreen extends StatefulWidget {
  const JobApplicationsListScreen({super.key});

  @override
  State<JobApplicationsListScreen> createState() =>
      _JobApplicationsListScreenState();
}

class _JobApplicationsListScreenState extends State<JobApplicationsListScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _items = [];
  int _currentPage = 1;
  bool _hasMore = true;
  String? _statusFilter;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _load(page: 1, refresh: true);
  }

  Future<void> _load({int page = 1, bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await JobApplicationApiService.list(
        page: page,
        status: _statusFilter,
        search: _searchQuery,
      );
      final List data = (result['data'] as List? ?? []);
      final pagination = result['pagination'] as Map? ?? {};

      setState(() {
        _currentPage = pagination['current_page'] ?? page;
        _hasMore = _currentPage < (pagination['last_page'] ?? 1);
        if (refresh) {
          _items = data.cast<Map<String, dynamic>>();
        } else {
          _items.addAll(data.cast<Map<String, dynamic>>());
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openDetails(int id) async {
    try {
      final details = await JobApplicationApiService.details(id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobApplicationDetailScreen(details: details),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette candidature ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteJobApplication(id);
    }
  }

  Future<void> _deleteJobApplication(int id) async {
    try {
      final ok = await JobApplicationApiService.delete(id);
      if (ok) {
        setState(() {
          _items.removeWhere((item) => item['id'] == id);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidature supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Recharger la liste
        _load(page: 1, refresh: true);
      } else {
        throw Exception('Suppression impossible');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidatures d\'emploi'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              final q = await showDialog<String>(
                context: context,
                builder: (context) {
                  final controller = TextEditingController(text: _searchQuery);
                  return AlertDialog(
                    title: const Text('Recherche'),
                    content: TextField(
                      controller: controller,
                      decoration:
                          const InputDecoration(hintText: 'Nom ou téléphone'),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler')),
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text.trim()),
                          child: const Text('Rechercher')),
                    ],
                  );
                },
              );
              if (q != null) {
                setState(() => _searchQuery = q.isEmpty ? null : q);
                _load(page: 1, refresh: true);
              }
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: (_items.isEmpty && !_isLoading)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 80,
                    color: isDark ? Colors.white54 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune candidature',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revenez plus tard ou actualisez',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _load(page: 1, refresh: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _load(page: 1, refresh: true),
              color: AppTheme.primaryOrange,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    return Center(
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            )
                          : ElevatedButton(
                              onPressed: () => _load(page: _currentPage + 1),
                              child: const Text('Charger plus'),
                            ),
                    );
                  }
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.work_outline),
                      title: Text(
                        item['full_name'] ?? '—',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${item['phone_number'] ?? '—'} • ${item['status_text'] ?? item['status'] ?? ''}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _confirmDelete(item['id'] as int),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _openDetails(item['id'] as int),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
