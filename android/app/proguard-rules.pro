# DocScan AR — keep rules for release/minified builds.
#
# To turn R8 back on, set `isMinifyEnabled = true` in `build.gradle.kts`.
# These rules cover every native plugin we depend on; if you add a new one,
# extend this file.

# ---------- ML Kit ----------
# Optional scripts (Chinese, Devanagari, Japanese, Korean) are referenced via
# reflection by `google_mlkit_text_recognition` even when you only use Latin.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.odml.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# ---------- AdMob ----------
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.ads.**

# ---------- Google Play Billing (in_app_purchase) ----------
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }
-dontwarn com.android.billingclient.**

# ---------- camera / CameraX ----------
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# ---------- pdf / printing ----------
-keep class com.tom_roush.pdfbox.** { *; }
-dontwarn com.tom_roush.pdfbox.**

# ---------- Flutter plugin generic ----------
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ---------- Kotlin / coroutines ----------
-keep class kotlin.Metadata { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ---------- Default Flutter rules ----------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
