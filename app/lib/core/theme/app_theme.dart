import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final ThemeData base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        secondary: AppColors.accent2,
        surface: AppColors.surface,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Manrope',
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      splashFactory: InkRipple.splashFactory,
      dividerColor: AppColors.line,
    );
  }
}

/// Named text styles matching the design (Manrope body, Space Grotesk numerals).
class AppText {
  AppText._();

  static const TextStyle display = TextStyle(
    fontFamily: 'Space Grotesk',
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.03,
    color: AppColors.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'Space Grotesk',
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.ink,
  );

  /// Tabular figures for money / dates.
  static const TextStyle fig = TextStyle(
    fontFamily: 'Space Grotesk',
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.ink,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  static const TextStyle muted = TextStyle(
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
    fontSize: 11,
    letterSpacing: 0.8,
    color: AppColors.muted,
  );
}
