/// Centralized brand + product constants. Renaming the app is a single edit.
class AppConstants {
  const AppConstants._();

  static const String appName = 'DocScan Pro';
  static const String appTagline = 'Scan. Save. Share.';
  static const String appPackage = 'com.docscanar.app';
  static const String appVersionLabel = 'v1.0.1';

  /// Developer support contact. Shown on the Help Center and About pages.
  static const String supportEmail = 'chillocreative@gmail.com';

  /// Pretty price tag rendered on the Premium card. The actual price the
  /// user is charged comes from Google Play's `ProductDetails.price` once
  /// the SKU below is configured in Play Console; this string is the
  /// pre-store fallback.
  static const String premiumPriceCopy = r'$4.99 lifetime';

  /// Google Play Store deep link. Tries the native `market://` first and
  /// falls back to the https URL on devices without the Play app.
  static const String playStoreMarketUrl =
      'market://details?id=$appPackage';
  static const String playStoreHttpsUrl =
      'https://play.google.com/store/apps/details?id=$appPackage';

  /// Public hosted copies of the legal documents — served from
  /// GitHub Pages off the project repo's `docs/` folder. These are
  /// the URLs to paste into the Google Play Console listing's
  /// "Privacy Policy" and "App Content" fields. The in-app pages
  /// (`PrivacyPolicyPage`, `TermsOfServicePage`) carry the same copy
  /// for offline access.
  static const String publicSiteBase =
      'https://chillocreative.github.io/docscanpro';
  static const String publicPrivacyPolicyUrl =
      '$publicSiteBase/privacy.html';
  static const String publicTermsUrl = '$publicSiteBase/terms.html';

  /// Default PDF page size key for export.
  static const String defaultPdfPageSize = 'a4';

  /// Show interstitial after every N successful exports.
  static const int interstitialEveryNExports = 3;

  /// Master switch for AdMob. When `false`, the SDK is never initialized,
  /// banners short-circuit to empty widgets, the export-counter
  /// interstitial is suppressed, and the "Ads Active" upsell banner on
  /// My Documents is hidden. Now `true` because the production AdMob
  /// IDs are wired up (see `AdIds`); set to `false` if you ever need to
  /// kill ads without uninstalling the SDK.
  static const bool kAdsEnabled = true;

  /// IAP product ID for the lifetime premium upgrade.
  ///
  /// Must be configured in Google Play Console as a **managed product**
  /// (one-time purchase), NOT a subscription. The IAP code calls
  /// `buyNonConsumable` against this SKU.
  static const String premiumLifetimeSku = 'premium_lifetime';
}
