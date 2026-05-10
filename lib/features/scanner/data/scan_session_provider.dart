import 'dart:typed_data';

import 'package:doc_scan_ar/core/services/db_service.dart';
import 'package:doc_scan_ar/core/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-progress multi-page scan. UI appends a JPEG buffer per captured page;
/// on "Done", we materialize a `documents` row + N `pages` rows on disk.
class ScanSession {
  const ScanSession({this.pages = const []});

  final List<Uint8List> pages;

  ScanSession addPage(Uint8List jpeg) =>
      ScanSession(pages: [...pages, jpeg]);

  ScanSession removePage(int index) {
    final next = [...pages]..removeAt(index);
    return ScanSession(pages: next);
  }

  ScanSession reset() => const ScanSession();
}

class ScanSessionController extends StateNotifier<ScanSession> {
  ScanSessionController(this._ref) : super(const ScanSession());

  final Ref _ref;

  void addPage(Uint8List jpeg) => state = state.addPage(jpeg);
  void removePage(int i) => state = state.removePage(i);
  void clear() => state = state.reset();

  /// Persist the current session as a new document. Returns the new
  /// document's ID. Resets the session on success.
  Future<int> saveAsNewDocument({required String title}) async {
    final db = await _ref.read(dbServiceProvider.future);
    final storage = _ref.read(storageServiceProvider);
    final docId = await db.createDocument(title);
    for (final bytes in state.pages) {
      final path = await storage.savePageJpeg(
        documentId: docId,
        bytes: bytes,
      );
      await db.addPage(documentId: docId, imagePath: path);
    }
    state = state.reset();
    return docId;
  }
}

final scanSessionProvider =
    StateNotifierProvider<ScanSessionController, ScanSession>((ref) {
  return ScanSessionController(ref);
});
