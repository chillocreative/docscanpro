import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lazily resolves the list of available cameras on the device. Used by the
/// scanner page to pick the back-facing camera.
final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) {
  return availableCameras();
});

/// Selects the back-facing camera from the available list, falling back to the
/// first camera if no back-facing one is reported (rare on Android).
final backCameraProvider = FutureProvider<CameraDescription>((ref) async {
  final cams = await ref.watch(availableCamerasProvider.future);
  if (cams.isEmpty) {
    throw StateError('No cameras available on this device');
  }
  return cams.firstWhere(
    (c) => c.lensDirection == CameraLensDirection.back,
    orElse: () => cams.first,
  );
});
