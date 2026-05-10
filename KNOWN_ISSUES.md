# Known issues

## OpenCV is pure-Dart, not native (M3/M5)

The spec asked us to try `opencv_dart` first and fall back to a Kotlin
MethodChannel + OpenCV Android SDK if the package was unstable. We tried
`opencv_dart 1.4.5` and its CMake/NDK build step failed on this environment
with `cmake.exe` exiting non-zero during `:opencv_dart:configureCMakeDebug`.
The likely root causes are:

1. The project root path contains a space (`D:\laragon\www\Cam Scanner\…`),
   which `opencv_dart`'s CMake configuration does not always quote correctly.
2. `opencv_dart` 1.x has documented issues building on Windows hosts when the
   pub cache and project sit on different drives (here C: vs D:).

Native Kotlin + the OpenCV Android SDK is the spec's documented fallback. It
adds ~250 MB of download (OpenCV Android SDK), a C++ JNI layer, and ~30 min
of one-time setup. It is **not currently wired in** because:

- C: drive is at 0 GB free as of 2026-05-08, so a 250 MB SDK download is not
  safe to drop on C: without first freeing space.
- Pure-Dart edge detection is already in place (`PureDartEdgeDetector`
  in `lib/features/scanner/data/edge_detector_dart.dart`) and supports the full
  end-to-end flow at lower FPS (~3-5 on a mid-range device).

### Plan to enable native OpenCV later

1. Free at least 5 GB on C:, or set `PUB_CACHE=D:\.pub_cache` and re-run
   `flutter pub get`.
2. Re-add `opencv_dart` (or `dartcv4` directly) to `pubspec.yaml`.
3. If `opencv_dart` still fails, download the OpenCV Android SDK
   (https://opencv.org/releases/) and follow Sec 3 of the build prompt
   (`claude_code_prompt_docscan.md`) — wire a `MethodChannel("opencv")` from
   `OpenCvEdgeDetector` (a new sibling of `PureDartEdgeDetector`) to a Kotlin
   helper under `android/app/src/main/kotlin/com/docscanar/app/opencv/`.
4. Swap the implementation in `scannerControllerProvider` from
   `PureDartEdgeDetector()` to `OpenCvEdgeDetector()`.

The `EdgeDetector` interface (`lib/features/scanner/domain/edge_detector.dart`)
was designed for this swap — no UI changes required.
