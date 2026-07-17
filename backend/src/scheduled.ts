// ─────────────────────────────────────────────────────────────────────────────
// Cron handler (see [triggers] crons in wrangler.toml). Runs two jobs:
//   1) keepAliveSupabase — defeats Supabase free-tier idle pause.
//   2) recomputeRenewals — rolls past-due next_renewal dates forward one cycle.
// Both swallow errors so one failing job never aborts the other.
// ─────────────────────────────────────────────────────────────────────────────

import type { Env, Subscription } from './types';
import { allRows, nowIso, todayYmd, uuid } from './lib/d1';

/**
 * WHY: Supabase pauses a free-tier project after ~7 days of inactivity, which
 * would break sign-in for a low-traffic portfolio app. A cheap daily request to
 * a lightweight endpoint keeps the project "active". We don't care about the
 * response — only that a request happened. Errors are logged and ignored.
 */
async function keepAliveSupabase(env: Env): Promise<void> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);
  try {
    // GoTrue health is unauthenticated and cheap. (Alternatively hit
    // `${SUPABASE_URL}/rest/v1/` with an `apikey: <anon key>` header — that also
    // counts as activity but needs the anon key wired as a var/secret.)
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

/** Advance a 'YYYY-MM-DD' date by one billing cycle, staying in UTC. */
function advance(dateYmd: string, cycle: 'monthly' | 'yearly'): string {
  const d = new Date(`${dateYmd}T00:00:00Z`);
  if (cycle === 'yearly') {
    d.setUTCFullYear(d.getUTCFullYear() + 1);
  } else {
    d.setUTCMonth(d.getUTCMonth() + 1);
  }
  return d.toISOString().slice(0, 10);
}

/**
 * For every subscription whose next_renewal is in the past, roll it forward one
 * cycle (repeatedly, until it's today-or-future) and record a payment_history
 * row for the charge that just passed. Updates updated_at. Batched per row.
 */
async function recomputeRenewals(env: Env): Promise<void> {
  const today = todayYmd();
  try {
    const due = await allRows<Subscription>(
      env.APP_DB.prepare(
        `SELECT * FROM subscriptions
           WHERE next_renewal IS NOT NULL
             AND cycle IS NOT NULL
             AND next_renewal < ?`,
      ).bind(today),
    );

    if (due.length === 0) {
      console.log('[cron] recomputeRenewals: nothing due');
      return;
    }

    const ts = nowIso();
    const updateStmt = env.APP_DB.prepare(
      'UPDATE subscriptions SET next_renewal = ?, updated_at = ? WHERE id = ?',
    );
    const paymentStmt = env.APP_DB.prepare(
      `INSERT INTO payment_history (id, subscription_id, user_id, amount, paid_at)
       VALUES (?, ?, ?, ?, ?)`,
    );

    const ops: D1PreparedStatement[] = [];
    for (const sub of due) {
      const cycle = sub.cycle as 'monthly' | 'yearly';
      let next = sub.next_renewal as string;
      // Record one payment per cycle boundary crossed (usually just one).
      let guard = 0;
      while (next < today && guard < 240) {
        ops.push(
          paymentStmt.bind(uuid(), sub.id, sub.user_id, sub.price ?? null, `${next}T00:00:00Z`),
        );
        next = advance(next, cycle);
        guard++;
      }
      ops.push(updateStmt.bind(next, ts, sub.id));
    }

    await env.APP_DB.batch(ops);
    console.log(`[cron] recomputeRenewals: advanced ${due.length} subscription(s)`);
  } catch (err) {
    console.log(`[cron] recomputeRenewals failed: ${String(err)}`);
  }
}

/**
 * Cron entrypoint. `ctx.waitUntil` keeps the isolate alive for the async work.
 */
export const scheduled: ExportedHandlerScheduledHandler<Env> = async (
  _event,
  env,
  ctx,
) => {
  ctx.waitUntil(
    (async () => {
      await keepAliveSupabase(env);
      await recomputeRenewals(env);
    })(),
  );
};
