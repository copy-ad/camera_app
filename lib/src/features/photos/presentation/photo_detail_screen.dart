import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/features/camera/presentation/timer_selection_sheet.dart';
import 'package:tempcam/src/features/paywall/presentation/premium_paywall_screen.dart';
import 'package:tempcam/src/shared/models/app_settings.dart';
import 'package:tempcam/src/shared/state/app_controller.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';

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

class PhotoDetailScreen extends StatelessWidget {
  const PhotoDetailScreen({super.key, required this.photoId});

  final String photoId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        final photo = controller.byId(photoId);
        if (photo == null) {
          return const Scaffold(body: Center(child: Text('Photo no longer exists.')));
        }
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(photo.filePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceLowest),
              ),
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
                          _TopCircle(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          const Column(
                            children: [
                              Text(
                                'TEMPCAM',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3,
                                  color: AppTheme.primary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'ENCRYPTED PREVIEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const _TopCircle(icon: Icons.info_outline_rounded),
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded, size: 14, color: AppTheme.secondary),
                              SizedBox(width: 6),
                              Text('Zero Trace Active', style: TextStyle(fontSize: 10, letterSpacing: 2)),
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
                                    onPressed: () async {
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
                                    onPressed: () async {
                                      if (!controller.hasPremiumAccess) {
                                        await PremiumPaywallScreen.show(context);
                                        return;
                                      }
                                      await controller.keepPhotoForever(photo);
                                    },
                                    icon: const Icon(Icons.auto_delete_rounded),
                                    label: Text(controller.hasPremiumAccess ? 'Keep Forever' : 'Premium Only'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: () async {
                                await controller.deletePhoto(photo);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
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
          ),
        );
      },
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
