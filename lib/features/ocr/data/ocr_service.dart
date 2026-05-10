import 'dart:async';
import 'dart:io';

import 'package:doc_scan_ar/core/services/db_service.dart';
import 'package:doc_scan_ar/core/services/logger.dart';
import 'package:doc_scan_ar/features/library/data/library_providers.dart';
import 'package:doc_scan_ar/features/library/domain/document.dart';
import 'package:doc_scan_ar/features/ocr/data/ocr_preprocessor.dart';
import 'package:doc_scan_ar/features/ocr/domain/ocr_blocks.dart';
import 'package:doc_scan_ar/features/settings/data/settings_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

const _log = Logger('OcrService');

/// Per-page result of an OCR run. Mirrors what we persist plus a few
/// stats useful for the progress UI.
@immutable
class OcrPageResult {
  const OcrPageResult({
    required this.pageId,
    required this.text,
    required this.blocks,
    required this.lines,
    required this.script,
  });

  final int pageId;
  final String text;
  final int blocks;
  final int lines;
  final TextRecognitionScript script;
}

/// Reports progress while OCR runs through every page of a document.
typedef OcrProgressCallback = void Function(OcrProgress p);

@immutable
class OcrProgress {
  const OcrProgress({
    required this.completed,
    required this.total,
    this.lastError,
    this.lastResult,
  });

  final int completed;
  final int total;
  final String? lastError;
  final OcrPageResult? lastResult;

  double get fraction => total == 0 ? 1 : completed / total;
}

/// Runs Google ML Kit text recognition (offline, on-device) over a
/// single page or every page of a document, with image preprocessing,
/// per-script recognizer caching, reading-order reconstruction, and
/// optional Latin fallback for non-Latin scripts.
class OcrService {
  OcrService(this._ref);

  final Ref _ref;
  final Map<TextRecognitionScript, TextRecognizer> _recognizers = {};

  TextRecognizer _recognizer(TextRecognitionScript script) {
    return _recognizers.putIfAbsent(
      script,
      () => TextRecognizer(script: script),
    );
  }

  /// Run OCR on [page]. The image is preprocessed in an isolate first
  /// (EXIF rotation + up-scaling + tonal lift + sharpen), then handed
  /// to ML Kit. If [script] is non-Latin and yields noticeably less
  /// text than a Latin pass would, the Latin output is used instead —
  /// users who pick "Japanese" but feed in a mostly-English page still
  /// get good results.
  Future<OcrPageResult> runOnPage(
    PageEntity page, {
    TextRecognitionScript? script,
    bool autoFallbackToLatin = true,
  }) async {
    final original = File(page.imagePath);
    if (!original.existsSync()) {
      throw StateError('Page image is missing: ${page.imagePath}');
    }
    final selected = script ?? _scriptFromSettings();

    // Preprocessing must run on a worker isolate — it decodes a JPEG
    // and rebuilds it with sharpening + scaling, which is CPU-bound and
    // would otherwise stall the UI for hundreds of ms per page.
    final tempDir = await resolveOcrTempDir();
    final pre = await compute(
      preprocessForOcr,
      OcrPreprocessArgs(inputPath: original.path, tempDir: tempDir),
    );
    final processed = File(pre.outputPath);

    try {
      final input = InputImage.fromFile(processed);
      var recognized = await _recognizer(selected).processImage(input);
      var usedScript = selected;

      // If a non-Latin pass returned very little text, the source page
      // probably wasn't in that script. Fall back to Latin and keep
      // whichever pass produced more characters of recognized text.
      if (autoFallbackToLatin &&
          selected != TextRecognitionScript.latin &&
          _isUnderwhelming(recognized)) {
        final latin = await _recognizer(TextRecognitionScript.latin)
            .processImage(input);
        if (latin.text.length > recognized.text.length) {
          recognized = latin;
          usedScript = TextRecognitionScript.latin;
        }
      }

      final structured = _reconstruct(recognized);
      final layout = _toLayout(
        recognized,
        original,
        processedWidth: pre.width,
        processedHeight: pre.height,
      );
      final blocksJson = layout?.encode();

      final db = await _ref.read(dbServiceProvider.future);
      await db.updatePageOcr(
        page.id,
        structured,
        blocksJson: blocksJson,
      );
      _ref.invalidate(documentPagesProvider(page.documentId));

      final lines = recognized.blocks.fold<int>(
        0,
        (sum, b) => sum + b.lines.length,
      );
      return OcrPageResult(
        pageId: page.id,
        text: structured,
        blocks: recognized.blocks.length,
        lines: lines,
        script: usedScript,
      );
    } finally {
      if (pre.isTempFile && processed.existsSync()) {
        try {
          processed.deleteSync();
        } on Object catch (e) {
          _log.w('Could not clean OCR temp ${processed.path}: $e');
        }
      }
    }
  }

