import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/currency.dart';
import '../../core/format/sub_math.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/budget_info.dart';
import '../../data/models/subscription.dart';
import '../../state/providers.dart';
import '../../state/settings_controller.dart';
import '../../state/subscriptions_controller.dart';
import '../shared/painters.dart';
import '../shared/widgets.dart';

final FutureProvider<BudgetInfo> budgetProvider = FutureProvider<BudgetInfo>(
    (ref) => ref.watch(subscriptionRepositoryProvider).budget());

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  static const List<String> _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Currency currency = ref.watch(currencyProvider);
    final List<Subscription> subs =
        ref.watch(subscriptionsControllerProvider).valueOrNull ??
            const <Subscription>[];
    final BudgetInfo? budget = ref.watch(budgetProvider).valueOrNull;
    if (budget == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final DateTime now = DateTime.now();
    final double total = SubMath.totalMonthly(subs);
    final double budgetVal = budget.monthlyBudget;
    final bool over = total > budgetVal;
    final double pct = budgetVal <= 0 ? 0 : (total / budgetVal).clamp(0, 1);
    final Map<String, double> capMap = <String, double>{
      for (final BudgetCap c in budget.categories) c.name: c.cap
    };
    final List<CategoryTotal> cats = SubMath.categoryTotals(subs);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 58, 18, 108),
      children: <Widget>[
        Text('Budget & goals', style: AppText.title.copyWith(fontSize: 26)),
        const SizedBox(height: 4),
        Text('${_months[now.month - 1]} ${now.year}',
            style: AppText.muted.copyWith(fontSize: 12)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: cardDecoration(),
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 168,
                height: 168,
                child: CustomPaint(
                  painter: RingPainter(
                      progress: pct, color: over ? AppColors.danger : AppColors.accent),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('${(pct * 100).round()}%',
                            style: AppText.fig.copyWith(
                                fontSize: 34,
                                color: over ? AppColors.danger : AppColors.ink)),
                        Text(over ? 'over budget' : 'of budget',
                            style: AppText.muted.copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _stat('Spent', currency.fmt(total), AppColors.ink),
                  _stat('Left', currency.fmt0(math.max(budgetVal - total, 0)),
                      AppColors.positive),
                  _stat('Budget', currency.fmt0(budgetVal), AppColors.ink),
                ],
              ),
            ],
          ),
        ),
        SectionHeader('By category'),
        for (int i = 0; i < cats.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _categoryBar(currency, cats[i],
                capMap[cats[i].name] ?? cats[i].value * 1.2, i),
          ),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: <Widget>[
        Text(value, style: AppText.fig.copyWith(fontSize: 18, color: color)),
        Text(label, style: AppText.muted.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _categoryBar(Currency currency, CategoryTotal cat, double cap, int i) {
    final bool over = cat.value > cap;
    final double frac = cap <= 0 ? 1 : math.min(cat.value / cap, 1);
    final Color barColor =
        over ? AppColors.danger : AppColors.ramp[i % AppColors.ramp.length];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(cat.name,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
              Text.rich(TextSpan(
                text: currency.fmt0(cat.value),
                style: AppText.fig.copyWith(
                    fontSize: 13, color: over ? AppColors.danger : AppColors.ink),
                children: <InlineSpan>[
                  TextSpan(
                      text: ' / ${currency.fmt0(cap)}',
                      style: AppText.muted.copyWith(fontSize: 13)),
                ],
              )),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: AppColors.line,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}
