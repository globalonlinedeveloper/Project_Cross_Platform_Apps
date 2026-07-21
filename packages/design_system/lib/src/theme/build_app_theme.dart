import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import 'app_theme_x.dart';

/// Builds the NIKATRU [ThemeData] for a [seed] colour and [brightness].
///
/// The light theme reproduces Subly's original palette exactly (so existing
/// screens render byte-for-byte the same); the dark theme derives a matching
/// Material 3 scheme from the same seed. Either way the brand tokens that don't
/// fit [ColorScheme] ride along as an [AppThemeX] extension.
ThemeData buildAppTheme({
  Color seed = AppColors.accent,
  Brightness brightness = Brightness.light,
}) {
  final bool isLight = brightness == Brightness.light;
  final ThemeData base = ThemeData(useMaterial3: true, brightness: brightness);

  final ColorScheme scheme = isLight
      ? ColorScheme.fromSeed(
          seedColor: seed,
          primary: AppColors.accent,
          secondary: AppColors.accent2,
          surface: AppColors.surface,
        )
      : ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          primary: AppColors.accent2,
          secondary: AppColors.accent,
        );

  final Color ink = isLight ? AppColors.ink : const Color(0xFFF4F4F8);

  return base.copyWith(
    scaffoldBackgroundColor: isLight ? AppColors.bg : AppColors.onboardBg,
    colorScheme: scheme,
    textTheme: base.textTheme.apply(
      fontFamily: 'Manrope',
      bodyColor: ink,
      displayColor: ink,
    ),
    splashFactory: InkRipple.splashFactory,
    dividerColor: isLight ? AppColors.line : const Color(0xFF2A2A38),
    extensions: <ThemeExtension<dynamic>>[
      isLight ? AppThemeX.light : AppThemeX.dark,
    ],
  );
}

/// Backwards-compatible façade for the original `AppTheme.light()` call site.
///
/// Kept so app code that predates [buildAppTheme] keeps compiling unchanged.
class AppTheme {
  AppTheme._();

  /// The original Subly light theme — now delegates to [buildAppTheme].
  static ThemeData light() => buildAppTheme(brightness: Brightness.light);

  /// Dark counterpart built from the same tokens.
  static ThemeData dark() => buildAppTheme(brightness: Brightness.dark);
}
