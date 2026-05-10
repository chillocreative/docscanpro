import 'dart:async';

import 'package:doc_scan_ar/core/constants/app_constants.dart';
import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/core/theme/app_theme.dart';
import 'package:doc_scan_ar/features/onboarding/data/onboarding_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Solid-blue splash with the DocScan Pro logo card. Resolves the
/// `seenOnboarding` flag and routes to onboarding (first launch) or the
/// main shell (every subsequent launch). Holds for at least 1.2s so the
/// brand has a beat to land.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Best effort: even if SharedPreferences is slow, we always show splash
    // for at least this long so the brand reads.
    _timer = Timer(const Duration(milliseconds: 1200), _decideNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _decideNext() async {
    try {
      final state = await ref.read(onboardingStateProvider.future);
      if (!mounted) return;
      context.go(state.seen ? '/home' : '/onboarding');
    } on Object {
      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.brandBlue,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LogoCard(),
              SizedBox(height: 28),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                S.appTagline,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White rounded-square card with the scan-brackets glyph, matching the
/// splash screenshot.
class _LogoCard extends StatelessWidget {
  const _LogoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.document_scanner_outlined,
          size: 76,
          color: AppTheme.brandBlue,
        ),
      ),
    );
  }
}
