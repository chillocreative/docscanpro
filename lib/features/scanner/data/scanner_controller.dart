import 'dart:async';

import 'package:camera/camera.dart';
import 'package:doc_scan_ar/core/services/logger.dart';
import 'package:doc_scan_ar/features/scanner/data/edge_detector_dart.dart';
import 'package:doc_scan_ar/features/scanner/domain/edge_detector.dart';
import 'package:doc_scan_ar/features/scanner/domain/quad.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _log = Logger('ScannerController');

/// Public state surfaced to the UI.
@immutable
class ScannerState {
  const ScannerState({
    this.smoothedQuad,
    this.hint = ScannerHint.looking,
    this.stableForFrames = 0,
  });

  final Quad? smoothedQuad;
  final ScannerHint hint;
  final int stableForFrames;

  ScannerState copyWith({
    Quad? smoothedQuad,
    bool clearQuad = false,
    ScannerHint? hint,
    int? stableForFrames,
  }) {
    return ScannerState(
      smoothedQuad: clearQuad ? null : (smoothedQuad ?? this.smoothedQuad),
      hint: hint ?? this.hint,
      stableForFrames: stableForFrames ?? this.stableForFrames,
    );
  }
}

enum ScannerHint { looking, moveCloser, holdSteady, ready }

/// Owns frame-stream lifecycle, throttling, edge detection, and EMA smoothing.
///
/// One instance per scanner page; UI subscribes via [scannerControllerProvider].
class ScannerController extends StateNotifier<ScannerState> {
  ScannerController({EdgeDetector? detector})
      : _detector = detector ?? PureDartEdgeDetector(),
        super(const ScannerState());

  final EdgeDetector _detector;
  static const _emaAlpha = 0.45; // higher = more responsive, less smooth
  static const _stableThreshold = 0.012; // normalized distance
  static const _readyFrames = 12; // ~1s at 12 FPS

  CameraController? _camera;
  bool _processing = false;
  DateTime _lastProcess = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> attach(CameraController camera) async {
    _camera = camera;
    if (camera.value.isStreamingImages) return;
    try {
      await camera.startImageStream(_onFrame);
    } on CameraException catch (e, st) {
      _log.e('Failed to start image stream', e, st);
    }
  }

  Future<void> detach() async {
    final c = _camera;
    _camera = null;
    if (c == null) return;
    if (c.value.isStreamingImages) {
      try {
        await c.stopImageStream();
      } on CameraException catch (e, st) {
        _log.e('Failed to stop image stream', e, st);
      }
    }
  }

  void _onFrame(CameraImage image) {
    final now = DateTime.now();
    if (_processing) return;
    // Throttle to ~10 FPS regardless of camera frame rate.
    if (now.difference(_lastProcess).inMilliseconds < 100) return;
    _lastProcess = now;
    _processing = true;
    unawaited(_processFrame(image));
  }

  Future<void> _processFrame(CameraImage image) async {
    try {
      final raw = await _detector.detect(image);
      if (raw == null) {
        state = state.copyWith(
          clearQuad: true,
          hint: ScannerHint.looking,
          stableForFrames: 0,
        );
        return;
      }
      final smoothed = state.smoothedQuad == null
          ? raw
          : state.smoothedQuad!.lerp(raw, _emaAlpha);
      final movement =
          state.smoothedQuad == null ? 1.0 : state.smoothedQuad!.meanDistance(smoothed);
      final stable = movement < _stableThreshold;
      final stableFrames = stable ? state.stableForFrames + 1 : 0;
      ScannerHint hint;
      if (raw.area < 0.18) {
        hint = ScannerHint.moveCloser;
      } else if (!stable) {
        hint = ScannerHint.holdSteady;
      } else if (stableFrames >= _readyFrames) {
        hint = ScannerHint.ready;
      } else {
        hint = ScannerHint.holdSteady;
      }
      state = state.copyWith(
        smoothedQuad: smoothed,
        hint: hint,
        stableForFrames: stableFrames,
      );
    } on Object catch (e, st) {
      _log.e('Edge detection threw', e, st);
    } finally {
      _processing = false;
    }
  }

  @override
  void dispose() {
    unawaited(detach());
    unawaited(_detector.dispose());
    super.dispose();
  }
}

final scannerControllerProvider =
    StateNotifierProvider.autoDispose<ScannerController, ScannerState>((ref) {
  return ScannerController();
});
