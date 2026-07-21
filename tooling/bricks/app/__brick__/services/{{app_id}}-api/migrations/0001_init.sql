-- ─────────────────────────────────────────────────────────────────────────────
-- 0001_init.sql — starter per-app schema for {{app_id}}. Applies to APP_DB
-- ({{app_id}}_db):  wrangler d1 migrations apply APP_DB --local  (or --remote)
-- Replace/extend `records` with this app's real tables. EVERY user-owned table
-- MUST carry a user_id column so the G2 account-deletion route can purge it.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS records (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL,
  title       TEXT,
  body        TEXT,
  created_at  TEXT,
  updated_at  TEXT
);
CREATE INDEX IF NOT EXISTS idx_records_user ON records (user_id);
