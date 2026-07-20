# Project_nek — nikatru.com

Static site for the **NIKATRU** brand — studio app portfolio + legal pages (privacy, terms, refund, contact),
plus a Cloudflare Pages Function (`/api/subscribe`) that stores launch-list signups in Cloudflare KV.

- **/** (repo root) → **nikatru.com**

## Hosting
**Cloudflare Pages**, connected to this repo (project `project-nek`, output dir `/`). Every push to `main`
redeploys automatically — no build step, plain static HTML + one Pages Function. (GitHub Pages is intentionally
not used.)

> rajasekarselvam.com is a **separate** site in its own repo `globalonlinedeveloper/Project_RS`
> (Cloudflare Pages project `project-rs`).
