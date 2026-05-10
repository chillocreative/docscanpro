import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Tri-state for the camera permission flow.
enum CameraPermissionState {
  /// We have not asked yet (or are still resolving). Show a short loading UI.
  unknown,

  /// User has granted permission — preview can render.
  granted,

  /// User denied. Show "Grant permission" CTA which re-requests.
  denied,

  /// Permanently denied. Direct the user to system settings.
  permanentlyDenied,
}

class CameraPermissionController extends Notifier<CameraPermissionState> {
  @override
  CameraPermissionState build() {
    // Resolve current status without prompting.
    Future.microtask(refresh);
    return CameraPermissionState.unknown;
  }

  /// Reads the current permission status without showing the OS prompt.
  Future<void> refresh() async {
    final s = await Permission.camera.status;
    state = _map(s);
  }

  /// Asks the OS for permission. Safe to call repeatedly.
  Future<void> request() async {
    final s = await Permission.camera.request();
    state = _map(s);
  }

  /// Opens the system settings page so the user can flip a permanently-denied
  /// permission back on. The result is reconciled the next time [refresh]
  /// runs (e.g. when the scanner page becomes visible again).
  Future<void> openSettings() async {
    await openAppSettings();
  }

  static CameraPermissionState _map(PermissionStatus s) {
    if (s.isGranted || s.isLimited) return CameraPermissionState.granted;
    if (s.isPermanentlyDenied || s.isRestricted) {
      return CameraPermissionState.permanentlyDenied;
    }
    return CameraPermissionState.denied;
  }
}

final cameraPermissionProvider =
    NotifierProvider<CameraPermissionController, CameraPermissionState>(
  CameraPermissionController.new,
);
