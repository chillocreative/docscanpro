import 'package:doc_scan_ar/core/constants/app_constants.dart';
import 'package:doc_scan_ar/core/providers/theme_mode_provider.dart';
import 'package:doc_scan_ar/core/router/app_router.dart';
import 'package:doc_scan_ar/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocScanArApp extends ConsumerWidget {
  const DocScanArApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
    );
  }
}
