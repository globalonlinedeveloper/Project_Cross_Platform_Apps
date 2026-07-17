import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/subscription.dart';
import 'providers.dart';
import 'settings_controller.dart';

/// Owns the subscription list and keeps on-device reminders in sync with it.
class SubscriptionsController extends AsyncNotifier<List<Subscription>> {
  @override
  Future<List<Subscription>> build() async {
    final List<Subscription> subs =
        await ref.watch(subscriptionRepositoryProvider).fetchAll();
    _syncReminders(subs);
    return subs;
  }

  Future<void> addSubscription(Subscription draft) async {
    final Subscription created =
        await ref.read(subscriptionRepositoryProvider).add(draft);
    final List<Subscription> list = <Subscription>[
      ...state.valueOrNull ?? const <Subscription>[],
      created,
    ];
    state = AsyncData<List<Subscription>>(list);
    _syncReminders(list);
  }

  Future<void> cancelSubscription(String id) async {
    await ref.read(subscriptionRepositoryProvider).cancel(id);
    final List<Subscription> list =
        (state.valueOrNull ?? const <Subscription>[])
            .where((Subscription s) => s.id != id)
            .toList();
    state = AsyncData<List<Subscription>>(list);
    _syncReminders(list);
  }

  void _syncReminders(List<Subscription> subs) {
    final bool alertsOn =
        ref.read(settingsControllerProvider).prefs['alerts'] ?? true;
    if (!alertsOn) return;
    // Fire-and-forget; NotificationService is a no-op on web.
    ref.read(notificationServiceProvider).syncAll(subs);
  }
}

final AsyncNotifierProvider<SubscriptionsController, List<Subscription>>
    subscriptionsControllerProvider =
    AsyncNotifierProvider<SubscriptionsController, List<Subscription>>(
        SubscriptionsController.new);
