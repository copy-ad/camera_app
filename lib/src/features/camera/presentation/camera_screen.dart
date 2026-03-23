import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/shared/state/app_controller.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
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
              _CameraTopControls(controller: controller),
              _CameraStats(controller: controller),
              Positioned(
                left: 0,
                right: 0,
                bottom: 178,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_rounded,
                            color: AppTheme.secondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Default ${controller.settings.defaultTimer.label}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                    child: _RecordingBadge(duration: controller.recordingDuration),
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

class _InteractiveCameraViewport extends StatefulWidget {
  const _InteractiveCameraViewport({required this.controller});

  final AppController controller;

  @override
  State<_InteractiveCameraViewport> createState() =>
      _InteractiveCameraViewportState();
}

class _InteractiveCameraViewportState extends State<_InteractiveCameraViewport> {
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
    final previewSize = camera.value.previewSize;
    if (previewSize == null || viewportSize.width <= 0 || viewportSize.height <= 0) {
      return const Offset(0.5, 0.5);
    }

    final previewWidth = previewSize.height;
    final previewHeight = previewSize.width;
    final previewAspectRatio = previewWidth / previewHeight;
    final viewportAspectRatio = viewportSize.width / viewportSize.height;

    double scaledWidth;
    double scaledHeight;
    double offsetX = 0;
    double offsetY = 0;

    if (previewAspectRatio > viewportAspectRatio) {
      scaledHeight = viewportSize.height;
      scaledWidth = scaledHeight * previewAspectRatio;
      offsetX = (scaledWidth - viewportSize.width) / 2;
    } else {
      scaledWidth = viewportSize.width;
      scaledHeight = scaledWidth / previewAspectRatio;
      offsetY = (scaledHeight - viewportSize.height) / 2;
    }

    final normalizedDx = ((localPosition.dx + offsetX) / scaledWidth).clamp(0.0, 1.0);
    final normalizedDy = ((localPosition.dy + offsetY) / scaledHeight).clamp(0.0, 1.0);
    return Offset(normalizedDx, normalizedDy);
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
          left: left.clamp(16.0, constraints.maxWidth - 52.0),
          top: top.clamp(16.0, constraints.maxHeight - 52.0),
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.secondary, width: 2),
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
        child: Align(
          alignment: Alignment.topLeft,
          child: _CircleActionButton(
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            label: 'PHOTO',
            selected: !controller.isVideoMode,
            onTap: controller.isVideoMode ? controller.toggleCaptureMode : null,
          ),
          const SizedBox(width: 6),
          _ModeChip(
            label: 'VIDEO',
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
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
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
          color: AppTheme.surfaceLowest.withValues(alpha: 0.58),
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
          color: AppTheme.surfaceHighest,
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
          color: AppTheme.surfaceContainer.withValues(alpha: 0.68),
        ),
        child: Icon(icon, color: AppTheme.onSurface),
      ),
    );
  }
}
