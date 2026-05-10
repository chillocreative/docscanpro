import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:doc_scan_ar/features/scanner/domain/quad.dart';
import 'package:doc_scan_ar/features/scanner/presentation/edge_overlay_painter.dart';
import 'package:flutter/material.dart';

/// Interactive 4-corner adjuster with a magnifier loupe.
///
/// - Renders [imageBytes] full-screen (fitted within the available box).
/// - Draws the current quad and four draggable corner handles on top.
/// - While a corner is being dragged, a circular [MagnifierLoupe] follows the
///   finger (offset above) at 2.5× zoom so the user can place the corner with
///   pixel accuracy.
class CornerAdjusterView extends StatefulWidget {
  const CornerAdjusterView({
    required this.imageBytes,
    required this.initialQuad,
    required this.onChanged,
    super.key,
  });

  /// Decoded JPEG bytes of the captured frame.
  final Uint8List imageBytes;

  /// Quad in normalized coordinates (0..1) over the image.
  final Quad initialQuad;

  /// Callback invoked on every drag end with the latest normalized quad.
  final ValueChanged<Quad> onChanged;

  @override
  State<CornerAdjusterView> createState() => _CornerAdjusterViewState();
}

class _CornerAdjusterViewState extends State<CornerAdjusterView> {
  late Quad _quad = widget.initialQuad;
  ui.Image? _image;
  Offset? _activeFinger; // null = not dragging
  int? _activeCornerIndex;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _image = frame.image);
  }

  Offset _cornerOffset(Quad q, int i, Size box) {
    final scaled = q.scaledTo(box.width, box.height);
    return switch (i) {
      0 => scaled.tl,
      1 => scaled.tr,
      2 => scaled.br,
      3 => scaled.bl,
      _ => Offset.zero,
    };
  }

  Quad _withCorner(Quad q, int i, Offset normalized) {
    return switch (i) {
      0 => Quad(tl: normalized, tr: q.tr, br: q.br, bl: q.bl),
      1 => Quad(tl: q.tl, tr: normalized, br: q.br, bl: q.bl),
      2 => Quad(tl: q.tl, tr: q.tr, br: normalized, bl: q.bl),
      3 => Quad(tl: q.tl, tr: q.tr, br: q.br, bl: normalized),
      _ => q,
    };
  }

  int? _hitTestCorner(Offset local, Size box) {
    const hitR = 36.0;
    for (var i = 0; i < 4; i++) {
      final c = _cornerOffset(_quad, i, box);
      if ((c - local).distance <= hitR) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit image inside the available box while preserving aspect.
        final imgAspect = image.width / image.height;
        final boxAspect = constraints.maxWidth / constraints.maxHeight;
        final boxW = imgAspect > boxAspect
            ? constraints.maxWidth
            : constraints.maxHeight * imgAspect;
        final boxH = imgAspect > boxAspect
            ? constraints.maxWidth / imgAspect
            : constraints.maxHeight;
        final box = Size(boxW, boxH);

        return Center(
          child: SizedBox(
            width: boxW,
            height: boxH,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) {
                final i = _hitTestCorner(d.localPosition, box);
                if (i != null) {
                  setState(() {
                    _activeCornerIndex = i;
                    _activeFinger = d.localPosition;
                  });
                }
              },
              onPanUpdate: (d) {
                final i = _activeCornerIndex;
                if (i == null) return;
                final p = Offset(
                  d.localPosition.dx.clamp(0, box.width),
                  d.localPosition.dy.clamp(0, box.height),
                );
                final norm = Offset(p.dx / box.width, p.dy / box.height);
                setState(() {
                  _quad = _withCorner(_quad, i, norm);
                  _activeFinger = p;
                });
              },
              onPanEnd: (_) {
                widget.onChanged(_quad);
                setState(() {
                  _activeCornerIndex = null;
                  _activeFinger = null;
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RawImage(image: image, fit: BoxFit.fill),
                  CustomPaint(
                    painter: EdgeOverlayPainter(
                      quad: _quad,
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                  if (_activeFinger != null)
                    Positioned.fromRect(
                      rect: _loupeRect(_activeFinger!, box),
                      child: MagnifierLoupe(
                        image: image,
                        target: _activeFinger!,
                        viewportSize: box,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Rect _loupeRect(Offset finger, Size box) {
    const radius = 60.0;
    // Place loupe ~80px above the finger, but flip below if it would go
    // off-screen at the top.
    var center = Offset(finger.dx, finger.dy - 100);
    if (center.dy - radius < 0) {
      center = Offset(finger.dx, finger.dy + 100);
    }
    center = Offset(
      center.dx.clamp(radius, box.width - radius),
      center.dy.clamp(radius, box.height - radius),
    );
    return Rect.fromCircle(center: center, radius: radius);
  }
}

/// Circular zoom window that samples [image] around [target].
class MagnifierLoupe extends StatelessWidget {
  const MagnifierLoupe({
    required this.image,
    required this.target,
    required this.viewportSize,
    this.zoom = 2.5,
    this.diameter = 120,
    super.key,
  });

  final ui.Image image;
  final Offset target;
  final Size viewportSize;
  final double zoom;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(blurRadius: 6, color: Colors.black54),
          ],
        ),
        child: CustomPaint(
          painter: _MagnifierPainter(
            image: image,
            target: target,
            viewportSize: viewportSize,
            zoom: zoom,
          ),
        ),
      ),
    );
  }
}

class _MagnifierPainter extends CustomPainter {
  _MagnifierPainter({
    required this.image,
    required this.target,
    required this.viewportSize,
    required this.zoom,
  });

  final ui.Image image;
  final Offset target;
  final Size viewportSize;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    final imgX = target.dx / viewportSize.width * image.width;
    final imgY = target.dy / viewportSize.height * image.height;
    final src = Rect.fromCenter(
      center: Offset(imgX, imgY),
      width: size.width / zoom * (image.width / viewportSize.width),
      height: size.height / zoom * (image.height / viewportSize.height),
    );
    final dst = Offset.zero & size;
    canvas
      ..drawImageRect(image, src, dst, Paint())
      ..drawCircle(
        size.center(Offset.zero),
        4,
        Paint()
          ..color = const Color(0xFF60A5FA)
          ..style = PaintingStyle.fill,
      )
      ..drawCircle(
        size.center(Offset.zero),
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
  }

  @override
  bool shouldRepaint(covariant _MagnifierPainter old) =>
      old.target != target || old.zoom != zoom || old.image != image;
}
