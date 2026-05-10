import 'package:doc_scan_ar/features/editor/data/image_pipeline.dart';
import 'package:doc_scan_ar/features/editor/domain/filter_kind.dart';
import 'package:doc_scan_ar/features/scanner/domain/quad.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  // 100x80 grey image we can use for quick filter sanity checks.
  img.Image makeImage() {
    final i = img.Image(width: 100, height: 80);
    img.fill(i, color: img.ColorRgb8(120, 120, 120));
    return i;
  }

  group('ImagePipeline.rectify', () {
    test('rectified image dimensions are derived from the longer edges', () {
      final src = makeImage();
      const q = Quad(
        tl: Offset.zero,
        tr: Offset(0.5, 0),
        br: Offset(0.5, 1),
        bl: Offset(0, 1),
      );
      final out = ImagePipeline.rectify(src, q);
      // Width spans 0..0.5 → 50px, height 0..1 → 80px.
      expect(out.width, 50);
      expect(out.height, 80);
    });
  });

  group('ImagePipeline.applyFilter', () {
    test('original keeps pixel value', () {
      final src = makeImage();
      final out = ImagePipeline.applyFilter(src, FilterKind.original);
      final p = out.getPixel(10, 10);
      expect(p.r.toInt(), 120);
    });

    test('grayscale produces equal R/G/B channels', () {
      final src = makeImage();
      final out = ImagePipeline.applyFilter(src, FilterKind.grayscale);
      final p = out.getPixel(10, 10);
      expect(p.r, p.g);
      expect(p.g, p.b);
    });

    test('black-and-white pixel is in {0, 255}', () {
      final src = makeImage();
      final out = ImagePipeline.applyFilter(src, FilterKind.blackAndWhite);
      final p = out.getPixel(50, 40);
      expect([0, 255].contains(p.r.toInt()), isTrue);
    });

    test('autoEnhance and magicColor return same dimensions', () {
      final src = makeImage();
      final ae = ImagePipeline.applyFilter(src, FilterKind.autoEnhance);
      final mc = ImagePipeline.applyFilter(src, FilterKind.magicColor);
      expect(ae.width, src.width);
      expect(mc.width, src.width);
      expect(ae.height, src.height);
    });
  });

  test('encodeJpeg produces non-empty bytes', () {
    final src = makeImage();
    final bytes = ImagePipeline.encodeJpeg(src);
    expect(bytes.lengthInBytes, greaterThan(100));
  });
}
