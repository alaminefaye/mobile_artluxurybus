import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ad_model.dart';
import '../services/ads_api_service.dart';
import '../services/audio_focus_manager.dart';

class AdBanner extends StatefulWidget {
  final double height;
  final BorderRadiusGeometry borderRadius;

  const AdBanner({super.key, this.height = 180, this.borderRadius = const BorderRadius.all(Radius.circular(12))});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> with WidgetsBindingObserver {
  List<AdModel> _ads = [];
  int _currentIndex = 0;
  VideoPlayerController? _controller; // single active controller
  Timer? _rotationTimer; // fallback timer when duration unknown
  bool _loading = true;
  String? _error;
  bool _isSwitching = false;
  bool _muted = true;
  bool _paused = false;
  bool _pausedByVoiceAnnouncement = false; // 🔇 Nouveau flag pour suivre la pause par annonce
  VoidCallback? _activeListener;
  StreamSubscription<bool>? _audioFocusSubscription; // 🔇 Listener audio focus

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAds();
    _setupAudioFocusListener(); // 🔇 Écouter les événements audio
  }

  Future<void> _loadAds() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ads = await AdsApiService.fetchActiveAds();
      if (!mounted) return;
      if (ads.isEmpty) {
        setState(() { _loading = false; _error = 'Aucune publicité disponible'; });
        return;
      }
      _ads = ads;

