import 'package:flutter/material.dart';

/// A single navigation destination for [AppScaffold].
@immutable
class AppDestination {
  const AppDestination({
    required this.icon,
    required this.label,
    IconData? selectedIcon,
  }) : selectedIcon = selectedIcon ?? icon;

  /// Icon shown when the destination is not selected.
  final IconData icon;

  /// Icon shown when the destination is selected (defaults to [icon]).
  final IconData selectedIcon;

  /// Human-readable label.
  final String label;
}

/// Width breakpoints (logical pixels) at which [AppScaffold] swaps the
/// navigation affordance. Loosely follows Material 3's window size classes.
class AppBreakpoints {
  AppBreakpoints._();

  /// Below this width → a bottom [NavigationBar] (compact).
  static const double medium = 640;

  /// At/above this width → a permanent [NavigationDrawer] (expanded);
  /// between [medium] and this → a [NavigationRail].
  static const double expanded = 1200;
}

/// Hand-rolled adaptive navigation scaffold. Chooses, by available width:
/// a bottom [NavigationBar] (compact), a side [NavigationRail] (medium) or a
/// permanent [NavigationDrawer] (expanded). Replaces the discontinued
/// `flutter_adaptive_scaffold` package with a tiny, dependency-free primitive.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.title,
    this.floatingActionButton,
  }) : assert(destinations.length >= 2, 'AppScaffold needs at least 2 destinations');

  /// The navigation destinations (>= 2).
  final List<AppDestination> destinations;

  /// Index of the currently selected destination.
  final int selectedIndex;

  /// Called with the tapped destination's index.
  final ValueChanged<int> onDestinationSelected;

  /// The primary content.
  final Widget body;

  /// Optional app-bar title widget.
  final Widget? title;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        if (width < AppBreakpoints.medium) {
          return _compact();
        }
        if (width < AppBreakpoints.expanded) {
          return _medium();
        }
        return _expanded();
      },
    );
  }

  PreferredSizeWidget? _appBar() => title == null ? null : AppBar(title: title);

  // Compact: bottom NavigationBar.
  Widget _compact() {
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: <Widget>[
          for (final AppDestination d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }

  // Medium: side NavigationRail + body.
  Widget _medium() {
    return Scaffold(
      appBar: _appBar(),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: <NavigationRailDestination>[
                for (final AppDestination d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  // Expanded: permanent NavigationDrawer + body.
  Widget _expanded() {
    return Scaffold(
      appBar: _appBar(),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 360,
              child: NavigationDrawer(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                children: <Widget>[
                  const SizedBox(height: 12),
                  for (final AppDestination d in destinations)
                    NavigationDrawerDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
