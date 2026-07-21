import type { Context } from 'hono';

// Bindings from wrangler.jsonc. APP_DB + EXPORTS are per-app; PLATFORM_DB +
// JWKS_CACHE + SUPABASE_URL are shared across every NIKATRU app.
export interface Env {
  APP_DB: D1Database;
  PLATFORM_DB: D1Database;
  JWKS_CACHE: KVNamespace;
  EXPORTS: R2Bucket;
  APP_ID: string;
  SUPABASE_URL: string;
  API_VERSION: string;
  ALLOWED_ORIGINS?: string;
  // Optional legacy HS256 fallback secret (most projects use ES256 JWKS).
  SUPABASE_JWT_SECRET?: string;
}

// Per-request variables set by middleware.
export interface Variables {
  requestId: string;
  userId: string;
  userEmail?: string;
}

export type AppEnv = { Bindings: Env; Variables: Variables };
export type AppContext = Context<AppEnv>;
