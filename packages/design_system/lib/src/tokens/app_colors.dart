import 'package:flutter/material.dart';

/// Palette lifted straight from the Subly design tokens.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFFF4F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF141420);
  static const Color muted = Color(0xFF73737F);
  static const Color line = Color(0xFFECECF2);

  static const Color accent = Color(0xFF6459F5);
  static const Color accent2 = Color(0xFF9B6BFF);
  static const Color positive = Color(0xFF10B981);
  static const Color warn = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4D6A);

  // Dark hero / detail header
  static const Color heroA = Color(0xFF1B1930);
  static const Color heroB = Color(0xFF2A2456);
  static const Color heroC = Color(0xFF3A2F6E);
  static const Color onboardBg = Color(0xFF12111C);

  // Category ramp (matches the design's donut/legend order)
  static const List<Color> ramp = <Color>[
    Color(0xFF6459F5),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFFF5D8F),
    Color(0xFF3BC7F5),
    Color(0xFF9B6BFF),
    Color(0xFF5B8DEF),
    Color(0xFFFFB020),
  ];

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[accent, accent2],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[heroA, heroB, heroC],
    stops: <double>[0.0, 0.7, 1.0],
  );
}
