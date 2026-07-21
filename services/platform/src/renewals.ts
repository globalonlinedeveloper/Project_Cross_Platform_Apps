// ─────────────────────────────────────────────────────────────────────────────
// Renewals recompute — relocated from subly-api's cron into the platform
// scheduler's per-app fan-out. The date math is a PURE core (unit tested); the
// D1 pass wraps it. Generic over any app DB with subscriptions + payment_history.
// ─────────────────────────────────────────────────────────────────────────────
import type { Subscription } from './types';
import { allRows, nowIso, todayYmd, uuid } from './lib/d1';

/** Advance a 'YYYY-MM-DD' date by one billing cycle, staying in UTC. */
export function advance(dateYmd: string, cycle: 'monthly' | 'yearly'): string {
  const d = new Date(`${dateYmd}T00:00:00Z`);
  if (cycle === 'yearly') {
    d.setUTCFullYear(d.getUTCFullYear() + 1);
  } else {
    d.setUTCMonth(d.getUTCMonth() + 1);
  }
  return d.toISOString().slice(0, 10);
}

/**
 * PURE core: roll `next` forward one cycle at a time until it is today-or-later.
 * Returns the new next-renewal date and the list of cycle-boundary dates crossed
 * (one payment_history row each). A guard caps pathological backlogs.
 */
export function rollForward(
  next: string,
  cycle: 'monthly' | 'yearly',
  today: string,
): { next: string; crossings: string[] } {
  const crossings: string[] = [];
  let cur = next;
  let guard = 0;
  while (cur < today && guard < 240) {
    crossings.push(cur);
    cur = advance(cur, cycle);
    guard++;
  }
  return { next: cur, crossings };
}

/**
 * For every subscription whose next_renewal is in the past, roll it forward and
 * record a payment_history row per crossed charge. Batched per DB. Errors are
 * swallowed so one app never aborts the others in the fan-out.
 */
export async function recomputeRenewals(db: D1Database, appId: string): Promise<void> {
  const today = todayYmd();
  try {
    const due = await allRows<Subscription>(
      db
        .prepare(
          `SELECT id, user_id, price, cycle, next_renewal FROM subscriptions
             WHERE next_renewal IS NOT NULL
               AND cycle IS NOT NULL
               AND next_renewal < ?`,
        )
        .bind(today),
    );

    if (due.length === 0) {
      console.log(`[cron] renewals(${appId}): nothing due`);
      return;
    }

    const ts = nowIso();
    const updateStmt = db.prepare(
      'UPDATE subscriptions SET next_renewal = ?, updated_at = ? WHERE id = ?',
    );
    const paymentStmt = db.prepare(
      `INSERT INTO payment_history (id, subscription_id, user_id, amount, paid_at)
       VALUES (?, ?, ?, ?, ?)`,
    );

    const ops: D1PreparedStatement[] = [];
    for (const sub of due) {
      const cycle = sub.cycle as 'monthly' | 'yearly';
      const { next, crossings } = rollForward(sub.next_renewal as string, cycle, today);
      for (const when of crossings) {
        ops.push(
          paymentStmt.bind(uuid(), sub.id, sub.user_id, sub.price ?? null, `${when}T00:00:00Z`),
        );
      }
      ops.push(updateStmt.bind(next, ts, sub.id));
    }

    await db.batch(ops);
    console.log(`[cron] renewals(${appId}): advanced ${due.length} subscription(s)`);
  } catch (err) {
    console.log(`[cron] renewals(${appId}) failed: ${String(err)}`);
  }
}
