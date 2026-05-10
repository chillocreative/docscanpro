// One-shot tool: render the splash logo as a 1024x1024 launcher icon.
//
//   dart run tools/gen_icon.dart
//
// Writes:
//   assets/icon/app_icon.png            (legacy / iOS-style icon)
//   assets/icon/app_icon_foreground.png (Android adaptive foreground)
//
// The generated artwork mirrors the splash page's _LogoCard widget: a
// white rounded square with a brand-blue scan-document glyph, on a
// brand-blue background.
import 'dart:io';

import 'package:image/image.dart' as img;

const int _size = 1024;

// AppTheme.brandBlue
final img.ColorRgba8 _blue = img.ColorRgba8(0x25, 0x63, 0xEB, 0xFF);
final img.ColorRgba8 _white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);
final img.ColorRgba8 _transparent = img.ColorRgba8(0, 0, 0, 0);

void main() {
  Directory('assets/icon').createSync(recursive: true);

  final mainIcon = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(mainIcon, color: _blue);
  _drawCardAndGlyph(mainIcon);
  File('assets/icon/app_icon.png')
      .writeAsBytesSync(img.encodePng(mainIcon));

  // Android adaptive icon foreground: transparent bg, same card+glyph.
  // Android renders this on top of a system-generated background; we set
  // the background colour separately in pubspec.yaml.
  final foreground = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(foreground, color: _transparent);
  _drawCardAndGlyph(foreground);
  File('assets/icon/app_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(foreground));

  stdout.writeln('Wrote app_icon.png and app_icon_foreground.png');
}

void _drawCardAndGlyph(img.Image canvas) {
  // White rounded card — matches the splash page's _LogoCard (130x130
  // out of ~390 logical pixels of vertical real estate ≈ 33%). At
  // 1024x1024 we use 640x640 so the glyph reads at small sizes too;
  // 640px also fits inside Android's adaptive-icon "safe zone" (the
  // inner 66% = 676px), so nothing critical gets cropped on round /
  // squircle masks.
  const cardSize = 640;
  const cardRadius = 140;
  const cardLeft = (_size - cardSize) ~/ 2;
  const cardTop = (_size - cardSize) ~/ 2;
  const cardRight = cardLeft + cardSize - 1;
  const cardBottom = cardTop + cardSize - 1;

  img.fillRect(
    canvas,
    x1: cardLeft,
    y1: cardTop,
    x2: cardRight,
    y2: cardBottom,
    color: _white,
    radius: cardRadius,
  );

  _drawScanDocumentGlyph(
    canvas,
    cx: _size ~/ 2,
    cy: _size ~/ 2,
  );
}

/// Stylised "scan a document" glyph: a rounded page outline with a
/// folded top-right corner, plus a horizontal scan beam across the
/// middle. Drawn in brand-blue strokes, sized so it fits inside the
/// 640x640 white card with comfortable padding.
void _drawScanDocumentGlyph(
  img.Image canvas, {
  required int cx,
  required int cy,
}) {
  // Page rectangle (the "document").
  const pageW = 360;
  const pageH = 460;
  const stroke = 16;
  const cornerCut = 90; // size of the folded corner triangle
  final left = cx - pageW ~/ 2;
  final top = cy - pageH ~/ 2;
  final right = left + pageW;
  final bottom = top + pageH;
  // The folded-corner cut starts `cornerCut` from the top-right corner,
  // so the visible page outline uses the inset top-right point.
  final cutX = right - cornerCut;
  final cutY = top + cornerCut;

  // Page outline: drawn as 4 thick line segments + the diagonal "fold"
  // edge. We don't use drawRect here because the top-right corner is
  // clipped by the fold.
  _thickLine(canvas, left, top, cutX, top, stroke); // top edge
  _thickLine(canvas, cutX, top, right, cutY, stroke); // diagonal fold
  _thickLine(canvas, right, cutY, right, bottom, stroke); // right
  _thickLine(canvas, right, bottom, left, bottom, stroke); // bottom
  _thickLine(canvas, left, bottom, left, top, stroke); // left

  // Inner mark of the folded corner: a small "L" hint that suggests
  // depth, drawn at the start of the diagonal.
  _thickLine(canvas, cutX, top, cutX, cutY, stroke);
  _thickLine(canvas, cutX, cutY, right, cutY, stroke);

  // Horizontal scan beam through the centre. Slightly wider than the
  // page so it reads as "scanning across" rather than being part of the
  // document. Rounded ends.
  const beamThickness = 22;
  const beamPad = 50;
  final beamLeft = left - beamPad;
  final beamRight = right + beamPad;
  img.fillRect(
    canvas,
    x1: beamLeft,
    y1: cy - beamThickness ~/ 2,
    x2: beamRight,
    y2: cy + beamThickness ~/ 2,
    color: _blue,
    radius: beamThickness ~/ 2,
  );
}

/// Helper: draw a thick orthogonal/diagonal line by stamping a series
/// of small filled circles along the segment. Cheaper than computing a
/// thick polygon, and the result is anti-aliased enough at 1024px.
void _thickLine(
  img.Image canvas,
  int x1,
  int y1,
  int x2,
  int y2,
  int thickness,
) {
  img.drawLine(
    canvas,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    color: _blue,
    thickness: thickness,
    antialias: true,
  );
  // Caps so corners join cleanly.
  final r = thickness ~/ 2;
  img.fillCircle(canvas, x: x1, y: y1, radius: r, color: _blue);
  img.fillCircle(canvas, x: x2, y: y2, radius: r, color: _blue);
}
