import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Bundled args for [preprocessForOcr]. Kept as a top-level class because
/// `compute` payloads must be sendable across isolate boundaries.
class OcrPreprocessArgs {
  const OcrPreprocessArgs({required this.inputPath, required this.tempDir});

  final String inputPath;

  /// Directory where the preprocessed file is dropped. Resolved on the
  /// main isolate (via path_provider) and passed in, because plugin
  /// channels are unavailable inside a `compute` worker.
  final String tempDir;
}

/// Output of [preprocessForOcr]: the path to a processed JPEG, the
/// dimensions ML Kit will see (so callers can map bounding boxes back
/// onto a canvas), and a flag telling the caller whether they should
/// delete it after OCR.
class OcrPreprocessResult {
  const OcrPreprocessResult({
    required this.outputPath,
    required this.isTempFile,
    required this.width,
    required this.height,
  });

  final String outputPath;
  final bool isTempFile;
  final int width;
  final int height;
}

/// Resolves a temp directory the OCR preprocessor can write into. Must
/// be called on the main isolate (uses path_provider).
Future<String> resolveOcrTempDir() async {
  final dir = await getTemporaryDirectory();
  final sub = Directory(p.join(dir.path, 'ocr_preproc'));
  if (!sub.existsSync()) sub.createSync(recursive: true);
  return sub.path;
}

/// Top-level entry point used with `compute()`. Reads the original
/// page JPEG and prepares an OCR-friendly version:
///
///   1. Decode + bake EXIF orientation so the recognizer sees an
///      upright frame.
///   2. Up-scale small images to a long-edge target so individual
///      glyphs land in ML Kit's preferred 24-30 px range.
///   3. Light contrast lift, modest gamma, mild un-sharp-mask via a
///      3x3 sharpening convolution. Aggressive binarization is
///      intentionally avoided — Google's text recognizer is trained on
///      natural images and tends to lose detail when fed pure B&W.
///   4. Re-encode JPEG quality 92 into the supplied temp dir.
///
/// Returns the path to the new file (or the original input path if the
/// image was unsuitable for processing — caller should still feed it to
/// the recognizer; ML Kit can usually handle raw camera frames).
OcrPreprocessResult preprocessForOcr(OcrPreprocessArgs args) {
  final input = File(args.inputPath);
  if (!input.existsSync()) {
    return OcrPreprocessResult(
      outputPath: args.inputPath,
      isTempFile: false,
      width: 0,
      height: 0,
    );
  }
  final bytes = input.readAsBytesSync();
  // decodeImage handles JPEG/PNG/etc.; null on undecodable frames.
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return OcrPreprocessResult(
      outputPath: args.inputPath,
      isTempFile: false,
      width: 0,
      height: 0,
    );
  }

  // 1. Apply any EXIF orientation tag so portraits aren't fed sideways.
  var image = img.bakeOrientation(decoded);

  // 2. Up-scale tiny scans. ML Kit performs best when individual glyphs
  // are at least ~24 px tall, which usually means the page itself wants
  // to be ~2400 px on the long edge. We never down-scale: a high-res
  // capture is already in the sweet spot, and shrinking would only hurt
  // accuracy.
  const minLongEdge = 2400;
  final longEdge = image.width > image.height ? image.width : image.height;
  if (longEdge < minLongEdge) {
    final scale = minLongEdge / longEdge;
    image = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.cubic,
    );
  }

  // 3. Tonal lift: a modest contrast boost + slight gamma flattens
  // shadows and brightens the page. Conservative settings because ML
  // Kit's models already include strong implicit normalization.
  image = img.adjustColor(
    image,
    contrast: 1.12,
    brightness: 1.04,
    gamma: 0.96,
  );

  // 4. Light un-sharp-mask via a 3x3 sharpening kernel — emphasises
  //    glyph edges without introducing the haloing of stronger
  //    sharpening. Coefficients sum to 1 so global luminance is
  //    preserved.
  image = img.convolution(
    image,
    filter: const [
      0, -1, 0, //
      -1, 5, -1, //
      0, -1, 0, //
    ],
    div: 1,
    offset: 0,
  );

  // 5. Re-encode and write.
  final out = img.encodeJpg(image, quality: 92);
  final outName = 'ocr_${DateTime.now().microsecondsSinceEpoch}_'
      '${p.basenameWithoutExtension(args.inputPath)}.jpg';
  final outPath = p.join(args.tempDir, outName);
  File(outPath).writeAsBytesSync(out, flush: true);
  return OcrPreprocessResult(
    outputPath: outPath,
    isTempFile: true,
    width: image.width,
    height: image.height,
  );
}
