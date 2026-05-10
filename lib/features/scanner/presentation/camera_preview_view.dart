import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/core/services/logger.dart';
import 'package:doc_scan_ar/core/theme/app_theme.dart';
import 'package:doc_scan_ar/features/editor/presentation/editor_page.dart';
import 'package:doc_scan_ar/features/scanner/data/camera_providers.dart';
import 'package:doc_scan_ar/features/scanner/data/scan_session_provider.dart';
import 'package:doc_scan_ar/features/scanner/data/scanner_controller.dart';
import 'package:doc_scan_ar/features/scanner/domain/quad.dart';
import 'package:doc_scan_ar/features/scanner/presentation/edge_overlay_painter.dart';
import 'package:doc_scan_ar/features/scanner/presentation/scan_brackets_painter.dart';
import 'package:doc_scan_ar/features/scanner/presentation/scan_session_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _log = Logger('CameraPreviewView');

class CameraPreviewView extends ConsumerStatefulWidget {
  const CameraPreviewView({super.key});

  @override
  ConsumerState<CameraPreviewView> createState() => _CameraPreviewViewState();
}

class _CameraPreviewViewState extends ConsumerState<CameraPreviewView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  bool _initializing = false;
  String? _initError;
  bool _autoScan = false;
  FlashMode _flashMode = FlashMode.off;
  late final AnimationController _bracketAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrap());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive) {
      if (c != null) {
        ref.read(scannerControllerProvider.notifier).detach();
        c.dispose();
        _controller = null;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (c == null && !_initializing) {
        unawaited(_bootstrap());
      }
    }
  }

  @override
  void dispose() {
    _bracketAnim.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// Initialize the camera. Surfaces errors with a Retry option, never just
  /// hangs on `Starting camera…`. We use `ResolutionPreset.medium` for
  /// broader device compat (some Android cameras refuse the high preset
  /// on first init), and a 12s overall timeout so a stuck `initialize()`
  /// surfaces as an error the user can retry.
  Future<void> _bootstrap() async {
    if (_initializing) return;
    if (mounted) {
      setState(() {
        _initializing = true;
        _initError = null;
      });
    } else {
      _initializing = true;
    }

    CameraController? controller;
    try {
      final cams = await ref.read(availableCamerasProvider.future);
      if (cams.isEmpty) {
        throw StateError('No camera found on this device');
      }
      final cam = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize().timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw TimeoutException(
              'Camera failed to start within 12s',
            ),
          );
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
        _initError = null;
      });
      await ref.read(scannerControllerProvider.notifier).attach(controller);
    } on Object catch (e, st) {
      _log.e('Camera bootstrap failed', e, st);
      // Best-effort dispose if we got partway.
      try {
        await controller?.dispose();
      } on Object {/* ignore */}
      if (!mounted) return;
      setState(() {
        _controller = null;
        _initializing = false;
        _initError = e.toString();
      });
    }
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null) return;
    final next =
        _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await c.setFlashMode(next);
      if (!mounted) return;
      setState(() => _flashMode = next);
    } on CameraException catch (e, st) {
      _log.w('setFlashMode failed: $e\n$st');
    }
  }

  Future<void> _flipCamera() async {
    final cams = await ref.read(availableCamerasProvider.future);
    if (cams.length < 2) return;
    final current = _controller?.description;
    final next = cams.firstWhere(
      (c) => c.lensDirection != current?.lensDirection,
      orElse: () => cams.first,
    );
    final newController = CameraController(
      next,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await ref.read(scannerControllerProvider.notifier).detach();
    await _controller?.dispose();
    await newController.initialize();
    if (!mounted) return;
    setState(() => _controller = newController);
    await ref.read(scannerControllerProvider.notifier).attach(newController);
  }

  Future<void> _onShutter() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    try {
      await ref.read(scannerControllerProvider.notifier).detach();
      final shot = await c.takePicture();
      _log.i('Captured: ${shot.path}');
      if (!mounted) return;
      // Push via rootNavigator so the editor + review pages cover the
      // shell's bottom bar (otherwise the bar draws over the filter strip).
      final result =
          await Navigator.of(context, rootNavigator: true).push<Uint8List>(
        MaterialPageRoute(builder: (_) => EditorPage(imagePath: shot.path)),
      );
      if (!mounted) return;
      if (result != null) {
        ref.read(scanSessionProvider.notifier).addPage(result);
        await Navigator.of(context, rootNavigator: true).push<void>(
          MaterialPageRoute(builder: (_) => const ScanSessionReviewPage()),
        );
        if (!mounted) return;
      }
      await ref.read(scannerControllerProvider.notifier).attach(c);
    } on CameraException catch (e, st) {
      _log.e('Capture failed', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanner = ref.watch(scannerControllerProvider);
    return Column(
      children: [
        Expanded(child: _buildPreviewArea(scanner)),
        _ControlPanel(
          flashOn: _flashMode == FlashMode.torch,
          onFlash: _toggleFlash,
          onShutter: _onShutter,
          onFlip: _flipCamera,
          autoScan: _autoScan,
          onAutoScanToggle: () => setState(() => _autoScan = !_autoScan),
        ),
      ],
    );
  }

  Widget _buildPreviewArea(ScannerState scanner) {
    Widget body;
    final err = _initError;
    final c = _controller;
    if (err != null) {
      body = _PreviewPlaceholder(
        message: 'Camera failed to start.\n$err',
        showRetry: true,
        onRetry: _bootstrap,
      );
    } else if (c == null || !c.value.isInitialized) {
      body = const _PreviewPlaceholder(message: 'Starting camera…');
    } else {
      body = _LivePreview(
        controller: c,
        quad: scanner.smoothedQuad,
        ready: scanner.hint == ScannerHint.ready,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: body,
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bracketAnim,
              builder: (_, __) => CustomPaint(
                painter: ScanBracketsPainter(
                  color: AppTheme.brandBlue.withValues(
                    alpha: 0.65 + 0.35 * _bracketAnim.value,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _AutoDetectPill(hint: scanner.hint),
          ),
        ],
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({
    required this.message,
    this.showRetry = false,
    this.onRetry,
  });

  final String message;
  final bool showRetry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F2937), Color(0xFF111827)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                showRetry
                    ? Icons.error_outline
                    : Icons.photo_camera_outlined,
                color: showRetry
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFF6B7280),
                size: 64,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 15,
                ),
              ),
              if (showRetry && onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({
    required this.controller,
    required this.quad,
    required this.ready,
  });

  final CameraController controller;

  /// Detected document corners (normalized 0..1 over the camera frame). May
  /// be null when the detector hasn't locked onto a quad yet.
  final Quad? quad;

  /// True iff the detector has reported [ScannerHint.ready] for the
  /// recent frames; flips the overlay polygon to green.
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final overlayColor = ready
        ? const Color(0xFF22C55E)
        : AppTheme.brandBlue;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        // Match the camera frame's aspect so the overlay polygon stays
        // inside the actual preview region (not the letterboxed black bars).
        child: AspectRatio(
          aspectRatio: 1 / controller.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              CustomPaint(
                painter: EdgeOverlayPainter(quad: quad, color: overlayColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutoDetectPill extends StatelessWidget {
  const _AutoDetectPill({required this.hint});

  final ScannerHint hint;

  @override
  Widget build(BuildContext context) {
    final isReady = hint == ScannerHint.ready;
    final dotColor = isReady
        ? AppTheme.introIconGreen
        : const Color(0xFFFBBF24); // amber while searching
    final label = switch (hint) {
      ScannerHint.looking => 'Looking…',
      ScannerHint.moveCloser => 'Move closer',
      ScannerHint.holdSteady => 'Hold steady',
      ScannerHint.ready => 'Ready',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.flashOn,
    required this.onFlash,
    required this.onShutter,
    required this.onFlip,
    required this.autoScan,
    required this.onAutoScanToggle,
  });

  final bool flashOn;
  final VoidCallback onFlash;
  final VoidCallback onShutter;
  final VoidCallback onFlip;
  final bool autoScan;
  final VoidCallback onAutoScanToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _LabeledIconButton(
                  icon: flashOn ? Icons.bolt : Icons.flash_off,
                  label: S.flash,
                  onTap: onFlash,
                ),
              ),
              _ShutterButton(onTap: onShutter),
              Expanded(
                child: _LabeledIconButton(
                  icon: Icons.flip_camera_android,
                  label: S.flip,
                  onTap: onFlip,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AutoScanToggle(value: autoScan, onTap: onAutoScanToggle),
        ],
      ),
    );
  }
}

class _LabeledIconButton extends StatelessWidget {
  const _LabeledIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoScanToggle extends StatelessWidget {
  const _AutoScanToggle({required this.value, required this.onTap});

  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: value ? AppTheme.brandBlue : const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value ? Icons.check_box : Icons.check_box_outline_blank,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                S.autoScan,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