  /// Run OCR over [pages] sequentially. Already-OCR'd pages are
  /// skipped unless [force] is set. Errors are swallowed per-page and
  /// surfaced through [onProgress] so a single bad scan doesn't cancel
  /// the whole document.
  Future<void> runOnAll(
    List<PageEntity> pages, {
    OcrProgressCallback? onProgress,
    TextRecognitionScript? script,
    bool force = false,
  }) async {
    final total = pages.length;
    var completed = 0;
    onProgress?.call(OcrProgress(completed: 0, total: total));
    for (final page in pages) {
      if (!force &&
          page.ocrText != null &&
          page.ocrText!.trim().isNotEmpty) {
        completed++;
        onProgress?.call(OcrProgress(completed: completed, total: total));
        continue;
      }
      try {
        final result = await runOnPage(page, script: script);
        completed++;
        onProgress?.call(
          OcrProgress(
            completed: completed,
            total: total,
            lastResult: result,
          ),
        );
      } on Object catch (e, st) {
        _log.e('OCR failed for page ${page.id}', e, st);
        completed++;
        onProgress?.call(
          OcrProgress(
            completed: completed,
            total: total,
            lastError: '$e',
          ),
        );
      }
    }
  }

  TextRecognitionScript _scriptFromSettings() {
    try {
      return _ref.read(settingsControllerProvider).ocrScript;
    } on Object {
      return TextRecognitionScript.latin;
    }
  }

  /// "Empty enough" heuristic: ML Kit returns the empty string when it
  /// finds nothing, but on a misclassified script it commonly returns
  /// only a few stray glyphs. Treat anything under 8 alpha-numerics as
  /// underwhelming and worth re-trying with Latin.
  bool _isUnderwhelming(RecognizedText t) {
    final alphaNums = RegExp('[A-Za-z0-9]').allMatches(t.text).length;
    return alphaNums < 8;
  }

  /// Reconstruct a sensible reading order from ML Kit's blocks.
  ///
  /// `recognized.text` already concatenates blocks by `\n`, but block
  /// ordering in the returned list is implementation-defined — for
  /// multi-column layouts and rotated text it can be wildly off. We
  /// re-sort blocks top-to-bottom, breaking ties by left-to-right when
  /// two blocks sit on roughly the same row. Lines inside a block keep
  /// ML Kit's order (which is reliable within a block).
  String _reconstruct(RecognizedText recognized) {
    if (recognized.blocks.isEmpty) return recognized.text.trim();
    final sorted = [...recognized.blocks]..sort((a, b) {
      final at = a.boundingBox.top;
      final bt = b.boundingBox.top;
      final h = (a.boundingBox.height + b.boundingBox.height) / 2;
      if ((at - bt).abs() < h * 0.55) {
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return at.compareTo(bt);
    });
    final out = StringBuffer();
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0) out.write('\n\n');
      out.write(sorted[i].text.trim());
    }
    return out.toString();
  }

  /// Capture the recognized blocks as a layout-preserving structure so
  /// the export pipeline can later render a clean text-on-white page.
  ///
  /// We measure boxes against the *processed* image (post-preprocess)
  /// because that's the coordinate space ML Kit returned. The
  /// dimensions come from the preprocessor; if it didn't run (small
  /// image, or unreadable input) we fall back to decoding the original
  /// to discover its dimensions, since the box coords match it 1:1 in
  /// that path.
  OcrBlocks? _toLayout(
    RecognizedText recognized,
    File originalSource, {
    int processedWidth = 0,
    int processedHeight = 0,
  }) {
    if (recognized.blocks.isEmpty) return null;
    var w = processedWidth;
    var h = processedHeight;
    if (w == 0 || h == 0) {
      try {
        final bytes = originalSource.readAsBytesSync();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          w = decoded.width;
          h = decoded.height;
        }
      } on Object {/* fall through */}
    }
    if (w == 0 || h == 0) return null;

    // Block ordering matches `_reconstruct`: top-to-bottom, ties on
    // the same row break left-to-right.
    final sorted = [...recognized.blocks]..sort((a, b) {
      final at = a.boundingBox.top;
      final bt = b.boundingBox.top;
      final bh = (a.boundingBox.height + b.boundingBox.height) / 2;
      if ((at - bt).abs() < bh * 0.55) {
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return at.compareTo(bt);
    });
    return OcrBlocks(
      imageWidth: w,
      imageHeight: h,
      blocks: [
        for (final b in sorted)
          OcrBlockLayout(
            left: b.boundingBox.left,
            top: b.boundingBox.top,
            width: b.boundingBox.width,
            height: b.boundingBox.height,
            lines: [for (final l in b.lines) l.text],
          ),
      ],
    );
  }

  void dispose() {
    for (final r in _recognizers.values) {
      unawaited(r.close());
    }
    _recognizers.clear();
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  final svc = OcrService(ref);
  ref.onDispose(svc.dispose);
  return svc;
});
