import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/core/constants/app_strings.dart';
import 'package:tempcam/src/localization/app_localizations.dart';
import 'package:tempcam/src/features/photos/presentation/photo_detail_screen.dart';
import 'package:tempcam/src/shared/models/photo_record.dart';
import 'package:tempcam/src/shared/state/app_controller.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

enum _GalleryFilter {
  all('All'),
  photos('Photos'),
  videos('Videos');

  const _GalleryFilter(this.label);
  final String label;
}

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  _GalleryFilter _filter = _GalleryFilter.all;
  final Set<String> _selectedIds = <String>{};
  bool _selectionMode = false;
  bool _pendingSmartOpenInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppController>().refreshPhotos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        _schedulePendingSmartOpen(controller);
        final l10n = context.l10n;
        final visibleMedia = _filteredMedia(controller.photos);
        final selectedMedia = controller.photos
            .where((item) => _selectedIds.contains(item.id))
            .toList(growable: false);
        final expiringSoon = visibleMedia
            .where((item) => !item.isKeptForever)
            .take(3)
            .toList(growable: false);
        final photoCount =
            controller.photos.where((item) => item.isPhoto).length;
        final videoCount =
            controller.photos.where((item) => item.isVideo).length;

        return Scaffold(
          body: RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: controller.refreshPhotos,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GalleryHero(
                            totalCount: controller.photos.length,
                            photoCount: photoCount,
                            videoCount: videoCount,
                            onOpenCamera: () => controller.setTab(1),
                            onImport: () => _importMedia(controller),
                            onPanicExit: controller.panicExit,
                          ),
                          const SizedBox(height: 18),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _GalleryFilter.values.map((filter) {
                                final isSelected = filter == _filter;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: filter == _GalleryFilter.values.last
                                        ? 0
                                        : 10,
                                  ),
                                  child: _FilterChipButton(
                                    label: l10n.tr(filter.label),
                                    selected: isSelected,
                                    onTap: () {
                                      if (_filter == filter) {
                                        return;
                                      }
                                      setState(() {
                                        _filter = filter;
                                        _clearSelection();
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (expiringSoon.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: _ExpiringSoonStrip(
                        items: expiringSoon,
                        onOpen: _openMedia,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.tr('Private Vault'),
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.tr(
                                      '{count} temp items ready',
                                      {'count': '${visibleMedia.length}'},
                                    ),
                                    style: const TextStyle(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _SelectionToggleButton(
                              selectionMode: _selectionMode,
                              selectedCount: _selectedIds.length,
                              onTap: () {
                                setState(() {
                                  if (_selectionMode) {
                                    _clearSelection();
                                  } else {
                                    _selectionMode = true;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _selectionMode
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: _SelectionBar(
                                    selectedCount: _selectedIds.length,
                                    onCancel: () {
                                      setState(_clearSelection);
                                    },
                                    onDelete: _selectedIds.isEmpty
                                        ? null
                                        : () => _deleteSelected(
                                              controller,
                                              selectedMedia,
                                            ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (visibleMedia.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyVaultState(filter: _filter),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = visibleMedia[index];
                          return _VaultTile(
                            item: item,
                            selected: _selectedIds.contains(item.id),
                            selectionMode: _selectionMode,
                            onTap: () => _handleTileTap(item),
                            onLongPress: () => _handleTileLongPress(item),
                          );
                        },
                        childCount: visibleMedia.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.74,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryContainer,
            foregroundColor: const Color(0xFF002A55),
            onPressed: () => controller.setTab(1),
            icon: const Icon(Icons.camera_alt_rounded),
            label: Text(
              l10n.tr('Capture'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      },
    );
  }

  List<PhotoRecord> _filteredMedia(List<PhotoRecord> allItems) {
    return allItems.where((item) {
      return switch (_filter) {
        _GalleryFilter.all => true,
        _GalleryFilter.photos => item.isPhoto,
        _GalleryFilter.videos => item.isVideo,
      };
    }).toList(growable: false);
  }

  void _handleTileTap(PhotoRecord item) {
    if (_selectionMode) {
      setState(() {
        _toggleSelection(item.id);
      });
      return;
    }
    _openMedia(item);
  }

  void _handleTileLongPress(PhotoRecord item) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(item.id);
    });
  }

  void _toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    if (_selectedIds.isEmpty) {
      _selectionMode = false;
    }
  }

  void _clearSelection() {
    _selectedIds.clear();
    _selectionMode = false;
  }

  void _schedulePendingSmartOpen(AppController controller) {
    final pendingPhotoId = controller.pendingSmartScanPhotoId;
    if (_pendingSmartOpenInFlight || pendingPhotoId == null) {
      return;
    }
    _pendingSmartOpenInFlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final photoId = controller.consumePendingSmartScanPhotoId();
      final photo = photoId == null ? null : controller.byId(photoId);
      if (photo != null && mounted) {
        await _openMedia(photo, showDetectedDetailsOnOpen: true);
      }
      _pendingSmartOpenInFlight = false;
    });
  }

  Future<void> _openMedia(
    PhotoRecord item, {
    bool showDetectedDetailsOnOpen = false,
  }) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoDetailScreen(
          photoId: item.id,
          showDetectedDetailsOnOpen:
              showDetectedDetailsOnOpen || item.hasDetectedDetails,
        ),
      ),
    );
  }

  Future<void> _deleteSelected(
    AppController controller,
    List<PhotoRecord> selectedMedia,
  ) async {
    if (selectedMedia.isEmpty) {
      return;
    }
    final ok = await controller.unlockForSensitiveAccess();
    if (!mounted || !ok) {
      return;
    }
    await controller.deletePhotos(selectedMedia);
    if (!mounted) {
      return;
    }
    setState(_clearSelection);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.tr(
              '{count} items deleted from TempCam.',
              {'count': '${selectedMedia.length}'},
            ),
          ),
        ),
      );
  }

  Future<void> _importMedia(AppController controller) async {
    final message = await controller.importMediaToVault(context);
    if (!mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GalleryHero extends StatelessWidget {
  const _GalleryHero({
    required this.totalCount,
    required this.photoCount,
    required this.videoCount,
    required this.onOpenCamera,
    required this.onImport,
    required this.onPanicExit,
  });

  final int totalCount;
  final int photoCount;
  final int videoCount;
  final VoidCallback onOpenCamera;
  final Future<void> Function() onImport;
  final Future<void> Function() onPanicExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF23272F), Color(0xFF121316)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: AppTheme.primary,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      foregroundColor: AppTheme.onSurface,
                    ),
                    onPressed: onOpenCamera,
                    icon: const Icon(Icons.camera_alt_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      foregroundColor: AppTheme.onSurface,
                    ),
                    onPressed: () => onImport(),
                    icon: const Icon(Icons.file_upload_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      foregroundColor: AppTheme.onSurface,
                    ),
                    onPressed: () => onPanicExit(),
                    icon: const Icon(Icons.visibility_off_rounded),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.tr('Every temporary moment, in one calm vault.'),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.tr(
              'Browse all temp photos and videos, focus on what is expiring, and clean up quickly when you need to.',
            ),
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(
                  label: context.l10n.tr('All Media'),
                  value: totalCount.toString(),
                  accent: AppTheme.primary),
              _HeroMetric(
                  label: context.l10n.tr('Photos'),
                  value: photoCount.toString(),
                  accent: AppTheme.secondary),
              _HeroMetric(
                  label: context.l10n.tr('Videos'),
                  value: videoCount.toString(),
                  accent: AppTheme.tertiary),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
                color: accent, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : Colors.white.withValues(alpha: 0.05),
            ),
            boxShadow: selected ? AppTheme.softGlow : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF003061) : AppTheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionToggleButton extends StatelessWidget {
  const _SelectionToggleButton({
    required this.selectionMode,
    required this.selectedCount,
    required this.onTap,
  });

  final bool selectionMode;
  final int selectedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor:
            selectionMode ? AppTheme.secondary : AppTheme.surfaceContainer,
        foregroundColor:
            selectionMode ? const Color(0xFF3C2F00) : AppTheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      child: Text(
        selectionMode && selectedCount > 0
            ? context.l10n.tr('Done ({count})', {'count': '$selectedCount'})
            : selectionMode
                ? context.l10n.tr('Done')
                : context.l10n.tr('Select'),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.selectedCount,
    required this.onCancel,
    required this.onDelete,
  });

  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.checklist_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selectedCount == 0
                  ? context.l10n.tr('Choose items to delete.')
                  : context.l10n.tr(
                      '{count} items selected for deletion.',
                      {'count': '$selectedCount'},
                    ),
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onCancel,
            child: Text(context.l10n.tr('Cancel')),
          ),
          const SizedBox(width: 6),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBF5A55),
              foregroundColor: Colors.white,
            ),
            onPressed: onDelete,
            child: Text(context.l10n.tr('Delete')),
          ),
        ],
      ),
    );
  }
}

