// ─────────────────────────────────────────────────────────────────────────────
// /v1/webhooks — server-to-server callbacks. NO Supabase user auth here; these
// are authenticated by a shared secret instead. Mounted OUTSIDE the protected
// group in index.ts.
// ─────────────────────────────────────────────────────────────────────────────

import { Hono } from 'hono';
import type { AppEnv } from '../types';
import { nowIso, run } from '../lib/d1';

const app = new Hono<AppEnv>();

/**
 * Minimal shape of the RevenueCat webhook body we consume. RevenueCat sends
 * `{ event: {...}, api_version }`. We read the fields we upsert and ignore the
 * rest. See https://www.revenuecat.com/docs/webhooks for the full schema.
 */
interface RevenueCatEvent {
  event?: {
    type?: string;
    app_user_id?: string;
    original_app_user_id?: string;
    entitlement_id?: string | null;
    entitlement_ids?: string[] | null;
    product_id?: string | null;
    store?: string | null; // APP_STORE | PLAY_STORE | STRIPE | ...
    expiration_at_ms?: number | null;
  };
}

// Events that mean "entitlement is (or stays) active" vs "revoked".
const ACTIVE_TYPES = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'PRODUCT_CHANGE',
  'UNCANCELLATION',
  'NON_RENEWING_PURCHASE',
  'SUBSCRIPTION_EXTENDED',
]);
const INACTIVE_TYPES = new Set(['EXPIRATION', 'CANCELLATION', 'BILLING_ISSUE']);

// POST /revenuecat
/** Constant-time string comparison (length leak only — unavoidable). */
function safeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const ab = enc.encode(a);
  const bb = enc.encode(b);
  if (ab.byteLength !== bb.byteLength) return false;
  return crypto.subtle.timingSafeEqual(ab, bb);
}

app.post('/revenuecat', async (c) => {
  // ── Auth: Bearer <REVENUECAT_WEBHOOK_SECRET> — FAIL CLOSED ──────────────────
  // Without a secret, anyone could write entitlements to the shared PLATFORM_DB.
  const configured = c.env.REVENUECAT_WEBHOOK_SECRET;
  if (!configured) {
    console.error(
      '[webhooks/revenuecat] REVENUECAT_WEBHOOK_SECRET not set — rejecting. ' +
        'Set it via `wrangler secret put` before wiring RevenueCat.',
    );
    return c.json({ error: 'webhook_not_configured' }, 503);
  }
  const authz = c.req.header('Authorization') ?? '';
  if (!safeEqual(authz, `Bearer ${configured}`)) {
    return c.json({ error: 'unauthorized' }, 401);
  }

  let body: RevenueCatEvent;
  try {
    body = await c.req.json<RevenueCatEvent>();
  } catch {
    return c.json({ error: 'invalid_json' }, 400);
  }

  const ev = body.event;
  const userId = ev?.app_user_id ?? ev?.original_app_user_id;
  if (!ev || !userId) {
    // Nothing actionable; ack so RevenueCat doesn't retry forever.
    console.warn('[webhooks/revenuecat] missing event or app_user_id');
    return c.json({ ok: true });
  }

  const appId = c.env.APP_ID;
  const type = ev.type ?? '';
  // Unknown event types are a NO-OP (ack + ignore) — never silently revoke.
  if (!ACTIVE_TYPES.has(type) && !INACTIVE_TYPES.has(type)) {
    console.warn(`[webhooks/revenuecat] ignoring unhandled event type: ${type}`);
    return c.json({ ok: true, ignored: type });
  }
  const isActive = ACTIVE_TYPES.has(type) ? 1 : 0;
  const expiresAt =
    typeof ev.expiration_at_ms === 'number'
      ? new Date(ev.expiration_at_ms).toISOString()
      : null;
  const store = ev.store ?? null;
  const productId = ev.product_id ?? null;
  const ts = nowIso();

  // An event can carry one or many entitlement ids. Upsert each.
  const entitlementIds =
    ev.entitlement_ids && ev.entitlement_ids.length > 0
      ? ev.entitlement_ids
      : ev.entitlement_id
        ? [ev.entitlement_id]
        : [];

  if (entitlementIds.length === 0) {
    console.warn('[webhooks/revenuecat] event has no entitlement id(s)');
    return c.json({ ok: true });
  }

  const stmt = c.env.PLATFORM_DB.prepare(
    `INSERT INTO entitlements
       (user_id, app_id, entitlement, product_id, store, is_active, expires_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(user_id, app_id, entitlement) DO UPDATE SET
       product_id = excluded.product_id,
       store      = excluded.store,
       is_active  = excluded.is_active,
       expires_at = excluded.expires_at,
       updated_at = excluded.updated_at`,
  );

  await c.env.PLATFORM_DB.batch(
    entitlementIds.map((entId) =>
      stmt.bind(
        userId,
        appId,
        entId,
        productId,
        store,
        isActive,
        expiresAt,
        ts,
      ),
    ),
  );

  return c.json({ ok: true });
});

export default app;
