# DocScan Pro

Production-grade, **Android-only** Flutter document scanner. Live edge
detection, manual 4-corner adjustment with a magnifier loupe,
perspective rectification, straighten step, five filters, on-device
OCR with layout-preserving "scanned document" output, multi-page
library, AdMob banners + interstitials, and a one-time **lifetime
Premium** unlock via Google Play Billing.

| | |
|--|--|
| Package ID | `com.docscanar.app` |
| Min / target / compile SDK | 24 / 34 / 36 |
| State / DI | Riverpod 2 |
| Routing | go_router |
| Lint preset | `very_good_analysis` (0 issues enforced) |
| OCR | `google_mlkit_text_recognition` (Latin / Chinese / Japanese / Korean / Devanagari) |

---

## Quick start

The repo's helper script handles every Windows-specific quirk this
machine needs (see [Build environment](#build-environment) below):

```powershell
.\tools\build.ps1 debug      # flutter build apk --debug
.\tools\build.ps1 release    # flutter build apk --release
.\tools\build.ps1 analyze    # flutter analyze
.\tools\build.ps1 test       # flutter test
.\tools\build.ps1 run        # flutter run
```

Or run Flutter directly with the equivalent env in front of it:

```powershell
$env:GRADLE_USER_HOME = 'D:\.gradle'
$env:TMP = 'D:\.tmp'
$env:TEMP = 'D:\.tmp'
$env:Path = 'D:\flt\bin;' + $env:Path
flutter build apk --release
```

The first APK build downloads the Android SDK / NDK and Gradle
dependencies — expect 5–8 minutes. Subsequent builds run in ~2 minutes.

---

## What's inside

```
lib/
├── core/                  app-wide constants, theme, services, router
├── features/
│   ├── ads/               AdMob banner + interstitial wrappers
│   ├── editor/            corner adjuster, straighten, filter strip
│   ├── export/            PDF / JPG / TXT writer + clean-doc renderer
│   ├── library/           home tab, doc list, document detail page
│   ├── ocr/               ML Kit recognizer, preprocessor, viewer
│   ├── onboarding/        splash + first-launch tour
│   ├── paywall/           Google Play Billing wrapper
│   ├── scanner/           live camera, edge detector, scan session
│   └── settings/          settings page + legal pages
└── widgets/               app-shell scaffolding
docs/                       hosted privacy policy + terms (GitHub Pages)
android/                    standard Flutter Android shell
assets/icon/                launcher icons
tools/                      gen_icon.ps1, build.ps1
```

---

## Highlight features

- **Live edge detection** — pure-Dart Sobel + adaptive threshold +
  per-quadrant corner search; no native OpenCV dependency.
- **Editor flow** — Adjust corners → Straighten (90° / fine ±15° slider)
  → Filter (Original / Auto / Grayscale / B&W / Magic Color).
- **OCR** — Google ML Kit, runs entirely on-device. Image is
  preprocessed (EXIF-aware rotation, up-scaling, contrast lift,
  sharpening) in a worker isolate before recognition. Auto-fallback
  to Latin if a non-Latin pass returns very little.
- **Clean "scanned document" export** — when OCR has been run,
  exports use a renderer that draws the recognised text onto a white
  page in the source's exact layout. PDF goes through the `pdf`
  package; JPG goes through `Printing.raster` so font quality matches.
- **Full-bleed photo export** — when there's no OCR, PDF page format
  matches the image's aspect ratio with `marginAll: 0`.
- **Multi-page library** — list / grid views, search by title,
  rename, reorder pages, share, download, delete.
- **Premium** — one-time `premium_lifetime` non-consumable purchase
  via Play Billing. See [`PAYMENT_INTEGRATION.md`](PAYMENT_INTEGRATION.md).

---

## Build environment

Two machine-specific quirks are baked in:

1. **`C:` is at ~0 GB free.** Gradle cache, Java temp, and build
   output all redirect to `D:` so APK builds don't error with
   `There is not enough space on the disk`:
   - `GRADLE_USER_HOME=D:\.gradle`
   - `TMP=D:\.tmp` and `TEMP=D:\.tmp`
   - `org.gradle.jvmargs=… -Djava.io.tmpdir=D:\\.tmp` in
     `android/gradle.properties`

2. **Flutter is installed at a path with a space.** Recent Flutter
   versions invoke a native-asset hook runner that breaks on cmd.exe
   when the SDK path is unquoted. Fix: a directory junction at
   `D:\flt` pointing at the same install but without spaces.
   ```powershell
   cmd /c 'mklink /J "D:\flt" "D:\TEMPORARY FOLDER\flutter\flutter"'
   $env:Path = 'D:\flt\bin;' + $env:Path
   ```

`tools/build.ps1` sets all of this for you.

---

## Hosted privacy policy + terms

A static copy of the privacy policy and terms of service is served
out of [`docs/`](docs/) via GitHub Pages. Once Pages is enabled
(repo Settings → Pages → Source: deploy from `main` branch, folder
`/docs`), the URLs become:

- `https://chillocreative.github.io/docscanpro/privacy.html`
- `https://chillocreative.github.io/docscanpro/terms.html`

These are the URLs to paste into the Google Play Console listing.

---

## Going live on Play Store

See [`PAYMENT_INTEGRATION.md`](PAYMENT_INTEGRATION.md) for the
end-to-end recipe: signing keystore, Play Console product
configuration, internal testing, license testers. The summary:

1. Generate a keystore (don't commit it).
2. Add `android/key.properties` (gitignored) with the signing
   credentials.
3. Wire `release` `signingConfig` in
   `android/app/build.gradle.kts` to read from `key.properties`.
4. `flutter build appbundle --release`.
5. Upload to the **Internal testing** track in Play Console.
6. Create the in-app product `premium_lifetime` (managed product) at
   $4.99.
7. Add yourself as a license tester.

---

## Replace test ads with production

1. In `lib/core/constants/ad_ids.dart`, replace the `test*Android`
   constants with your real AdMob unit IDs and the `testAppIdAndroid`
   with your AdMob app ID.
2. In `android/app/src/main/AndroidManifest.xml`, replace the
   `com.google.android.gms.ads.APPLICATION_ID` meta-data value.
3. Rebuild the release APK.

---

## App icon

Generate the launcher icon (mirrors the splash logo) anytime with:

```powershell
.\tools\gen_icon.ps1
dart run flutter_launcher_icons
```

The PowerShell script renders the icon via System.Drawing because
`dart run` trips on the Flutter SDK path's space when objective_c
hooks are pulled in transitively.

---

## License

[MIT](LICENSE) — see the LICENSE file.

The legal copy in `docs/privacy.html` and `docs/terms.html`
(and the in-app `legal_pages.dart`) is a starting template. Have a
lawyer review it before publishing the app.
