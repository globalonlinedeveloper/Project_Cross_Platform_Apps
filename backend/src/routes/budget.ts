// ─────────────────────────────────────────────────────────────────────────────
// /v1/budget — monthly budget + per-category caps for the current user.
// ─────────────────────────────────────────────────────────────────────────────

import { Hono } from 'hono';
import type { AppEnv } from '../types';
import { allRows, firstRow, nowIso, run } from '../lib/d1';

const app = new Hono<AppEnv>();

interface BudgetRow {
  user_id: string;
  monthly_budget: number | null;
  updated_at: string | null;
}
interface CategoryRow {
  user_id: string;
  name: string;
  cap: number | null;
}
interface PutBody {
  monthly_budget?: number;
  categories?: Array<{ name: string; cap: number }>;
}

// GET / — returns defaults when nothing is stored yet.
app.get('/', async (c) => {
  const userId = c.get('userId');

  const budget = await firstRow<BudgetRow>(
    c.env.APP_DB.prepare('SELECT * FROM budgets WHERE user_id = ?').bind(userId),
  );
  const categories = await allRows<CategoryRow>(
    c.env.APP_DB.prepare(
      'SELECT name, cap FROM budget_categories WHERE user_id = ? ORDER BY name ASC',
    ).bind(userId),
  );

  return c.json({
    monthly_budget: budget?.monthly_budget ?? 0,
    categories: categories.map((r) => ({ name: r.name, cap: r.cap })),
  });
});

// PUT / — upsert monthly_budget and replace the category set.
app.put('/', async (c) => {
  const userId = c.get('userId');
  let body: PutBody;
  try {
    body = await c.req.json<PutBody>();
  } catch {
    return c.json({ error: 'invalid_json' }, 400);
  }

  const ts = nowIso();

  // Upsert the monthly budget.
  await run(
    c.env.APP_DB.prepare(
      `INSERT INTO budgets (user_id, monthly_budget, updated_at)
       VALUES (?, ?, ?)
       ON CONFLICT(user_id) DO UPDATE SET
         monthly_budget = excluded.monthly_budget,
         updated_at = excluded.updated_at`,
    ).bind(userId, body.monthly_budget ?? 0, ts),
  );

  // Replace category caps (simplest correct semantics for a small set).
  await run(
    c.env.APP_DB.prepare(
      'DELETE FROM budget_categories WHERE user_id = ?',
    ).bind(userId),
  );

  const categories = body.categories ?? [];
  if (categories.length > 0) {
    const stmt = c.env.APP_DB.prepare(
      'INSERT INTO budget_categories (user_id, name, cap) VALUES (?, ?, ?)',
    );
    await c.env.APP_DB.batch(
      categories.map((cat) => stmt.bind(userId, cat.name, cat.cap)),
    );
  }

  return c.json({
    monthly_budget: body.monthly_budget ?? 0,
    categories,
  });
});

export default app;
