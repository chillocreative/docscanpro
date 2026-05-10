import 'dart:io';
import 'dart:typed_data';

import 'package:doc_scan_ar/core/services/logger.dart';
import 'package:doc_scan_ar/features/export/data/document_renderer.dart';
import 'package:doc_scan_ar/features/library/domain/document.dart';
import 'package:doc_scan_ar/features/ocr/domain/ocr_blocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

const _log = Logger('ExportService');

/// Exports a [DocumentEntity] as a PDF or as one JPG per page, then opens the
/// system share sheet so the user can drop them anywhere (Drive, Photos,
/// email, etc.). Files land in `<external>/DocScanAR/{Documents,Pictures}/`.
///
/// Two render paths run side-by-side:
///   * **Photo** (default): the rectified scan, edge-to-edge, on a
///     PDF page sized to match the image's aspect ratio. No A4-style
///     letterbox margins.
///   * **Clean document**: when a page has OCR layout data
///     (`PageEntity.ocrBlocksJson`), the renderer reproduces the
///     document as crisp text on a white background — what a real
///     scanner would output, not a photo of paper.
class ExportService {
  Future<File> exportPdf({
    required DocumentEntity doc,
    required List<PageEntity> pages,
  }) async {
    final pdf = pw.Document();
    for (final page in pages) {
      final layout = OcrBlocks.tryDecode(page.ocrBlocksJson);
      if (layout != null && layout.isNotEmpty) {
        pdf.addPage(DocumentRenderer.buildCleanPdfPage(layout));
        continue;
      }
      final f = File(page.imagePath);
      if (!f.existsSync()) continue;
      final bytes = await f.readAsBytes();
      final dims = _decodeDimensions(bytes);
      final pageFormat = PdfPageFormat(
        dims.width.toDouble(),
        dims.height.toDouble(),
        marginAll: 0,
      );
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) => pw.Image(
            pw.MemoryImage(bytes),
            fit: pw.BoxFit.fill,
            width: pageFormat.width,
            height: pageFormat.height,
          ),
        ),
      );
    }
    final dir = await _outputDir('Documents');
    final file = File(p.join(dir.path, '${_safe(doc.title)}.pdf'));
    await file.writeAsBytes(await pdf.save(), flush: true);
    _log.i('PDF saved: ${file.path}');
    return file;
  }

  Future<List<File>> exportJpgs({
    required DocumentEntity doc,
    required List<PageEntity> pages,
  }) async {
    final dir = await _outputDir('Pictures');
    final out = <File>[];
    for (final (i, page) in pages.indexed) {
      final dst = File(p.join(
        dir.path,
        '${_safe(doc.title)}_p${i + 1}.jpg',
      ));
      final layout = OcrBlocks.tryDecode(page.ocrBlocksJson);
      if (layout != null && layout.isNotEmpty) {
        try {
          final bytes = await DocumentRenderer.renderCleanJpg(layout);
          await dst.writeAsBytes(bytes, flush: true);
          out.add(dst);
          continue;
        } on Object catch (e, st) {
          // Renderer failure shouldn't abort the export — fall through
          // to the photo path so the user still gets *something*.
          _log.w('Clean-doc JPG render failed for page ${page.id}: '
              '$e\n$st');
        }
      }
      final src = File(page.imagePath);
      if (!src.existsSync()) continue;
      await dst.writeAsBytes(await src.readAsBytes(), flush: true);
      out.add(dst);
    }
    _log.i('JPGs saved: ${out.length}');
    return out;
  }

  Future<File?> exportTxt({
    required DocumentEntity doc,
    required List<PageEntity> pages,
  }) async {
    final body = StringBuffer();
    var any = false;
    for (final (i, page) in pages.indexed) {
      if (page.ocrText == null || page.ocrText!.isEmpty) continue;
      any = true;
      if (i > 0) body.writeln();
      body
        ..writeln('--- Page ${i + 1} ---')
        ..writeln(page.ocrText);
    }
    if (!any) return null;
    final dir = await _outputDir('Documents');
    final file = File(p.join(dir.path, '${_safe(doc.title)}.txt'));
    await file.writeAsString(body.toString(), flush: true);
    return file;
  }

  Future<void> share(List<File> files, {String? subject}) async {
    if (files.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          for (final f in files) XFile(f.path),
        ],
        subject: subject,
      ),
    );
  }

  Future<Directory> _outputDir(String which) async {
    // App-specific external directory — present on Android, doesn't need a
    // runtime permission. Visible at /Android/data/<pkg>/files/<which>/DocScanAR
    final base = await getExternalStorageDirectory();
    final root = base ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, which, 'DocScanAR'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  String _safe(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w\-. ]'), '_').trim();
    return cleaned.isEmpty ? 'document' : cleaned;
  }

  /// Cheap dimension probe — only decodes enough of the JPEG/PNG
  /// header to learn width × height, which is what the PDF page format
  /// needs. Falls back to A4 portrait if the image won't decode.
  _ImageDims _decodeDimensions(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const _ImageDims(width: 595, height: 842); // A4 in points
    }
    return _ImageDims(width: decoded.width, height: decoded.height);
  }
}

class _ImageDims {
  const _ImageDims({required this.width, required this.height});
  final int width;
  final int height;
}

final exportServiceProvider = Provider<ExportService>((_) => ExportService());

/// Counts successful exports across the session — drives the M10 interstitial
/// frequency rule (every 3rd export).
class ExportCounter extends Notifier<int> {
  @override
  int build() => 0;
  void increment() => state += 1;
}

final exportCounterProvider =
    NotifierProvider<ExportCounter, int>(ExportCounter.new);

/// Convenience: increment the counter for a successful export. Returns true
/// if the next [Uint8List] action should also trigger an interstitial ad.
bool shouldShowInterstitialAfter(int count) =>
    count > 0 && count % 3 == 0;
