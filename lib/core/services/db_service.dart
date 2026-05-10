import 'dart:async';

import 'package:doc_scan_ar/features/library/domain/document.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Single-connection SQLite-backed repository for documents and pages.
///
/// Schema (v2):
///   documents(id, title, created_at)
///   pages(id, document_id, image_path, order_index, ocr_text,
///         ocr_blocks_json)
///
/// `pages.document_id` cascades; deleting a document drops its pages.
/// `pages.ocr_blocks_json` stores the layout-preserving result of an
/// OCR run so the export pipeline can render a clean
/// text-on-white scanned document later (see `OcrBlocks`).
class DbService {
  DbService._(this._db);

  final Database _db;

  static const int _schemaVersion = 2;

  static Future<DbService> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'docscan.db');
    final db = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return DbService._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE documents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE pages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
        image_path TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        ocr_text TEXT,
        ocr_blocks_json TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_pages_doc_order ON pages(document_id, order_index)',
    );
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // v1 → v2: add ocr_blocks_json column. Existing rows get NULL,
      // which the export pipeline reads as "no clean-doc layout
      // available — fall back to the photo".
      await db.execute('ALTER TABLE pages ADD COLUMN ocr_blocks_json TEXT');
    }
  }

  // ---------- documents ----------

  Future<int> createDocument(String title) async {
    return _db.insert('documents', {
      'title': title,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Look up a single document with its joined cover/page-count fields.
  Future<DocumentEntity?> getDocument(int id) async {
    final rows = await _db.rawQuery('''
      SELECT d.id, d.title, d.created_at,
             (SELECT COUNT(*) FROM pages WHERE document_id = d.id) AS page_count,
             (SELECT image_path FROM pages WHERE document_id = d.id
              ORDER BY order_index ASC LIMIT 1) AS cover_image_path
      FROM documents d
      WHERE d.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    return DocumentEntity.fromMap(rows.first);
  }

  Future<List<DocumentEntity>> listDocuments() async {
    // Join page count + first-page cover via a LEFT JOIN.
    final rows = await _db.rawQuery('''
      SELECT d.id, d.title, d.created_at,
             (SELECT COUNT(*) FROM pages WHERE document_id = d.id) AS page_count,
             (SELECT image_path FROM pages WHERE document_id = d.id
              ORDER BY order_index ASC LIMIT 1) AS cover_image_path
      FROM documents d
      ORDER BY d.created_at DESC
    ''');
    return rows.map(DocumentEntity.fromMap).toList();
  }

  Future<void> renameDocument(int id, String title) async {
    await _db.update(
      'documents',
      {'title': title},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDocument(int id) async {
    await _db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- pages ----------

  Future<int> addPage({
    required int documentId,
    required String imagePath,
  }) async {
    final maxOrder = Sqflite.firstIntValue(await _db.rawQuery(
      'SELECT COALESCE(MAX(order_index), -1) FROM pages WHERE document_id = ?',
      [documentId],
    )) ?? -1;
    return _db.insert('pages', {
      'document_id': documentId,
      'image_path': imagePath,
      'order_index': maxOrder + 1,
      'ocr_text': null,
      'ocr_blocks_json': null,
    });
  }

  Future<List<PageEntity>> listPages(int documentId) async {
    final rows = await _db.query(
      'pages',
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'order_index ASC',
    );
    return rows.map(PageEntity.fromMap).toList();
  }

  /// Persist the OCR text for a page. If [blocksJson] is provided,
  /// also persist the layout-preserving block structure used by the
  /// clean-document exporter.
  Future<void> updatePageOcr(
    int id,
    String ocrText, {
    String? blocksJson,
  }) async {
    await _db.update(
      'pages',
      {
        'ocr_text': ocrText,
        if (blocksJson != null) 'ocr_blocks_json': blocksJson,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePage(int id) async {
    await _db.delete('pages', where: 'id = ?', whereArgs: [id]);
  }

  /// Persists a new ordering for the given document. Each tuple is
  /// `(pageId, newOrderIndex)`.
  Future<void> reorderPages(
    int documentId,
    List<(int, int)> ordering,
  ) async {
    final batch = _db.batch();
    for (final (id, idx) in ordering) {
      batch.update(
        'pages',
        {'order_index': idx},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() => _db.close();
}

/// Async provider that opens the DB lazily on first read.
final dbServiceProvider = FutureProvider<DbService>((ref) async {
  final db = await DbService.open();
  ref.onDispose(db.close);
  return db;
});
