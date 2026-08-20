import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';

class CustomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int initialPositionSeconds;
  final int totalDurationSeconds;
  final VoidCallback? onComplete;
  final void Function(int seconds)? onPositionChanged;

  const CustomVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    this.initialPositionSeconds = 0,
    this.totalDurationSeconds = 765, // 12:45 default
    this.onComplete,
    this.onPositionChanged,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _errorMessage;
  double _playbackSpeed = 1.0;
  late int _currentSeconds;
  bool _subtitlesEnabled = false;
  bool _isFullscreen = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _fallbackTimer;

  final List<double> _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.initialPositionSeconds.clamp(0, widget.totalDurationSeconds);
    _initializePlayer();
  }

  @override
  void didUpdateWidget(CustomVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl || oldWidget.title != widget.title) {
      _currentSeconds = widget.initialPositionSeconds.clamp(0, widget.totalDurationSeconds);
      _errorMessage = null;
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    debugPrint('================================================================');
    debugPrint('[CustomVideoPlayer] 🎬 Initializing VideoPlayerController');
    debugPrint('[CustomVideoPlayer] 📍 Target Lesson: "${widget.title}"');
    debugPrint('[CustomVideoPlayer] 🔗 EXACT streamUrl: "${widget.videoUrl}"');
    debugPrint('================================================================');

    _hideControlsTimer?.cancel();
    _fallbackTimer?.cancel();
    await _controller?.dispose();

    if (widget.videoUrl.isEmpty) {
      setState(() {
        _errorMessage = 'No video URL provided for this lesson.';
      });
      return;
    }

    try {
      final uri = Uri.parse(widget.videoUrl);
      final controller = VideoPlayerController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      _controller = controller;

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      if (controller.value.hasError) {
        final err = controller.value.errorDescription ?? 'Controller reported an error during initialization.';
        debugPrint('[CustomVideoPlayer] ❌ Controller Value Error: $err');
        setState(() {
          _errorMessage = err;
        });
        return;
      }

      if (widget.initialPositionSeconds > 0) {
        await controller.seekTo(Duration(seconds: widget.initialPositionSeconds));
      }

      controller.addListener(_onControllerUpdate);

      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });

      _startHideControlsTimer();
    } catch (e) {
      debugPrint('[CustomVideoPlayer] ❌ Video player initialization exception: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          if (e is! UnimplementedError) {
            _errorMessage = 'Initialization exception: $e';
          }
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted || _controller == null) return;

    final controller = _controller!;
    if (controller.value.hasError) {
      final err = controller.value.errorDescription ?? 'Video playback error occurred.';
      debugPrint('[CustomVideoPlayer] ❌ Controller error in listener: $err');
      setState(() {
        _errorMessage = err;
      });
      return;
    }

    final posSec = controller.value.position.inSeconds;
    final durSec = controller.value.duration.inSeconds;
    final isPlaying = controller.value.isPlaying;

    if (posSec != _currentSeconds) {
      setState(() {
        _currentSeconds = posSec;
        _isPlaying = isPlaying;
      });
      if (posSec % 3 == 0) {
        widget.onPositionChanged?.call(posSec);
      }
    }

    if (durSec > 0 && posSec >= durSec && !isPlaying) {
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _fallbackTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller != null && _controller!.value.isInitialized) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        setState(() => _isPlaying = false);
        widget.onPositionChanged?.call(_currentSeconds);
        _showControlsTemporarily();
      } else {
        _controller!.play();
        setState(() => _isPlaying = true);
        _startHideControlsTimer();
      }
    } else {
      setState(() => _isPlaying = !_isPlaying);
      if (_isPlaying) {
        _startFallbackPlaybackTimer();
      } else {
        _fallbackTimer?.cancel();
        widget.onPositionChanged?.call(_currentSeconds);
      }
    }
  }

  void _startFallbackPlaybackTimer() {
    _fallbackTimer?.cancel();
    final intervalMs = (1000 / _playbackSpeed).round();
    _fallbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_currentSeconds < widget.totalDurationSeconds) {
        setState(() => _currentSeconds++);
        if (_currentSeconds % 5 == 0) {
          widget.onPositionChanged?.call(_currentSeconds);
        }
      } else {
        _fallbackTimer?.cancel();
        setState(() => _isPlaying = false);
        widget.onComplete?.call();
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _cyclePlaybackSpeed() {
    final nextIdx = (_speeds.indexOf(_playbackSpeed) + 1) % _speeds.length;
    final nextSpeed = _speeds[nextIdx];
    setState(() => _playbackSpeed = nextSpeed);
    _controller?.setPlaybackSpeed(nextSpeed);
    if (!_isInitialized && _isPlaying) {
      _startFallbackPlaybackTimer();
    }
    _showControlsTemporarily();
  }

  String _formatDuration(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Surface visible error UI if initialization or controller has an error
    if (_errorMessage != null && _errorMessage!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: _isFullscreen ? BorderRadius.zero : AppSpacing.roundedLg,
          border: Border.all(color: AppColors.error.withOpacity(0.6), width: 2),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 10),
                  Text(
                    'Video Playback Error',
                    style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: SelectableText(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(color: Colors.redAccent, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    'Stream URL: ${widget.videoUrl}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _initializePlayer();
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry Playback'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final totalDuration = (_controller != null && _controller!.value.isInitialized)
        ? _controller!.value.duration.inSeconds
        : widget.totalDurationSeconds;

    final progress = totalDuration > 0
        ? (_currentSeconds / totalDuration).clamp(0.0, 1.0)
        : 0.0;

    final currentTimeStr = _formatDuration(_currentSeconds);
    final totalTimeStr = _formatDuration(totalDuration);

    return MouseRegion(
      onHover: (_) => _showControlsTemporarily(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: _isFullscreen ? BorderRadius.zero : AppSpacing.roundedLg,
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: (_controller != null && _controller!.value.isInitialized && _controller!.value.aspectRatio > 0)
              ? _controller!.value.aspectRatio
              : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Real Hardware Video Element or Background Canvas
              if (_controller != null && _controller!.value.isInitialized)
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: SizedBox.expand(
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F172A), Color(0xFF020617)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                          size: 64,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            widget.title,
                            style: AppTypography.titleMedium.copyWith(color: Colors.white70),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.initialPositionSeconds > 0 && !_isPlaying) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.25),
                              borderRadius: AppSpacing.roundedFull,
                              border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                            ),
                            child: Text(
                              'Resuming at $currentTimeStr',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.secondaryFixed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Subtitles Box
              if (_subtitlesEnabled && _isPlaying)
                Positioned(
                  bottom: 64,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: Text(
                        'Captions: ${widget.title}',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              // Center Action Target
              Positioned.fill(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  behavior: HitTestBehavior.opaque,
                ),
              ),

              // Center Play/Pause Icon Button Overlay
              if (_showControls || !_isPlaying)
                IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Bottom Controls Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress Scrub Bar
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: AppColors.secondary,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: AppColors.secondary,
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: (val) {
                            final targetSec = (val * totalDuration).round();
                            if (_controller != null && _controller!.value.isInitialized) {
                              _controller!.seekTo(Duration(seconds: targetSec));
                            } else {
                              setState(() => _currentSeconds = targetSec);
                            }
                            _showControlsTemporarily();
                          },
                        ),
                      ),

                      // Controls row
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _togglePlayPause,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$currentTimeStr / $totalTimeStr',
                            style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                          ),
                          const Spacer(),
                          // Speed Button
                          InkWell(
                            onTap: _cyclePlaybackSpeed,
                            borderRadius: AppSpacing.roundedSm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: Text(
                                '${_playbackSpeed}x',
                                style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Subtitles Button
                          IconButton(
                            tooltip: 'Toggle Subtitles',
                            icon: Icon(
                              _subtitlesEnabled ? Icons.closed_caption : Icons.closed_caption_outlined,
                              color: _subtitlesEnabled ? AppColors.secondary : Colors.white70,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() => _subtitlesEnabled = !_subtitlesEnabled);
                              _showControlsTemporarily();
                            },
                          ),
                          const SizedBox(width: 8),
                          // Fullscreen
                          IconButton(
                            icon: Icon(
                              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Colors.white70,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() => _isFullscreen = !_isFullscreen);
                              _showControlsTemporarily();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
