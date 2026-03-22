import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tempcam/src/core/constants/app_strings.dart';
import 'package:tempcam/src/features/photos/presentation/photo_detail_screen.dart';
import 'package:tempcam/src/shared/models/photo_record.dart';
import 'package:tempcam/src/shared/state/app_controller.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';
import 'package:tempcam/src/shared/widgets/top_bar.dart';

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

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final TextEditingController _searchController = TextEditingController();

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
        final photos = controller.photosMatching(_searchController.text);
        final expiringSoon = photos.where((photo) => !photo.isKeptForever).take(3).toList();
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
                  child: Column(
                    children: [
                      const TopBar(
                        title: AppStrings.appName,
                        leading: Icon(Icons.grid_view_rounded, color: AppTheme.primary, size: 22),
                        trailing: Icon(Icons.flash_on_rounded, color: AppTheme.primary, size: 22),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your TempCam',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Managed volatility for your visual memory.',
                              style: TextStyle(color: AppTheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 22),
                            TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(color: AppTheme.onSurface),
                              decoration: InputDecoration(
                                hintText: 'Search temporary archive...',
                                hintStyle: const TextStyle(color: AppTheme.outline),
                                filled: true,
                                fillColor: AppTheme.surfaceContainer,
                                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(999),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (expiringSoon.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _ExpiringSoonSection(photos: expiringSoon),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'All Temporary Photos',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            _roundAction(Icons.sort_rounded),
                            const SizedBox(width: 10),
                            _roundAction(Icons.filter_list_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (photos.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyPhotosState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _PhotoTile(photo: photos[index]),
                        childCount: photos.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: .76,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.primaryContainer,
            foregroundColor: const Color(0xFF002A55),
            onPressed: () => controller.setTab(1),
            child: const Icon(Icons.camera_alt_rounded),
          ),
        );
      },
    );
  }

  Widget _roundAction(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(color: AppTheme.surfaceHigh, shape: BoxShape.circle),
      child: Icon(icon, color: AppTheme.onSurfaceVariant, size: 20),
    );
  }
}

class _ExpiringSoonSection extends StatelessWidget {
  const _ExpiringSoonSection({required this.photos});

  final List<PhotoRecord> photos;

  @override
  Widget build(BuildContext context) {
    final primary = photos.first;
    final secondary = photos.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Expiring Soon',
              style: TextStyle(fontFamily: 'Manrope', fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              'HIGH PRIORITY',
              style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: AppTheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 240,
                child: _LargePreviewCard(photo: primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: secondary
                    .map(
                      (photo) => Padding(
                        padding: EdgeInsets.only(bottom: photo == secondary.last ? 0 : 12),
                        child: SizedBox(height: 114, child: _LargePreviewCard(photo: photo)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LargePreviewCard extends StatelessWidget {
  const _LargePreviewCard({required this.photo});

  final PhotoRecord photo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context, photo),
      borderRadius: BorderRadius.circular(22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.filePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceContainer),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xAA131313), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  _formatRemaining(photo.expiresAt, isKeptForever: photo.isKeptForever),
                  style: const TextStyle(color: Color(0xFF3C2F00), fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, PhotoRecord photo) async {
    final controller = context.read<AppController>();
    final ok = await controller.unlockForSensitiveAccess();
    if (!context.mounted || !ok) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PhotoDetailScreen(photoId: photo.id)),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final PhotoRecord photo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.filePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceContainer),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Color(0xAA131313), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _formatRemaining(photo.expiresAt, isKeptForever: photo.isKeptForever),
                  style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final controller = context.read<AppController>();
    final ok = await controller.unlockForSensitiveAccess();
    if (!context.mounted || !ok) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PhotoDetailScreen(photoId: photo.id)),
    );
  }
}

class _EmptyPhotosState extends StatelessWidget {
  const _EmptyPhotosState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: AppTheme.surfaceContainer,
              child: Icon(Icons.photo_library_outlined, color: AppTheme.outline, size: 36),
            ),
            SizedBox(height: 20),
            Text(
              'Captured moments, only as long as you need them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
