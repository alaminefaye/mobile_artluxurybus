import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/promo_code_service.dart';
import '../theme/app_theme.dart';
import '../utils/api_config.dart';
import '../utils/error_message_helper.dart';

class PromoCodeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> promoCode;
  final bool canManage;

  const PromoCodeDetailScreen({
    super.key,
    required this.promoCode,
    required this.canManage,
  });

  @override
  State<PromoCodeDetailScreen> createState() => _PromoCodeDetailScreenState();
}

class _PromoCodeDetailScreenState extends State<PromoCodeDetailScreen> {
  late Map<String, dynamic> _promoCode;
  var _isWorking = false;
  var _shouldRefresh = false;
  var _allowPop = false;

  void _leave({bool refresh = false}) {
    if (refresh) _shouldRefresh = true;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(_shouldRefresh);
    });
  }

  @override
  void initState() {
    super.initState();
    _promoCode = Map<String, dynamic>.from(widget.promoCode);
    _loadDetails();
  }

  int? get _id {
    final id = _promoCode['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'validated':
        return 'Validé';
      case 'refused':
        return 'Refusé';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'validated':
        return Colors.green;
      case 'refused':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String? _formatDate(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return null;
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  bool _isImageUrl(String url) {
    final path = url.split('?').first.toLowerCase();
    return !path.endsWith('.pdf');
  }

  String? _resolveTicketUrl(Map<String, dynamic> data) {
    final direct = data['ticket_file_url']?.toString();
    if (direct != null && direct.isNotEmpty && direct != 'null') {
      return direct;
    }

    final file = data['ticket_file']?.toString();
    if (file == null || file.isEmpty || file == 'null') return null;
    if (file.startsWith('http')) return file;

    final origin = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$origin/storage/${file.replaceFirst(RegExp(r'^/+'), '')}';
  }

  Future<void> _loadDetails() async {
    final id = _id;
    if (id == null) return;

    final result = await PromoCodeService.getPromoCodeDetails(id);
    if (!mounted || result['success'] != true || result['data'] is! Map) {
      return;
    }

    setState(() {
      _promoCode = Map<String, dynamic>.from(result['data'] as Map);
    });
  }

  Future<void> _updateStatus(String status) async {
    final id = _id;
    if (id == null || _isWorking) return;

    setState(() => _isWorking = true);
    final result = await PromoCodeService.updatePromoCodeStatus(id, status);
    if (!mounted) return;

    setState(() {
      _isWorking = false;
      if (result['success'] == true) {
        _promoCode['status'] = status;
        _shouldRefresh = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Statut mis à jour.'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _sharePromoCode(String code, String customerName) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      Rect? sharePositionOrigin;
      if (box != null && box.size.width > 0 && box.size.height > 0) {
        final position = box.localToGlobal(Offset.zero);
        sharePositionOrigin = Rect.fromLTWH(
          position.dx,
          position.dy,
          box.size.width,
          box.size.height,
        );
      }

      await Share.share(
        'Code promotionnel Art Luxury Bus\n\n'
        'Code: $code\n'
        'Client: $customerName\n\n'
        'Utilisez ce code lors de votre réservation pour bénéficier d\'un ticket gratuit !',
        subject: 'Code promotionnel Art Luxury Bus',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du partage. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePromoCode(String code) async {
    final id = _id;
    if (id == null || _isWorking) return;

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

    if (confirm != true || !mounted) return;

    setState(() => _isWorking = true);
    try {
      final result = await PromoCodeService.deletePromoCode(id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                (result['success'] == true
                    ? 'Code promotionnel supprimé avec succès.'
                    : 'Erreur lors de la suppression du code promo.'),
          ),
          backgroundColor:
              result['success'] == true ? Colors.green : Colors.red,
        ),
      );

      if (result['success'] == true) {
        _leave(refresh: true);
      } else {
        setState(() => _isWorking = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isWorking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMessageHelper.getOperationError('supprimer', error: e),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final code = _promoCode['code']?.toString() ?? '';
    final customerName = _promoCode['customer_name']?.toString() ?? '';
    final description = _promoCode['description']?.toString();
    final gare = _promoCode['gare']?.toString();
    final status = _promoCode['status']?.toString() ?? 'validated';
    final isUsed = _promoCode['is_used'] == true;
    final ticketUrl = _resolveTicketUrl(_promoCode);
    final creator = _promoCode['creator'];
    final creatorName = creator is Map ? creator['name']?.toString() : null;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leave();
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : AppTheme.backgroundGrey,
        appBar: AppBar(
          title: const Text('Détail du code promo'),
          backgroundColor: AppTheme.primaryOrange,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: isDark ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Client', value: customerName),
                    if (gare != null && gare.isNotEmpty)
                      _DetailRow(label: 'Gare', value: gare),
                    if (description != null && description.isNotEmpty)
                      _DetailRow(label: 'Description', value: description),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              'Statut',
                              style: TextStyle(color: mutedColor),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _DetailRow(
                      label: 'Utilisation',
                      value: isUsed ? 'Utilisé' : 'Disponible',
                    ),
                    if (_formatDate(_promoCode['created_at']) != null)
                      _DetailRow(
                        label: 'Créé le',
                        value: _formatDate(_promoCode['created_at'])!,
                      ),
                    if (_formatDate(_promoCode['expires_at']) != null)
                      _DetailRow(
                        label: 'Expire le',
                        value: _formatDate(_promoCode['expires_at'])!,
                      ),
                    if (isUsed && _formatDate(_promoCode['used_at']) != null)
                      _DetailRow(
                        label: 'Utilisé le',
                        value: _formatDate(_promoCode['used_at'])!,
                      ),
                    if (creatorName != null && creatorName.isNotEmpty)
                      _DetailRow(label: 'Créé par', value: creatorName),
                  ],
                ),
              ),
            ),
            if (ticketUrl != null) ...[
              const SizedBox(height: 16),
              Card(
                color: isDark ? Colors.grey[850] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photo du ticket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isImageUrl(ticketUrl))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ticketUrl,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Text(
                              'Ticket indisponible',
                              style: TextStyle(color: mutedColor),
                            ),
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.tryParse(ticketUrl);
                            if (uri == null) return;
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Ouvrir le ticket'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_isWorking)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (widget.canManage && status == 'pending') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isWorking ? null : () => _updateStatus('validated'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Valider'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isWorking ? null : () => _updateStatus('refused'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Refuser'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (status == 'validated') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isWorking
                      ? null
                      : () => _sharePromoCode(code, customerName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (!isUsed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isWorking ? null : () => _deletePromoCode(code),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text('Supprimer'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
