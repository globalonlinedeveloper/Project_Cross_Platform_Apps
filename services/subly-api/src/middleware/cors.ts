// ─────────────────────────────────────────────────────────────────────────────
// CORS — env-driven allow-list. Set [vars].ALLOWED_ORIGINS to a comma-separated
// list of browser origins (e.g. "https://subly.nikatru.com,https://subly.pages.dev").
// Absent/empty ⇒ '*' (template mode, permissive — tighten per deployment).
// Non-browser clients (mobile/desktop apps) send no Origin header ⇒ unaffected.
//
// Localhost origins (any port, http/https) are ALWAYS allowed on top of the
// env list so local dev AND the CI integration_test harness can reach the API:
// `flutter drive -d web-server` serves the app on http://localhost:<random-port>,
// which is a cross-origin caller to api.nikatru.com. A localhost page still needs
// a valid Bearer token to read anything, so this is low-risk.
// ─────────────────────────────────────────────────────────────────────────────

import { cors } from 'hono/cors';
import type { Context, Next } from 'hono';
import type { AppEnv } from '../types';

const LOCALHOST = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

export const corsMiddleware = (c: Context<AppEnv>, next: Next) => {
  const list = (c.env.ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  return cors({
    origin: (origin) => {
      if (list.length === 0) return '*';
      if (list.includes(origin)) return origin;
      if (LOCALHOST.test(origin)) return origin;
      return null;
    },
    allowMethods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Authorization', 'Content-Type'],
    maxAge: 86400,
  })(c, next);
};
