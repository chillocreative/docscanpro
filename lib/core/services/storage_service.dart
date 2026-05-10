import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persists captured page images inside the app's documents directory under
/// `pages/<docId>/<timestamp>.jpg`. Returns an absolute path that is safe to
/// store in the DB.
class StorageService {
  Future<String> savePageJpeg({
    required int documentId,
    required Uint8List bytes,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final pagesDir = Directory(p.join(dir.path, 'pages', '$documentId'));
    if (!pagesDir.existsSync()) {
      await pagesDir.create(recursive: true);
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(p.join(pagesDir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> deletePageFile(String path) async {
    final f = File(path);
    if (f.existsSync()) await f.delete();
  }
}

final storageServiceProvider = Provider<StorageService>((_) => StorageService());
