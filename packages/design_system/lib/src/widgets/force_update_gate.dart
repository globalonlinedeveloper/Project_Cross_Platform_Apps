import 'package:flutter/material.dart';

/// A blocking gate that replaces the app with an "update required" screen when
/// [mustUpdate] is true, otherwise shows [child]. The force-update DECISION
/// lives in `core` (`mustForceUpdate(current, minSupported)`, the CFG G-14
/// kill-switch); this widget is presentational only, so `design_system` stays
/// free of a domain dependency. Wrap the app's home:
/// `ForceUpdateGate(mustUpdate: core.mustForceUpdate(v, cfg.minSupportedVersion),
/// onUpdate: ..., child: HomeScreen())`.
class ForceUpdateGate extends StatelessWidget {
  const ForceUpdateGate({
    super.key,
    required this.mustUpdate,
    required this.child,
    this.onUpdate,
    this.title = 'Update required',
    this.message =
        'This version is no longer supported. Please update to keep using the app.',
    this.buttonLabel = 'Update now',
  });

  /// Whether the running version is below the supported floor.
  final bool mustUpdate;

  /// The normal app content, shown when no update is required.
  final Widget child;

  /// Invoked when the user taps the update button (e.g. open the store listing).
  /// When null the button is hidden (the screen still blocks the app).
  final VoidCallback? onUpdate;

  final String title;
  final String message;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    if (!mustUpdate) return child;
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.system_update_outlined,
                      size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 20),
                  Text(title,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(message,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                  if (onUpdate != null) ...<Widget>[
                    const SizedBox(height: 28),
                    FilledButton(onPressed: onUpdate, child: Text(buttonLabel)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
