import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Layout-preserving OCR result. Captured at recognition time and
/// persisted to `pages.ocr_blocks_json` so we can later re-render the
/// page as a clean text-on-white "scanned document" without keeping
/// the original photo.
@immutable
class OcrBlocks {
  const OcrBlocks({
    required this.imageWidth,
    required this.imageHeight,
    required this.blocks,
  });

  factory OcrBlocks.fromJson(Map<String, Object?> json) {
    final w = (json['w'] as num?)?.toInt() ?? 0;
    final h = (json['h'] as num?)?.toInt() ?? 0;
    final raw = json['b'];
    final blocks = <OcrBlockLayout>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          blocks.add(
            OcrBlockLayout.fromJson(item.cast<String, Object?>()),
          );
        }
      }
    }
    return OcrBlocks(
      imageWidth: w,
      imageHeight: h,
      blocks: blocks,
    );
  }

  static OcrBlocks? tryDecode(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final decoded = jsonDecode(s);
      if (decoded is! Map) return null;
      return OcrBlocks.fromJson(decoded.cast<String, Object?>());
    } on Object {
      return null;
    }
  }

  /// Pixel dimensions of the image the blocks were measured against.
  /// Block bounding boxes are in the same pixel coordinate space.
  final int imageWidth;
  final int imageHeight;

  final List<OcrBlockLayout> blocks;

  bool get isEmpty => blocks.isEmpty;
  bool get isNotEmpty => blocks.isNotEmpty;

  Map<String, Object?> toJson() => {
        'w': imageWidth,
        'h': imageHeight,
        'b': [for (final b in blocks) b.toJson()],
      };

  String encode() => jsonEncode(toJson());
}

/// One ML Kit text block: bounding box (in image pixels) and the lines
/// of text it contains. Lines are kept separated so the renderer can
/// reproduce line breaks faithfully without trying to wrap or reflow.
@immutable
class OcrBlockLayout {
  const OcrBlockLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.lines,
  });

  factory OcrBlockLayout.fromJson(Map<String, Object?> json) {
    final lines = <String>[];
    final raw = json['L'];
    if (raw is List) {
      for (final item in raw) {
        lines.add(item?.toString() ?? '');
      }
    }
    return OcrBlockLayout(
      left: (json['l'] as num?)?.toDouble() ?? 0,
      top: (json['t'] as num?)?.toDouble() ?? 0,
      width: (json['w'] as num?)?.toDouble() ?? 0,
      height: (json['h'] as num?)?.toDouble() ?? 0,
      lines: lines,
    );
  }

  final double left;
  final double top;
  final double width;
  final double height;
  final List<String> lines;

  double get right => left + width;
  double get bottom => top + height;

  String get text => lines.join('\n');

  Map<String, Object?> toJson() => {
        'l': left,
        't': top,
        'w': width,
        'h': height,
        'L': lines,
      };
}
