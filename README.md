# Cross Platform Apps

A portfolio template for building **30–50+ Flutter "tracker" apps** on one shared identity
layer, one backend pattern, and one monetization stack. **App #1 is _Subly_** — a
subscription tracker for all six platforms (iOS · Android · Web · macOS · Windows · Linux).

See **[ARCHITECTURE.md](ARCHITECTURE.md)** for the full design and the rationale behind every
choice. This README is the quickstart + clone guide.

```
Cross Platform Apps/
├── ARCHITECTURE.md      · the design (read this first)
├── PROJECT_STATE.md     · working tracker / session handoff
├── app/                 · Flutter template (the reusable app)  → app/README.md
└── backend/             · Cloudflare Worker (Hono + D1)        → backend/README.md
```

## Stack (finalized)

Supabase Auth (shared identity, pure REST → all 6 platforms) · Cloudflare Workers + D1
(per-app data over REST) · on-device `flutter_local_notifications` (renewal reminders) ·
Cloudflare Cron (keep-alive + nightly recompute) + R2 (exports) · RevenueCat + Stripe with a
shared `(user_id, app_id)` entitlements table.

## Quickstart — run the app in DEMO mode (no backend needed)

The app boots against a mock auth repository + in-memory seed data (identical to the design)
until you supply real credentials. So you can see all 8 screens immediately:

```bash
cd app
flutter pub get
flutter run                      # or: -d chrome / windows / macos / linux
```

Flow: Onboarding → Sign in (any email/password works in demo) → Scan → dashboard with Home,
Calendar, Insights, Budget, Settings, plus subscription detail, notifications, add, and cancel.

## Go live

1. **Supabase** — create a project; copy the Project URL + anon (publishable) key.
2. **Backend** — see [backend/README.md](backend/README.md): fill `wrangler.toml`
   (`SUPABASE_URL`, D1 ids), `wrangler d1 create subly_db` + `platform_db`, apply migrations,
   `wrangler deploy`. Set secrets with `wrangler secret put` (never commit them).
3. **App** — run with real values via `--dart-define` (nothing secret is hardcoded):

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=eyJ... \
     --dart-define=API_BASE_URL=https://subly-api.YOUR.workers.dev
   ```

   With these set, the app automatically switches from mock/seed to Supabase Auth + the live
   Worker. (`--dart-define-from-file=env.json` works too — keep that file gitignored.)

## Clone for the next app (#2..N)

Auth and entitlements are **portfolio-wide**; only the per-app data DB is new.

1. Copy `app/` and `backend/` into the new app's folder.
2. **App:** edit the three identity constants at the top of
   `app/lib/core/config/app_config.dart` (`appId`, `appName`, `appTagline`). Restyle
   `app/lib/core/theme/app_colors.dart` if you want a different accent. Replace the
   `features/` screens with the new tracker's UI — the `data/`, `services/`, `state/`, and
   `core/` layers are reusable as-is.
3. **Backend:** in `backend/wrangler.toml` change `name`, `APP_ID`, and the `APP_DB`
   binding; `wrangler d1 create <newapp>_db` and paste its id. **Keep the same
   `PLATFORM_DB`** (shared entitlements) and **the same Supabase project.**
4. Point the app at the new Worker URL via `--dart-define`. Done — same login works across
   the whole portfolio, and a user's Pro status is visible to every app.

## Verification status

- **Backend:** `tsc --noEmit` passes (typechecked).
- **Flutter:** authored to the Riverpod 2 / go_router 14 / supabase_flutter 2 /
  flutter_local_notifications 17 APIs. Run `cd app && flutter pub get && flutter analyze` on
  your machine — versions may need `flutter pub upgrade --major-versions` on a 2026 SDK; the
  most version-sensitive file is `services/notifications/notification_service.dart` (see its
  header note). CI runs `flutter analyze` on every push (`.github/workflows/ci.yml`).

## Security

All credentials live only in `.cowork-private/secrets.env` (gitignored). Nothing secret is
committed or hardcoded: the app reads config via `--dart-define`; the Worker reads secrets
from `wrangler secret` / `.dev.vars` (gitignored). The Supabase anon key is the only key that
ships in the client — that is by design (it is a public, RLS-guarded key).
