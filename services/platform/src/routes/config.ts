// ─────────────────────────────────────────────────────────────────────────────
// GET /config/:app — CFG-1. Compiled-in defaults overlaid with a KV override
// (`config:<app>`), edge-cached. Unknown app ⇒ 404. Never returns secrets.
// ─────────────────────────────────────────────────────────────────────────────
import { Hono } from 'hono';
import type { AppEnv } from '../types';
import { resolveConfig } from '../config';

const app = new Hono<AppEnv>();

app.get('/:app', async (c) => {
  const appId = c.req.param('app');
  const kvValue = await c.env.CONFIG_KV.get(`config:${appId}`);
  const cfg = resolveConfig(appId, kvValue);
  if (!cfg) return c.json({ error: 'unknown_app' }, 404);
  // Edge + client cache; overrides propagate within the TTL.
  c.header('Cache-Control', 'public, max-age=300, s-maxage=300');
  return c.json(cfg);
});

export default app;
