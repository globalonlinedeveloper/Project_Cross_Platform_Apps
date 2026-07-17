-- ─────────────────────────────────────────────────────────────────────────────
-- 0002_entitlements.sql — SHARED entitlements schema.
--
-- IMPORTANT: this migration targets the SHARED platform database (PLATFORM_DB /
-- platform_db), NOT the per-app APP_DB. Apply it once for the whole portfolio:
--   wrangler d1 migrations apply PLATFORM_DB --local   (or --remote)
--
-- Because `migrations_dir` is bound to APP_DB in wrangler.toml, run this file
-- against PLATFORM_DB explicitly, e.g.:
--   wrangler d1 execute PLATFORM_DB --local --file=migrations/0002_entitlements.sql
-- (or maintain a separate migrations dir for the platform db).
--
-- One row per (user, app, entitlement). RevenueCat webhook upserts here; the
-- app's /entitlements route reads here. Shared across all portfolio apps.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS entitlements (
  user_id     TEXT,
  app_id      TEXT,
  entitlement TEXT,
  product_id  TEXT,
  store       TEXT,
  is_active   INTEGER DEFAULT 0,  -- boolean 0/1
  expires_at  TEXT,               -- ISO-8601, nullable
  updated_at  TEXT,
  PRIMARY KEY (user_id, app_id, entitlement)
);
CREATE INDEX IF NOT EXISTS idx_entitlements_user
  ON entitlements (user_id);
CREATE INDEX IF NOT EXISTS idx_entitlements_user_app
  ON entitlements (user_id, app_id);
