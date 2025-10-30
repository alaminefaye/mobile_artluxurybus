import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeVideo();
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

  @override
  void dispose() {
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