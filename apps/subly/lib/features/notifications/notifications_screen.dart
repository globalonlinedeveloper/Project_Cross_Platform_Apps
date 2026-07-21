import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/currency.dart';
import '../../core/format/sub_math.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/subscription.dart';
import '../../state/settings_controller.dart';
import '../../state/subscriptions_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Currency currency = ref.watch(currencyProvider);
    final List<Subscription> subs =
        ref.watch(subscriptionsControllerProvider).valueOrNull ??
            const <Subscription>[];
    final double savings = SubMath.savings(subs);

    final List<_Notif> items = <_Notif>[
      _Notif(Icons.priority_high, AppColors.warn,
          const Color.fromRGBO(245, 158, 11, 0.13), '2 subscriptions look unused',
          'Adobe CC and Disney+ haven’t been opened in weeks. Cancel to save ${currency.fmt(savings)}/mo.',
          '2h ago'),
      _Notif(Icons.trending_up, AppColors.danger,
          const Color.fromRGBO(239, 77, 106, 0.12), 'Netflix price increased',
          'Premium went from ${currency.fmt(13.99)} to ${currency.fmt(15.49)}/mo.',
          'Yesterday'),
      _Notif(Icons.notifications_none, AppColors.accent,
          const Color.fromRGBO(100, 89, 245, 0.12), 'Spotify renews in 2 days',
          '${currency.fmt(11.99)} will be charged on Jul 19.', 'Yesterday'),
      _Notif(Icons.notifications_none, AppColors.accent,
          const Color.fromRGBO(100, 89, 245, 0.12), 'ChatGPT Plus renews soon',
          '${currency.fmt(20)} on Jul 20.', '2d ago'),
      _Notif(Icons.check_rounded, AppColors.positive,
          const Color.fromRGBO(16, 185, 129, 0.13), 'You’re under budget',
          'Spending is below your monthly cap.', '3d ago'),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Notifications', style: AppText.title.copyWith(fontSize: 22)),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line)),
                      child: const Icon(Icons.close, size: 18, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int i) => _card(items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(_Notif n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: n.bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(n.icon, color: n.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(n.title,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(n.body,
                    style: AppText.muted.copyWith(fontSize: 13, height: 1.45)),
                const SizedBox(height: 6),
                Text(n.time.toUpperCase(), style: AppText.label.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notif {
  const _Notif(this.icon, this.color, this.bg, this.title, this.body, this.time);
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String body;
  final String time;
}
