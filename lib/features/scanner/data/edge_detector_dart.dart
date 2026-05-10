import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:camera/camera.dart';
import 'package:doc_scan_ar/features/scanner/domain/edge_detector.dart';
import 'package:doc_scan_ar/features/scanner/domain/quad.dart';
import 'package:image/image.dart' as img;

/// Pure-Dart fallback edge detector. Slower than OpenCV (~3-5 FPS on a
/// mid-range Android device) but ships zero native code.
///
/// Pipeline:
///   1. Convert YUV420 luma plane to a small grayscale image (downsample 4x).
///   2. 3x3 box blur to suppress single-pixel noise.
///   3. Sobel gradient magnitude.
///   4. Adaptive threshold based on the magnitude histogram (mean + k·std).
///   5. Per-quadrant corner search: each of TL/TR/BR/BL is taken as the
///      extreme edge pixel inside its own quadrant, excluding a border
///      margin to avoid latching onto frame-edge artefacts. Each candidate
///      must have at least N other edge pixels within a small radius so a
///      single noisy pixel can't hijack the quad.
class PureDartEdgeDetector extends EdgeDetector {
  PureDartEdgeDetector({
    this.downsample = 4,
    this.minAreaRatio = 0.06,
    this.borderMarginRatio = 0.04,
    this.neighborhoodRadius = 4,
    this.minNeighborhoodHits = 4,
  });

  /// Downsample factor on each axis before processing.
  final int downsample;

  /// Reject quads whose normalized area is below this. Smaller values pick
  /// up documents that don't fill the frame.
  final double minAreaRatio;

  /// Fraction of width/height to ignore at each border. Keeps the camera
  /// preview's own framing artefacts from being mistaken for a document
  /// corner.
  final double borderMarginRatio;

  /// Radius (in downsampled pixels) used to validate a candidate corner.
  final int neighborhoodRadius;

  /// Minimum number of edge pixels that must exist within
  /// [neighborhoodRadius] of a candidate corner for it to be accepted.
  final int minNeighborhoodHits;

  bool _busy = false;

  @override
  Future<Quad?> detect(CameraImage image) async {
    if (_busy) return null;
    _busy = true;
    try {
      return _detectSync(image);
    } finally {
      _busy = false;
    }
  }

  Quad? _detectSync(CameraImage image) {
    if (image.planes.isEmpty) return null;
    final luma = image.planes.first;
    final w = image.width;
    final h = image.height;

    final dw = (w / downsample).round();
    final dh = (h / downsample).round();
    final small = _downsampleLuma(luma.bytes, w, h, luma.bytesPerRow, dw, dh);
    final blurred = _boxBlur3(small, dw, dh);
    final mag = _sobelMagnitude(blurred, dw, dh);
    final edges = _adaptiveThreshold(mag, dw, dh);

    final pts = _quadrantCorners(edges, dw, dh);
    if (pts == null) return null;

    final quad = Quad.fromPoints([
      Offset(pts.tl.dx / dw, pts.tl.dy / dh),
      Offset(pts.tr.dx / dw, pts.tr.dy / dh),
      Offset(pts.br.dx / dw, pts.br.dy / dh),
      Offset(pts.bl.dx / dw, pts.bl.dy / dh),
    ]);
    if (quad.area < minAreaRatio) return null;
    return quad;
  }

  Uint8List _downsampleLuma(
    Uint8List src,
    int w,
    int h,
    int bytesPerRow,
    int dw,
    int dh,
  ) {
    final out = Uint8List(dw * dh);
    final sx = w / dw;
    final sy = h / dh;
    for (var y = 0; y < dh; y++) {
      final srcY = (y * sy).floor();
      final rowStart = srcY * bytesPerRow;
      for (var x = 0; x < dw; x++) {
        final srcX = (x * sx).floor();
        out[y * dw + x] = src[rowStart + srcX];
      }
    }
    return out;
  }

