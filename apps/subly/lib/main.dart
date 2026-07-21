import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'services/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local notifications work on all six platforms (web falls back to a no-op).
  await NotificationService.instance.init();

  // Only initialize Supabase when real credentials are supplied via --dart-define.
  // Left unconfigured, the app runs in demo mode with a mock auth repository.
  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // anonKey is the publishable client key; deprecated alias in newer SDKs.
      // ignore: deprecated_member_use
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: SublyApp()));
}
