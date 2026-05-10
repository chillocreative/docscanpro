import 'package:doc_scan_ar/features/ads/data/ad_service.dart';
import 'package:doc_scan_ar/features/paywall/data/iap_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Renders an AdMob banner at the bottom of the Library screen. Hides itself
/// entirely when the user has the "Remove ads" entitlement.
class BannerAdView extends ConsumerStatefulWidget {
  const BannerAdView({super.key});

  @override
  ConsumerState<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends ConsumerState<BannerAdView> {
  BannerAd? _ad;

  @override
  void initState() {
    super.initState();
    _request();
  }

  Future<void> _request() async {
    final svc = ref.read(adServiceProvider);
    await svc.ensureInitialized();
    if (!mounted) return;
    setState(() => _ad = svc.newBanner());
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(adsHiddenProvider)) return const SizedBox.shrink();
    final ad = _ad;
    if (ad == null) return const SizedBox(height: 50);
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
