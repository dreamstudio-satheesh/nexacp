<p align="center"><img src="frontend/src/assets/images/1panel-logo.svg" alt="NexaCP" width="300" /></p>

<p align="center">
  Modern, open-source Linux server management panel — rebranded for NexaCP.
</p>

<p align="center">
  <a href="https://www.gnu.org/licenses/gpl-3.0.html"><img src="https://shields.io/github/license/1Panel-dev/1Panel?color=%234F46E5" alt="License: GPL v3"></a>
</p>

---

## What is NexaCP?

NexaCP is a modern, open-source Linux server management panel. Through an intuitive web interface, it provides comprehensive, one-stop server management capabilities:

- **AI Management**: A unified management platform from bare metal to agents (Metal-to-Agent), with an integrated AI gateway, Skills Hub, and centralized management of agents and models.
- **Efficient Visual Operations**: Manage Linux servers through a web-based GUI — host monitoring, file management, database management, and container management.
- **Rapid Website Deployment**: Deeply integrates with popular website builders, with one-click domain binding and SSL certificate configuration.
- **Curated App Store**: A built-in store of high-quality open-source applications with one-click installation and upgrades.
- **Enterprise-Grade Security**: Applications run in containers to minimize vulnerability exposure, with WAF and log auditing.
- **One-Click Data Backup**: One-click backup and restoration with integration for various cloud storage solutions.

## Why NexaCP?

| | NexaCP | cPanel / Plesk | aaPanel | Webmin |
|--|--------|----------------|---------|--------|
| Free & open source | ✅ | ❌ | Partial | ✅ |
| AI management | ✅ | ❌ | ❌ | ❌ |
| One-click app marketplace | ✅ 165+ apps | ❌ | ✅ | ❌ |
| Modern UI (post-2020) | ✅ | ❌ | Partial | ❌ |
| Docker / container management | ✅ | ❌ | ❌ | ❌ |
| Active development | ✅ | ✅ | ✅ | Slow |

## Domains

| Domain | Purpose |
|--------|---------|
| `nexacp.in` | Root / future marketing & docs |
| `panel.nexacp.in` | The NexaCP panel UI (reverse-proxied to the local panel port) |
| `resource.nexacp.in` | Release host — installer script, packages, checksums |

## Quick Start

Prepare a Linux server and run:

```bash
bash -c "$(curl -sSL https://resource.nexacp.in/v2/quick_start.sh)"
```

After installation, open `https://panel.nexacp.in/<security-path>` in your browser.  
Run `1pctl user-info` via SSH to retrieve your access credentials.

## Build from Source

Requirements: Go 1.26+, Node.js 22+, npm.

```bash
make build_all
```

This builds the frontend (embedded into the core binary), `1panel-core`, and `1panel-agent` into `build/`.

## Release & Deployment

The release pipeline mirrors the upstream 1Panel resource layout under `deploy/`:

```bash
# 1. Build + package a release (default v2.0.0, linux/amd64)
./deploy/release.sh [VERSION] [ARCH]

# 2. Provision the VPS (nginx, certbot, webroot, bare git repo)
sudo bash deploy/setup-vps.sh

# 3. Publish the release to the VPS (served at resource.nexacp.in/v2/stable/...)
./deploy/publish.sh ubuntu@<vps-ip>
```

- `deploy/quick_start.sh` — installer entrypoint (`resource.nexacp.in/v2/quick_start.sh`)
- `deploy/pkg-base/` — vendored installer assets (`install.sh`, `1pctl`, systemd units, `GeoIP.mmdb`, i18n)
- `deploy/nginx/` — nginx site configs for `resource.nexacp.in` and `panel.nexacp.in`
- `deploy/stable/` — built releases (gitignored; pushed to the VPS bare repo)

## Security

Found a vulnerability? Please read [SECURITY.md](/SECURITY.md) before disclosing.

## License

Licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).

NexaCP is a fork of [1Panel](https://github.com/1Panel-dev/1Panel). Upstream license, copyright, and attribution are retained.
