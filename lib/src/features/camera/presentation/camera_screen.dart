import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/localization/app_localizations.dart';
import 'package:tempcam/src/shared/state/app_controller.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';
import 'package:tempcam/src/shared/widgets/glass_panel.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        final l10n = context.l10n;
        final camera = controller.cameraController;
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (camera != null && camera.value.isInitialized)
                _InteractiveCameraViewport(controller: controller)
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF242424), AppTheme.surfaceLowest],
                    ),
                  ),
                ),
              if (controller.isSwitchingCamera)
                ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.tr('Switching camera...'),
                          style: const TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _CameraTopControls(controller: controller),
              _CameraStats(controller: controller),
              Positioned(
                left: 0,
                right: 0,
                bottom: 178,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width - 40,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: controller.hasPremiumAccess
                            ? null
                            : () => controller.promptForPremiumAccess(context),
                        child: DecoratedBox(
                          decoration: AppTheme.glassDecoration(
                            radius: 999,
                            fill:
                                AppTheme.surfaceContainer.withValues(alpha: 0.48),
                            shadows: const [],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  controller.hasPremiumAccess
                                      ? Icons.timer_rounded
                                      : Icons.lock_clock_rounded,
                                  color: AppTheme.secondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    controller.hasPremiumAccess
                                        ? l10n.tr(
                                            'Default {timer}',
                                            {
                                              'timer': l10n.timerLabel(
                                                controller
                                                    .settings.defaultTimer,
                                              ),
                                            },
                                          )
                                        : l10n.tr(
                                            'Explore camera now. Unlock to save with a timer.',
                                          ),
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (controller.hasLiveScanResult)
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 236,
                  child: _LiveScanAssistCard(controller: controller),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 124,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 180),
                    child: _ModeSwitcher(controller: controller),
                  ),
                ),
              ),
              if (controller.isRecordingVideo)
                Positioned(
                  top: 130,
                  left: 0,
                  right: 0,
                  child: Center(
                    child:
                        _RecordingBadge(duration: controller.recordingDuration),
                  ),
                ),
              Positioned(
                left: 22,
                right: 22,
                bottom: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _GalleryThumb(
                      file: controller.latestThumbnail,
                      onTap: () => controller.setTab(0),
                    ),
                    _ShutterButton(
                      isVideoMode: controller.isVideoMode,
                      isRecording: controller.isRecordingVideo,
                      busy: controller.isCapturing,
                      onTap: () => _handlePrimaryAction(context, controller),
                    ),
                    _CircleIconButton(
                      icon: Icons.flip_camera_ios_rounded,
                      onTap: () => controller.switchCamera(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    AppController controller,
  ) async {
    final message = await controller.handlePrimaryCapture(context);
    if (!context.mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LiveScanAssistCard extends StatelessWidget {
  const _LiveScanAssistCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.liveScanResult;
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      radius: 22,
      color: AppTheme.surfaceContainer.withValues(alpha: 0.56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context.l10n.tr('Live Scan'),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.tr('Detected on camera'),
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (result.phoneNumber != null) ...[
            const SizedBox(height: 12),
            _LiveScanRow(
              icon: Icons.call_rounded,
              value: result.phoneNumber!,
              actions: [
                _LiveScanAction(
                  label: context.l10n.tr('Call'),
                  onTap: () => _runLiveAction(
                    context,
                    () => controller.callLiveScanPhoneNumber(
                      result.phoneNumber!,
                    ),
                  ),
                ),
                _LiveScanAction(
                  label: context.l10n.tr('Add to Contacts'),
                  onTap: () => _runLiveAction(
                    context,
                    () => controller.addLiveScanPhoneNumberToContacts(
                      result.phoneNumber!,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (result.address != null) ...[
            const SizedBox(height: 12),
            _LiveScanRow(
              icon: Icons.location_on_rounded,
              value: result.address!,
              actions: [
                _LiveScanAction(
                  label: context.l10n.tr('Open in Maps'),
                  onTap: () => _runLiveAction(
                    context,
                    () => controller.openLiveScanAddress(result.address!),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runLiveAction(
    BuildContext context,
    Future<String?> Function() action,
  ) async {
    final message = await action();
    if (!context.mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LiveScanRow extends StatelessWidget {
  const _LiveScanRow({
    required this.icon,
    required this.value,
    required this.actions,
  });

  final IconData icon;
  final String value;
  final List<_LiveScanAction> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppTheme.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions
              .map(
                (action) => FilledButton.tonal(
                  onPressed: action.onTap,
                  child: Text(action.label),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _LiveScanAction {
  const _LiveScanAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final Future<void> Function() onTap;
}

class _InteractiveCameraViewport extends StatefulWidget {
  const _InteractiveCameraViewport({required this.controller});

  final AppController controller;

  @override
  State<_InteractiveCameraViewport> createState() =>
      _InteractiveCameraViewportState();
}

class _InteractiveCameraViewportState
    extends State<_InteractiveCameraViewport> {
  double _baseZoomLevel = 1.0;
  bool _isScaling = false;

  @override
  Widget build(BuildContext context) {
    final camera = widget.controller.cameraController;
    if (camera == null || !camera.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (_isScaling) {
              return;
            }
            final normalizedPoint = _normalizedPreviewPoint(
              camera,
              details.localPosition,
              Size(constraints.maxWidth, constraints.maxHeight),
            );
            widget.controller.focusAtPoint(normalizedPoint);
          },
          onScaleStart: (_) {
            _isScaling = true;
            _baseZoomLevel = widget.controller.currentZoomLevel;
          },
          onScaleUpdate: (details) {
            if (details.pointerCount < 2) {
              return;
            }
            widget.controller.setZoomLevel(_baseZoomLevel * details.scale);
          },
          onScaleEnd: (_) {
            _isScaling = false;
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CameraViewport(controller: camera),
              _FocusIndicatorOverlay(controller: widget.controller),
            ],
          ),
        );
      },
    );
  }

  Offset _normalizedPreviewPoint(
    CameraController camera,
    Offset localPosition,
    Size viewportSize,
  ) {
    if (!camera.value.isInitialized ||
        viewportSize.width <= 0 ||
        viewportSize.height <= 0) {
      return const Offset(0.5, 0.5);
    }
    return Offset(
      (localPosition.dx / viewportSize.width).clamp(0.0, 1.0),
      (localPosition.dy / viewportSize.height).clamp(0.0, 1.0),
    );
  }
}

class _CameraViewport extends StatelessWidget {
  const _CameraViewport({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    final portraitWidth = previewSize.height;
    final portraitHeight = previewSize.width;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: portraitWidth,
            height: portraitHeight,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _FocusIndicatorOverlay extends StatelessWidget {
  const _FocusIndicatorOverlay({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final focusPoint = controller.focusIndicatorPoint;
    if (focusPoint == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final left = (focusPoint.dx * constraints.maxWidth) - 34;
        final top = (focusPoint.dy * constraints.maxHeight) - 34;

        return Positioned(
          left: left.clamp(12.0, constraints.maxWidth - 60.0),
          top: top.clamp(12.0, constraints.maxHeight - 60.0),
          child: IgnorePointer(
            child: _ProFocusRing(
              key: ValueKey(
                '${focusPoint.dx.toStringAsFixed(3)}-${focusPoint.dy.toStringAsFixed(3)}',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProFocusRing extends StatelessWidget {
  const _ProFocusRing({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.24, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.95),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withValues(alpha: 0.18),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            ...const [
              _FocusTick(alignment: Alignment.topCenter, width: 12, height: 2),
              _FocusTick(
                  alignment: Alignment.bottomCenter, width: 12, height: 2),
              _FocusTick(alignment: Alignment.centerLeft, width: 2, height: 12),
              _FocusTick(
                  alignment: Alignment.centerRight, width: 2, height: 12),
            ],
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusTick extends StatelessWidget {
  const _FocusTick({
    required this.alignment,
    required this.width,
    required this.height,
  });

  final Alignment alignment;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.secondary,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _CameraTopControls extends StatelessWidget {
  const _CameraTopControls({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: Row(
          children: [
            _CircleActionButton(
              icon: _flashIconFor(controller.flashMode),
              onTap: () async {
                final message = await controller.toggleFlash();
                if (!context.mounted || message == null) {
                  return;
                }
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(message)));
              },
            ),
            const Spacer(),
            _CircleActionButton(
              icon: Icons.visibility_off_rounded,
              onTap: () => controller.panicExit(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _flashIconFor(FlashMode mode) {
    return switch (mode) {
      FlashMode.auto => Icons.flash_auto_rounded,
      FlashMode.always => Icons.flash_on_rounded,
      FlashMode.torch => Icons.flash_on_rounded,
      FlashMode.off => Icons.flash_off_rounded,
    };
  }
}

class _CameraStats extends StatelessWidget {
  const _CameraStats({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 92,
      right: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'ISO 100',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'f/1.8',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${controller.currentZoomLevel.toStringAsFixed(1)}x',
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(4),
      radius: 999,
      color: AppTheme.surfaceContainer.withValues(alpha: 0.44),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            label: context.l10n.tr('PHOTO'),
            selected: !controller.isVideoMode,
            onTap: controller.isVideoMode ? controller.toggleCaptureMode : null,
          ),
          const SizedBox(width: 6),
          _ModeChip(
            label: context.l10n.tr('VIDEO'),
            selected: controller.isVideoMode,
            onTap: controller.isVideoMode ? null : controller.toggleCaptureMode,
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryContainer],
                )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? AppTheme.softGlow : const [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF003061) : AppTheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _RecordingBadge extends StatelessWidget {
  const _RecordingBadge({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC3B0A0A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.fiber_manual_record_rounded,
            color: Color(0xFFFF5A5A),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceContainer.withValues(alpha: 0.44),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: AppTheme.onSurface),
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({required this.file, required this.onTap});

  final File? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 56,
        height: 56,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 2,
          ),
          color: AppTheme.surfaceContainer.withValues(alpha: 0.58),
        ),
        child: file != null
            ? Image.file(file!, fit: BoxFit.cover)
            : const Icon(
                Icons.photo_library_outlined,
                color: AppTheme.onSurfaceVariant,
              ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.isVideoMode,
    required this.isRecording,
    required this.busy,
    required this.onTap,
  });

  final bool isVideoMode;
  final bool isRecording;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color innerColor = isVideoMode
        ? (isRecording ? const Color(0xFFFF5A5A) : const Color(0xFFFF7474))
        : AppTheme.primary;

    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.onSurface.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: AppTheme.deepShadow,
          ),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: innerColor,
            boxShadow: AppTheme.softGlow,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(22),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.background,
                  ),
                )
              : Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: isVideoMode ? (isRecording ? 24 : 28) : 56,
                    height: isVideoMode ? (isRecording ? 24 : 28) : 56,
                    decoration: BoxDecoration(
                      color: isVideoMode
                          ? (isRecording
                              ? Colors.white
                              : const Color(0xFF7A1010))
                          : AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        isVideoMode && isRecording ? 8 : 999,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceContainer.withValues(alpha: 0.44),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: AppTheme.onSurface),
      ),
    );
  }
}
