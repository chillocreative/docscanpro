import 'package:flutter/material.dart';

/// Animated blue scan-corner brackets at the four corners of the camera
/// preview. Drawn as 4 L-shaped strokes with rounded line-caps; matches the
/// `Scan Document` screenshot.
class ScanBracketsPainter extends CustomPainter {
  ScanBracketsPainter({
    required this.color,
    this.armLength = 38,
    this.thickness = 5,
    this.cornerRadius = 22,
  });

  final Color color;

  /// Length of each L arm in logical pixels.
  final double armLength;

  /// Stroke thickness.
  final double thickness;

  /// Radius of the rounded corner where the two arms meet.
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final r = cornerRadius;

    // Top-left
    final tl = Path()
      ..moveTo(0, armLength + r)
      ..lineTo(0, r)
      ..arcToPoint(
        Offset(r, 0),
        radius: Radius.circular(r),
      )
      ..lineTo(armLength + r, 0);

    // Top-right
    final tr = Path()
      ..moveTo(w - armLength - r, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(
        Offset(w, r),
        radius: Radius.circular(r),
      )
      ..lineTo(w, armLength + r);

    // Bottom-right
    final br = Path()
      ..moveTo(w, h - armLength - r)
      ..lineTo(w, h - r)
      ..arcToPoint(
        Offset(w - r, h),
        radius: Radius.circular(r),
      )
      ..lineTo(w - armLength - r, h);

    // Bottom-left
    final bl = Path()
      ..moveTo(armLength + r, h)
      ..lineTo(r, h)
      ..arcToPoint(
        Offset(0, h - r),
        radius: Radius.circular(r),
      )
      ..lineTo(0, h - armLength - r);

    canvas
      ..drawPath(tl, paint)
      ..drawPath(tr, paint)
      ..drawPath(br, paint)
      ..drawPath(bl, paint);
  }

  @override
  bool shouldRepaint(covariant ScanBracketsPainter old) =>
      old.color != color ||
      old.armLength != armLength ||
      old.thickness != thickness;
}
