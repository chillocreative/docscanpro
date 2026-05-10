import 'package:flutter/foundation.dart';

/// A single scanned page belonging to a [DocumentEntity].
@immutable
class PageEntity {
  const PageEntity({
    required this.id,
    required this.documentId,
    required this.imagePath,
    required this.order,
    this.ocrText,
    this.ocrBlocksJson,
  });

  factory PageEntity.fromMap(Map<String, Object?> m) => PageEntity(
        id: m['id']! as int,
        documentId: m['document_id']! as int,
        imagePath: m['image_path']! as String,
        order: m['order_index']! as int,
        ocrText: m['ocr_text'] as String?,
        ocrBlocksJson: m['ocr_blocks_json'] as String?,
      );

  final int id;
  final int documentId;
  final String imagePath;
  final int order;
  final String? ocrText;

  /// Serialized OcrBlocks (image dimensions + per-block geometry +
  /// recognised text). Populated by `OcrService.runOnPage`. Null if
  /// OCR has not been run on this page or the run produced nothing.
  final String? ocrBlocksJson;

  bool get hasOcrLayout =>
      ocrBlocksJson != null && ocrBlocksJson!.isNotEmpty;

  Map<String, Object?> toMap() => {
        'id': id,
        'document_id': documentId,
        'image_path': imagePath,
        'order_index': order,
        'ocr_text': ocrText,
        'ocr_blocks_json': ocrBlocksJson,
      };

  PageEntity copyWith({
    int? order,
    String? ocrText,
    String? ocrBlocksJson,
    String? imagePath,
  }) =>
      PageEntity(
        id: id,
        documentId: documentId,
        imagePath: imagePath ?? this.imagePath,
        order: order ?? this.order,
        ocrText: ocrText ?? this.ocrText,
        ocrBlocksJson: ocrBlocksJson ?? this.ocrBlocksJson,
      );
}

/// A multi-page scanned document.
@immutable
class DocumentEntity {
  const DocumentEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.coverImagePath,
    required this.pageCount,
  });

  factory DocumentEntity.fromMap(Map<String, Object?> m) => DocumentEntity(
        id: m['id']! as int,
        title: m['title']! as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          m['created_at']! as int,
        ),
        coverImagePath: (m['cover_image_path'] as String?) ?? '',
        pageCount: (m['page_count'] as int?) ?? 0,
      );

  final int id;
  final String title;
  final DateTime createdAt;
  final String coverImagePath;
  final int pageCount;
}
