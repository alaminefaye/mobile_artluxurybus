import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/audio_focus_manager.dart';

class CachedVideoWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? width;
  final double? height;

  const CachedVideoWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.width,
    this.height,
  });

  @override
  State<CachedVideoWidget> createState() => _CachedVideoWidgetState();
}

class _CachedVideoWidgetState extends State<CachedVideoWidget> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _pausedByVoiceAnnouncement = false; // 🔇 Flag pour suivre la pause par annonce
  StreamSubscription<bool>? _audioFocusSubscription; // 🔇 Listener audio focus

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _setupAudioFocusListener(); // 🔇 Écouter les événements audio
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Récupérer le fichier depuis le cache (le télécharge automatiquement si pas en cache)
      final file = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      
      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();

      if (widget.autoPlay) {
        await _controller!.play();
      }

      _controller!.setLooping(widget.looping);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  /// 🔇 Configurer le listener pour les annonces vocales
  void _setupAudioFocusListener() {
    final audioFocus = AudioFocusManager();
    
    // Écouter les changements d'état des annonces vocales
    _audioFocusSubscription = audioFocus.voiceAnnouncementActiveStream.listen((isActive) {
      if (!mounted) return;
      
      if (isActive) {
        // Annonce vocale démarrée - mettre en pause la vidéo
        debugPrint('🔇 [CachedVideo] Annonce vocale activée - Pause vidéo');
        _pauseForVoiceAnnouncement();
      } else {
        // Annonce vocale terminée - reprendre la vidéo si elle était en lecture
        debugPrint('🔊 [CachedVideo] Annonce vocale terminée - Reprise vidéo');
        _resumeFromVoiceAnnouncement();
      }
    });
  }

  /// 🔇 Mettre en pause la vidéo pour l'annonce vocale
  void _pauseForVoiceAnnouncement() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    
    // Si la vidéo était en lecture, la mettre en pause
    if (ctrl.value.isPlaying) {
      _pausedByVoiceAnnouncement = true;
      ctrl.pause();
      debugPrint('✅ [CachedVideo] Vidéo mise en pause pour annonce vocale');
    }
  }

  /// 🔊 Reprendre la vidéo après l'annonce vocale
  void _resumeFromVoiceAnnouncement() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    
    // Reprendre seulement si la pause était due à l'annonce vocale ET si autoPlay est activé
    if (_pausedByVoiceAnnouncement && widget.autoPlay) {
      _pausedByVoiceAnnouncement = false;
      ctrl.play();
      debugPrint('✅ [CachedVideo] Vidéo reprise après annonce vocale');
    }
  }

  @override
  void dispose() {
    _audioFocusSubscription?.cancel(); // 🔇 Nettoyer le listener
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError || _controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.grey,
                size: 50,
              ),
              SizedBox(height: 8),
              Text(
                'Erreur de chargement',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    Widget videoPlayer = AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );

    if (widget.showControls) {
      return Stack(
        children: [
          videoPlayer,
          Positioned.fill(
            child: VideoPlayerControls(controller: _controller!),
          ),
        ],
      );
    }

    return videoPlayer;
  }
}

// Widget simple pour les contrôles vidéo
class VideoPlayerControls extends StatefulWidget {
  final VideoPlayerController controller;

  const VideoPlayerControls({
    super.key,
    required this.controller,
  });

  @override
  State<VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<VideoPlayerControls> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (widget.controller.value.isPlaying) {
            widget.controller.pause();
          } else {
            widget.controller.play();
          }
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Icon(
            widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 50,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}