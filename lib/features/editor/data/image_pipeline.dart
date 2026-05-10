import 'dart:typed_data';

import 'package:doc_scan_ar/features/editor/domain/filter_kind.dart';
import 'package:doc_scan_ar/features/scanner/domain/quad.dart';
import 'package:image/image.dart' as img;

/// Pure-Dart image pipeline: perspective rectification + 5 filters. All
/// methods are synchronous and CPU-only; callers should run them in an
/// isolate via `compute()` if image size is large (>2 MP).
class ImagePipeline {
  const ImagePipeline._();

  /// Decode a JPEG buffer.
  static img.Image? decodeJpeg(Uint8List bytes) => img.decodeJpg(bytes);

  /// Encode an [img.Image] to JPEG bytes.
  static Uint8List encodeJpeg(img.Image image, {int quality = 92}) {
    return img.encodeJpg(image, quality: quality);
  }

  /// Warps a source image so that the 4 normalized corners ([quad]) become a
  /// rectified rectangle. Output dimensions are derived from the longest edge
  /// pair of the quad to keep aspect.
  static img.Image rectify(img.Image source, Quad quad) {
    final scaled = quad.scaledTo(
      source.width.toDouble(),
      source.height.toDouble(),
    );
    final widthTop = (scaled.tr - scaled.tl).distance;
    final widthBottom = (scaled.br - scaled.bl).distance;
    final heightLeft = (scaled.bl - scaled.tl).distance;
    final heightRight = (scaled.br - scaled.tr).distance;
    final outW = (widthTop > widthBottom ? widthTop : widthBottom).round();
    final outH =
        (heightLeft > heightRight ? heightLeft : heightRight).round();
    // Normalized coords can reach 1.0, which scales to width/height (one
    // past the last valid pixel). Clamp so copyRectify never samples out of
    // bounds at u=1, v=1.
    final maxX = source.width - 1.0;
    final maxY = source.height - 1.0;
    img.Point clamped(double x, double y) =>
        img.Point(x.clamp(0.0, maxX), y.clamp(0.0, maxY));
    return img.copyRectify(
      source,
      topLeft: clamped(scaled.tl.dx, scaled.tl.dy),
      topRight: clamped(scaled.tr.dx, scaled.tr.dy),
      bottomLeft: clamped(scaled.bl.dx, scaled.bl.dy),
      bottomRight: clamped(scaled.br.dx, scaled.br.dy),
      toImage: img.Image(
        width: outW,
        height: outH,
        numChannels: source.numChannels,
      ),
    );
  }

  static img.Image applyFilter(img.Image source, FilterKind kind) {
    return switch (kind) {
      FilterKind.original => img.Image.from(source),
      FilterKind.autoEnhance => _autoEnhance(source),
      FilterKind.grayscale => img.grayscale(img.Image.from(source)),
      FilterKind.blackAndWhite => _blackAndWhite(source),
      FilterKind.magicColor => _magicColor(source),
    };
  }

  static img.Image _autoEnhance(img.Image source) {
    final c = img.Image.from(source);
    return img.adjustColor(c, contrast: 1.18, brightness: 1.05, saturation: 1.05);
  }

  static img.Image _magicColor(img.Image source) {
    final c = img.Image.from(source);
    return img.adjustColor(c, saturation: 1.45, contrast: 1.12, gamma: 0.95);
  }

  /// Adaptive-ish black-and-white: grayscale → local mean threshold using a
  /// blurred copy as the threshold reference. Keeps text crisp on uneven
  /// lighting better than a single global threshold.
  static img.Image _blackAndWhite(img.Image source) {
    final gray = img.grayscale(img.Image.from(source));
    final blurred = img.gaussianBlur(img.Image.from(gray), radius: 12);
    final w = gray.width;
    final h = gray.height;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final pix = gray.getPixel(x, y).r;
        final ref = blurred.getPixel(x, y).r;
        final v = pix < ref - 8 ? 0 : 255;
        gray.setPixelRgb(x, y, v, v, v);
      }
    }
    return gray;
  }
}
