# Changelog

## 1.2.0 — 2026-05-09 (live edge overlay + lifetime IAP + strict format)

- **Live edge overlay on the camera.** `ScannerController` was already
  streaming frames through `PureDartEdgeDetector` and publishing a
  smoothed quad, but the painter was never instantiated. Wired
  `EdgeOverlayPainter` into `_LivePreview` *inside* the camera's
  `AspectRatio` (so corners track the actual frame, not the letterbox
  bars). Polygon turns from blue → green when `ScannerHint.ready`. The
  "Auto Detect" pill now reads from the live hint: amber dot +
  "Looking…" / "Move closer" / "Hold steady", green dot + "Ready" when
  the quad has been stable for ~1 s.
- **Premium card → "Get lifetime — $4.99".** Subhead now reads
  "Lifetime access. One payment, all features." Removed the 7-day
  trial bullet. SKU renamed `remove_ads_monthly` → `premium_lifetime`
  (`AppConstants.premiumLifetimeSku`). The IAP code already used
  `buyNonConsumable` so the wiring matches a managed-product
  one-time purchase. **Play Console action required:** create a
  managed product (one-time) with ID `premium_lifetime`. Method
  rename: `IapController.buyRemoveAds` → `buyPremium`.
- **Default Save Format is now strictly enforced.** Tapping a card
  → Document Actions → Share / Download now reads
  `Settings.defaultSaveFormat` (was using a `pageCount > 1`
  heuristic, so single-page docs always exported as JPG). The card's
  format chip + tinted file-type icon also follow the setting — flip
  the toggle in Settings and every card on Home updates instantly.
  Auto-save on scan-session "Done" already followed the setting; this
  closes the gap on the share/download flow.
- **Release APK:** 91.7 MB. Manifest verified at
  `com.docscanar.app.MainActivity` and `android:label="DocScan Pro"`.

## 1.1.3 — 2026-05-09 (Document Actions bottom sheet + new card design)

- **New grid + list cards.** Grid tile now has a tall tinted icon area on
  top, then a separate info section below with title, date, format chip
  ("PDF" or "JPG") and file size right-aligned — matches the Figma comp.
  List rows compact the same info into a single horizontal row.
- **Tap a card → Document Actions sheet.** Replaced the in-card
  three-dot menu with a modal bottom sheet titled "Document Actions"
  with Share (blue), Download (green), Delete (red), and a Cancel pill
  at the bottom. Drag handle at the top, rounded top corners.
  - **Share** — exports the document (PDF if multi-page, JPGs otherwise)
    and opens the system share sheet via `share_plus`.
  - **Download** — same export, but lands in
    `<external>/Documents|Pictures/DocScanAR/` and shows the saved path
    in a snackbar.
  - **Delete** — confirm dialog, then removes page images from disk and
    the document row (cascade deletes the page rows).
- Format chip on the card is derived from page count (`>1` → PDF, else
  JPG); future: store the format on the document row so re-opens reflect
  the exact saved format.
- **Release APK:** 91.7 MB.

## 1.1.2 — 2026-05-09 (blank-dashboard + camera-hang fixes)

- **Dashboard no longer goes blank.** The Library page used to nest its
  own Scaffold with a `bottomNavigationBar: SafeArea(child: Center(child:
  BannerAdView()))` slot — with ads disabled `BannerAdView` returned
  `SizedBox.shrink`, but the safe-area + nested-Scaffold layering on top of
  the outer shell's bottom bar was collapsing the body in some device
  configurations. Rewrote: removed the inner `bottomNavigationBar` (the
  shell already has one), pulled the title + search bar out of the
  AsyncValue.when so they always render, and made each loading / error /
  empty branch render visible content (icon + clear text) so the screen
  can never silently show only white.
- **Camera no longer hangs on "Starting camera…".** Replaced the
  `FutureBuilder`-driven init with explicit `_initializing` and
  `_initError` state, wrapped `_bootstrap()` in `try/catch` and a 12-second
  `.timeout(...)`, surfaced any failure as a clear "Camera failed to start"
  card with a **Retry** button right inside the preview area, and dropped
  to `ResolutionPreset.medium` for broader device compat (some Android
  cameras refuse the high preset on first init). Lifecycle handler also
  reworked so `inactive → resumed` only restarts bootstrap if the
  controller actually got disposed, instead of racing a second init while
  the first is still in flight.
- **Release APK:** 92.5 MB. Manifest verified at
  `com.docscanar.app.MainActivity` and `android:label="DocScan Pro"`.

## 1.1.1 — 2026-05-09 (UX fixes + ads off + PDF auto-save)

- **Bottom navbar no longer covers content.** Removed
  `extendBody: true` from `MainScaffold` so the body stops sliding
  under the bar (the About row in Settings and the filter strip in
  the editor were getting clipped). Pushed the editor + scan-review
  pages with `rootNavigator: true` so they cover the full screen
  during editing instead of redrawing under the bar.
