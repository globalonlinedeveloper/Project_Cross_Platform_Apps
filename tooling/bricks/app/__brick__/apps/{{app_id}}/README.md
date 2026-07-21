# {{display_name}}

A NIKATRU Cross Platform App, stamped from `tooling/bricks/app`.

Pre-wired to the shared spine: `nikatru_core`, `nikatru_api_client`,
`nikatru_design_system` (tokens + `buildAppTheme` + adaptive `AppScaffold`) and
`nikatru_telemetry` (GlitchTip facade, no-op until a DSN is supplied).

## Run

```sh
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=API_BASE_URL=https://{{api_domain}}
```

Left unconfigured, the app boots in demo mode. Brand seed: `#{{seed_hex}}`.
