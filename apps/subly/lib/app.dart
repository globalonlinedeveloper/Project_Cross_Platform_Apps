import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/providers.dart';

class SublyApp extends ConsumerWidget {
  const SublyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start the CFG-1 runtime-config load at launch. Offline-safe (falls back
    // to compiled-in defaults) and hermetic in demo/test builds, so first
    // paint never blocks on the network.
    ref.watch(appConfigProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
