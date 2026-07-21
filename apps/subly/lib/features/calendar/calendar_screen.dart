import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/currency.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/subscription.dart';
import '../../state/settings_controller.dart';
import '../../state/subscriptions_controller.dart';
import '../shared/due.dart';
import '../shared/widgets.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const List<String> _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const List<String> _weekdays = <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const List<String> _mon = <String>[
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Currency currency = ref.watch(currencyProvider);
    final List<Subscription> subs =
        ref.watch(subscriptionsControllerProvider).valueOrNull ??
            const <Subscription>[];
    final DateTime now = DateTime.now();
    final int y = now.year, m = now.month;
    final int firstOffset = DateTime(y, m, 1).weekday % 7; // Sun=0
    final int dim = DateTime(y, m + 1, 0).day;

    final Map<int, int> byDay = <int, int>{};
    for (final Subscription s in subs) {
      if (s.nextRenewal.year == y && s.nextRenewal.month == m) {
        byDay[s.nextRenewal.day] = (byDay[s.nextRenewal.day] ?? 0) + 1;
      }
    }
    final List<Subscription> inMonth = subs
        .where((Subscription s) =>
            s.nextRenewal.year == y && s.nextRenewal.month == m)
        .toList()
      ..sort((Subscription a, Subscription b) =>
          a.nextRenewal.day.compareTo(b.nextRenewal.day));
    final double monthTotal = inMonth.fold(
        0.0, (double a, Subscription s) => a + s.monthlyPrice);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 58, 18, 108),
      children: <Widget>[
        Text('Renewal calendar', style: AppText.title.copyWith(fontSize: 26)),
        const SizedBox(height: 4),
        Text('${_months[m - 1]} $y · ${currency.fmt(monthTotal)} renewing',
            style: AppText.muted.copyWith(fontSize: 12)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: Column(
            children: <Widget>[
              Row(
                children: _weekdays
                    .map((String w) => Expanded(
                          child: Center(
                            child: Text(w,
                                style: AppText.label.copyWith(fontSize: 10)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                ),
                itemCount: firstOffset + dim,
                itemBuilder: (BuildContext context, int i) {
                  if (i < firstOffset) return const SizedBox.shrink();
                  final int day = i - firstOffset + 1;
                  final bool today = day == now.day;
                  final bool has = byDay.containsKey(day);
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: today ? AppColors.brandGradient : null,
                      color: today
                          ? null
                          : (has
                              ? const Color.fromRGBO(100, 89, 245, 0.1)
                              : Colors.transparent),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('$day',
                            style: AppText.fig.copyWith(
                                fontSize: 12,
                                color: today ? Colors.white : AppColors.ink)),
                        const SizedBox(height: 2),
                        if (has)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: today ? Colors.white : AppColors.accent),
                          )
                        else
                          const SizedBox(height: 4),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SectionHeader('By date'),
        ...inMonth.map((Subscription s) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _dateRow(context, currency, s, now),
            )),
        if (inMonth.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('No renewals this month.', style: AppText.muted),
          ),
      ],
    );
  }

  Widget _dateRow(
      BuildContext context, Currency currency, Subscription s, DateTime now) {
    final DueInfo due = DueInfo.of(s, now);
    return Container(
      decoration: cardDecoration(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/sub/${s.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 44,
                  child: Column(
                    children: <Widget>[
                      Text('${s.nextRenewal.day}',
                          style: AppText.fig.copyWith(fontSize: 19)),
                      Text(_mon[s.nextRenewal.month - 1],
                          style: AppText.label.copyWith(fontSize: 9)),
                    ],
                  ),
                ),
                Container(
                  width: 3,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(3)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(s.name,
                          style: AppText.body
                              .copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(due.label,
                          style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: due.color)),
                    ],
                  ),
                ),
                Text(currency.fmt(s.monthlyPrice),
                    style: AppText.fig.copyWith(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
