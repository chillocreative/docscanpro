import 'package:camera/camera.dart';
import 'package:doc_scan_ar/features/scanner/domain/quad.dart';

/// Pluggable edge detector. Implementations:
/// - `PureDartEdgeDetector` (always available, ~3-5 FPS)
/// - `OpenCvEdgeDetector` (when `opencv_dart` ships on the platform)
abstract class EdgeDetector {
  /// Best-effort detection of the document quadrilateral inside [image].
  /// Returns `null` if no high-confidence quad is found.
  ///
  /// Implementations MUST be safe to call from a Dart isolate-free context;
  /// the caller throttles to ~10-15 FPS and skips frames if the previous one
  /// is still in flight.
  Future<Quad?> detect(CameraImage image);

  /// Releases any native resources. Called when the scanner page is disposed.
  Future<void> dispose() async {}
}
