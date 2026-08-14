# NexaCP Deployment Guide

Infrastructure and deploy workflow for the NexaCP project.

## Architecture overview

Two servers are used:

| Server | Role | Access |
|--------|------|--------|
| **Resource host** — `5.230.122.175` (VM 143) | Serves the installer + release packages at `resource.nexacp.in`. Minimal: nginx + fail2ban + ssh only. No panel, no Docker. | `ssh ubuntu@5.230.122.175` |
| **Test VM** — `5.230.167.86` (VM 144 `nexatestvm`) | Runs the NexaCP panel (`1panel-core`) and **builds + deploys** from git pushes. Ubuntu 24, 16 GB RAM, 4 cores. | `ssh ubuntu@5.230.167.86` |

```text
                    ┌─────────────────────────────┐
                    │  Resource host 5.230.122.175 │
                    │  resource.nexacp.in          │
                    │  quick_start.sh + packages   │
                    └──────────────┬──────────────┘
                                   │  installer downloads
                                   ▼
                    ┌─────────────────────────────┐
   git push deploy  │  Test VM 5.230.167.86        │
   ────────────────►│  /var/git/nexacp-app.git     │
                    │  post-receive hook:          │
                    │  npm run build:pro           │
                    │  go build → 1panel-core      │
                    │  systemctl restart           │
                    └─────────────────────────────┘
```

## Installing a fresh panel on any VM

```bash
bash -c "$(curl -sSL https://resource.nexacp.in/v2/quick_start.sh)"
```

Then get credentials:
```bash
sudo 1pctl user-info
```

### Test VM panel (current)

- URL: `http://5.230.167.86:17223/nexatest`
- Secure entrance: `nexatest`
- Panel service: `1panel-core` (binary at `/usr/local/bin/1panel-core`)

## Deploying code changes (git push → auto build + deploy)

On your **local machine** (one-time setup):

```bash
git remote add deploy deploy@5.230.167.86:/var/git/nexacp-app.git
```

Then, every time you change code:

```bash
git add -A
git commit -m "describe your change"
git push deploy main
```

That single push runs the post-receive hook on the test VM, which:

1. Checks out the code to `/var/www/nexacp-app`
2. Builds the frontend: `cd frontend && npm install && npm run build:pro`
3. Builds the core binary: `cd core && go build` → `1panel-core`
4. Backs up and replaces `/usr/local/bin/1panel-core`, restarts `1panel-core`
5. Prints `systemctl is-active` result

Refresh the panel in your browser (hard refresh, Ctrl+Shift+R) to see the change.

### Deploy user

- User: `deploy` (sudo-capable) on the test VM
- SSH key: your local `~/.ssh/id_ed25519.pub` is authorized at `/home/deploy/.ssh/authorized_keys`
- Bare repo: `/var/git/nexacp-app.git` (owned by `deploy`)
- Hook: `/var/git/nexacp-app.git/hooks/post-receive` (executable)

## Server details

### Resource host (5.230.122.175)

- nginx sites: `nexacp-resource` only (`panel.nexacp.in` site removed)
- Webroot: `/var/www/nexacp-resource` (git checkout of the resource repo)
- Bare repo: `/var/git/nexacp-resource.git` (post-receive hook updates webroot)
- TLS: certbot for `resource.nexacp.in` (auto-renew)
- Publish a release: `./deploy/publish.sh ubuntu@5.230.122.175`

### Test VM (5.230.167.86)

- Panel installed at `/opt/1panel` (data) with binary symlinked at `/usr/local/bin/1panel-core`
- Docker installed (needed by panel apps)
- Node.js 22 + Go 1.26 installed for server-side builds
- Root disk resized to 40 GB (growpart + resize2fs already applied)

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `git push deploy main` says "Everything up-to-date" | The hook only runs on new commits; make a commit first |
| Panel not updated after push | Check hook output; re-run `sudo systemctl restart 1panel-core`; verify `/usr/local/bin/1panel-core` mtime |
| Build fails with disk full | `df -h /` — grow the disk (growpart/resize2fs) and clean `npm`/apt caches |
| Deploy permission error | Ensure `/var/git/nexacp-app.git` and hook are owned by `deploy` and hook is `+x` |
