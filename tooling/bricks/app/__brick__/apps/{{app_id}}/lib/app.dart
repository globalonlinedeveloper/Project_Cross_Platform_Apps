import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nikatru_design_system/nikatru_design_system.dart';

import 'core/app_config.dart';
import 'core/router.dart';

/// Root widget for {{display_name}}.
class {{app_id.pascalCase()}}App extends ConsumerWidget {
  const {{app_id.pascalCase()}}App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
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