  /// 3x3 box blur — averages each pixel with its 8 neighbours. Cheap,
  /// noticeably reduces sensor noise that otherwise produces stray Sobel
  /// hits.
  Uint8List _boxBlur3(Uint8List src, int w, int h) {
    final out = Uint8List(w * h);
    for (var y = 1; y < h - 1; y++) {
      final yPrev = (y - 1) * w;
      final yCurr = y * w;
      final yNext = (y + 1) * w;
      for (var x = 1; x < w - 1; x++) {
        final s = src[yPrev + x - 1] +
            src[yPrev + x] +
            src[yPrev + x + 1] +
            src[yCurr + x - 1] +
            src[yCurr + x] +
            src[yCurr + x + 1] +
            src[yNext + x - 1] +
            src[yNext + x] +
            src[yNext + x + 1];
        out[yCurr + x] = (s / 9).round();
      }
    }
    // Copy borders unchanged so they aren't black (they'd show up as huge
    // gradients in Sobel otherwise).
    for (var x = 0; x < w; x++) {
      out[x] = src[x];
      out[(h - 1) * w + x] = src[(h - 1) * w + x];
    }
    for (var y = 0; y < h; y++) {
      out[y * w] = src[y * w];
      out[y * w + w - 1] = src[y * w + w - 1];
    }
    return out;
  }

  /// Per-pixel Sobel magnitude (clamped to 0..255). Stored as a Uint8List
  /// so we can run histogram statistics without re-walking floats.
  Uint8List _sobelMagnitude(Uint8List src, int w, int h) {
    final out = Uint8List(w * h);
    int at(int x, int y) => src[y * w + x];
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final gx = -at(x - 1, y - 1) -
            2 * at(x - 1, y) -
            at(x - 1, y + 1) +
            at(x + 1, y - 1) +
            2 * at(x + 1, y) +
            at(x + 1, y + 1);
        final gy = -at(x - 1, y - 1) -
            2 * at(x, y - 1) -
            at(x + 1, y - 1) +
            at(x - 1, y + 1) +
            2 * at(x, y + 1) +
            at(x + 1, y + 1);
        var m = math.sqrt(gx * gx + gy * gy).round();
        if (m > 255) m = 255;
        out[y * w + x] = m;
      }
    }
    return out;
  }

  /// Threshold using mean + k·stddev. Keeps the detector usable across
  /// lit/dim scenes without a hand-tuned absolute threshold.
  Uint8List _adaptiveThreshold(Uint8List mag, int w, int h) {
    var sum = 0;
    var sumSq = 0;
    final n = mag.length;
    for (var i = 0; i < n; i++) {
      final v = mag[i];
      sum += v;
      sumSq += v * v;
    }
    final mean = sum / n;
    final variance = (sumSq / n) - (mean * mean);
    final std = math.sqrt(variance < 0 ? 0 : variance);
    // k=1.5 gave the best precision/recall balance on a small bench of
    // sample frames (printed receipt on wood, page on cluttered desk,
    // notebook on white tablecloth). Floor at 40 so blank scenes don't
    // produce a sea of false positives.
    final thr = math.max(40, mean + 1.5 * std).round();
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = mag[i] >= thr ? 255 : 0;
    }
    return out;
  }

  /// Walks each quadrant of the frame (TL/TR/BR/BL) and picks the edge
  /// pixel furthest from the centre that has at least
  /// [minNeighborhoodHits] other edge pixels nearby. Returns null if any
  /// quadrant has no acceptable candidate.
  _ExtremePoints? _quadrantCorners(Uint8List edges, int w, int h) {
    final marginX = (w * borderMarginRatio).round();
    final marginY = (h * borderMarginRatio).round();
    final midX = w ~/ 2;
    final midY = h ~/ 2;

    final tl = _findCorner(
      edges,
      w,
      h,
      xMin: marginX,
      xMax: midX,
      yMin: marginY,
      yMax: midY,
      score: (x, y) => -(x + y),
    );
    final tr = _findCorner(
      edges,
      w,
      h,
      xMin: midX,
      xMax: w - marginX,
      yMin: marginY,
      yMax: midY,
      score: (x, y) => x - y,
    );
    final br = _findCorner(
      edges,
      w,
      h,
      xMin: midX,
      xMax: w - marginX,
      yMin: midY,
      yMax: h - marginY,
      score: (x, y) => x + y,
    );
    final bl = _findCorner(
      edges,
      w,
      h,
      xMin: marginX,
      xMax: midX,
      yMin: midY,
      yMax: h - marginY,
      score: (x, y) => y - x,
    );
    if (tl == null || tr == null || br == null || bl == null) return null;
    return _ExtremePoints(tl: tl, tr: tr, br: br, bl: bl);
  }

  Offset? _findCorner(
    Uint8List edges,
    int w,
    int h, {
    required int xMin,
    required int xMax,
    required int yMin,
    required int yMax,
    required int Function(int, int) score,
  }) {
    var best = -1 << 30;
    Offset? bestOffset;
    for (var y = yMin; y < yMax; y++) {
      final row = y * w;
      for (var x = xMin; x < xMax; x++) {
        if (edges[row + x] == 0) continue;
        final s = score(x, y);
        if (s <= best) continue;
        if (!_hasNeighborhoodSupport(edges, w, h, x, y)) continue;
        best = s;
        bestOffset = Offset(x.toDouble(), y.toDouble());
      }
    }
    return bestOffset;
  }

  /// Counts edge pixels within [neighborhoodRadius] of (x,y); returns true
  /// once the count reaches [minNeighborhoodHits]. Short-circuits to keep
  /// the inner loop cheap.
  bool _hasNeighborhoodSupport(
    Uint8List edges,
    int w,
    int h,
    int x,
    int y,
  ) {
    final r = neighborhoodRadius;
    final x0 = math.max(0, x - r);
    final y0 = math.max(0, y - r);
    final x1 = math.min(w - 1, x + r);
    final y1 = math.min(h - 1, y + r);
    var hits = 0;
    for (var yy = y0; yy <= y1; yy++) {
      final row = yy * w;
      for (var xx = x0; xx <= x1; xx++) {
        if (edges[row + xx] != 0) {
          hits++;
          if (hits >= minNeighborhoodHits) return true;
        }
      }
    }
    return false;
  }
}

