// ─────────────────────────────────────────────────────────────────────────────
// /v1/renewals — subscriptions renewing within N days, ascending, with days_left.
// ─────────────────────────────────────────────────────────────────────────────

import { Hono } from 'hono';
import type { AppEnv, Subscription } from '../types';
import { allRows, todayYmd } from '../lib/d1';

const app = new Hono<AppEnv>();

/** Whole-day difference between two 'YYYY-MM-DD' dates (b - a), UTC. */
function daysBetween(a: string, b: string): number {
  const ms =
    Date.parse(`${b}T00:00:00Z`) - Date.parse(`${a}T00:00:00Z`);
  return Math.round(ms / 86_400_000);
}

// GET /?withinDays=7
app.get('/', async (c) => {
  const userId = c.get('userId');
  const withinDaysRaw = c.req.query('withinDays');
  const withinDays = Number.isFinite(Number(withinDaysRaw))
    ? Math.max(0, Math.trunc(Number(withinDaysRaw)))
    : 7;

  const today = todayYmd();
  const until = new Date(Date.parse(`${today}T00:00:00Z`) + withinDays * 86_400_000)
    .toISOString()
    .slice(0, 10);

  const rows = await allRows<Subscription>(
    c.env.APP_DB.prepare(
      `SELECT * FROM subscriptions
         WHERE user_id = ?
           AND next_renewal IS NOT NULL
           AND next_renewal >= ?
           AND next_renewal <= ?
         ORDER BY next_renewal ASC`,
    ).bind(userId, today, until),
  );

  const out = rows.map((row) => ({
    id: row.id,
    user_id: row.user_id,
    name: row.name,
    category: row.category,
    price: row.price,
    cycle: row.cycle,
    next_renewal: row.next_renewal,
    plan: row.plan,
    glyph: row.glyph,
    used_pct: row.used_pct,
    usage_note: row.usage_note,
    unused: row.unused === 1,
    created_at: row.created_at,
    updated_at: row.updated_at,
    days_left: row.next_renewal ? daysBetween(today, row.next_renewal) : null,
  }));

  return c.json(out);
});

export default app;
