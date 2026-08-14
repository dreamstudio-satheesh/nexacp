#!/bin/bash
set -euo pipefail

# Publish deploy/stable -> VPS bare repo (which serves /var/www/nexacp-resource)
# Usage: ./deploy/publish.sh [VPS]   (VPS default: ubuntu@5.230.122.175)
# Run from a machine whose SSH key is authorized for the ubuntu user on the VPS.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VPS="${1:-ubuntu@5.230.122.175}"
REPO_DIR="${ROOT}/deploy/resource-repo"

if [[ ! -f "${ROOT}/deploy/stable/latest" ]]; then
    echo "No release found in deploy/stable/. Run ./deploy/release.sh first."
    exit 1
fi

echo "==> Staging resource tree (v2/...)"
rm -rf "$REPO_DIR"
mkdir -p "${REPO_DIR}/v2"
cp "${ROOT}/deploy/quick_start.sh" "${REPO_DIR}/v2/quick_start.sh"
cp -r "${ROOT}/deploy/stable/." "${REPO_DIR}/v2/stable/"

echo "==> Committing"
cd "$REPO_DIR"
git init -q
git add -A
git -c user.name="nexacp" -c user.email="deploy@nexacp.in" commit -qm "release $(cat v2/stable/latest)"

echo "==> Pushing to ${VPS}:/var/git/nexacp-resource.git (force: content mirror)"
git push -f "${VPS}:/var/git/nexacp-resource.git" HEAD:master

echo "==> Done. Check https://resource.nexacp.in/v2/stable/latest"
