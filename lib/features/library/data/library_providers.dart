import 'package:doc_scan_ar/core/services/db_service.dart';
import 'package:doc_scan_ar/features/library/domain/document.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All documents, newest first. Library grid watches this.
final documentsProvider = FutureProvider<List<DocumentEntity>>((ref) async {
  final db = await ref.watch(dbServiceProvider.future);
  return db.listDocuments();
});

/// Pages of a single document, ordered by `order_index`.
final documentPagesProvider =
    FutureProvider.family<List<PageEntity>, int>((ref, docId) async {
  final db = await ref.watch(dbServiceProvider.future);
  return db.listPages(docId);
});
