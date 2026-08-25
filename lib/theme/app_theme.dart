import 'package:flutter/material.dart';

/// One UI 8.5-inspired dark theme tuned for the Samsung Galaxy A24.
class AppTheme {
  AppTheme._();

  // Core palette.
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceElevated = Color(0xFF2C2C2E);
  static const Color samsungBlue = Color(0xFF0A5CEA);
  static const Color samsungBluePressed = Color(0xFF0848B5);
  static const Color accent = Color(0xFF0A84FF);
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF453A);
  static const Color onBackground = Color(0xFFF2F2F7);
  static const Color onSurface = Color(0xFFF2F2F7);
  static const Color onSurfaceMuted = Color(0xFF98989F);

  // Overlay subtitle surface (semi-transparent charcoal).
  static const Color overlaySurface = Color(0xFF1C1C1E);
  static const double overlayOpacity = 0.60;
  static const double overlayBlurSigma = 12.0;
  static const double overlayRadius = 24.0;

  static const String arabicFontFamily = 'NotoNaskhArabic';

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: samsungBlue,
        onPrimary: Colors.white,
        secondary: accent,
        surface: surface,
        onSurface: onSurface,
        error: error,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: samsungBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onBackground,
          side: const BorderSide(color: Color(0xFF48484A)),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: onBackground,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          color: onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        bodyLarge: TextStyle(
          color: onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: onSurfaceMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: onBackground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}
