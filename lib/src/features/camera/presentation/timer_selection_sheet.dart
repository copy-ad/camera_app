import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../shared/models/app_settings.dart';
import '../../../shared/models/photo_record.dart';
import '../../../shared/theme/app_theme.dart';

class TimerSelectionSheet extends StatefulWidget {
  const TimerSelectionSheet({
    super.key,
    required this.initial,
    required this.hasPremiumAccess,
    this.previewFilePath,
    this.previewMediaType = MediaType.photo,
  });

  final AppTimerOption initial;
  final bool hasPremiumAccess;
  final String? previewFilePath;
  final MediaType previewMediaType;

  static Future<AppTimerOption?> show(
    BuildContext context,
    AppTimerOption initial, {
    required bool hasPremiumAccess,
    String? previewFilePath,
    MediaType previewMediaType = MediaType.photo,
  }) {
    return showModalBottomSheet<AppTimerOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimerSelectionSheet(
        initial: initial,
        hasPremiumAccess: hasPremiumAccess,
        previewFilePath: previewFilePath,
        previewMediaType: previewMediaType,
      ),
    );
  }

  @override
  State<TimerSelectionSheet> createState() => _TimerSelectionSheetState();
}

class _TimerSelectionSheetState extends State<TimerSelectionSheet> {
  late AppTimerOption selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: const BoxDecoration(
          color: Color(0xE6131313),
          borderRadius: BorderRadius.vertical(top: Radius.circular(42)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 52, height: 4, decoration: BoxDecoration(color: AppTheme.surfaceHighest, borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 22),
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.previewFilePath == null ? null : _openPreview,
              child: Container(
                width: double.infinity,
                height: 188,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A3A3A), Color(0xFF131313)]),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _PreviewSurface(
                      filePath: widget.previewFilePath,
                      mediaType: widget.previewMediaType,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xC6131313), Colors.transparent],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_full_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Tap to view', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 20,
                      left: 18,
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_rounded, size: 16, color: AppTheme.primary),
                          SizedBox(width: 6),
                          Text('Encrypted Preview', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Set Self-Destruct Timer', style: TextStyle(fontFamily: 'Manrope', fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              widget.hasPremiumAccess ? 'Choose when this capture evaporates from the vault.' : '7 day timers are available with Premium.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.25,
              physics: const NeverScrollableScrollPhysics(),
              children: AppTimerOption.captureOptions.map((option) {
                final isLocked = option.requiresPremium && !widget.hasPremiumAccess;
                final isSelected = option == selected;
                return InkWell(
                  onTap: () {
                    if (isLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unlock Premium to use the 7 day timer.')),
                      );
                      return;
                    }
                    setState(() => selected = option);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.secondary : AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: isSelected ? const [BoxShadow(color: Color(0x44E9C349), blurRadius: 16)] : const [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            option.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? const Color(0xFF3C2F00) : isLocked ? AppTheme.onSurfaceVariant : AppTheme.onSurface,
                            ),
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.lock_rounded, size: 16, color: isSelected ? const Color(0xFF3C2F00) : AppTheme.onSurfaceVariant),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF003061),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.of(context).pop(selected),
                child: const Text('Apply Timer', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Defaults to 24 hours if skipped.', style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppTheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Future<void> _openPreview() async {
    final filePath = widget.previewFilePath;
    if (filePath == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.94),
      builder: (_) => _MediaPreviewDialog(
        filePath: filePath,
        mediaType: widget.previewMediaType,
      ),
    );
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({
    required this.filePath,
    required this.mediaType,
  });

  final String? filePath;
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    if (filePath == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A3A3A), Color(0xFF131313)],
          ),
        ),
      );
    }
    if (mediaType == MediaType.video) {
      return _SheetVideoPreview(filePath: filePath!);
    }
    return Image.file(
      File(filePath!),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFF131313)),
      ),
    );
  }
}

class _MediaPreviewDialog extends StatelessWidget {
  const _MediaPreviewDialog({
    required this.filePath,
    required this.mediaType,
  });

  final String filePath;
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF060606),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Flexible(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: mediaType == MediaType.video
                          ? _SheetVideoPreview(filePath: filePath, autoplay: true, showControls: true)
                          : Image.file(
                              File(filePath),
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  mediaType == MediaType.video ? 'Review this encrypted video before setting its timer.' : 'Review this encrypted photo before setting its timer.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.42),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetVideoPreview extends StatefulWidget {
  const _SheetVideoPreview({
    required this.filePath,
    this.autoplay = false,
    this.showControls = false,
  });

  final String filePath;
  final bool autoplay;
  final bool showControls;

  @override
  State<_SheetVideoPreview> createState() => _SheetVideoPreviewState();
}

class _SheetVideoPreviewState extends State<_SheetVideoPreview> {
  VideoPlayerController? _controller;

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
    await controller.setVolume(1.0);
    controller.setLooping(true);
    if (widget.autoplay) {
      await controller.play();
    }
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
      onTap: () {
        if (!widget.showControls) {
          return;
        }
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
        setState(() {});
      },
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.38),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          if (widget.showControls)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.36),
                shape: BoxShape.circle,
              ),
              child: Icon(
                controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.36),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
        ],
      ),
    );
  }
}
