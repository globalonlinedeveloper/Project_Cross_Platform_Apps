import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format/currency.dart';

class SettingsState {
  const SettingsState({
    this.currencySymbol = r'$',
    this.prefs = const <String, bool>{
      'alerts': true,
      'priceHike': true,
      'unused': true,
      'weekly': false,
    },
  });

  final String currencySymbol;
  final Map<String, bool> prefs;

  SettingsState copyWith({String? currencySymbol, Map<String, bool>? prefs}) =>
      SettingsState(
        currencySymbol: currencySymbol ?? this.currencySymbol,
        prefs: prefs ?? this.prefs,
      );
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void setCurrency(String symbol) =>
      state = state.copyWith(currencySymbol: symbol);

  void toggle(String key) {
    final Map<String, bool> next = Map<String, bool>.of(state.prefs);
    next[key] = !(next[key] ?? false);
    state = state.copyWith(prefs: next);
  }
}

final NotifierProvider<SettingsController, SettingsState>
    settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

/// The active [Currency], derived from the chosen symbol.
final Provider<Currency> currencyProvider = Provider<Currency>(
    (ref) => Currency(ref.watch(settingsControllerProvider).currencySymbol));
