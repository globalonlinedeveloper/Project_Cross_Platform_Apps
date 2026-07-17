import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/subscription.dart';

/// Human "due in N days" label + urgency color, shared by Home/Calendar/Detail.
class DueInfo {
  const DueInfo(this.label, this.color);
  final String label;
  final Color color;

  static DueInfo of(Subscription s, DateTime now) {
    final int d = s.daysUntil(now);
    if (d <= 0) return const DueInfo('Due today', AppColors.warn);
    if (d == 1) return const DueInfo('Renews tomorrow', AppColors.warn);
    if (d <= 5) return DueInfo('In $d days', AppColors.accent);
    return DueInfo('In $d days', AppColors.muted);
  }
}
