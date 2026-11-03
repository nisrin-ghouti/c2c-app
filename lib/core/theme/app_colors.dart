import 'package:flutter/material.dart';

/// Color tokens ported from the reference web app's `styles.css`
/// (OKLCH custom properties, converted to sRGB hex). Keeping these as named
/// constants — rather than scattering hex literals through the widget
/// tree — is what lets [AppTheme] and every screen agree on one palette.
abstract final class AppColors {
  // Light palette
  static const background = Color(0xFFFEF9F1); // warm cream
  static const foreground = Color(0xFF2A253B); // deep plum
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF6F3FE);
  static const card = Color(0xFFFFFFFF);

  static const primary = Color(0xFFBC97E8); // lavender
  static const primaryForeground = Color(0xFF1D1333);
  static const primaryGlow = Color(0xFFD8B2F5);

  /// Saturated violet for selected-state icons/labels (bottom nav, active
  /// tabs). [primary] is a pale lavender that reads pinkish/washed-out as a
  /// text or icon tint on white surfaces — this is the same hue pushed dark
  /// enough to be unmistakably "the app's primary color", matching the
  /// selected-tab label in the reference design.
  static const primaryStrong = Color(0xFF8B5CF6);

  static const secondary = Color(0xFF94DEF5); // baby blue
  static const secondaryForeground = Color(0xFF10213E);

  static const muted = Color(0xFFF3F0F9);
  static const mutedForeground = Color(0xFF646073);

  static const accentMint = Color(0xFFB3EDD3);
  static const accentForeground = Color(0xFF002A1D);

  static const success = Color(0xFF61D19A);
  static const successForeground = Color(0xFF001D0E);
  static const destructive = Color(0xFFF16F78);

  static const border = Color(0xFFE9E6EF);
  static const input = Color(0xFFECE9F2);
  static const ring = Color(0xFFBC97E8);

  // Pastel accent tiles (dashboard stat cards, tags)
  static const mint = Color(0xFFA5E9CA);
  static const peach = Color(0xFFFFCFAF);
  static const sky = Color(0xFFB2E8FA);
  static const pink = Color(0xFFFFB9C3);

  // Gradient stops
  static const gradientPrimaryStart = Color(0xFFC8A5F0);
  static const gradientPrimaryEnd = Color(0xFF94DEF5);

  static const gradientHeroStart = Color(0xFFE4CBFF);
  static const gradientHeroMid = Color(0xFFAAEAFE);
  static const gradientHeroEnd = Color(0xFFACEFD1);

  // Dark palette
  static const darkBackground = Color(0xFF171322);
  static const darkForeground = Color(0xFFF6F4FB);
  static const darkSurface = Color(0xFF231E31);
  static const darkPrimary = Color(0xFFC9A3F5);
}
