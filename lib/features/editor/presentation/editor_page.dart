import 'dart:io';

import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/core/services/logger.dart';
import 'package:doc_scan_ar/core/theme/app_theme.dart';
import 'package:doc_scan_ar/features/editor/data/image_pipeline.dart';
import 'package:doc_scan_ar/features/editor/domain/filter_kind.dart';
import 'package:doc_scan_ar/features/editor/presentation/corner_adjuster_view.dart';
import 'package:doc_scan_ar/features/scanner/data/edge_detector_dart.dart';
import 'package:doc_scan_ar/features/scanner/domain/quad.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

const _log = Logger('EditorPage');

/// Three-step editor: corner adjustment → straighten (rotate) → filter.
class EditorPage extends StatefulWidget {
  const EditorPage({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

enum _Step { adjust, straighten, filter }

class _EditorPageState extends State<EditorPage> {
  _Step _step = _Step.adjust;
  Uint8List? _originalBytes;
  Quad? _quad;

  /// Output of the rectify pass; the *base* image used by the
  /// straighten step. Stored so toggling the rotation slider doesn't
  /// re-rectify on every tick.
  img.Image? _rectified;

  /// Image after the user's rotation was applied. Re-derived whenever
  /// the rotation angle changes; feeds the filter preview.
  img.Image? _straightened;

  /// Final preview JPEG that will be returned via Navigator.pop.
  Uint8List? _filteredJpeg;

  FilterKind _filter = FilterKind.autoEnhance;
  double _rotation = 0; // degrees, negative = counter-clockwise
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    if (!mounted) return;
    final detected = detectQuadInJpeg(bytes) ?? _defaultQuad();
    setState(() {
      _originalBytes = bytes;
      _quad = detected;
    });
  }

  Quad _defaultQuad() {
    return const Quad(
      tl: Offset(0.08, 0.10),
      tr: Offset(0.92, 0.10),
      br: Offset(0.92, 0.90),
      bl: Offset(0.08, 0.90),
    );
  }

  Future<void> _onContinueAdjust() async {
    final bytes = _originalBytes;
    final quad = _quad;
    if (bytes == null || quad == null) return;
    setState(() => _processing = true);
    try {
      final rect = await compute(_rectifyInIsolate, _RectifyArgs(bytes, quad));
      if (!mounted) return;
      setState(() {
        _rectified = rect;
        _straightened = rect; // initial, no rotation
        _rotation = 0;
        _step = _Step.straighten;
      });
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Update the previewed image to reflect [_rotation]. We hand the
  /// rotation off to a worker isolate because copyRotate at full
  /// resolution can take 100+ms which would jank the slider.
  Future<void> _refreshRotation() async {
    final rect = _rectified;
    if (rect == null) return;
    final args = _RotateArgs(rect, _rotation);
    final rotated = await compute(_rotateInIsolate, args);
    if (!mounted) return;
    setState(() => _straightened = rotated);
  }

  Future<void> _onContinueStraighten() async {
    final base = _straightened;
    if (base == null) return;
    setState(() => _processing = true);
    try {
      final filtered = await compute(
        _filterInIsolate,
        _FilterArgs(base, _filter),
      );
      if (!mounted) return;
      setState(() {
        _filteredJpeg = filtered;
        _step = _Step.filter;
      });
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _onFilterChanged(FilterKind kind) async {
    final base = _straightened;
    if (base == null) return;
    setState(() {
      _filter = kind;
      _processing = true;
    });
    final filtered = await compute(_filterInIsolate, _FilterArgs(base, kind));
    if (!mounted) return;
    setState(() {
      _filteredJpeg = filtered;
      _processing = false;
    });
  }

  Future<void> _onSave() async {
    final bytes = _filteredJpeg;
    if (bytes == null) return;
    _log.i('Editor → save (${bytes.lengthInBytes} bytes)');
    if (!mounted) return;
    Navigator.of(context).pop(bytes);
  }

  void _onBack() {
    setState(() {
      switch (_step) {
        case _Step.adjust:
          Navigator.of(context).pop();
        case _Step.straighten:
          _step = _Step.adjust;
        case _Step.filter:
          _step = _Step.straighten;
      }
    });
  }

  String _titleForStep() => switch (_step) {
        _Step.adjust => S.editorAdjustCorners,
        _Step.straighten => S.editorStraighten,
        _Step.filter => 'Filter',
      };

  @override
  Widget build(BuildContext context) {
    final bytes = _originalBytes;
    final quad = _quad;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: _onBack),
        title: Text(_titleForStep()),
        actions: [
          if (_step == _Step.filter)
            TextButton(
              onPressed: _processing ? null : _onSave,
              child: const Text('Save'),
            ),
        ],
      ),
      body: bytes == null || quad == null
          ? const Center(child: CircularProgressIndicator())
          : switch (_step) {
              _Step.adjust => CornerAdjusterView(
                  imageBytes: bytes,
                  initialQuad: quad,
                  onChanged: (q) => setState(() => _quad = q),
                ),
              _Step.straighten => _StraightenStep(
                  preview: _straightened,
                  rotation: _rotation,
                  busy: _processing,
                  onRotationChanged: (v) {
                    setState(() => _rotation = v);
                  },
                  onRotationCommitted: _refreshRotation,
                  onRotateBy: (delta) {
                    setState(() {
                      _rotation = _normalizeRotation(_rotation + delta);
                    });
                    _refreshRotation();
                  },
                  onReset: () {
                    setState(() => _rotation = 0);
                    _refreshRotation();
                  },
                ),
              _Step.filter => _FilterStep(
                  jpegBytes: _filteredJpeg,
                  selected: _filter,
                  onSelected: _onFilterChanged,
                  busy: _processing,
                ),
            },
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget? _bottomBar() {
    return switch (_step) {
      _Step.adjust => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: _processing ? null : _onContinueAdjust,
              child: _processing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(S.editorContinue),
            ),
          ),
        ),
      _Step.straighten => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: _processing ? null : _onContinueStraighten,
              child: _processing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(S.editorContinue),
            ),
          ),
        ),
      _Step.filter => null,
    };
  }
}

