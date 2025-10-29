import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/video_advertisement_model.dart';
import '../../services/video_advertisement_service.dart';
import '../../theme/app_theme.dart';

class VideoAdvertisementDetailScreen extends StatefulWidget {
  final VideoAdvertisement video;

  const VideoAdvertisementDetailScreen({super.key, required this.video});

  @override
  State<VideoAdvertisementDetailScreen> createState() =>
      _VideoAdvertisementDetailScreenState();
}

class _VideoAdvertisementDetailScreenState
    extends State<VideoAdvertisementDetailScreen> {
  final VideoAdvertisementService _service = VideoAdvertisementService();
  late VideoAdvertisement _video;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _video = widget.video;
  }

  Future<void> _toggleStatus() async {
    setState(() => _isLoading = true);

    try {
      await _service.toggleVideoStatus(_video.id);
      
      // Rafraîchir les données
      final updatedVideo = await _service.getAllVideos();
      final updated = updatedVideo.firstWhere((v) => v.id == _video.id);
      
      setState(() {
        _video = updated;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_video.isActive ? 'Vidéo activée' : 'Vidéo désactivée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteVideo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${_video.title}" ?'),
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

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await _service.deleteVideo(_video.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vidéo supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Retour à la liste
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey[400]),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _video.isActive 
          ? Colors.green.withOpacity(0.15) 
          : Colors.grey[850],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _video.isActive 
              ? Colors.green.withOpacity(0.3) 
              : Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _video.isActive 
                    ? Colors.green.withOpacity(0.2) 
                    : Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _video.isActive ? Icons.check_circle : Icons.cancel,
                color: _video.isActive ? Colors.green : Colors.grey[500],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statut de la vidéo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _video.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _video.isActive ? Colors.green : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _video.isActive,
              onChanged: _isLoading ? null : (_) => _toggleStatus(),
              activeColor: Colors.green,
              activeTrackColor: Colors.green.withOpacity(0.5),
              inactiveThumbColor: Colors.grey[600],
              inactiveTrackColor: Colors.grey[800],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la vidéo'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _deleteVideo,
            icon: const Icon(Icons.delete),
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec le titre
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryBlue,
                          AppTheme.primaryBlue.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _video.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Carte de statut
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStatusCard(),
                  ),

                  // Informations principales
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: Colors.grey[850],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Divider(height: 24, color: Colors.grey[700]),
                            
                            if (_video.description != null) ...[
                              _buildInfoRow(
                                'Description',
                                _video.description!,
                                icon: Icons.description,
                              ),
                              Divider(height: 24, color: Colors.grey[700]),
                            ],

                            _buildInfoRow(
                              'Taille du fichier',
                              _video.fileSizeFormatted,
                              icon: Icons.storage,
                            ),
                            Divider(height: 24, color: Colors.grey[700]),

                            _buildInfoRow(
                              'Durée',
                              _video.durationFormatted,
                              icon: Icons.timer,
                            ),
                            Divider(height: 24, color: Colors.grey[700]),

                            _buildInfoRow(
                              'Ordre d\'affichage',
                              '#${_video.displayOrder}',
                              icon: Icons.sort,
                            ),
                            Divider(height: 24, color: Colors.grey[700]),

                            _buildInfoRow(
                              'Nombre de vues',
                              '${_video.viewsCount} vues',
                              icon: Icons.visibility,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Informations sur le créateur
                  if (_video.createdBy != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        color: Colors.grey[850],
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Créateur',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Divider(height: 24, color: Colors.grey[700]),
                              _buildInfoRow(
                                'Nom',
                                _video.createdBy!.name,
                                icon: Icons.person,
                              ),
                              Divider(height: 24, color: Colors.grey[700]),
                              _buildInfoRow(
                                'Email',
                                _video.createdBy!.email,
                                icon: Icons.email,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Dates
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: Colors.grey[850],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Historique',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Divider(height: 24, color: Colors.grey[700]),
                            _buildInfoRow(
                              'Date de création',
                              dateFormat.format(_video.createdAt),
                              icon: Icons.calendar_today,
                            ),
                            Divider(height: 24, color: Colors.grey[700]),
                            _buildInfoRow(
                              'Dernière modification',
                              dateFormat.format(_video.updatedAt),
                              icon: Icons.update,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

