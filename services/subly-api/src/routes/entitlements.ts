// ─────────────────────────────────────────────────────────────────────────────
// /v1/entitlements — read this user's entitlements for THIS app from PLATFORM_DB.
// ─────────────────────────────────────────────────────────────────────────────

import { Hono } from 'hono';
import type { AppEnv, Entitlement } from '../types';
import { allRows } from '../lib/d1';

const app = new Hono<AppEnv>();

// GET / — { app_id, is_pro, entitlements: [...] }
app.get('/', async (c) => {
  const userId = c.get('userId');
  const appId = c.env.APP_ID;

  const rows = await allRows<Entitlement>(
    c.env.PLATFORM_DB.prepare(
      'SELECT * FROM entitlements WHERE user_id = ? AND app_id = ?',
    ).bind(userId, appId),
  );

  const nowMs = Date.now();
  const entitlements = rows.map((r) => ({
    entitlement: r.entitlement,
    product_id: r.product_id,
    store: r.store,
    is_active: r.is_active === 1,
    expires_at: r.expires_at,
  }));

  // "Pro" = any active, unexpired entitlement for this app.
  const isPro = rows.some((r) => {
    if (r.is_active !== 1) return false;
    if (!r.expires_at) return true;
    const exp = Date.parse(r.expires_at);
    return Number.isNaN(exp) ? true : exp > nowMs;
  });

  return c.json({
    app_id: appId,
    is_pro: isPro,
    entitlements,
  });
});

export default app;