- **PDF / JPG auto-save on Done.** When the user taps **Done** in
  the scan-session review, we now also write a PDF or per-page JPGs
  to disk based on **Settings → Default Save Format**. PDFs land in
  `<external>/Documents/DocScanAR/`, JPGs in
  `<external>/Pictures/DocScanAR/`. A snackbar shows the saved path.
- **AdMob temporarily disabled.** Added `AppConstants.kAdsEnabled`
  (currently `false`). When false: `MobileAds.initialize()` is
  skipped at boot, `BannerAdView` short-circuits to `SizedBox.shrink`,
  `AdService.maybeShowInterstitial` is a no-op, the "Ads Active"
  amber banner on My Documents is hidden, and `adsHiddenProvider`
  reports true. Flip the constant back to `true` to re-enable
  everything — the SDK and ad unit IDs are still wired.
- **Release APK:** 92.4 MB.

## 1.1.0 — 2026-05-09 (DocScan Pro redesign)

Re-skinned to match the supplied Figma comps. The package ID stays
`com.docscanar.app` so the new APK installs over the old one cleanly.

- **Brand:** Renamed app and launcher label from *DocScan AR* to
  *DocScan Pro*. New tagline "Scan. Save. Share."
- **New:** Splash screen (solid blue, white scan-brackets logo card,
  brand + tagline). Holds for 1.2s and decides next route based on
  `seenOnboarding` flag in shared_preferences.
- **New:** First-run onboarding — three pages with Skip / Next /
  Get Started, animated dot indicator. Pages: Scan Documents (blue
  camera), Save as PDF or JPG (purple doc), Share Anywhere (green
  share). Once skipped or completed, the flag persists and the
  onboarding is not shown again.
- **Nav:** Replaced the 3-tab bottom nav with Home / Camera FAB /
  Settings. The center Camera button is a real shell branch (not a
  push), so the bottom bar stays visible on the scan page and the
  FAB shows as selected when active.
- **My Documents (Home):** New "My Documents" header with grid/list
  toggle, search field, amber "Ads Active" upsell banner that pushes
  the paywall on tap, document rows with file-type badge (red for
  multi-page PDFs, blue for single-page images), date · pages · size
  meta, three-dot menu for rename/delete.
- **Scan Document:** Black surface, animated blue scan brackets at
  all four corners (pulse via `AnimationController`), "Auto Detect"
  pill with green status dot, labeled Flash / Flip controls flanking
  the white shutter, "Auto Scan" toggle pill (blue when on). Flash
  toggles `setFlashMode(torch/off)`; Flip switches between
  front/back cameras.
- **Settings:** Orange-gradient Premium upsell card with crown icon,
  five bullet features, white "Subscribe for $4.99/month" CTA wired
  to the IAP controller. Reorganized into General (Notifications
  toggle, Theme cycle, Default Save Format toggle), Privacy & Security
  (Privacy Policy, Terms), Support (Help, Rate, Restore, About).
  Notifications + default save format persisted in shared_preferences.
- **Tests:** Replaced the old library widget test with a
  `My Documents` header check. Added unit tests for the new
  `SettingsState`. 14 tests passing.
- **Release APK:** 92.7 MB, manifest verified at
  `com.docscanar.app.MainActivity` and `android:label="DocScan Pro"`.

## 1.0.1 — 2026-05-08 (release-APK crash fix)

- **Fix:** Release APK crashed on launch with `ClassNotFoundException`
  because `MainActivity` lived at `com.docscanar.doc_scan_ar.MainActivity`
  while the manifest's `applicationId`/namespace had been changed to
  `com.docscanar.app` in M1. Moved the Kotlin source to
  `kotlin/com/docscanar/app/MainActivity.kt` (package `com.docscanar.app`)
  so the activity class resolves at launch. Verified in `classes.dex`:
  `Lcom/docscanar/app/MainActivity;` is now present, and
  `aapt dump xmltree` shows the manifest activity name as
  `com.docscanar.app.MainActivity`.
- **Defensive:** Wrapped `MobileAds.instance.initialize()` in a
  try/catch and installed a `FlutterError.onError` handler so a
  misbehaving plugin at boot can't black-screen the app.
- **Build:** R8 (`minifyReleaseWithR8`) was rejecting the build with
  missing-class errors for optional ML Kit language modules
  (Devanagari, Japanese, Korean) that the plugin references via
  reflection even when only Latin is used. Disabled minification for
  release (`isMinifyEnabled = false`, `isShrinkResources = false`)
  and shipped a proper `android/app/proguard-rules.pro` with keep
  rules for ML Kit, AdMob, Play Billing, CameraX, pdf, and Flutter
  embedding — so re-enabling R8 later is a one-line change.

## 1.0.0 — 2026-05-08 (initial build)

