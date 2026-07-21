import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Brand tokens that don't map cleanly onto [ColorScheme] — status colours,
/// the muted/line neutrals, the brand + hero gradients and the category ramp.
///
/// Read them anywhere with `Theme.of(context).extension<AppThemeX>()!`.
@immutable
class AppThemeX extends ThemeExtension<AppThemeX> {
  const AppThemeX({
    required this.positive,
    required this.warn,
    required this.danger,
    required this.muted,
    required this.line,
    required this.brandGradient,
    required this.heroGradient,
    required this.categoryRamp,
  });

  final Color positive;
  final Color warn;
  final Color danger;
  final Color muted;
  final Color line;
  final Gradient brandGradient;
  final Gradient heroGradient;
  final List<Color> categoryRamp;

  /// Light-mode brand tokens (the original Subly values).
  static const AppThemeX light = AppThemeX(
    positive: AppColors.positive,
    warn: AppColors.warn,
    danger: AppColors.danger,
    muted: AppColors.muted,
    line: AppColors.line,
    brandGradient: AppColors.brandGradient,
    heroGradient: AppColors.heroGradient,
    categoryRamp: AppColors.ramp,
  );

  /// Dark-mode brand tokens — same accents, a darker divider neutral.
  static const AppThemeX dark = AppThemeX(
    positive: AppColors.positive,
    warn: AppColors.warn,
    danger: AppColors.danger,
    muted: AppColors.muted,
    line: Color(0xFF2A2A38),
    brandGradient: AppColors.brandGradient,
    heroGradient: AppColors.heroGradient,
    categoryRamp: AppColors.ramp,
  );

  @override
  AppThemeX copyWith({
    Color? positive,
    Color? warn,
    Color? danger,
    Color? muted,
    Color? line,
    Gradient? brandGradient,
    Gradient? heroGradient,
    List<Color>? categoryRamp,
  }) {
    return AppThemeX(
      positive: positive ?? this.positive,
      warn: warn ?? this.warn,
      danger: danger ?? this.danger,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      brandGradient: brandGradient ?? this.brandGradient,
      heroGradient: heroGradient ?? this.heroGradient,
      categoryRamp: categoryRamp ?? this.categoryRamp,
    );
  }

  @override
  AppThemeX lerp(covariant ThemeExtension<AppThemeX>? other, double t) {
    if (other is! AppThemeX) {
      return this;
    }
    return AppThemeX(
      positive: Color.lerp(positive, other.positive, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      brandGradient: Gradient.lerp(brandGradient, other.brandGradient, t) ?? brandGradient,
      heroGradient: Gradient.lerp(heroGradient, other.heroGradient, t) ?? heroGradient,
      categoryRamp: t < 0.5 ? categoryRamp : other.categoryRamp,
    );
  }
}
