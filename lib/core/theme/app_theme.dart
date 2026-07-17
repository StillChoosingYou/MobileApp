import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sampled directly from the real PGPC seal (`assets/images/pgpc_logo.png`)
/// via k-means clustering on the seal's ink colors — no longer a guess.
/// Everything else in the theme derives from these two seeds via
/// [ColorScheme.fromSeed], so if the college ever issues an official
/// Pantone/hex spec, swapping these two constants re-themes the whole app.
class AppColors {
  AppColors._();

  static const Color royalBlueSeed = Color(0xFF102A6D);
  static const Color goldSeed = Color(0xFFDABD64);
  static const Color goldAccentDark = Color(0xFFE8CC7A);

  static const Color success = Color(0xFF2E7D4F);
  static const Color warning = Color(0xFFB8860B);
  static const Color danger = Color(0xFFB3261E);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.royalBlueSeed,
      brightness: brightness,
      secondary: isDark ? AppColors.goldAccentDark : AppColors.goldSeed,
      tertiary: AppColors.royalBlueSeed,
    );

    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    final displayFont = GoogleFonts.playfairDisplayTextTheme(baseTextTheme);
    final bodyFont = GoogleFonts.interTextTheme(baseTextTheme);
    final textTheme = bodyFont.copyWith(
      displayLarge: displayFont.displayLarge,
      displayMedium: displayFont.displayMedium,
      displaySmall: displayFont.displaySmall,
      headlineLarge: displayFont.headlineLarge,
      headlineMedium: displayFont.headlineMedium,
      headlineSmall: displayFont.headlineSmall,
      titleLarge: displayFont.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHighest : scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        elevation: 1,
      ),
      dividerColor: scheme.outlineVariant,
    );
  }
}
