import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/currency.dart';
import '../../core/format/sub_math.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/subscription.dart';
import '../../state/settings_controller.dart';
import '../../state/subscriptions_controller.dart';
import '../cancel/cancel_sheet.dart';
import '../shared/painters.dart';
import '../shared/widgets.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Currency currency = ref.watch(currencyProvider);
    final List<Subscription> subs =
        ref.watch(subscriptionsControllerProvider).valueOrNull ??
            const <Subscription>[];
    final double total = SubMath.totalMonthly(subs);
    final List<CategoryTotal> cats = SubMath.categoryTotals(subs);
    final List<Subscription> unused = SubMath.unused(subs);
    final double savings = SubMath.savings(subs);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 58, 18, 108),
      children: <Widget>[
        Text('Insights', style: AppText.title.copyWith(fontSize: 26)),
        const SizedBox(height: 4),
        Text('Where your money goes', style: AppText.muted.copyWith(fontSize: 12)),
        const SizedBox(height: 16),
        _trendCard(currency, total),
        const SizedBox(height: 14),
        _categoryCard(currency, cats, total),
        const SizedBox(height: 14),
        _savingsCard(context, currency, unused, savings),
      ],
    );
  }

  Widget _trendCard(Currency currency, double total) {
    final List<double> vals = <double>[142, 156, 151, 168, 174, total];
    const List<String> labels = <String>['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
    final double maxV = vals.reduce(math.max) * 1.15;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('6-month trend', style: AppText.title.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(vals.length, (int i) {
                final bool last = i == vals.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(currency.fmt0(vals[i]),
                            style: AppText.fig.copyWith(fontSize: 10)),
                        const SizedBox(height: 6),
                        Container(
                          height: (vals[i] / maxV) * 104,
                          decoration: BoxDecoration(
                            gradient: last ? AppColors.brandGradient : null,
                            color: last ? null : const Color(0xFFD9D5FB),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8), bottom: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(labels[i], style: AppText.label.copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(Currency currency, List<CategoryTotal> cats, double total) {
    final List<MapEntry<double, Color>> segments = <MapEntry<double, Color>>[
      for (int i = 0; i < cats.length; i++)
        MapEntry<double, Color>(cats[i].value, AppColors.ramp[i % AppColors.ramp.length]),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('By category', style: AppText.title.copyWith(fontSize: 16)),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              SizedBox(
                width: 126,
                height: 126,
                child: CustomPaint(
                  painter: DonutPainter(segments: segments),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(currency.fmt0(total),
                            style: AppText.fig.copyWith(fontSize: 18)),
                        Text('/ mo', style: AppText.muted.copyWith(fontSize: 9)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < cats.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: AppColors.ramp[i % AppColors.ramp.length],
                                  borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(cats[i].name,
                                  style: AppText.body.copyWith(
                                      fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                            Text(currency.fmt0(cats[i].value),
                                style: AppText.fig
                                    .copyWith(fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _savingsCard(BuildContext context, Currency currency,
      List<Subscription> unused, double savings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Savings opportunities', style: AppText.title.copyWith(fontSize: 16)),
              const SizedBox(width: 8),
              Pill('${currency.fmt(savings)}/mo',
                  bg: const Color.fromRGBO(16, 185, 129, 0.12), fg: AppColors.positive),
            ],
          ),
          const SizedBox(height: 12),
          for (final Subscription s in unused)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: <Widget>[
                    GlyphTile(glyph: s.glyph, size: 40, fontSize: 11),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(s.name,
                              style: AppText.body
                                  .copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(s.usageNote,
                              style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppColors.warn)),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: GradientButton(
                        label: 'Cancel',
                        height: 36,
                        fontSize: 12,
                        onPressed: () => showCancelSheet(context, s),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (unused.isEmpty)
            Text('Nothing flagged — nice.', style: AppText.muted),
        ],
      ),
    );
  }
}
