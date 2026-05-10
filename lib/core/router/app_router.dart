import 'package:doc_scan_ar/features/library/presentation/library_page.dart';
import 'package:doc_scan_ar/features/onboarding/presentation/onboarding_page.dart';
import 'package:doc_scan_ar/features/onboarding/presentation/splash_page.dart';
import 'package:doc_scan_ar/features/scanner/presentation/scanner_page.dart';
import 'package:doc_scan_ar/features/settings/presentation/settings_page.dart';
import 'package:doc_scan_ar/widgets/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// App-level go_router. Cold-start flow:
/// `/splash` → (onboarding if first launch) → `/home` (or any branch).
///
/// Three shell branches: `/home`, `/scan`, `/settings`. The bottom bar
/// renders Home/Camera-FAB/Settings; tapping the camera FAB switches to the
/// `/scan` branch, so the bar stays visible across pages.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const LibraryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                builder: (_, __) => const ScannerPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});
