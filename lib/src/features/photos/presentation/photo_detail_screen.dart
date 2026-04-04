import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/features/camera/presentation/timer_selection_sheet.dart';
import 'package:tempcam/src/features/paywall/presentation/premium_paywall_screen.dart';
import 'package:tempcam/src/localization/app_localizations.dart';
import 'package:tempcam/src/shared/models/app_settings.dart';
import 'package:tempcam/src/shared/models/photo_record.dart';
import 'package:tempcam/src/shared/state/app_controller.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';
import 'package:video_player/video_player.dart';

class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({super.key, required this.photoId});

  final String photoId;

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  final TransformationController _transformationController =
      TransformationController();
  bool _chromeVisible = false;
  bool _scanRequested = false;
  bool _phoneSheetPresented = false;

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
          return Scaffold(
            body:
                Center(child: Text(context.l10n.tr('Media no longer exists.'))),
          );
        }
        _scheduleSmartScanIfNeeded(controller, photo);
        _schedulePhoneSheetIfNeeded(photo);
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
                  child: Center(
                    child: _PrivateMediaPreview(
                      photo: photo,
                      onTap: _toggleChrome,
                    ),
                  ),
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
                        final unlocked =
                            await controller.promptForPremiumAccess(context);
                        if (!context.mounted || !unlocked) {
                          return;
                        }
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
                        final message =
                            await controller.keepPhotoForever(photo);
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
                      onPhoneTap: (phoneNumber) =>
                          _showPhoneActions(controller, phoneNumber),
                      onAddressTap: (address) =>
                          _showAddressActions(controller, address),
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

  void _scheduleSmartScanIfNeeded(AppController controller, PhotoRecord photo) {
    if (!photo.isPhoto || photo.hasCompletedSmartScan || _scanRequested) {
      return;
    }
    _scanRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      controller.ensurePhotoSmartScan(photo.id);
    });
  }

  void _schedulePhoneSheetIfNeeded(PhotoRecord photo) {
    if (_phoneSheetPresented || photo.detectedPhoneNumbers.isEmpty) {
      return;
    }
    _phoneSheetPresented = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final controller = context.read<AppController>();
      _showPhoneActions(controller, photo.detectedPhoneNumbers.first);
    });
  }

  Future<void> _showPhoneActions(
    AppController controller,
    String phoneNumber,
  ) async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheetContext.l10n.tr('Detected phone number'),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phoneNumber,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _runControllerAction(
                        () => controller.callDetectedPhoneNumber(phoneNumber),
                      );
                    },
                    icon: const Icon(Icons.call_rounded),
                    label: Text(sheetContext.l10n.tr('Call')),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _runControllerAction(
                        () => controller
                            .addDetectedPhoneNumberToContacts(phoneNumber),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(sheetContext.l10n.tr('Add to Contacts')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddressActions(
    AppController controller,
    String address,
  ) async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheetContext.l10n.tr('Detected address'),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  address,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _runControllerAction(
                        () => controller.openDetectedAddress(address),
                      );
                    },
                    icon: const Icon(Icons.map_rounded),
                    label: Text(sheetContext.l10n.tr('Open in Maps')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runControllerAction(
    Future<String?> Function() action,
  ) async {
    final message = await action();
    if (!mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PrivateMediaPreview extends StatelessWidget {
  const _PrivateMediaPreview({
    required this.photo,
    required this.onTap,
  });

  final PhotoRecord photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (photo.isVideo) {
      return _PrivateVideoPlayer(
        filePath: photo.filePath,
        onSurfaceTap: onTap,
      );
    }
    return Image.file(
      File(photo.filePath),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceLowest),
    );
  }
}

class _PrivateVideoPlayer extends StatefulWidget {
  const _PrivateVideoPlayer({
    required this.filePath,
    required this.onSurfaceTap,
  });

  final String filePath;
  final VoidCallback onSurfaceTap;

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
    await controller.setVolume(1.0);
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
        widget.onSurfaceTap();
        setState(() => _showPlayerControls = !_showPlayerControls);
      },
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.black),
                  child: Center(child: VideoPlayer(controller)),
                ),
                if (_showPlayerControls)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0x77000000)],
                      ),
                    ),
                    child: Center(
                      child: IconButton(
                        iconSize: 72,
                        color: Colors.white,
                        onPressed: () {
                          if (value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        },
                        icon: Icon(
                          value.isPlaying
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
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.56),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
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
                          Row(
                            children: [
                              Icon(
                                value.isPlaying
                                    ? Icons.graphic_eq_rounded
                                    : Icons.pause_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
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
    required this.onPhoneTap,
    required this.onAddressTap,
  });

  final PhotoRecord photo;
  final bool hasPremiumAccess;
  final VoidCallback onBack;
  final Future<void> Function() onExtend;
  final Future<void> Function() onKeepForever;
  final Future<void> Function() onDelete;
  final ValueChanged<String> onPhoneTap;
  final ValueChanged<String> onAddressTap;

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
              colors: [
                Color(0xAA131313),
                Colors.transparent,
                Color(0xE6131313)
              ],
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
                      icon: photo.isVideo
                          ? Icons.videocam_rounded
                          : Icons.photo_rounded,
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            size: 14, color: AppTheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.tr(
                            photo.isVideo ? 'Private Video' : 'Private Photo',
                          ),
                          style:
                              const TextStyle(fontSize: 10, letterSpacing: 2),
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
                    border: Border.all(
                        color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.tr('Expiring in'),
                              style: const TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: AppTheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.formatRemaining(
                                photo.expiresAt,
                                isKeptForever: photo.isKeptForever,
                              ),
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
                            Text(
                              context.l10n.tr('Created'),
                              style: const TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: AppTheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.formatDateTime(photo.createdAt),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      if (photo.hasDetectedDetails) ...[
                        _DetectedDetailsPanel(
                          photo: photo,
                          onPhoneTap: onPhoneTap,
                          onAddressTap: onAddressTap,
                        ),
                        const SizedBox(height: 14),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.onSurface,
                                backgroundColor: AppTheme.surfaceHigh,
                                side: BorderSide.none,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: onExtend,
                              icon: const Icon(Icons.update_rounded,
                                  color: AppTheme.secondary),
                              label: Text(context.l10n.tr('Extend Timer')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: const Color(0xFF003061),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: onKeepForever,
                              icon: const Icon(Icons.auto_delete_rounded),
                              label: Text(
                                context.l10n.tr(
                                  hasPremiumAccess
                                      ? 'Keep Forever'
                                      : 'Premium Only',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_forever_rounded,
                            color: AppTheme.error),
                        label: Text(
                          context.l10n.tr('Delete Now'),
                          style: const TextStyle(color: AppTheme.error),
                        ),
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

class _DetectedDetailsPanel extends StatelessWidget {
  const _DetectedDetailsPanel({
    required this.photo,
    required this.onPhoneTap,
    required this.onAddressTap,
  });

  final PhotoRecord photo;
  final ValueChanged<String> onPhoneTap;
  final ValueChanged<String> onAddressTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.tr('Detected details'),
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.tr(
              'Saved in TempCam until this photo expires or you keep it forever.',
            ),
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (photo.detectedPhoneNumbers.isNotEmpty) ...[
            const SizedBox(height: 14),
            _DetectedDetailGroup(
              title: context.l10n.tr('Phone numbers'),
              icon: Icons.call_rounded,
              items: photo.detectedPhoneNumbers,
              onTap: onPhoneTap,
            ),
          ],
          if (photo.detectedAddresses.isNotEmpty) ...[
            const SizedBox(height: 14),
            _DetectedDetailGroup(
              title: context.l10n.tr('Addresses'),
              icon: Icons.location_on_rounded,
              items: photo.detectedAddresses,
              onTap: onAddressTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetectedDetailGroup extends StatelessWidget {
  const _DetectedDetailGroup({
    required this.title,
    required this.icon,
    required this.items,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => InkWell(
                  onTap: () => onTap(item),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: AppTheme.secondary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}
