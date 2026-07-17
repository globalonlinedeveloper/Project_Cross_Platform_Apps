// ─────────────────────────────────────────────────────────────────────────────
// CORS — env-driven allow-list. Set [vars].ALLOWED_ORIGINS to a comma-separated
// list of browser origins (e.g. "https://subly.nikatru.com,https://subly.pages.dev").
// Absent/empty ⇒ '*' (template mode, permissive — tighten per deployment).
// Non-browser clients (mobile/desktop apps) send no Origin header ⇒ unaffected.
// ─────────────────────────────────────────────────────────────────────────────

import { cors } from 'hono/cors';
import type { Context, Next } from 'hono';
import type { AppEnv } from '../types';

export const corsMiddleware = (c: Context<AppEnv>, next: Next) => {
  const list = (c.env.ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  return cors({
    origin: (origin) =>
      list.length === 0 ? '*' : list.includes(origin) ? origin : null,
    allowMethods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Authorization', 'Content-Type'],
    maxAge: 86400,
  })(c, next);
};
