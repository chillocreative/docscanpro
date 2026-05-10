import 'dart:math' as math;
import 'dart:ui' show Offset;

/// A 4-point convex polygon, ordered top-left, top-right, bottom-right,
/// bottom-left in *normalized* image coordinates (0..1 on each axis).
///
/// Normalized coordinates let the same quad survive preview-size changes,
/// rotation, and orientation flips without re-detection.
class Quad {
  const Quad({
    required this.tl,
    required this.tr,
    required this.br,
    required this.bl,
  });

  /// Builds a Quad from any 4 points by sorting them into TL/TR/BR/BL by
  /// position. Assumes the points come from a roughly rectangular contour.
  factory Quad.fromPoints(List<Offset> pts) {
    assert(pts.length == 4, 'Quad.fromPoints needs exactly 4 points');
    // Sort by sum (x+y): smallest = TL, largest = BR.
    // Sort by difference (y-x): smallest = TR, largest = BL.
    final sorted = [...pts]
      ..sort((a, b) => (a.dx + a.dy).compareTo(b.dx + b.dy));
    final tl = sorted.first;
    final br = sorted.last;
    final remaining = sorted.sublist(1, 3)
      ..sort((a, b) => (a.dy - a.dx).compareTo(b.dy - b.dx));
    final tr = remaining.first;
    final bl = remaining.last;
    return Quad(tl: tl, tr: tr, br: br, bl: bl);
  }

  final Offset tl;
  final Offset tr;
  final Offset br;
  final Offset bl;

  /// Linear interpolation toward [other]. Used to smooth corners across
  /// frames.
  Quad lerp(Quad other, double t) {
    return Quad(
      tl: Offset.lerp(tl, other.tl, t)!,
      tr: Offset.lerp(tr, other.tr, t)!,
      br: Offset.lerp(br, other.br, t)!,
      bl: Offset.lerp(bl, other.bl, t)!,
    );
  }

  /// Average corner movement vs [other], in normalized units. Used as a
  /// stability metric for auto-capture.
  double meanDistance(Quad other) {
    double d(Offset a, Offset b) =>
        math.sqrt(math.pow(a.dx - b.dx, 2) + math.pow(a.dy - b.dy, 2));
    return (d(tl, other.tl) + d(tr, other.tr) + d(br, other.br) + d(bl, other.bl)) / 4;
  }

  /// Approximate area in normalized units (0..1).
  double get area {
    // Shoelace formula on TL, TR, BR, BL.
    final s = (tl.dx * tr.dy - tr.dx * tl.dy) +
        (tr.dx * br.dy - br.dx * tr.dy) +
        (br.dx * bl.dy - bl.dx * br.dy) +
        (bl.dx * tl.dy - tl.dx * bl.dy);
    return s.abs() / 2;
  }

  List<Offset> toList() => [tl, tr, br, bl];

  /// Maps each normalized corner into pixel coordinates of an image of the
  /// given [width]/[height].
  Quad scaledTo(double width, double height) {
    Offset s(Offset n) => Offset(n.dx * width, n.dy * height);
    return Quad(tl: s(tl), tr: s(tr), br: s(br), bl: s(bl));
  }
}
