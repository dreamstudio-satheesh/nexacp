# agent.md — Working in this repository (NexaCP)

Guidance for AI agents and contributors working on the NexaCP codebase. NexaCP is a fork of [1Panel](https://github.com/1Panel-dev/1Panel) (GPL-3.0, upstream attribution retained) — a Linux server management panel.

## Product & brand

- Product name: **NexaCP** (never "1Panel" in user-facing text).
- Domains:
  - `panel.nexacp.in` — the panel UI (nginx reverse proxy to local panel port).
  - `resource.nexacp.in` — release host: installer + packages + checksums.
  - `nexacp.in` — root domain.
- Brand color: `#4F46E5` (indigo). Light variants in `frontend/src/styles/element.scss`; dark/pro gold stays `#F0BE96`.
- Logos: `frontend/src/assets/images/1panel-logo.svg` (wordmark), `1panel-menu-logo.svg` (mark), `favicon.svg`; PNG copies in `frontend/public/`, `core/cmd/server/app/`, `core/cmd/server/web/`.

## Repository layout

- `core/` — Go backend (module `github.com/1Panel-dev/1Panel/core`; go 1.26.1).
- `agent/` — Go node agent (module `github.com/1Panel-dev/1Panel/agent`; go 1.25.10).
- `frontend/` — Vue 3 + Element Plus + Vite. Build output goes **directly into** `core/cmd/server/web/` (`vite.config.ts` `outDir`), which is embedded into the core binary.
- `deploy/` — release pipeline:
  - `quick_start.sh` — installer entrypoint served at `resource.nexacp.in/v2/quick_start.sh`.
  - `pkg-base/` — vendored installer assets (install.sh, 1pctl, systemd units, GeoIP.mmdb, i18n).
  - `release.sh` — build + package → `deploy/stable/<VERSION>/release/` + `checksums.txt` + `latest`.
  - `publish.sh` — force-push `deploy/stable/` + `quick_start.sh` to the VPS bare repo (content mirror; `git push -f`).
  - `setup-vps.sh` — VPS provisioning (nginx, certbot, webroot, bare repo).
  - `nginx/` — reference nginx site configs.
- `build/`, `deploy/stable/`, `deploy/resource-repo/` are gitignored build artifacts.

## Common commands

```bash
make build_all                 # frontend + core + agent (linux/amd64)
./deploy/release.sh v2.0.0     # build + package a release
./deploy/publish.sh ubuntu@<vps-ip>   # push release to the VPS
```
Frontend type-check: `cd frontend && npm run type-check` (note: `auto-imports.d.ts`/`components.d.ts` are generated at build time; pre-existing `TS2304` errors appear when they are absent).

## Do NOT change (upstream compatibility / risk)

- Go module paths `github.com/1Panel-dev/1Panel/...` — keep as-is.
- Functional identifiers: `/opt/1panel` install dir, `1panel-core`/`1panel-agent` binaries + systemd services, `1pctl`, `/1panel/swagger/` route, DB paths, `1panel-network`, `.1panel_clash`, `1panel-php-fpm`, localStorage keys.
- Resource/update/app-store URLs pointing at upstream (`resource.fit2cloud.com`, `apps-assets.fit2cloud.com`, `apps.1panel.pro`, `1panel.cn`, `docs.1panel.pro`) — no NexaCP equivalents exist yet; changing them breaks updates/app-store.
- Upstream license/attribution: `LICENSE`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, footer copyright links.

## Branding rules when editing

- User-facing product name: `1Panel` → `NexaCP` (capital `P` only; lowercase `1panel` tokens are usually functional — leave them).
- When rebranding colors: update all defaults consistently — `frontend/src/styles/element.scss`, `frontend/src/store/modules/global.ts`, `svg-icon.vue`, `views/setting/panel/theme-color/index.vue`, `views/setting/panel/index.vue`, login pages.
- i18n files: `frontend/src/lang/modules/*.ts` contain user-facing strings; replace product-name mentions only, never paths/keys.

## Infrastructure (verified)

- VPS: Ubuntu 24.04 at `5.230.122.175` (root SSH via `ubuntu` user, passwordless sudo). SSH key on the build machine is authorized.
- Resource webroot on VPS: `/var/www/nexacp-resource` (git checkout from `/var/git/nexacp-resource.git` via post-receive hook).
- Panel installed on the VPS: port `30899`, security entrance required (`https://panel.nexacp.in/<entrance>`), credentials via `1pctl user-info`.
- TLS: Let's Encrypt via certbot on the VPS nginx (auto-renew).
- DNS: Cloudflare, zone `nexacp.in`, A records → `5.230.122.175` (DNS-only/grey cloud).