class _ExtremePoints {
  const _ExtremePoints({
    required this.tl,
    required this.tr,
    required this.br,
    required this.bl,
  });
  final Offset tl;
  final Offset tr;
  final Offset br;
  final Offset bl;
}

/// Decode a JPEG byte buffer (e.g. a captured still) and re-detect a quad.
/// Used by the editor screen after the user taps capture.
Quad? detectQuadInJpeg(Uint8List jpegBytes, {double minAreaRatio = 0.06}) {
  final decoded = img.decodeJpg(jpegBytes);
  if (decoded == null) return null;
  final gray = img.grayscale(decoded);
  final w = gray.width;
  final h = gray.height;
  final detector = PureDartEdgeDetector(
    downsample: 1,
    minAreaRatio: minAreaRatio,
  );
  final luma = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      luma[y * w + x] = gray.getPixel(x, y).r.toInt();
    }
  }
  final blurred = detector._boxBlur3(luma, w, h);
  final mag = detector._sobelMagnitude(blurred, w, h);
  final edges = detector._adaptiveThreshold(mag, w, h);
  final pts = detector._quadrantCorners(edges, w, h);
  if (pts == null) return null;
  final quad = Quad.fromPoints([
    Offset(pts.tl.dx / w, pts.tl.dy / h),
    Offset(pts.tr.dx / w, pts.tr.dy / h),
    Offset(pts.br.dx / w, pts.br.dy / h),
    Offset(pts.bl.dx / w, pts.bl.dy / h),
  ]);
  if (quad.area < minAreaRatio) return null;
  return quad;
}
