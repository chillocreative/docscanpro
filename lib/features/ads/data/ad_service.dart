import 'dart:async';

import 'package:doc_scan_ar/core/constants/ad_ids.dart';
import 'package:doc_scan_ar/core/constants/app_constants.dart';
import 'package:doc_scan_ar/core/services/logger.dart';
import 'package:doc_scan_ar/features/paywall/data/iap_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _log = Logger('AdService');

/// Wraps `google_mobile_ads`: lazy SDK init, banner factory, and a single
/// preloaded interstitial that the export flow consumes.
class AdService {
  AdService(this._ref);

  final Ref _ref;
  bool _initialized = false;
  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;

  bool get _adsHidden => _ref.read(adsHiddenProvider);
  bool get _adsDisabled => !AppConstants.kAdsEnabled || _adsHidden;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    if (_adsDisabled) return; // Don't even spin up the SDK if disabled.
    await MobileAds.instance.initialize();
    unawaited(_loadInterstitial());
  }

  /// Request a banner ad. Returns null if ads are disabled by feature flag
  /// or hidden by the user's "Remove Ads" entitlement.
  BannerAd? newBanner({AdSize size = AdSize.banner}) {
    if (_adsDisabled) return null;
    final ad = BannerAd(
      adUnitId: AdIds.bannerAndroid,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) {
          _log.w('Banner failed: $err');
          ad.dispose();
        },
      ),
    );
    unawaited(ad.load());
    return ad;
  }

  Future<void> _loadInterstitial() async {
    if (_adsDisabled || _interstitialLoading || _interstitial != null) return;
    _interstitialLoading = true;
    await InterstitialAd.load(
      adUnitId: AdIds.interstitialAndroid,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (err) {
          _log.w('Interstitial failed: $err');
          _interstitialLoading = false;
        },
      ),
    );
  }

  /// Show the preloaded interstitial if one is ready. Returns true if the
  /// ad was shown. The caller is responsible for the per-N-exports cadence.
  Future<bool> maybeShowInterstitial() async {
    if (_adsDisabled) return false;
    final ad = _interstitial;
    if (ad == null) {
      unawaited(_loadInterstitial());
      return false;
    }
    final shownCompleter = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        if (!shownCompleter.isCompleted) shownCompleter.complete(true);
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        unawaited(_loadInterstitial());
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        _log.w('Interstitial show failed: $err');
        ad.dispose();
        _interstitial = null;
        if (!shownCompleter.isCompleted) shownCompleter.complete(false);
      },
    );
    await ad.show();
    return shownCompleter.future;
  }
}

final adServiceProvider = Provider<AdService>((ref) {
  final svc = AdService(ref);
  // Kick off init in the background; the first banner build will wait on it.
  unawaited(svc.ensureInitialized());
  return svc;
});
