// ─────────────────────────────────────────────────────────────────────────────
// /v1/subscriptions — user-scoped CRUD. All rows are keyed by c.get('userId').
// JSON is snake_case matching the DB columns; `unused` (0/1) serializes to bool.
// ─────────────────────────────────────────────────────────────────────────────

import { Hono } from 'hono';
import type { AppEnv, Payment, Subscription } from '../types';
import { allRows, firstRow, nowIso, run, uuid } from '../lib/d1';

const app = new Hono<AppEnv>();

/** DB row -> API JSON (0/1 `unused` becomes a real boolean). */
function serializeSubscription(row: Subscription) {
  return {
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
  };
}

interface CreateBody {
  name?: string;
  category?: string;
  price?: number;
  cycle?: 'monthly' | 'yearly';
  next_renewal?: string;
  plan?: string;
  glyph?: string;
  used_pct?: number;
  usage_note?: string;
  unused?: boolean;
}

// GET / — list, most expensive first.
app.get('/', async (c) => {
  const userId = c.get('userId');
  const rows = await allRows<Subscription>(
    c.env.APP_DB.prepare(
      'SELECT * FROM subscriptions WHERE user_id = ? ORDER BY price DESC',
    ).bind(userId),
  );
  return c.json(rows.map(serializeSubscription));
});

// POST / — create.
app.post('/', async (c) => {
  const userId = c.get('userId');
  let body: CreateBody;
  try {
    body = await c.req.json<CreateBody>();
  } catch {
    return c.json({ error: 'invalid_json' }, 400);
  }

  const id = uuid();
  const ts = nowIso();
  const unused = body.unused ? 1 : 0;

  await run(
    c.env.APP_DB.prepare(
      `INSERT INTO subscriptions
         (id, user_id, name, category, price, cycle, next_renewal, plan, glyph,
          used_pct, usage_note, unused, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(
      id,
      userId,
      body.name ?? null,
      body.category ?? null,
      body.price ?? null,
      body.cycle ?? null,
      body.next_renewal ?? null,
      body.plan ?? null,
      body.glyph ?? null,
      body.used_pct ?? 0,
      body.usage_note ?? null,
      unused,
      ts,
      ts,
    ),
  );

  const row = await firstRow<Subscription>(
    c.env.APP_DB.prepare('SELECT * FROM subscriptions WHERE id = ?').bind(id),
  );
  return c.json(row ? serializeSubscription(row) : { error: 'not_found' }, 201);
});

// GET /:id — one subscription (must be owned) + its payment history.
app.get('/:id', async (c) => {
  const userId = c.get('userId');
  const id = c.req.param('id');

  const row = await firstRow<Subscription>(
    c.env.APP_DB.prepare(
      'SELECT * FROM subscriptions WHERE id = ? AND user_id = ?',
    ).bind(id, userId),
  );
  if (!row) return c.json({ error: 'not_found' }, 404);

  const payments = await allRows<Payment>(
    c.env.APP_DB.prepare(
      `SELECT * FROM payment_history
         WHERE subscription_id = ? AND user_id = ?
         ORDER BY paid_at DESC`,
    ).bind(id, userId),
  );

  return c.json({
    ...serializeSubscription(row),
    payment_history: payments,
  });
});

// PATCH /:id — update a whitelisted set of fields.
app.patch('/:id', async (c) => {
  const userId = c.get('userId');
  const id = c.req.param('id');

  let body: CreateBody;
  try {
    body = await c.req.json<CreateBody>();
  } catch {
    return c.json({ error: 'invalid_json' }, 400);
  }

  // Ownership check up front.
  const existing = await firstRow<Subscription>(
    c.env.APP_DB.prepare(
      'SELECT id FROM subscriptions WHERE id = ? AND user_id = ?',
    ).bind(id, userId),
  );
  if (!existing) return c.json({ error: 'not_found' }, 404);

  const sets: string[] = [];
  const values: unknown[] = [];
  const put = (col: string, val: unknown) => {
    sets.push(`${col} = ?`);
    values.push(val);
  };

  if (body.name !== undefined) put('name', body.name);
  if (body.category !== undefined) put('category', body.category);
  if (body.price !== undefined) put('price', body.price);
  if (body.cycle !== undefined) put('cycle', body.cycle);
  if (body.next_renewal !== undefined) put('next_renewal', body.next_renewal);
  if (body.plan !== undefined) put('plan', body.plan);
  if (body.glyph !== undefined) put('glyph', body.glyph);
  if (body.used_pct !== undefined) put('used_pct', body.used_pct);
  if (body.usage_note !== undefined) put('usage_note', body.usage_note);
  if (body.unused !== undefined) put('unused', body.unused ? 1 : 0);

  put('updated_at', nowIso());

  values.push(id, userId);
  await run(
    c.env.APP_DB.prepare(
      `UPDATE subscriptions SET ${sets.join(', ')} WHERE id = ? AND user_id = ?`,
    ).bind(...values),
  );

  const row = await firstRow<Subscription>(
    c.env.APP_DB.prepare('SELECT * FROM subscriptions WHERE id = ?').bind(id),
  );
  return c.json(row ? serializeSubscription(row) : { error: 'not_found' });
});

// DELETE /:id — cancel/remove.
app.delete('/:id', async (c) => {
  const userId = c.get('userId');
  const id = c.req.param('id');
  await run(
    c.env.APP_DB.prepare(
      'DELETE FROM subscriptions WHERE id = ? AND user_id = ?',
    ).bind(id, userId),
  );
  return c.json({ ok: true });
});

export default app;
