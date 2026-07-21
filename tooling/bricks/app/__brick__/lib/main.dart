import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nikatru_telemetry/nikatru_telemetry.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Telemetry chassis: no DSN -> NoOp client (appRunner runs directly);
  // a GLITCHTIP_DSN via --dart-define enables GlitchTip/Sentry with PII
  // scrubbing. sentry_flutter is isolated inside packages/telemetry.
  const TelemetryConfig config = TelemetryConfig(
    dsn: String.fromEnvironment('GLITCHTIP_DSN'),
    release: '{{app_id.snakeCase()}}@0.1.0',
    environment: String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
  );

  await TelemetryBootstrap.init(
    config,
    appRunner: () async {
      runApp(const ProviderScope(child: {{app_id.pascalCase()}}App()));
    },
  );
}
