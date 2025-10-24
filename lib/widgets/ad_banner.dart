import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ad_model.dart';
import '../services/ads_api_service.dart';

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
  VoidCallback? _activeListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAds();
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
    if (_ads.isEmpty) return;
    _rotationTimer?.cancel();
    _isSwitching = false;
    _currentIndex = index;

    // Dispose previous controller to free decoders/buffers
    if (_controller != null) {
      try {
        _controller!.removeListener(_activeListener ?? () {});
      } catch (_) {}
      await _controller!.dispose();
      _controller = null;
    }

    final ad = _ads[index];
    if (ad.videoUrl == null || ad.videoUrl!.isEmpty) return;

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(ad.videoUrl!));
    await ctrl.initialize();
    await ctrl.setLooping(false);
    await ctrl.setVolume(_muted ? 0 : 1);
    _paused = false;
    await ctrl.play();
    _controller = ctrl;
    if (mounted) setState(() {});

    // Listener for completion
    _activeListener = () {
      if (!mounted) return;
      final v = ctrl.value;
      if (v.isInitialized) {
        final dur = v.duration;
        final pos = v.position;
        if (!_paused && !_isSwitching && !v.isPlaying && dur.inMilliseconds > 0 && pos >= dur) {
          _isSwitching = true;
          _goNext();
        }
      }
    };
    ctrl.addListener(_activeListener!);

    // Fallback timer if duration unavailable
    final seconds = _ads.length > index ? (_ads[index].displaySeconds ?? 8) : 8;
    if (ctrl.value.duration.inMilliseconds == 0) {
      _rotationTimer = Timer(Duration(seconds: seconds), () {
        if (!mounted) return;
        if (_currentIndex == index && !_isSwitching && !_paused) {
          _isSwitching = true;
          _goNext();
        }
      });
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          gradient: LinearGradient(colors: [
            Colors.grey.shade200, Colors.grey.shade100
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
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Container(
        height: widget.height,
        color: Colors.grey.shade100,
        child: Center(
          child: Text(
            msg,
            style: TextStyle(color: Colors.grey.shade600),
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
