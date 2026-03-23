import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/features/camera/presentation/timer_selection_sheet.dart';
import 'package:tempcam/src/features/paywall/presentation/premium_paywall_screen.dart';
import 'package:tempcam/src/shared/models/app_settings.dart';
import 'package:tempcam/src/shared/models/photo_record.dart';
import 'package:tempcam/src/shared/state/app_controller.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';
import 'package:video_player/video_player.dart';

String _formatRemaining(DateTime? expiresAt, {required bool isKeptForever}) {
  if (isKeptForever) {
    return 'Forever';
  }
  if (expiresAt == null) {
    return 'Expired';
  }
  final now = DateTime.now();
  final difference = expiresAt.difference(now);
  if (difference.isNegative) {
    return 'Expired';
  }
  final days = difference.inDays;
  final hours = difference.inHours.remainder(24);
  final minutes = difference.inMinutes.remainder(60);
  if (days > 0) {
    return '${days}d ${hours}h';
  }
  if (difference.inHours > 0) {
    return '${difference.inHours}h ${minutes}m';
  }
  return '${difference.inMinutes}m';
}

String _formatTimestamp(DateTime value) {
  return DateFormat('MMM d, yyyy • h:mm a').format(value);
}

class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({super.key, required this.photoId});

  final String photoId;

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  final TransformationController _transformationController = TransformationController();
  bool _chromeVisible = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        final photo = controller.byId(widget.photoId);
        if (photo == null) {
          return const Scaffold(
            body: Center(child: Text('Media no longer exists.')),
          );
        }
        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleChrome,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: photo.isVideo ? 1 : 1,
                  maxScale: photo.isVideo ? 1 : 4,
                  onInteractionStart: (_) {
                    if (_chromeVisible) {
                      setState(() => _chromeVisible = false);
                    }
                  },
                  child: Center(child: _PrivateMediaPreview(photo: photo)),
                ),
                IgnorePointer(
                  ignoring: !_chromeVisible,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _chromeVisible ? 1 : 0,
                    child: _PhotoDetailChrome(
                      photo: photo,
                      hasPremiumAccess: controller.hasPremiumAccess,
                      onBack: () => Navigator.of(context).pop(),
                      onExtend: () async {
                        final timer = await TimerSelectionSheet.show(
                          context,
                          AppTimerOption.twentyFourHours,
                          hasPremiumAccess: controller.hasPremiumAccess,
                        );
                        if (timer == null) {
                          return;
                        }
                        await controller.extendPhoto(photo, timer);
                      },
                      onKeepForever: () async {
                        if (!controller.hasPremiumAccess) {
                          await PremiumPaywallScreen.show(context);
                          return;
                        }
                        final ok = await controller.unlockForSensitiveAccess();
                        if (!context.mounted || !ok) {
                          return;
                        }
                        final message = await controller.keepPhotoForever(photo);
                        if (!context.mounted || message == null) {
                          return;
                        }
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(message)));
                      },
                      onDelete: () async {
                        final ok = await controller.unlockForSensitiveAccess();
                        if (!context.mounted || !ok) {
                          return;
                        }
                        await controller.deletePhoto(photo);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleChrome() {
    final matrix = _transformationController.value;
    final isZoomed = matrix.getMaxScaleOnAxis() > 1.01;
    if (isZoomed && _chromeVisible) {
      return;
    }
    setState(() => _chromeVisible = !_chromeVisible);
  }
}

class _PrivateMediaPreview extends StatelessWidget {
  const _PrivateMediaPreview({required this.photo});

  final PhotoRecord photo;

  @override
  Widget build(BuildContext context) {
    if (photo.isVideo) {
      return _PrivateVideoPlayer(filePath: photo.filePath);
    }
    return Image.file(
      File(photo.filePath),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceLowest),
    );
  }
}

class _PrivateVideoPlayer extends StatefulWidget {
  const _PrivateVideoPlayer({required this.filePath});

  final String filePath;

  @override
  State<_PrivateVideoPlayer> createState() => _PrivateVideoPlayerState();
}

class _PrivateVideoPlayerState extends State<_PrivateVideoPlayer> {
  VideoPlayerController? _controller;
  bool _showPlayerControls = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.file(File(widget.filePath));
    await controller.initialize();
    controller.setLooping(true);
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _showPlayerControls = !_showPlayerControls),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            if (_showPlayerControls)
              Container(
                color: Colors.black26,
                child: Center(
                  child: IconButton(
                    iconSize: 72,
                    color: Colors.white,
                    onPressed: () {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                      setState(() {});
                    },
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                    ),
                  ),
                ),
              ),
            if (_showPlayerControls)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppTheme.primary,
                        bufferedColor: AppTheme.surfaceHighest,
                        backgroundColor: AppTheme.surfaceContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDuration(controller.value.position)} / ${_formatDuration(controller.value.duration)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _PhotoDetailChrome extends StatelessWidget {
  const _PhotoDetailChrome({
    required this.photo,
    required this.hasPremiumAccess,
    required this.onBack,
    required this.onExtend,
    required this.onKeepForever,
    required this.onDelete,
  });

  final PhotoRecord photo;
  final bool hasPremiumAccess;
  final VoidCallback onBack;
  final Future<void> Function() onExtend;
  final Future<void> Function() onKeepForever;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xAA131313), Colors.transparent, Color(0xE6131313)],
              stops: [0, .32, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    _TopCircle(icon: Icons.arrow_back_rounded, onTap: onBack),
                    const Spacer(),
                    _TopCircle(
                      icon: photo.isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 14, color: AppTheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          photo.isVideo ? 'Private Video' : 'Private Photo',
                          style: const TextStyle(fontSize: 10, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Expiring in',
                              style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppTheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRemaining(photo.expiresAt, isKeptForever: photo.isKeptForever),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 38,
                        color: AppTheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Created',
                              style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppTheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(photo.createdAt),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontFamily: 'Manrope', fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                  decoration: const BoxDecoration(
                    color: Color(0xEE0E0E0E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.onSurface,
                                backgroundColor: AppTheme.surfaceHigh,
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: onExtend,
                              icon: const Icon(Icons.update_rounded, color: AppTheme.secondary),
                              label: const Text('Extend Timer'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: const Color(0xFF003061),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: onKeepForever,
                              icon: const Icon(Icons.auto_delete_rounded),
                              label: Text(hasPremiumAccess ? 'Keep Forever' : 'Premium Only'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.error),
                        label: const Text('Delete Now', style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopCircle extends StatelessWidget {
  const _TopCircle({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceContainer.withValues(alpha: 0.56),
        ),
        child: Icon(icon, color: AppTheme.onSurface),
      ),
    );
  }
}
