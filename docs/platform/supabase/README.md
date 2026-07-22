# Supabase auth — portfolio branding (Cross_Platform_Auth · lcrkiurkvzhkonjwhpiv)

One Supabase project authenticates every app in the portfolio. Branding it once brands all apps.

## What's configured via the Management API (session-applied, re-runnable)
- **Site URL:** `https://subly.nikatru.com` (app #1's web home; OAuth/email links default here).
- **Redirect allow-list:** `https://subly.nikatru.com/**`, `https://subly.pages.dev/**`,
  `http://localhost:3000/**`, `http://localhost:8080/**` (web + local dev). Add per-app web
  origins as apps ship; add a custom-scheme deep link (e.g. `subly://auth-callback`) once the
  desktop/mobile apps register one.
- **Email templates** (`email-templates/*.html`): Nikatru-branded confirm-signup, magic-link,
  reset-password. Inline-CSS table layout (email-client-safe), no remote images (no logo
  hosting dependency, no tracking flags). Variables: `{{ .ConfirmationURL }}`, `{{ .Email }}`.

## Custom SMTP (noreply@nikatru.com) — NEEDS OWNER (accounts + DNS)
**Custom SMTP is the gate for ALL email branding:** Supabase free tier + default mailer
REJECTS template/subject changes (`400: Email template modification is not available for free
tier projects using the default email provider`). Once SMTP creds are configured, a session
re-applies the staged templates in one PATCH. The built-in sender is also heavily rate-limited
(a few emails/hour) and sends from supabase.io. Providers:

| Provider | Free tier | Notes |
|---|---|---|
| **Resend** (recommended) | 3,000 emails/mo | Simple, modern; SMTP + API |
| SendGrid | 100/day | Long-standing default |
| Brevo | 300/day | Generous daily cap |

Owner steps (one-time, ~15 min): create the provider account → add domain `nikatru.com` →
add the DKIM/SPF DNS records the provider shows (Cloudflare DNS dashboard) → create an SMTP
key → hand the SMTP host/port/user/pass to a session (or paste into
`.cowork-private/secrets.env` as `SMTP_HOST/PORT/USER/PASS`) → a session PATCHes it into
Supabase auth config (`smtp_*` fields) with sender `noreply@nikatru.com`.

## Custom auth domain (auth.nikatru.com) — PAID, decision pending
Supabase custom domains: **$10/mo add-on**, requires **Pro plan ($25/mo)** → ~$35/mo total
(project is currently FREE tier). Pure vanity/deliverability win (auth URLs show
auth.nikatru.com instead of lcrkiurkvzhkonjwhpiv.supabase.co). Recommendation: defer until
revenue; custom SMTP + templates deliver most of the branding value for $0.

## Re-apply / extend (any session)
Management API: `PATCH https://api.supabase.com/v1/projects/{ref}/config/auth` with
`Authorization: Bearer $SUPABASE_PAT`. Fields used: `site_url`, `uri_allow_list` (comma-joined
string), `mailer_subjects_*`, `mailer_templates_*_content`, `smtp_*`. Templates live in this
folder as the source of truth — edit here, re-PATCH.
