// ─────────────────────────────────────────────────────────────────────────────
// Shared types for the platform Worker. Keep Env in sync with wrangler.jsonc.
// ─────────────────────────────────────────────────────────────────────────────

/** Worker bindings + environment. Names must match wrangler.jsonc bindings. */
export interface Env {
  // SHARED entitlements DB (platform is the sole migrations applier).
  PLATFORM_DB: D1Database;
  // Per-app DBs bound for the nightly renewals fan-out. Add one per app.
  SUBLY_DB: D1Database;

  // Edge-cached per-app config overrides (key: `config:<app>`).
  CONFIG_KV: KVNamespace;

  // Non-secret vars (wrangler.jsonc vars).
  APP_ID: string;
  SUPABASE_URL: string;
  API_VERSION: string;
  /** Comma-separated browser origins for CORS. Absent/empty ⇒ '*'. */
  ALLOWED_ORIGINS?: string;
}

/** Hono context Variables set by middleware. */
export interface Variables {
  /** Correlation id stamped by the request-id middleware (echoed in headers). */
  requestId: string;
}

/** Convenience: the generics shape used across the worker + sub-routers. */
export type AppEnv = { Bindings: Env; Variables: Variables };

/**
 * Resolved runtime config for an app (CFG-1). DATA/flags only — never UI.
 * Apps compile in their own fallback and overlay this at launch.
 */
export interface AppConfig {
  app_id: string;
  api_base_url: string;
  features: Record<string, boolean>;
  paywall: { enabled: boolean; [k: string]: unknown };
  content_pack: string | null;
  copy: Record<string, string>;
  min_supported_version: string;
  theme?: Record<string, unknown>;
}

/** A subscription row (subset used by the renewals fan-out). */
export interface Subscription {
  id: string;
  user_id: string;
  price: number | null;
  cycle: 'monthly' | 'yearly' | null;
  next_renewal: string | null; // 'YYYY-MM-DD'
}

/** One app the nightly scheduler fans out to. */
export interface AppTarget {
  appId: string;
  db: D1Database;
}
