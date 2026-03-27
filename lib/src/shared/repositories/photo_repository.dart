import 'dart:io';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/photo_record.dart';
import '../services/photo_storage_service.dart';

class PhotoRepository {
  PhotoRepository(this._box, this._storageService);

  final Box<PhotoRecord> _box;
  final PhotoStorageService _storageService;
  final Uuid _uuid = const Uuid();

  List<PhotoRecord> readAllSorted() {
    final items = _box.values.toList();
    items.sort((a, b) {
      if (a.isKeptForever && !b.isKeptForever) {
        return 1;
      }
      if (!a.isKeptForever && b.isKeptForever) {
        return -1;
      }
      final aExpiry = a.expiresAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bExpiry = b.expiresAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aExpiry.compareTo(bExpiry);
    });
    return items;
  }

  Future<PhotoRecord> createFromCapture({
    required String sourcePath,
    required AppTimerOption timer,
    MediaType mediaType = MediaType.photo,
  }) async {
    final id = _uuid.v4();
    final storedPath = await _storageService.persistCapture(
      id: id,
      sourcePath: sourcePath,
      mediaType: mediaType,
    );
    final now = DateTime.now();
    final record = PhotoRecord(
      id: id,
      filePath: storedPath,
      createdAt: now,
      expiresAt: now.add(timer.duration),
      isKeptForever: false,
      timerLabel: timer.label,
      mediaType: mediaType,
    );
    await _box.put(id, record);
    return record;
  }

  Future<PhotoRecord> createVideoFromCapture({
    required String sourcePath,
    required AppTimerOption timer,
  }) {
    return createFromCapture(
      sourcePath: sourcePath,
      timer: timer,
      mediaType: MediaType.video,
    );
  }

  Future<void> deleteNow(PhotoRecord record) async {
    await _storageService.deleteIfExists(record.filePath);
    await _box.delete(record.id);
  }

  Future<void> deleteMany(Iterable<PhotoRecord> records) async {
    final ids = <String>[];
    for (final record in records) {
      await _storageService.deleteIfExists(record.filePath);
      ids.add(record.id);
    }
    if (ids.isNotEmpty) {
      await _box.deleteAll(ids);
    }
  }

  Future<void> keepForever(PhotoRecord record) async {
    final updated = record.copyWith(
      expiresAt: null,
      isKeptForever: true,
      timerLabel: 'Forever',
    );
    await _box.put(record.id, updated);
  }

  Future<void> extend(PhotoRecord record, AppTimerOption timer) async {
    final base = record.expiresAt != null && record.expiresAt!.isAfter(DateTime.now())
        ? record.expiresAt!
        : DateTime.now();
    final updated = record.copyWith(
      expiresAt: base.add(timer.duration),
      isKeptForever: false,
      timerLabel: timer.label,
    );
    await _box.put(record.id, updated);
  }

  Future<List<PhotoRecord>> cleanupExpired() async {
    final expired = _box.values.where((item) => item.isExpired).toList();
    for (final photo in expired) {
      await _storageService.deleteIfExists(photo.filePath);
      await _box.delete(photo.id);
    }
    return expired;
  }

  Future<File?> lastThumbnailFileFromSorted(List<PhotoRecord> items) async {
    for (final item in items.reversed) {
      if (!item.isPhoto) {
        continue;
      }
      final file = File(item.filePath);
      if (await file.exists()) {
        return file;
      }
    }
    return null;
  }

  Future<File?> lastThumbnailFile() async {
    return lastThumbnailFileFromSorted(readAllSorted());
  }
}
