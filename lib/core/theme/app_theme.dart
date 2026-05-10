import 'package:flutter/material.dart';

/// Material 3 themes for DocScan AR. Single seed color drives both light and
/// dark variants so brand changes are a one-line edit.
class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFF2563EB); // calm slate-blue
  static const Color brandBlue = Color(0xFF2563EB);
  static const Color amberWarn = Color(0xFFF59E0B);
  static const Color premiumStart = Color(0xFFFF9500);
  static const Color premiumEnd = Color(0xFFFF6B00);
  static const Color introIconPurple = Color(0xFF9333EA);
  static const Color introIconGreen = Color(0xFF22C55E);
  static const Color pdfRed = Color(0xFFEF4444);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
