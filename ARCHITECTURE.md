# Cross Platform Apps — Reference Architecture

**Portfolio:** a family of 30–50+ Flutter "tracker" apps sharing one identity layer, one
backend pattern, and one monetization stack. **App #1:** *Subly* — a subscription tracker
targeting all six platforms (iOS · Android · Web · macOS · Windows · Linux).

**Status:** plan confirmed · auth finalized (**Supabase**) · scaffold-only (no live cloud
resources provisioned).

---

## 1. The decision that shapes everything: platform coverage

Flutter builds for six targets, but not every backend SDK does. The only capabilities that
*don't* span all six are Firebase Firestore and Firebase FCM (no official Windows/Linux). So
the architecture routes **all data over plain REST** (works everywhere) and keeps
**reminders on-device** (works everywhere) — nothing app-critical depends on a
platform-limited SDK.

| Capability | iOS | Android | Web | macOS | Windows | Linux |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| **Supabase Auth (GoTrue, REST)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Cloudflare Workers + D1 (REST)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Local notifications** | ✅ | ✅ | ⚠️¹ | ✅ | ✅² | ✅ |

¹ Web uses service-worker notifications, not the plugin. ² Windows can't do *periodic
repeating* notifications, but one-off `zonedSchedule` per renewal date works — which is
exactly our model.

---

## 2. Finalized stack

```
                    ┌───────────────────────────────────────────────┐
                    │      Flutter app  (one codebase → 6 targets)   │
                    │   iOS · Android · Web · macOS · Windows · Linux │
                    │                                                 │
                    │   AuthRepository ─┐          ┌─ ApiClient       │
                    └───────────────────┼──────────┼─────────────────┘
        1. sign in (email / Google /    │          │  3. REST calls with
           Apple) — pure REST           │          │     Bearer <supabase JWT>
                                        ▼          ▼
                        ┌──────────────────┐   ┌──────────────────────────────────┐
                        │  Supabase Auth   │   │   Cloudflare Worker (Hono)        │
                        │  (GoTrue)        │   │   • verifies Supabase JWT (JWKS)  │
                        │  all 6 platforms │   │   • /subscriptions /renewals ...  │
                        └────────┬─────────┘   │            │            │        │
                                 │             │   per-app  ▼   shared   ▼        │
              2. returns JWT ────┘             │   ┌──────────────┐ ┌───────────┐ │
                                               │   │ D1: app data │ │ D1:       │ │
                                               │   │ (SQLite)     │ │ entitle-  │ │
                                               │   └──────────────┘ │ ments     │ │
                                               │   Cron → keep-alive └───────────┘ │
                                               │        + nightly renewals recompute│
                                               │   R2 → CSV exports / receipts      │
                                               └──────────────────────────────────┘
                                                            ▲
                     RevenueCat + Stripe ──── webhook ──────┘  (writes entitlements)

   Renewal reminders scheduled ON-DEVICE via flutter_local_notifications
   (iOS/Android/macOS/Windows/Linux — no server push needed).
```

| Concern | Owner | Why |
|---|---|---|
| Identity / sign-in | **Supabase Auth (GoTrue)** | Pure REST → all 6 platforms, no desktop delegate; open-source; Postgres user store |
| App data (subs, renewals, budgets, history) | **Cloudflare D1** (per-app DB) via Workers | Relational fit; REST works everywhere; isolation per app |
| API / business logic | **Cloudflare Worker (Hono)** | Verifies Supabase JWT; one gateway for all reads/writes |
| Cross-app entitlements | **Shared D1** `(user_id, app_id)` | One paid identity spanning the whole portfolio |
| Renewal reminders | **On-device local notifications** | Covers Windows/Linux/macOS too |
| Scheduled jobs | **Cloudflare Cron** | Keep-alive ping (defeats Supabase 7-day idle pause) + nightly recompute |
| File storage (CSV export, receipts) | **Cloudflare R2** | 10 GB free, zero egress |
| Payments / subscriptions | **RevenueCat + Stripe** | Cross-platform purchases; webhook → entitlements |

---

## 3. Why Supabase Auth (the one open call, now closed)

The Backend Research doc leaned Firebase Auth; for this portfolio we finalized **Supabase**:

1. **True 6-platform uniformity.** Supabase Auth is HTTP/GoTrue — `supabase_flutter` runs on
   Windows/Linux with **no `firebase_auth_desktop` delegate**. One code path everywhere.
2. **Simplest Worker verification.** Verify the Supabase JWT with `jose` against the
   project JWKS (asymmetric signing keys), or a single shared secret (HS256 legacy). Public
   keys cached in KV.
3. **Portfolio portability.** Open-source; a Postgres user store you can query/join and
   even self-host later — no Google lock-in across 30–50 apps.
4. **The one weakness is already handled.** Supabase's free tier pauses after 7 days idle;
   our **Cloudflare Cron keep-alive** pings it well inside that window.

Firebase Auth remains a drop-in alternative: `AuthRepository` is an abstraction, so swapping
means one adapter (`lib/data/auth/`) + one Worker middleware file (`src/middleware/auth.ts`).

---

## 4. Multi-tenant data model

- **Per-app D1 database** — each app in the portfolio gets its own D1 (`subly_db`,
  `<next_app>_db`, …). Isolation, independent scaling, blast-radius containment.
- **Shared entitlements D1** — one `platform_db` bound by *every* app's Worker. Table keyed
  by `(user_id, app_id)` so a user's paid status is portfolio-wide and RevenueCat webhooks
  land in one place.
- **user_id** = the Supabase auth UUID (`sub` claim of the verified JWT). It is the join key
  across auth, app data, and entitlements.

---

## 5. Cost

Build/validate: **$0/mo**. Supabase free (auth + Postgres, kept warm by cron), Cloudflare
free (Workers 100k req/day, D1 5 GB, R2 10 GB zero-egress, 5 cron triggers). Budget headroom
of **~$25–30/mo** only engages at scale (Supabase Pro $25 and/or Workers Paid $5), i.e. once
paid subscribers cover it.

---

## 6. Repository layout

```
Cross Platform Apps/
├── ARCHITECTURE.md          ← this file
├── README.md                ← quickstart + how to clone for the next app
├── app/                     ← Flutter template (the reusable app)
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart · app.dart
│   │   ├── core/            config · theme · router
│   │   ├── data/            auth/ (abstraction + Supabase) · api/ (abstraction + Dio) · models
│   │   ├── services/        notifications · purchases (RevenueCat stub) · entitlements
│   │   ├── state/           Riverpod providers
│   │   └── features/        onboarding · auth · scan · home · calendar · insights ·
│   │                        budget · settings · detail · notifications · add · cancel · shell
│   └── README.md
└── backend/                 ← Cloudflare Worker template (Hono + D1)
    ├── wrangler.toml
    ├── src/                 index · middleware/ · routes/ · lib/ · scheduled
    ├── migrations/          0001_init.sql · 0002_entitlements.sql
    └── README.md
```

## 7. How to clone for app #2..N

The whole point of the template. See `README.md` §"Clone for the next app" — in short:
copy `app/` + `backend/`, change **one** `AppConfig` block and **one** `wrangler.toml`
(app_id, names, D1 binding), create a new per-app D1, and keep pointing at the *same*
Supabase project and the *same* shared `platform_db`. Auth and entitlements are portfolio-wide;
only the per-app data DB is new.
