import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/photo_record.dart';

class PhotoStorageService {
  Future<Directory> _privateMediaDirectory(MediaType mediaType) async {
    final root = await getApplicationDocumentsDirectory();
    final folder = mediaType == MediaType.photo ? 'photos' : 'videos';
    final dir = Directory(p.join(root.path, 'tempcam', folder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> persistCapture({
    required String id,
    required String sourcePath,
    required MediaType mediaType,
  }) async {
    final dir = await _privateMediaDirectory(mediaType);
    final extension = p.extension(sourcePath).isEmpty
        ? (mediaType == MediaType.photo ? '.jpg' : '.mp4')
        : p.extension(sourcePath);
    final targetPath = p.join(dir.path, '$id$extension');
    final file = await File(sourcePath).copy(targetPath);
    return file.path;
  }

  Future<void> deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
