import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nikatru_design_system/nikatru_design_system.dart';

import 'core/app_config.dart';
import 'core/router.dart';
import 'state/providers.dart';

/// Root widget for {{display_name}}.
class {{app_id.pascalCase()}}App extends ConsumerWidget {
  const {{app_id.pascalCase()}}App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Kick off CFG-1 runtime-config resolution at launch. Offline-safe: it falls
    // back to the compiled-in default, so this never blocks the UI. Consumers
    // read appConfigProvider (e.g. api_base_url, feature flags, force-update).
    ref.watch(appConfigProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(seed: const Color(0xFF{{{seed_hex}}})),
      darkTheme: buildAppTheme(
        seed: const Color(0xFF{{{seed_hex}}}),
        brightness: Brightness.dark,
      ),
      routerConfig: router,
    );
  }
}
