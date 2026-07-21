# nikatru_telemetry

GlitchTip/Sentry telemetry facade for NIKATRU apps (Step 1 of the
app-factory platform hardening; additive, no live impact).

## What it is

- `TelemetryClient` - the only interface app code talks to
  (`captureException`, `captureMessage`, `addBreadcrumb`, `setUser`,
  `close`).
- `TelemetryBootstrap.init(config, appRunner: ...)` - one-shot wiring.
  Empty DSN returns a `NoOpTelemetryClient` (telemetry fully off; the
  `appRunner` still runs).
- `PiiScrubber` - pure-Dart, deterministic redaction of PAN, Aadhaar,
  emails, Indian phone numbers and long digit runs, applied to every
  outgoing event via Sentry's `beforeSend` hook.

## Isolation rule

`sentry_flutter` is a dependency of THIS package only. No other package or
app may import it - everything goes through `TelemetryClient`. That keeps
the vendor SDK swappable (GlitchTip today, anything Sentry-compatible
tomorrow) and enforces the PII policy in exactly one place.

## Configuration

DSN, release and environment always come from runtime CFG - never hardcode
them in source, never commit them. `dsn: ''` disables telemetry.

```dart
final telemetry = await TelemetryBootstrap.init(
  TelemetryConfig(
    dsn: cfg.glitchtipDsn, // '' => NoOpTelemetryClient
    release: cfg.release,
    environment: cfg.env,
  ),
  appRunner: () async => runApp(const App()),
);
```

## Testing

`test/pii_scrubber_test.dart` covers the scrubber (PAN, Aadhaar spaced and
unspaced, email, +91 and bare phones, and a no-PII control string that must
stay byte-identical). CI (`flutter analyze` + `flutter test`) is the gate.
