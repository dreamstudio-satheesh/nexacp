#!/bin/bash
set -euo pipefail

# NexaCP VPS provisioning — Ubuntu 24.04
# Run as root:  sudo bash setup-vps.sh
# Idempotent: safe to re-run.

VPS_IP="5.230.122.175"
RESOURCE_DOMAIN="resource.nexacp.in"
PANEL_DOMAIN="panel.nexacp.in"
WEBROOT="/var/www/nexacp-resource"
GIT_DIR="/var/git/nexacp-resource.git"
GIT_USER="ubuntu"

echo "==> 1/6 Installing packages (nginx, certbot, git)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq nginx certbot python3-certbot-nginx git

echo "==> 2/6 Creating bare repo ${GIT_DIR} (owner: ${GIT_USER})"
mkdir -p "$(dirname "$GIT_DIR")"
if [[ ! -d "$GIT_DIR" ]]; then
    git init --bare "$GIT_DIR"
    chown -R "${GIT_USER}:${GIT_USER}" "$(dirname "$GIT_DIR")"
fi
HOOK="${GIT_DIR}/hooks/post-receive"
cat > "$HOOK" <<'EOF'
#!/bin/bash
TARGET=/var/www/nexacp-resource
mkdir -p "$TARGET"
git --git-dir="$GIT_DIR" --work-tree="$TARGET" checkout -f
git --git-dir="$GIT_DIR" --work-tree="$TARGET" clean -fd
chmod -R a+rX "$TARGET"
EOF
chmod +x "$HOOK"
chown -R "${GIT_USER}:${GIT_USER}" "$GIT_DIR"

echo "==> 3/6 Creating webroot ${WEBROOT}"
mkdir -p "$WEBROOT"
chown -R "ubuntu:www-data" "$WEBROOT"
chmod 775 "$WEBROOT"

echo "==> 4/6 Writing nginx site configs"
PANEL_PORT="30899"
if [[ -f /usr/local/bin/1pctl ]]; then
    PANEL_PORT="$(grep '^ORIGINAL_PORT=' /usr/local/bin/1pctl | head -1 | cut -d= -f2 | tr -d '"')"
    [[ -n "$PANEL_PORT" ]] || PANEL_PORT="30899"
fi

cat > /etc/nginx/sites-available/nexacp-resource <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name resource.nexacp.in;

    root /var/www/nexacp-resource;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~* \.(tar\.gz|txt)$ {
        add_header Cache-Control "public, max-age=3600";
    }
}
EOF

sed "s/__PANEL_PORT__/${PANEL_PORT}/" > /etc/nginx/sites-available/nexacp-panel <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name panel.nexacp.in;

    location / {
        proxy_pass http://127.0.0.1:__PANEL_PORT__;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_buffering off;
        client_max_body_size 0;
    }
}
EOF

ln -sf /etc/nginx/sites-available/nexacp-resource /etc/nginx/sites-enabled/nexacp-resource
ln -sf /etc/nginx/sites-available/nexacp-panel /etc/nginx/sites-enabled/nexacp-panel
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "==> 5/6 DNS check for ${RESOURCE_DOMAIN}"
if getent hosts "${RESOURCE_DOMAIN}" | grep -q "${VPS_IP}"; then
    echo "    DNS is live -> issuing Let's Encrypt certificates"
    certbot --nginx -d "${RESOURCE_DOMAIN}" -d "${PANEL_DOMAIN}" --non-interactive --agree-tos --redirect -m admin@nexacp.in
    systemctl reload nginx
else
    echo "    DNS not pointing here yet. After adding A records in Cloudflare, run:"
    echo "    sudo certbot --nginx -d ${RESOURCE_DOMAIN} -d ${PANEL_DOMAIN} --non-interactive --agree-tos --redirect -m admin@nexacp.in"
fi

echo "==> 6/6 Done"
echo "    Push releases:  git push ubuntu@${VPS_IP}:${GIT_DIR} HEAD:master"
echo "    Then verify:     curl -s https://${RESOURCE_DOMAIN}/v2/stable/latest"
echo "    Install panel:   bash -c \"\$(curl -sSL https://${RESOURCE_DOMAIN}/v2/quick_start.sh)\""
