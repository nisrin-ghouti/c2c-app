import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradients ported 1:1 from the reference web app's `.bg-gradient-hero`
/// and `.bg-gradient-primary` CSS classes.
abstract final class AppGradients {
  /// Full-screen background behind every auth screen.
  static const hero = LinearGradient(
    begin: Alignment(-0.8, -1),
    end: Alignment(0.8, 1),
    colors: [
      AppColors.gradientHeroStart,
      AppColors.gradientHeroMid,
      AppColors.gradientHeroEnd,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Primary call-to-action buttons.
  static const primary = LinearGradient(
    begin: Alignment(-0.7, -1),
    end: Alignment(0.7, 1),
    colors: [AppColors.gradientPrimaryStart, AppColors.gradientPrimaryEnd],
  );

  /// Home's "take a survey" banner.
  static const survey = LinearGradient(
    begin: Alignment(-0.7, -1),
    end: Alignment(0.7, 1),
    colors: [AppColors.mint, AppColors.success],
  );
}
