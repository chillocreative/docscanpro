import 'package:doc_scan_ar/features/scanner/domain/quad.dart';
import 'package:flutter/material.dart';

/// Paints a smoothed quad overlay on top of the camera preview. Quad is in
/// normalized coordinates; this painter scales to widget size.
class EdgeOverlayPainter extends CustomPainter {
  EdgeOverlayPainter({required this.quad, required this.color});

  final Quad? quad;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final q = quad;
    if (q == null) return;
    final s = q.scaledTo(size.width, size.height);
    final path = Path()
      ..moveTo(s.tl.dx, s.tl.dy)
      ..lineTo(s.tr.dx, s.tr.dy)
      ..lineTo(s.br.dx, s.br.dy)
      ..lineTo(s.bl.dx, s.bl.dy)
      ..close();

    final fill = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(path, fill)
      ..drawPath(path, stroke);

    // Corner pips
    final pipFill = Paint()..color = color;
    final pipBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final c in s.toList()) {
      canvas
        ..drawCircle(c, 8, pipFill)
        ..drawCircle(c, 8, pipBorder);
    }
  }

  @override
  bool shouldRepaint(covariant EdgeOverlayPainter old) =>
      old.quad != quad || old.color != color;
}
