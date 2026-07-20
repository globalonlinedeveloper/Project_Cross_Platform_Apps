// Cloudflare Pages Function: POST /api/subscribe
// Stores launch-notify signups in a Cloudflare KV namespace.
//
// Privacy: we store ONLY the email address and a timestamp — nothing else.
// This matches the promise shown on the site ("your email only ... nothing else, ever").
// For abuse protection we rate-limit per IP, but the IP is hashed (SHA-256) and the
// counter auto-expires; the raw IP is never written to storage.
//
// SETUP (one time, in the Cloudflare dashboard):
//   1. Workers & Pages -> KV -> Create namespace, e.g. "nikatru-signups".
//   2. Pages project "project-nek" -> Settings -> Functions ->
//      KV namespace bindings -> Add binding:
//         Variable name: SIGNUPS
//         KV namespace:  nikatru-signups
//      (Add it for Production, and Preview if you want.)
//   3. Redeploy (any push) so the binding takes effect.
//
// Read signups later: dashboard KV browser (keys prefixed "sub:"), or
//   `wrangler kv key list --binding SIGNUPS`.

const json = (obj, status = 200) =>
  new Response(JSON.stringify(obj), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });

const isEmail = (e) =>
  typeof e === "string" &&
  e.length <= 254 &&
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e);

// Hash a value so it is never stored in plaintext (used for the rate-limit key).
async function sha256(text) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

const RATE_LIMIT = 12; // max signups per IP per hour

export async function onRequestPost({ request, env }) {
  let email = "";
  let honeypot = "";

  try {
    const ct = request.headers.get("content-type") || "";
    if (ct.includes("application/json")) {
      const body = await request.json();
      email = (body.email || "").toString().trim();
      honeypot = (body.company || "").toString().trim();
    } else {
      const form = await request.formData();
      email = (form.get("email") || "").toString().trim();
      honeypot = (form.get("company") || "").toString().trim();
    }
  } catch (_) {
    return json({ ok: false, error: "Could not read your submission. Please try again." }, 400);
  }

  // Honeypot: a bot filled the hidden field. Pretend success, store nothing.
  if (honeypot) return json({ ok: true });

  if (!isEmail(email)) {
    return json({ ok: false, error: "Please enter a valid email address." }, 400);
  }

  // KV not bound yet -> fail gracefully (see SETUP above).
  if (!env || !env.SIGNUPS) {
    return json(
      { ok: false, error: "Signups aren't switched on yet. Please try again soon." },
      503
    );
  }

  // --- Abuse guard: soft per-IP rate limit, IP hashed and never persisted raw. ---
  const ip = request.headers.get("cf-connecting-ip") || "";
  if (ip) {
    try {
      const rlKey = "rl:" + (await sha256(ip));
      const hits = parseInt((await env.SIGNUPS.get(rlKey)) || "0", 10);
      if (hits >= RATE_LIMIT) {
        return json({ ok: false, error: "Too many attempts. Please try again later." }, 429);
      }
      // Counter expires after 1 hour so nothing lingers.
      await env.SIGNUPS.put(rlKey, String(hits + 1), { expirationTtl: 3600 });
    } catch (_) {
      // If the rate-limit check fails, don't block a real signup.
    }
  }

  // --- Store the signup: email + timestamp ONLY. ---
  const key = "sub:" + email.toLowerCase();
  try {
    const existing = await env.SIGNUPS.get(key);
    if (!existing) {
      const record = { email, ts: new Date().toISOString() };
      await env.SIGNUPS.put(key, JSON.stringify(record));
    }
    return json({ ok: true });
  } catch (_) {
    return json({ ok: false, error: "Something went wrong. Please try again." }, 500);
  }
}

// GET (or a curious visitor) -> 405, so the endpoint never leaks a stack trace.
export async function onRequestGet() {
  return json({ ok: false, error: "Method not allowed. POST an { email } payload." }, 405);
}