class _ExpiringSoonStrip extends StatelessWidget {
  const _ExpiringSoonStrip({
    required this.items,
    required this.onOpen,
  });

  final List<PhotoRecord> items;
  final ValueChanged<PhotoRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            context.l10n.tr('Expiring Soon'),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => _ExpiringCard(
              item: items[index],
              onTap: () => onOpen(items[index]),
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: items.length,
          ),
        ),
      ],
    );
  }
}

class _ExpiringCard extends StatelessWidget {
  const _ExpiringCard({
    required this.item,
    required this.onTap,
  });

  final PhotoRecord item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        width: 228,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppTheme.surfaceContainer,
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _MediaThumbnail(item: item),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xD8131313), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MediaPill(
                    label: context.l10n.tr(item.isVideo ? 'VIDEO' : 'PHOTO'),
                  ),
                  if (item.hasDetectedDetails) ...[
                    const SizedBox(height: 8),
                    _DetectedDetailPill(
                      count: item.detectedPhoneNumbers.length +
                          item.detectedAddresses.length,
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.timerLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      context.l10n.formatRemaining(
                        item.expiresAt,
                        isKeptForever: item.isKeptForever,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF3C2F00),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _VaultTile extends StatelessWidget {
  const _VaultTile({
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final PhotoRecord item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : Colors.white.withValues(alpha: 0.06),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected ? AppTheme.softGlow : const [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _MediaThumbnail(item: item),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [Color(0xAA131313), Colors.transparent],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MediaPill(
                              label: context.l10n.tr(
                                item.isVideo ? 'VIDEO' : 'PHOTO',
                              ),
                            ),
                            if (item.hasDetectedDetails) ...[
                              const SizedBox(height: 8),
                              _DetectedDetailPill(
                                count: item.detectedPhoneNumbers.length +
                                    item.detectedAddresses.length,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 140),
                          opacity: selectionMode ? 1 : 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primary
                                  : Colors.black.withValues(alpha: 0.28),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primary
                                    : Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Icon(
                              selected
                                  ? Icons.check_rounded
                                  : Icons.circle_outlined,
                              size: 16,
                              color: selected
                                  ? const Color(0xFF003061)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.isKeptForever
                            ? context.l10n.tr('Kept Forever')
                            : context.l10n
                                .timerLabelFromString(item.timerLabel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      item.isVideo
                          ? Icons.play_circle_fill_rounded
                          : Icons.photo_rounded,
                      color:
                          item.isVideo ? AppTheme.tertiary : AppTheme.primary,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.formatRemaining(
                    item.expiresAt,
                    isKeptForever: item.isKeptForever,
                  ),
                  style: TextStyle(
                    color: item.isKeptForever
                        ? AppTheme.secondary
                        : AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.hasDetectedDetails) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.tr('Tap to view detected details'),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({required this.item});

  final PhotoRecord item;

  @override
  Widget build(BuildContext context) {
    if (item.isVideo) {
      return _VideoThumbnailView(filePath: item.filePath);
    }
    return Image.file(
      File(item.filePath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceHigh),
    );
  }
}

class _VideoThumbnailView extends StatefulWidget {
  const _VideoThumbnailView({required this.filePath});

  final String filePath;

  @override
  State<_VideoThumbnailView> createState() => _VideoThumbnailViewState();
}

class _VideoThumbnailViewState extends State<_VideoThumbnailView> {
  static final Map<String, Future<Uint8List?>> _cache =
      <String, Future<Uint8List?>>{};

  late final Future<Uint8List?> _thumbnailFuture = _cache.putIfAbsent(
    widget.filePath,
    () => VideoThumbnail.thumbnailData(
      video: widget.filePath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 420,
      quality: 72,
      timeMs: 900,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF23252B), Color(0xFF111214)],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: AppTheme.primary,
                size: 48,
              ),
            ),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(data, fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: 0.16)),
            const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MediaPill extends StatelessWidget {
  const _MediaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontSize: 10,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetectedDetailPill extends StatelessWidget {
  const _DetectedDetailPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.document_scanner_rounded,
            size: 12,
            color: Color(0xFF003061),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF003061),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVaultState extends StatelessWidget {
  const _EmptyVaultState({required this.filter});

  final _GalleryFilter filter;

  @override
  Widget build(BuildContext context) {
    final title = switch (filter) {
      _GalleryFilter.all => context.l10n.tr('Your vault is empty'),
      _GalleryFilter.photos => context.l10n.tr('No temp photos yet'),
      _GalleryFilter.videos => context.l10n.tr('No temp videos yet'),
    };
    final subtitle = switch (filter) {
      _GalleryFilter.all => context.l10n.tr(
          'Capture a photo or video and it will appear here with its self-destruct timer.',
        ),
      _GalleryFilter.photos => context.l10n.tr(
          'This filter only shows temp photos stored inside TempCam.',
        ),
      _GalleryFilter.videos => context.l10n.tr(
          'This filter only shows temp videos stored inside TempCam.',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.outline, size: 40),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
