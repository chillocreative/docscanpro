/// AdMob unit identifiers.
///
/// During development we use Google's official **test** ad unit IDs
/// so we never accidentally bill a real account.
///
// TODO(release): replace with production IDs before release and verify the
// AdMob app ID meta-data in AndroidManifest.xml.
class AdIds {
  const AdIds._();

  // Google official test ad unit IDs (Android).
  // https://developers.google.com/admob/android/test-ads
  static const String testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';

  /// AdMob app ID used in the AndroidManifest meta-data.
  /// Test value below — REPLACE for release.
  static const String testAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';

  static String get bannerAndroid => testBannerAndroid;
  static String get interstitialAndroid => testInterstitialAndroid;
}
