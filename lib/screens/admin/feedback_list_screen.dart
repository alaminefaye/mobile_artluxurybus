import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/feedback_model.dart';
import '../../providers/feedback_provider.dart';
import '../../services/feedback_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackListScreen extends ConsumerStatefulWidget {
  final int? initialFeedbackId;
  const FeedbackListScreen({super.key, this.initialFeedbackId});

  @override
  ConsumerState<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends ConsumerState<FeedbackListScreen> {
  final Map<String, dynamic> _params = {'page': 1, 'per_page': 100};
  bool _loadingDetail = false;
  // Deleted:String? _statusFilter;
  String? _priorityFilter;
  final TextEditingController _searchCtrl = TextEditingController();
  List<FeedbackModel> _items = [];
  int _currentPage = 1;
  final int _perPage = 100;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    // Si un ID est fourni, tenter d'ouvrir le détail après le build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialFeedbackId != null) {
        await _openFeedbackDetail(widget.initialFeedbackId!);
      }
    });
  }

  Future<void> _openFeedbackDetail(int id) async {
    setState(() => _loadingDetail = true);
    try {
      final data = await FeedbackApiService.getFeedbackDetails(id);
      final json = data['data'] ?? data;
      final model = FeedbackModel.fromJson(json);
      if (!mounted) {
        return;
      }
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.feedback_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Suggestion détaillée',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Sujet', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(model.subject,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white)),
                const SizedBox(height: 12),
                Text('Message', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(model.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (model.priority != null)
                      Chip(label: Text('Priorité: ${model.priority}')),
                    if (model.status != null)
                      Chip(
                        label: Text(
                          'Statut: ${model.status}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : ((model.status == 'résolu')
                                        ? Colors.green.shade800
                                        : (model.status == 'en_cours')
                                            ? Colors.orange.shade800
                                            : Colors.grey.shade800),
                          ),
                        ),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? ((model.status == 'résolu')
                                    ? Colors.green.shade700
                                    : (model.status == 'en_cours')
                                        ? Colors.orange.shade700
                                        : Colors.grey.shade700)
                                : ((model.status == 'résolu')
                                    ? Colors.green.shade100
                                    : (model.status == 'en_cours')
                                        ? Colors.orange.shade100
                                        : Colors.grey.shade200),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                    if (model.createdAtHuman != null)
                      Chip(label: Text('Reçu: ${model.createdAtHuman}')),
                  ],
                ),
                const SizedBox(height: 12),
                // Coordonnées
                Text('Coordonnées',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(model.name,
                            style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
                const SizedBox(height: 6),
                if ((model.phone).isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(model.phone,
                              style: Theme.of(context).textTheme.bodyMedium)),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _launchPhone(model.phone),
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Appeler'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                if ((model.email).isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(model.email,
                              style: Theme.of(context).textTheme.bodyMedium)),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _launchEmail(model.email),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Email'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                if (model.travelInfo != null) ...[
                  Text('Infos voyage',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${model.travelInfo!.station ?? ''} • ${model.travelInfo!.route ?? ''} • Siège ${model.travelInfo!.seatNumber ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Fermer'),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  void _applyFilters() {
    // Mettre/retirer les paramètres selon sélection
    if (_priorityFilter == null || _priorityFilter!.isEmpty) {
      _params.remove('priority');
    } else {
      _params['priority'] = _priorityFilter!;
    }
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      _params.remove('search');
    } else {
      _params['search'] = q;
    }
    _items = [];
    _currentPage = 1;
    _hasMore = true;
    setState(() {});
    // ignore: unused_result
    ref.refresh(feedbackListProvider(_params));
  }

  Future<void> _changeStatus(int id, String status) async {
    try {
      await FeedbackApiService.updateFeedbackStatus(id, status);
      _refreshList();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur statut: $e')),
      );
    }
  }

  Future<void> _changePriority(int id, String priority) async {
    try {
      await FeedbackApiService.updateFeedbackPriority(id, priority);
      _refreshList();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur priorité: $e')),
      );
    }
  }

  Future<void> _deleteFeedback(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la suggestion'),
        content:
            const Text('Êtes-vous sûr de vouloir supprimer cette suggestion ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    try {
      await FeedbackApiService.deleteFeedback(id);
      _refreshList();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur suppression: $e')),
      );
    }
  }

  void _refreshList() {
    setState(() {});
    // ignore: unused_result
    ref.refresh(feedbackListProvider(_params));
  }

  // Deleted: Future<void> _launchEmail(String email) async {
  // Deleted:   final uri = Uri.parse('mailto:$email');
  // Deleted:   await launchUrl(uri);
  // Deleted: }

  Future<void> _launchPhone(String phone) async {
    final tel = phone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$tel');
    await launchUrl(uri);
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    await launchUrl(uri);
  }

  // Deleted: Future<void> _launchEmail(String email) async {
  // Deleted:   final uri = Uri.parse('mailto:$email');
  // Deleted:   await launchUrl(uri);
  // Deleted: }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final nextPage = _currentPage + 1;
      final result = await FeedbackApiService.getFeedbacks(
        page: nextPage,
        perPage: _perPage,
        search: _params['search'],
        priority: _params['priority'],
      );
      final List<dynamic> raw = (result['data'] ?? []) as List<dynamic>;
      final List<FeedbackModel> newItems =
          raw.map((j) => FeedbackModel.fromJson(j)).toList();
      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage = nextPage;
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Recherche (nom, sujet, message)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.filter_alt),
              label: const Text('Filtrer'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Priorité: Haute'),
              selected: _priorityFilter == 'haute',
              onSelected: (v) {
                setState(() {
                  _priorityFilter = v ? 'haute' : null;
                });
                _applyFilters();
              },
            ),
            FilterChip(
              label: const Text('Priorité: Moyenne'),
              selected: _priorityFilter == 'moyenne',
              onSelected: (v) {
                setState(() {
                  _priorityFilter = v ? 'moyenne' : null;
                });
                _applyFilters();
              },
            ),
            FilterChip(
              label: const Text('Priorité: Basse'),
              selected: _priorityFilter == 'basse',
              onSelected: (v) {
                setState(() {
                  _priorityFilter = v ? 'basse' : null;
                });
                _applyFilters();
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncFeedbacks = ref.watch(feedbackListProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestions et préoccupations'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 8),
            Expanded(
              child: asyncFeedbacks.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                        child: Text('Aucune suggestion trouvée'));
                  }
                  final displayList = _items.isEmpty ? list : _items;
                  return ListView.separated(
                    itemCount: displayList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final f = displayList[i];
                      return ListTile(
                        leading: Icon(
                          Icons.feedback,
                          color: f.priority == 'haute'
                              ? Colors.red
                              : f.priority == 'moyenne'
                                  ? Colors.orange
                                  : Colors.blue,
                        ),
                        title: Text(f.subject),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                Chip(
                                  label: Text(
                                    'Statut: ${f.status ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : ((f.status == 'résolu')
                                              ? Colors.green.shade800
                                              : (f.status == 'en_cours')
                                                  ? Colors.orange.shade800
                                                  : Colors.grey.shade800),
                                    ),
                                  ),
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? ((f.status == 'résolu')
                                              ? Colors.green.shade700
                                              : (f.status == 'en_cours')
                                                  ? Colors.orange.shade700
                                                  : Colors.grey.shade700)
                                          : ((f.status == 'résolu')
                                              ? Colors.green.shade100
                                              : (f.status == 'en_cours')
                                                  ? Colors.orange.shade100
                                                  : Colors.grey.shade200),
                                  labelPadding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                ),
                              ],
                            )
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            final id = f.id ?? 0;
                            switch (value) {
                              case 'status_new':
                                _changeStatus(id, 'nouveau');
                                break;
                              case 'status_in_progress':
                                _changeStatus(id, 'en_cours');
                                break;
                              case 'status_resolved':
                                _changeStatus(id, 'résolu');
                                break;
                              case 'prio_high':
                                _changePriority(id, 'haute');
                                break;
                              case 'prio_medium':
                                _changePriority(id, 'moyenne');
                                break;
                              case 'prio_low':
                                _changePriority(id, 'basse');
                                break;
                              case 'delete':
                                _deleteFeedback(id);
                                break;
                            }
                          },
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(
                                value: 'status_new',
                                child: Text('Statut: Nouveau')),
                            PopupMenuItem(
                                value: 'status_in_progress',
                                child: Text('Statut: En cours')),
                            PopupMenuItem(
                                value: 'status_resolved',
                                child: Text('Statut: Résolu')),
                            PopupMenuDivider(),
                            PopupMenuItem(
                                value: 'prio_high',
                                child: Text('Priorité: Haute')),
                            PopupMenuItem(
                                value: 'prio_medium',
                                child: Text('Priorité: Moyenne')),
                            PopupMenuItem(
                                value: 'prio_low',
                                child: Text('Priorité: Basse')),
                            PopupMenuDivider(),
                            PopupMenuItem(
                                value: 'delete', child: Text('Supprimer')),
                          ],
                        ),
                        onTap: () {
                          final id = f.id;
                          if (id != null) {
                            _openFeedbackDetail(id);
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
              ),
            ),
            if (_hasMore) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isLoadingMore ? null : _loadMore,
                icon: const Icon(Icons.expand_more),
                label: Text(_isLoadingMore ? 'Chargement...' : 'Charger plus'),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar:
          _loadingDetail ? const LinearProgressIndicator(minHeight: 2) : null,
    );
  }
}
