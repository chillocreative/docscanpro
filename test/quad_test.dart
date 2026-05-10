import 'package:doc_scan_ar/features/scanner/domain/quad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quad', () {
    test('fromPoints orders TL/TR/BR/BL regardless of input order', () {
      final q = Quad.fromPoints([
        const Offset(10, 10),
        Offset.zero,
        const Offset(10, 0),
        const Offset(0, 10),
      ]);
      expect(q.tl, Offset.zero);
      expect(q.tr, const Offset(10, 0));
      expect(q.br, const Offset(10, 10));
      expect(q.bl, const Offset(0, 10));
    });

    test('lerp midpoint of two quads', () {
      final a = Quad.fromPoints([
        Offset.zero,
        const Offset(10, 0),
        const Offset(10, 10),
        const Offset(0, 10),
      ]);
      final b = Quad.fromPoints([
        const Offset(2, 2),
        const Offset(12, 2),
        const Offset(12, 12),
        const Offset(2, 12),
      ]);
      final mid = a.lerp(b, 0.5);
      expect(mid.tl, const Offset(1, 1));
      expect(mid.br, const Offset(11, 11));
    });

    test('meanDistance is 0 for identical quads', () {
      final q = Quad.fromPoints([
        Offset.zero,
        const Offset(10, 0),
        const Offset(10, 10),
        const Offset(0, 10),
      ]);
      expect(q.meanDistance(q), 0);
    });

    test('area is correct for unit square', () {
      final q = Quad.fromPoints([
        Offset.zero,
        const Offset(1, 0),
        const Offset(1, 1),
        const Offset(0, 1),
      ]);
      expect(q.area, closeTo(1.0, 1e-9));
    });

    test('scaledTo multiplies normalized coords by image dimensions', () {
      final q = Quad.fromPoints([
        Offset.zero,
        const Offset(0.5, 0),
        const Offset(0.5, 0.5),
        const Offset(0, 0.5),
      ]);
      final s = q.scaledTo(100, 200);
      expect(s.tl, Offset.zero);
      expect(s.tr, const Offset(50, 0));
      expect(s.br, const Offset(50, 100));
      expect(s.bl, const Offset(0, 100));
    });
  });
}
