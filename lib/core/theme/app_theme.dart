import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Builds the app's [ThemeData]. The font family switches per script so
/// Arabic text renders with a face that actually supports it — Heebo
/// (used for Latin + Hebrew, matching the reference web app's `--font-sans:
/// "Heebo"`) has no Arabic glyphs.
abstract final class AppTheme {
  static const _radius = 22.0;

  static String fontFamilyFor(String languageCode) {
    return languageCode == 'ar' ? 'NotoSansArabic' : 'Heebo';
  }

  static ThemeData light(String languageCode) {
    final fontFamily = fontFamilyFor(languageCode);
    final colorScheme = const ColorScheme.light().copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      surface: AppColors.surface,
      onSurface: AppColors.foreground,
      error: AppColors.destructive,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: Typography.blackMountainView.apply(fontFamily: fontFamily),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        hintStyle: TextStyle(
          color: AppColors.mutedForeground,
          fontFamily: fontFamily,
        ),
      ),
      // NOTE: no `minimumSize: Size.fromHeight(...)` here on purpose. That
      // pins minWidth to infinity, which crashes ("BoxConstraints forces an
      // infinite width") the moment a plain FilledButton/OutlinedButton is
      // used somewhere *not* full-width — e.g. next to a TextField in a Row,
      // or inside a Column without stretch. The app's actual full-width CTA
      // is the custom PrimaryGradientButton, which doesn't use these Material
      // widgets at all, so this theme has nothing that legitimately needs a
      // forced-infinite minimum width. Compact, content-sized buttons are the
      // safe default; individual call sites opt into full width explicitly
      // (see CampusEventCard's FilledButton for the pattern).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        // Light (white) status bar icons/text, matching the colored app bar
        // — the standard look for a non-white app bar. `statusBarColor`
        // stays transparent since the AppBar already paints that area
        // itself (edge-to-edge); only the icon/text brightness needs to
        // change per platform (Android reads `statusBarIconBrightness`,
        // iOS reads `statusBarBrightness`).
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static ThemeData dark(String languageCode) {
    // `base` already carries the right font family via its textTheme
    // (baked in by `light()`'s ThemeData constructor), so there's nothing
    // font-related left to override here.
    final base = light(languageCode);
    final colorScheme = const ColorScheme.dark().copyWith(
      primary: AppColors.darkPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkForeground,
    );
    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
  }
}
