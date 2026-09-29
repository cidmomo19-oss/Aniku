import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../app/theme.dart';
import '../../data/local_db.dart';

class DirectPlayerWidget extends StatefulWidget {
  final String videoUrl; // remote or local file path
  final int animeId;
  final int episodeNumber;
  final String episodeTitle;
  final String sourceChannel;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPrevEpisode;

  const DirectPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.animeId,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.sourceChannel,
    this.onNextEpisode,
    this.onPrevEpisode,
  });

  @override
  State<DirectPlayerWidget> createState() => _DirectPlayerWidgetState();
}

class _DirectPlayerWidgetState extends State<DirectPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isLocked = false;
  bool _isFullscreen = false;
  Timer? _controlsTimer;

  // Skip pulse animation state
  bool _showLeftPulse = false;
  bool _showRightPulse = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final uri = Uri.parse(widget.videoUrl);
    if (widget.videoUrl.startsWith('http://') ||
        widget.videoUrl.startsWith('https://')) {
      _controller = VideoPlayerController.networkUrl(uri);
    } else {
      _controller = VideoPlayerController.contentUri(uri);
    }

    try {
      await _controller.initialize();
      // Enable wakelock while watching
      await WakelockPlus.enable();

      // Check saved watch position
      final history = await LocalDb.instance.getHistoryForAnime(widget.animeId);
      if (history != null && history['episode_number'] == widget.episodeNumber) {
        final posMs = history['position_ms'] as int?;
        if (posMs != null && posMs > 0 && posMs < _controller.value.duration.inMilliseconds) {
          await _controller.seekTo(Duration(milliseconds: posMs));
        }
      }

      await _controller.play();
      _startControlsTimer();

      _controller.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _videoListener() {
    if (_controller.value.isInitialized) {
      // Save history position
      LocalDb.instance.saveWatchHistory(
        animeId: widget.animeId,
        episodeNumber: widget.episodeNumber,
        positionMs: _controller.value.position.inMilliseconds,
        durationMs: _controller.value.duration.inMilliseconds,
      );
    }
    if (mounted) setState(() {});
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  Future<void> _seekRelative(int seconds) async {
    final currentPos = _controller.value.position;
    final newPos = currentPos + Duration(seconds: seconds);
    final clampedPos = Duration(
      milliseconds: newPos.inMilliseconds.clamp(
        0,
        _controller.value.duration.inMilliseconds,
      ),
    );
    await _controller.seekTo(clampedPos);

    // Trigger pulse animation
    if (seconds < 0) {
      setState(() => _showLeftPulse = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showLeftPulse = false);
      });
    } else {
      setState(() => _showRightPulse = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showRightPulse = false);
      });
    }
  }

  void _showSpeedBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final currentSpeed = _controller.value.playbackSpeed;
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kecepatan Putar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: speeds.map((speed) {
                  final isSelected = currentSpeed == speed;
                  return ChoiceChip(
                    label: Text('${speed}x'),
                    selected: isSelected,
                    selectedColor: AppColors.accentStart,
                    backgroundColor: AppColors.surface1,
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        _controller.setPlaybackSpeed(speed);
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controlsTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAlignment.start,
      children: [
        // Video Viewport with Custom UI Overlay
        AspectRatio(
          aspectRatio: _isFullscreen ? (16 / 9) : (16 / 9),
          child: Container(
            color: Colors.black,
            child: !_isInitialized
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentStart,
                    ),
                  )
                : GestureDetector(
                    onTap: _toggleControls,
                    onDoubleTapDown: (details) {
                      final screenWidth = context.size?.width ?? 300;
                      if (details.localPosition.dx < screenWidth / 2) {
                        _seekRelative(-10);
                      } else {
                        _seekRelative(10);
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller),

                        // Skip Pulse Overlay - Left (-10s)
                        if (_showLeftPulse)
                          Positioned(
                            left: 40,
                            child: AnimatedOpacity(
                              opacity: _showLeftPulse ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fast_rewind_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    Text(
                                      '-10s',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Skip Pulse Overlay - Right (+10s)
                        if (_showRightPulse)
                          Positioned(
                            right: 40,
                            child: AnimatedOpacity(
                              opacity: _showRightPulse ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fast_forward_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    Text(
                                      '+10s',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Controls Overlay
                        if (_showControls) ...[
                          Container(color: Colors.black38),

                          // Lock Button Top Left
                          Positioned(
                            top: 12,
                            left: 12,
                            child: IconButton(
                              icon: Icon(
                                _isLocked
                                    ? Icons.lock_rounded
                                    : Icons.lock_open_rounded,
                                color: _isLocked
                                    ? AppColors.accentStart
                                    : Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isLocked = !_isLocked;
                                });
                              },
                            ),
                          ),

                          if (!_isLocked) ...[
                            // Center Controls: Prev, Play/Pause, Next
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.onPrevEpisode != null)
                                  IconButton(
                                    iconSize: 36,
                                    icon: const Icon(
                                      Icons.skip_previous_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: widget.onPrevEpisode,
                                  ),
                                const SizedBox(width: 16),
                                IconButton(
                                  iconSize: 52,
                                  icon: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause_circle_filled_rounded
                                        : Icons.play_circle_fill_rounded,
                                    color: AppColors.accentStart,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_controller.value.isPlaying) {
                                        _controller.pause();
                                      } else {
                                        _controller.play();
                                      }
                                    });
                                    _startControlsTimer();
                                  },
                                ),
                                const SizedBox(width: 16),
                                if (widget.onNextEpisode != null)
                                  IconButton(
                                    iconSize: 36,
                                    icon: const Icon(
                                      Icons.skip_next_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: widget.onNextEpisode,
                                  ),
                              ],
                            ),

                            // Bottom Bar: Seekbar, Time, Speed, Fullscreen
                            Positioned(
                              bottom: 8,
                              left: 12,
                              right: 12,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _formatDuration(
                                            _controller.value.position),
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderThemeData(
                                            trackHeight: 3,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                    enabledThumbRadius: 6),
                                            activeTrackColor:
                                                AppColors.accentStart,
                                            inactiveTrackColor: Colors.white24,
                                            thumbColor: AppColors.accentEnd,
                                          ),
                                          child: Slider(
                                            value: _controller
                                                .value.position.inMilliseconds
                                                .toDouble()
                                                .clamp(
                                                  0.0,
                                                  _controller.value.duration
                                                      .inMilliseconds
                                                      .toDouble(),
                                                ),
                                            min: 0.0,
                                            max: _controller
                                                .value.duration.inMilliseconds
                                                .toDouble(),
                                            onChanged: (val) {
                                              _controller.seekTo(Duration(
                                                  milliseconds: val.toInt()));
                                            },
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(
                                            _controller.value.duration),
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _showSpeedBottomSheet,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${_controller.value.playbackSpeed}x',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        iconSize: 20,
                                        icon: Icon(
                                          _isFullscreen
                                              ? Icons.fullscreen_exit_rounded
                                              : Icons.fullscreen_rounded,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isFullscreen = !_isFullscreen;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              Text(
                widget.episodeTitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.video_library_rounded,
                    color: AppColors.infoCyan,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sumber: ${widget.sourceChannel}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
