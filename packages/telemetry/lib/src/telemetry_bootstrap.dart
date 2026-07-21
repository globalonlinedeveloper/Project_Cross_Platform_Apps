import 'package:sentry_flutter/sentry_flutter.dart';

import 'noop_telemetry_client.dart';
import 'pii_scrubber.dart';
import 'sentry_telemetry_client.dart';
import 'telemetry_client.dart';
import 'telemetry_config.dart';

/// One-shot initializer wiring [TelemetryConfig], Sentry and the PII
/// scrubber together.
class TelemetryBootstrap {
  TelemetryBootstrap._();

  static const PiiScrubber _scrubber = PiiScrubber();

  /// Initializes telemetry and returns the client the app should use.
  ///
  /// * When `config.enabled` is false (empty DSN): runs [appRunner] directly
  ///   and returns a [NoOpTelemetryClient]. No Sentry code path is touched.
  /// * Otherwise: initializes `sentry_flutter` with a `beforeSend` hook that
  ///   scrubs PII from every outgoing event, then returns a
  ///   [SentryTelemetryClient].
  static Future<TelemetryClient> init(
    TelemetryConfig config, {
    Future<void> Function()? appRunner,
  }) async {
    if (!config.enabled) {
      if (appRunner != null) {
        await appRunner();
      }
      return const NoOpTelemetryClient();
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = config.dsn;
        options.release = config.release;
        options.environment = config.environment;
        options.tracesSampleRate = config.tracesSampleRate;
        // Belt and braces: never attach default PII (ip address, ...).
        options.sendDefaultPii = false;
        options.beforeSend = (event, hint) => _scrub(event);
      },
      appRunner: appRunner,
    );

    return const SentryTelemetryClient();
  }

  /// Scrubs PII from the user-influenced string fields of [event]: the
  /// message, breadcrumb messages and exception values.
  ///
  /// sentry-dart 9.x protocol classes are mutable, so the event is mutated
  /// in place and returned. (Returning `null` would drop the event.)
  static SentryEvent _scrub(SentryEvent event) {
    // Message (captureMessage payloads).
    final message = event.message;
    if (message != null) {
      message.formatted = _scrubber.scrubText(message.formatted);
      final template = message.template;
      if (template != null) {
        message.template = _scrubber.scrubText(template);
      }
    }

    // Breadcrumb messages.
    final breadcrumbs = event.breadcrumbs;
    if (breadcrumbs != null) {
      for (final crumb in breadcrumbs) {
        final crumbMessage = crumb.message;
        if (crumbMessage != null) {
          crumb.message = _scrubber.scrubText(crumbMessage);
        }
      }
    }

    // Exception values, e.g. Exception('otp to 9876543210 failed').
    final exceptions = event.exceptions;
    if (exceptions != null) {
      for (final exception in exceptions) {
        final value = exception.value;
        if (value != null) {
          exception.value = _scrubber.scrubText(value);
        }
      }
    }

    return event;
  }
}
