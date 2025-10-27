import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/bus_models.dart';
import '../../providers/bus_provider.dart';
import 'patent_detail_screen.dart';
import 'patent_form_screen.dart';

class PatentListScreen extends ConsumerStatefulWidget {
  final int busId;
  final String busNumber;

  const PatentListScreen({
    super.key,
    required this.busId,
    required this.busNumber,
  });

  @override
  ConsumerState<PatentListScreen> createState() => _PatentListScreenState();
}

class _PatentListScreenState extends ConsumerState<PatentListScreen> {
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final patentsAsync = ref.watch(patentsProvider((busId: widget.busId, page: _currentPage)));

    return patentsAsync.when(
      data: (response) {
        if (response.data.isEmpty) {
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(patentsProvider((busId: widget.busId, page: _currentPage)));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _buildEmptyState(),
                  ),
                ),
              ),
              // Bouton FAB pour ajouter une patente
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'patent_fab',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatentFormScreen(
                          busId: widget.busId,
                          busNumber: widget.busNumber,
                        ),
                      ),
                    );
                    // Rafraîchir la liste
                    ref.invalidate(patentsProvider((busId: widget.busId, page: _currentPage)));
                  },
                  backgroundColor: Colors.deepPurple,
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(patentsProvider((busId: widget.busId, page: _currentPage)));
              },
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: response.data.length,
                      itemBuilder: (context, index) {
                        final patent = response.data[index];
                        return _buildPatentCard(patent);
                      },
                    ),
                  ),
                  if (response.lastPage > 1) _buildPagination(response),
                ],
              ),
            ),
            // Bouton FAB pour ajouter une patente
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                heroTag: 'patent_fab',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatentFormScreen(
                        busId: widget.busId,
                        busNumber: widget.busNumber,
                      ),
                    ),
                  );
                  // Rafraîchir la liste
                  ref.invalidate(patentsProvider((busId: widget.busId, page: _currentPage)));
                },
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucune patente enregistrée', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Ajoutez la première patente', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Erreur de chargement', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error.toString(), style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(patentsProvider((busId: widget.busId, page: _currentPage))),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPatentCard(Patent patent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatentDetailScreen(
                busId: widget.busId,
                busNumber: widget.busNumber,
                patent: patent,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: patent.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.description, color: patent.statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patent.patentNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: patent.statusColor, borderRadius: BorderRadius.circular(12)),
                              child: Text(patent.status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                            ),
                            if (patent.isExpiringSoon || patent.isExpired) ...[
                              const SizedBox(width: 8),
                              Text('${patent.daysUntilExpiration} jours', style: TextStyle(fontSize: 12, color: patent.statusColor, fontWeight: FontWeight.w500)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(child: _buildInfoItem(icon: Icons.calendar_today, label: 'Délivrance', value: _formatDate(patent.issueDate))),
                  Expanded(child: _buildInfoItem(icon: Icons.event, label: 'Expiration', value: _formatDate(patent.expiryDate))),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoItem(icon: Icons.attach_money, label: 'Coût', value: '${patent.cost.toStringAsFixed(0)} FCFA'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildPagination(PaginatedResponse<Patent> response) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          ),
          Text('Page $_currentPage / ${response.lastPage}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < response.lastPage ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
