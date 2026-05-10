import 'package:flutter/foundation.dart';

/// AdMob unit identifiers.
///
/// In `kDebugMode` the app falls back to Google's official **test** unit
/// IDs — those never bill a real account and are documented at
/// <https://developers.google.com/admob/android/test-ads>.
/// Release builds use the production IDs supplied by AdMob for
/// publisher account `ca-app-pub-3464451429907034`.
///
/// **Important:** the AdMob app ID lives separately in
/// `android/app/src/main/AndroidManifest.xml` as a `<meta-data>` entry
/// (`com.google.android.gms.ads.APPLICATION_ID`). Keep the value below
/// in sync with that meta-data tag — the SDK refuses to initialise if
/// they disagree.
class AdIds {
  const AdIds._();

  // ---------- Production (Android) ----------

  /// AdMob app ID for publisher `ca-app-pub-3464451429907034`. Mirrors
  /// the `<meta-data>` value in AndroidManifest.xml.
  static const String prodAppIdAndroid =
      'ca-app-pub-3464451429907034~4744178919';

  /// Banner ad unit (currently used by the Library tab footer).
  static const String prodBannerAndroid =
      'ca-app-pub-3464451429907034/2120289116';

  /// Interstitial ad unit (shown after every Nth successful export per
  /// `AppConstants.interstitialEveryNExports`).
  static const String prodInterstitialAndroid =
      'ca-app-pub-3464451429907034/5706356501';

  /// Native ad unit. Created in AdMob and reserved here for a future
  /// in-feed placement; the app does not load native ads yet.
  static const String prodNativeAndroid =
      'ca-app-pub-3464451429907034/8713617624';

  /// Rewarded ad unit. Created in AdMob and reserved here for a future
  /// `watch ad to unlock X` flow; the app does not load rewarded ads
  /// yet.
  static const String prodRewardedAndroid =
      'ca-app-pub-3464451429907034/9015046123';

  // ---------- Test (Android) ----------

  // Google's official test ad unit IDs (Android).
  // https://developers.google.com/admob/android/test-ads
  static const String testAppIdAndroid =
      'ca-app-pub-3940256099942544~3347511713';
  static const String testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';

  // ---------- Active resolution ----------

  /// Active banner unit. Production in release, test in debug — keeps
  /// `flutter run` from accidentally racking up impressions against the
  /// real account.
  static String get bannerAndroid =>
      kDebugMode ? testBannerAndroid : prodBannerAndroid;

  /// Active interstitial unit. Production in release, test in debug.
  static String get interstitialAndroid =>
      kDebugMode ? testInterstitialAndroid : prodInterstitialAndroid;
}