### M1 — Project scaffolding
- Flutter Android-only project at `D:\laragon\www\Cam Scanner\docscan_ar\`.
- Material 3 + dark mode theme (`AppTheme`).
- Riverpod for DI/state, go_router with three-branch StatefulShellRoute
  for the bottom nav (Scanner / Library / Settings).
- Centralized strings in `core/l10n/strings_en.dart`.
- `core/services/logger.dart` wraps `dart:developer` so `avoid_print`
  stays strict.
- `very_good_analysis` enforced; 0 issues at end of M1.

### M2 — Camera + permissions
- `camera` plugin + `permission_handler`.
- `CameraPermissionGate` with grant / open-settings flows.
- Full-bleed `CameraPreviewView` with shutter button and capture stub.
- Bumped `compileSdk` 34→36 (CameraX 1.5.3 requirement).

### M3 — Edge detection + AR overlay
- `EdgeDetector` interface + EMA-smoothed `ScannerController`.
- `PureDartEdgeDetector` (Sobel + extreme-points) at ~10 FPS.
- `EdgeOverlayPainter` for the live AR-style polygon overlay.
- HUD hints driven by contour stability (Looking / Move closer /
  Hold steady / Capture-ready).
- Auto-capture toggle.
- Attempted `opencv_dart 1.4.5`; its CMake/NDK step fails on this
  Windows host (path has a space, cross-drive layout). Fell back to
  pure-Dart per the spec's documented contingency.

### M4 — Corner adjuster + magnifier loupe
- `CornerAdjusterView` with 4 draggable handles.
- `MagnifierLoupe` (~120dp diameter, 2.5× zoom, offset above the
  finger, flips below if it would clip the top edge).

### M5 — Perspective warp + 5 filters
- `ImagePipeline.rectify` via `image.copyRectify` with
  source-channel-matched destination.
- Five filters: Original, Auto-Enhance, Grayscale, B&W
  (adaptive-ish via gaussian-blur reference), Magic Color.
- Editor uses `compute()` so warp + filter run in an isolate.

### M6 — Local DB + Library
- `sqflite`-backed `DbService` with `documents` and `pages` tables,
  cascade-delete, batched reorder.
- `StorageService` writes page images under
  `<docs>/pages/<docId>/<ts>.jpg`.
- Library grid with cover thumbnail + title + relative date,
  long-press → rename / delete.

### M7 — Multi-page flow
- `ScanSessionController` collects in-progress page bytes.
- `ScanSessionReviewPage` shown after each capture: Add another /
  Done. Done writes the new Document + pages.
- Document detail page supports drag-handle reorder + swipe-to-delete.

### M8 — Export + share
- `ExportService.exportPdf` (configurable PdfPageFormat, default
  A4), `exportJpgs`, `exportTxt`.
- Outputs land in `<external>/{Documents,Pictures}/DocScanAR/`.
- `share_plus` opens the system share sheet for the resulting files.
- `ExportCounter` + `shouldShowInterstitialAfter` drive the M10 ad.

### M9 — OCR
- `OcrService` runs Google ML Kit text recognition on each page,
  persists `pages.ocr_text`.
- `OcrTextPage` renders a copyable `SelectableText` + Copy action.
- `.txt` export reuses the same body format.

### M10 — AdMob
- `google_mobile_ads` initialized in `main`.
- `AdService` lazy-init, banner factory, single preloaded
  interstitial.
- `BannerAdView` mounted at the bottom of the Library screen.
- Interstitial shown after every 3rd successful export (subject to
  the `adsHidden` entitlement gate).
- AdMob app ID + ad unit IDs are Google's official test values.
  `TODO(release)` comments mark the swap points.

### M11 — IAP / paywall
- `IapController` subscribes to `purchaseStream`, queries
  `remove_ads_monthly`, persists entitlement in
  `shared_preferences`, re-verifies on every app start via
  `restorePurchases`.
- `PaywallPage` reachable from Settings → Remove Ads.
- Restore button.
- `adsHiddenProvider` lets ad widgets hide themselves immediately
  on entitlement change.

### M12 — Settings
- Theme cycle (system → light → dark) via `themeModeProvider`.
- Remove Ads CTA wired to the paywall.
- Restore Purchases.
- About + Privacy URL placeholder.

### M13 — Icon / splash placeholders
- `flutter_launcher_icons` + `flutter_native_splash` configured in
  pubspec.yaml; awaiting PNG assets at `assets/icon/`.
- README documents the one-time icon generation step.

### M14 — Regression
- `flutter analyze` → 0 issues.
- `flutter test` → 13 tests passing (Quad math, image pipeline,
  Library + Settings widget tests).
- `flutter build apk --debug` succeeds.
- `flutter build apk --release` documented in README; signing
  config is the spec's debug fallback until the user wires a
  release keystore.
