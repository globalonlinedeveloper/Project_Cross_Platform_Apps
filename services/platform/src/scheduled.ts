// ─────────────────────────────────────────────────────────────────────────────
// Consolidated nightly cron (see triggers.crons in wrangler.jsonc). ONE cron for
// the whole portfolio (Free-tier 5-cron cap): a platform-wide Supabase keep-alive
// plus a per-app renewals fan-out. Each job swallows its own errors.
// ─────────────────────────────────────────────────────────────────────────────
import type { AppTarget, Env } from './types';
import { recomputeRenewals } from './renewals';

/**
 * Apps the scheduler fans out to. Static today (subly only); as more apps ship,
 * add their APP_DB binding here (or drive it from a platform_db registry).
 */
export function appTargets(env: Env): AppTarget[] {
  return [{ appId: 'subly', db: env.SUBLY_DB }];
}

/**
 * WHY: Supabase pauses a free-tier project after ~7 days idle, breaking sign-in
 * for a low-traffic portfolio. A cheap daily request keeps the project active.
 * The response is irrelevant — only that a request happened. Errors ignored.
 */
async function keepAliveSupabase(env: Env): Promise<void> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);
  try {
    const res = await fetch(`${env.SUPABASE_URL}/auth/v1/health`, {
      signal: controller.signal,
    });
    console.log(`[cron] supabase keep-alive: ${res.status}`);
  } catch (err) {
    console.log(`[cron] supabase keep-alive failed: ${String(err)}`);
  } finally {
    clearTimeout(timeout);
  }
}

/** Cron entrypoint. `ctx.waitUntil` keeps the isolate alive for the async work. */
export const scheduled: ExportedHandlerScheduledHandler<Env> = async (_event, env, ctx) => {
  ctx.waitUntil(
    (async () => {
      await keepAliveSupabase(env);
      for (const t of appTargets(env)) {
        await recomputeRenewals(t.db, t.appId);
      }
    })(),
  );
};
