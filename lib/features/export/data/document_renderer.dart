import 'dart:typed_data';

import 'package:doc_scan_ar/features/ocr/domain/ocr_blocks.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Renders OCR'd pages as clean **scanned-document** output: a white
/// page with the recognised text positioned at the same coordinates
/// it occupied in the original photo. The point is to ship something
/// that looks like a freshly-scanned document — not a photo pasted on
/// a white sheet.
///
/// Supported output:
///   • [buildCleanPdfPage] — a `pw.Page` you can add to a `pw.Document`
///   • [renderCleanJpg]    — a JPG byte buffer (built via Printing.raster
///                           so font rendering matches the PDF)
class DocumentRenderer {
  const DocumentRenderer._();

  /// Build a clean PDF page from layout-preserving OCR blocks.
  ///
  /// Page format: the same width/height (in PDF points) as the source
  /// image's pixel dimensions. Treating one source pixel as one point
  /// yields the original aspect ratio at native resolution and lets
  /// the block coords drop in 1:1.
  static pw.Page buildCleanPdfPage(OcrBlocks blocks) {
    final pageW = blocks.imageWidth.toDouble();
    final pageH = blocks.imageHeight.toDouble();
    return pw.Page(
      pageFormat: PdfPageFormat(pageW, pageH, marginAll: 0),
      build: (context) {
        return pw.Container(
          width: pageW,
          height: pageH,
          color: PdfColors.white,
          child: pw.Stack(
            children: [
              for (final block in blocks.blocks)
                pw.Positioned(
                  left: block.left,
                  top: block.top,
                  child: _BlockText(block: block),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Render the clean document as a JPG byte buffer.
  ///
  /// Internally we build a single-page PDF and rasterize it at
  /// 144 dpi — about twice the native resolution so the resulting
  /// JPG looks crisp on phone screens without ballooning the file
  /// size.
  static Future<Uint8List> renderCleanJpg(
    OcrBlocks blocks, {
    int dpi = 144,
    int jpegQuality = 88,
  }) async {
    final pdf = pw.Document()..addPage(buildCleanPdfPage(blocks));
    final pdfBytes = await pdf.save();

    Uint8List? pngBytes;
    await for (final raster in Printing.raster(
      pdfBytes,
      dpi: dpi.toDouble(),
    )) {
      pngBytes = await raster.toPng();
      break;
    }
    if (pngBytes == null) {
      // Printing.raster declined (no Play services?). Fall back to a
      // pure-Dart text render so the export still produces something.
      return _renderJpgFallback(
        blocks,
        targetWidth: blocks.imageWidth,
        jpegQuality: jpegQuality,
      );
    }
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      return _renderJpgFallback(
        blocks,
        targetWidth: blocks.imageWidth,
        jpegQuality: jpegQuality,
      );
    }
    return Uint8List.fromList(
      img.encodeJpg(decoded, quality: jpegQuality),
    );
  }

  /// Pure-Dart fallback when Printing.raster is unavailable. Uses the
  /// `image` package's bitmap fonts (Arial 14/24/48). Output is less
  /// pretty than the rasterised PDF but the layout is preserved.
  static Uint8List _renderJpgFallback(
    OcrBlocks blocks, {
    required int targetWidth,
    required int jpegQuality,
  }) {
    final scale = targetWidth / blocks.imageWidth;
    final outW = targetWidth;
    final outH = (blocks.imageHeight * scale).round();
    final canvas = img.Image(width: outW, height: outH);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    final black = img.ColorRgb8(0, 0, 0);
    for (final block in blocks.blocks) {
      final lineCount =
          block.lines.isEmpty ? 1 : block.lines.length;
      final blockHeightPx = block.height * scale;
      final lineHeightPx = blockHeightPx / lineCount;
      final font = _bitmapFontForLineHeight(lineHeightPx);
      var lineY = (block.top * scale).round();
      for (final line in block.lines) {
        img.drawString(
          canvas,
          line,
          font: font,
          x: (block.left * scale).round(),
          y: lineY,
          color: black,
        );
        lineY += lineHeightPx.round();
      }
    }

    return Uint8List.fromList(img.encodeJpg(canvas, quality: jpegQuality));
  }

  /// Pick the largest bitmap font that fits the target line height.
  static img.BitmapFont _bitmapFontForLineHeight(double px) {
    if (px >= 56) return img.arial48;
    if (px >= 28) return img.arial24;
    return img.arial14;
  }
}

/// One block of text, sized so that no individual line overflows its
/// horizontal slot. We render line by line because ML Kit's per-block
/// `text` already breaks lines where the original image did, and we
/// want to preserve that structure.
class _BlockText extends pw.StatelessWidget {
  _BlockText({required this.block});

  final OcrBlockLayout block;

  @override
  pw.Widget build(pw.Context context) {
    final lineCount = block.lines.isEmpty ? 1 : block.lines.length;
    final lineHeight = block.height / lineCount;
    final fontSize = (lineHeight * 0.78).clamp(6.0, 72.0);
    return pw.Container(
      width: block.width,
      height: block.height,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final line in block.lines)
            pw.SizedBox(
              width: block.width,
              height: lineHeight,
              child: pw.FittedBox(
                alignment: pw.Alignment.centerLeft,
                fit: pw.BoxFit.scaleDown,
                child: pw.Text(
                  line.isEmpty ? ' ' : line,
                  style: pw.TextStyle(
                    fontSize: fontSize,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
