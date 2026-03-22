import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoStorageService {
  Future<Directory> _photosDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'tempcam', 'photos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> persistCapture({
    required String id,
    required String sourcePath,
  }) async {
    final dir = await _photosDirectory();
    final targetPath = p.join(dir.path, '$id.jpg');
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