/// Straighten step UI: shows the rectified image and a control bar
/// with rotate-left, rotate-right, reset, and a fine ±15° slider.
class _StraightenStep extends StatelessWidget {
  const _StraightenStep({
    required this.preview,
    required this.rotation,
    required this.busy,
    required this.onRotationChanged,
    required this.onRotationCommitted,
    required this.onRotateBy,
    required this.onReset,
  });

  final img.Image? preview;
  final double rotation;
  final bool busy;
  final ValueChanged<double> onRotationChanged;
  final VoidCallback onRotationCommitted;
  final ValueChanged<double> onRotateBy;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: preview == null
              ? const Center(child: CircularProgressIndicator())
              : InteractiveViewer(
                  child: Center(
                    child: Image.memory(
                      Uint8List.fromList(img.encodeJpg(preview!, quality: 85)),
                      gaplessPlayback: true,
                    ),
                  ),
                ),
        ),
        Container(
          color: const Color(0xFF111827),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _IconAction(
                    icon: Icons.rotate_90_degrees_ccw,
                    label: S.editorRotateLeft,
                    onPressed: busy ? null : () => onRotateBy(-90),
                  ),
                  _IconAction(
                    icon: Icons.refresh,
                    label: S.editorReset,
                    onPressed: busy || rotation == 0 ? null : onReset,
                  ),
                  _IconAction(
                    icon: Icons.rotate_90_degrees_cw,
                    label: S.editorRotateRight,
                    onPressed: busy ? null : () => onRotateBy(90),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    width: 56,
                    child: Text(
                      'Fine',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _displayAngle(rotation),
                      min: -15,
                      max: 15,
                      divisions: 60,
                      activeColor: AppTheme.brandBlue,
                      label: '${_displayAngle(rotation).toStringAsFixed(1)}°',
                      onChanged: busy
                          ? null
                          : (v) {
                              final base = _baseAngle(rotation);
                              onRotationChanged(_normalizeRotation(base + v));
                            },
                      onChangeEnd: busy ? null : (_) => onRotationCommitted(),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${rotation.toStringAsFixed(1)}°',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Slider only spans ±15°; isolate the fine portion of [rotation]
  /// from any 90° increments coming from the rotate buttons.
  static double _displayAngle(double rotation) {
    final n = _normalizeRotation(rotation);
    final fine = n - _baseAngle(n);
    return fine.clamp(-15.0, 15.0);
  }

  static double _baseAngle(double rotation) {
    return ((rotation / 90).round() * 90).toDouble();
  }
}

/// Wrap a rotation into [-180°, 180°].
double _normalizeRotation(double angle) {
  var a = angle % 360;
  if (a > 180) a -= 360;
  if (a < -180) a += 360;
  return a;
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: disabled ? Colors.white24 : Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: disabled ? Colors.white24 : Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterStep extends StatelessWidget {
  const _FilterStep({
    required this.jpegBytes,
    required this.selected,
    required this.onSelected,
    required this.busy,
  });

  final Uint8List? jpegBytes;
  final FilterKind selected;
  final ValueChanged<FilterKind> onSelected;
  final bool busy;

  static const _options = <(FilterKind, String)>[
    (FilterKind.original, S.filterOriginal),
    (FilterKind.autoEnhance, S.filterAuto),
    (FilterKind.grayscale, S.filterGray),
    (FilterKind.blackAndWhite, S.filterBw),
    (FilterKind.magicColor, S.filterMagic),
  ];

  @override
  Widget build(BuildContext context) {
    final bytes = jpegBytes;
    return Column(
      children: [
        Expanded(
          child: bytes == null
              ? const Center(child: CircularProgressIndicator())
              : InteractiveViewer(
                  child: Center(child: Image.memory(bytes)),
                ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (kind, label) = _options[i];
              final isSelected = kind == selected;
              return GestureDetector(
                onTap: busy ? null : () => onSelected(kind),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white24,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Icon(
                        _iconFor(kind),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static IconData _iconFor(FilterKind kind) => switch (kind) {
        FilterKind.original => Icons.image_outlined,
        FilterKind.autoEnhance => Icons.auto_awesome_outlined,
        FilterKind.grayscale => Icons.gradient_outlined,
        FilterKind.blackAndWhite => Icons.invert_colors_outlined,
        FilterKind.magicColor => Icons.color_lens_outlined,
      };
}

// ---------- isolate workers ----------

class _RectifyArgs {
  const _RectifyArgs(this.jpeg, this.quad);
  final Uint8List jpeg;
  final Quad quad;
}

img.Image _rectifyInIsolate(_RectifyArgs args) {
  final source = ImagePipeline.decodeJpeg(args.jpeg);
  if (source == null) {
    throw StateError('Could not decode source JPEG in editor isolate');
  }
  return ImagePipeline.rectify(source, args.quad);
}

class _RotateArgs {
  const _RotateArgs(this.image, this.degrees);
  final img.Image image;
  final double degrees;
}

img.Image _rotateInIsolate(_RotateArgs args) {
  if (args.degrees == 0) return args.image;
  // copyRotate enlarges the canvas to fit the rotated image. For
  // non-90° angles this leaves transparent triangles in the corners
  // which we fill white so the page reads as a clean document.
  final rotated = img.copyRotate(
    args.image,
    angle: args.degrees,
    interpolation: img.Interpolation.cubic,
  );
  if (args.degrees % 90 == 0) return rotated;
  // Composite onto a white background so the corner triangles aren't
  // black/transparent in the final JPEG.
  final w = rotated.width;
  final h = rotated.height;
  final canvas = img.Image(width: w, height: h);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  return img.compositeImage(canvas, rotated);
}

class _FilterArgs {
  const _FilterArgs(this.image, this.kind);
  final img.Image image;
  final FilterKind kind;
}

Uint8List _filterInIsolate(_FilterArgs args) {
  final out = ImagePipeline.applyFilter(args.image, args.kind);
  return ImagePipeline.encodeJpeg(out);
}