      // Initialize only the first controller to avoid multiple decoders
      _playIndex(0);
      setState(() { _loading = false; });
    } on SocketException {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Pas de connexion internet'; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Erreur lors du chargement'; });
    }
  }

  Future<void> _playIndex(int index) async {
    if (_ads.isEmpty || !mounted) return;
    _rotationTimer?.cancel();
    _isSwitching = false;
    _currentIndex = index;

    // Dispose previous controller to free decoders/buffers
    if (_controller != null) {
      try {
        _controller!.removeListener(_activeListener ?? () {});
      } catch (_) {}
      try {
      await _controller!.dispose();
      } catch (e) {
        debugPrint('⚠️ [AdBanner] Erreur lors de la libération du controller: $e');
      }
      _controller = null;
    }

    final ad = _ads[index];
    if (ad.videoUrl == null || ad.videoUrl!.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    try {
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(ad.videoUrl!));
    await ctrl.initialize();
      
      // Vérifier que le widget est toujours monté après l'initialisation
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      
    await ctrl.setLooping(false);
    await ctrl.setVolume(_muted ? 0 : 1);
    _paused = false;
    await ctrl.play();
    _controller = ctrl;
    if (mounted) setState(() {});

    // Listener for completion
    _activeListener = () {
        if (!mounted || _controller == null) return;
        final v = _controller!.value;
      if (v.isInitialized) {
        final dur = v.duration;
        final pos = v.position;
        if (!_paused && !_isSwitching && !v.isPlaying && dur.inMilliseconds > 0 && pos >= dur) {
          _isSwitching = true;
          _goNext();
        }
      }
    };
      _controller?.addListener(_activeListener!);

    // Fallback timer if duration unavailable
    final seconds = _ads.length > index ? (_ads[index].displaySeconds ?? 8) : 8;
      if (_controller != null && _controller!.value.duration.inMilliseconds == 0) {
      _rotationTimer = Timer(Duration(seconds: seconds), () {
        if (!mounted) return;
        if (_currentIndex == index && !_isSwitching && !_paused) {
          _isSwitching = true;
          _goNext();
        }
      });
      }
    } catch (e) {
      debugPrint('❌ [AdBanner] Erreur lors de l\'initialisation de la vidéo: $e');
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement de la vidéo';
        });
      }
      return;
    }
  }

  void _goNext() {
    if (_ads.isEmpty || _ads.length == 1) return;
    int next = _currentIndex + 1;
    if (next >= _ads.length) next = 0; // loop playlist
    setState(() { _currentIndex = next; });
    _playIndex(next);
  }

  void _goPrev() {
    if (_ads.isEmpty || _ads.length == 1) return;
    int prev = _currentIndex - 1;
    if (prev < 0) prev = _ads.length - 1;
    setState(() { _currentIndex = prev; });
    _playIndex(prev);
  }

  void _togglePlayPause() {
    final ctrl = _controller;
    if (ctrl == null) return;
    if (_paused) {
      setState(() { _paused = false; });
      ctrl.play();
    } else {
      setState(() { _paused = true; });
      _rotationTimer?.cancel();
      ctrl.pause();
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
        debugPrint('🔇 [AdBanner] Annonce vocale activée - Pause vidéo');
        _pauseForVoiceAnnouncement();
      } else {
        // Annonce vocale terminée - reprendre la vidéo si elle était en lecture
        debugPrint('🔊 [AdBanner] Annonce vocale terminée - Reprise vidéo');
        _resumeFromVoiceAnnouncement();
      }
    });
  }

  /// 🔇 Mettre en pause la vidéo pour l'annonce vocale
  void _pauseForVoiceAnnouncement() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    
    // Si la vidéo était en lecture, la mettre en pause
    if (ctrl.value.isPlaying && !_paused) {
      _pausedByVoiceAnnouncement = true;
      ctrl.pause();
      _rotationTimer?.cancel();
      debugPrint('✅ [AdBanner] Vidéo mise en pause pour annonce vocale');
    }
  }

  /// 🔊 Reprendre la vidéo après l'annonce vocale
  void _resumeFromVoiceAnnouncement() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    
    // Reprendre seulement si la pause était due à l'annonce vocale
    if (_pausedByVoiceAnnouncement && !_paused) {
      _pausedByVoiceAnnouncement = false;
      ctrl.play();
      debugPrint('✅ [AdBanner] Vidéo reprise après annonce vocale');
      
      // Redémarrer le timer de rotation si nécessaire
      if (ctrl.value.duration.inMilliseconds == 0) {
        final seconds = _ads.isNotEmpty && _currentIndex < _ads.length
            ? (_ads[_currentIndex].displaySeconds ?? 8)
            : 8;
        _rotationTimer = Timer(Duration(seconds: seconds), () {
          if (!mounted) return;
          if (!_isSwitching && !_paused && !_pausedByVoiceAnnouncement) {
            _isSwitching = true;
            _goNext();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioFocusSubscription?.cancel(); // 🔇 Nettoyer le listener
    _rotationTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openLink(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContainedVideo(VideoPlayerController controller) {
    if (!controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    
    // Vérifier que le controller est toujours valide avant de l'utiliser
    try {
    final size = controller.value.size;
    return Container(
      color: Colors.black, // side bars/background
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
    } catch (e) {
      // Si le controller n'est plus valide, retourner un widget vide
      debugPrint('⚠️ [AdBanner] Erreur VideoPlayer: $e');
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _skeleton();
    }
    if (_error != null) {
      return _errorWidget(_error!);
    }
    if (_ads.isEmpty || _controller == null) {
      return _skeleton();
    }

    final controller = _controller!;
    
    // Vérifier que le controller est toujours valide
    if (!controller.value.isInitialized) {
      return _skeleton();
    }
    
    final ad = _ads[_currentIndex];

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: GestureDetector(
        onTap: () => _openLink(ad.linkUrl),
        child: AspectRatio(
          // Force landscape banner ratio; portrait videos are center-cropped
          aspectRatio: 16/9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Contain-fit video centered; portrait will show side bars
              _buildContainedVideo(controller),
              // Gradient overlay bottom for readability
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                    ),
                  ),
                ),
              ),
              // Mute/Unmute button
              Positioned(
                right: 8,
                top: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.black45,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _muted = !_muted;
                          _controller?.setVolume(_muted ? 0 : 1);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Playback controls
              Positioned(
                left: 8,
                bottom: 8,
                child: Row(
                  children: [
                    _controlBtn(icon: Icons.skip_previous_rounded, onTap: _goPrev),
                    const SizedBox(width: 6),
                    _controlBtn(
                      icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      onTap: _togglePlayPause,
                    ),
                    const SizedBox(width: 6),
                    _controlBtn(icon: Icons.skip_next_rounded, onTap: _goNext),
                  ],
                ),
              ),

              // Indicators only
              Positioned(
                right: 12,
                bottom: 8,
                child: (_ads.length > 1)
                    ? Row(
                        children: List.generate(_ads.length, (i) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _currentIndex ? Colors.white : Colors.white54,
                          ),
                        )),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          gradient: LinearGradient(colors: [
            isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            isDark ? Colors.grey.shade700 : Colors.grey.shade100,
          ]),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _controlBtn({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.black45,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _errorWidget(String msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: widget.borderRadius,
        ),
        child: Center(
          child: Text(
            msg,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  // Pause/resume on app lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_controller == null) return;
    if (state == AppLifecycleState.paused) {
      _controller!.pause();
    } else if (state == AppLifecycleState.resumed && !_paused) {
      _controller!.play();
    }
  }
}
