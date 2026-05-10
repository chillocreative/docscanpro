import 'dart:async';

import 'package:doc_scan_ar/app.dart';
import 'package:doc_scan_ar/core/constants/app_constants.dart';
import 'package:doc_scan_ar/core/services/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _log = Logger('main');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Catch anything that escapes the framework so a misbehaving plugin can't
  // black-screen the app at boot.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _log.e('Uncaught Flutter error', details.exception, details.stack);
  };
  // AdMob init is fire-and-forget. If Play Services is missing or the
  // device is offline at first launch, initialize() can throw — swallow it
  // so the rest of the UI still boots. Skipped entirely while ads are
  // disabled via `AppConstants.kAdsEnabled`.
  if (AppConstants.kAdsEnabled) {
    unawaited(_initAdMob());
  }
  runApp(const ProviderScope(child: DocScanArApp()));
}

Future<void> _initAdMob() async {
  try {
    await MobileAds.instance.initialize();
  } on Object catch (e, st) {
    _log.w('MobileAds init failed: $e\n$st');
  }
}
