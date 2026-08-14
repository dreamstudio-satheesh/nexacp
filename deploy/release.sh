#!/bin/bash
set -euo pipefail

# NexaCP release builder
# Usage: ./deploy/release.sh [VERSION] [ARCH]
#   VERSION  default v2.0.0
#   ARCH     default amd64
# Builds frontend + core + agent, stages the upstream-compatible package
# layout and writes checksums.txt + latest into deploy/stable/.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-v2.0.0}"
ARCH="${2:-amd64}"

PKG_NAME="1panel-${VERSION}-linux-${ARCH}"
RELEASE_DIR="${ROOT}/deploy/stable/${VERSION}/release"
STAGE="${RELEASE_DIR}/${PKG_NAME}"

echo "==> Building NexaCP ${VERSION} (linux/${ARCH})"

echo "==> Frontend (vite -> core/cmd/server/web)"
cd "${ROOT}/frontend"
if [[ ! -d node_modules ]]; then
    npm install --no-audit --no-fund
fi
npm run build:pro

echo "==> Core binary"
cd "${ROOT}/core"
CGO_ENABLED=0 GOOS=linux GOARCH="${ARCH}" go build -trimpath -ldflags '-s -w' -o "${ROOT}/build/1panel-core" ./cmd/server/main.go

echo "==> Agent binary"
cd "${ROOT}/agent"
CGO_ENABLED=0 GOOS=linux GOARCH="${ARCH}" go build -trimpath -ldflags '-s -w' -o "${ROOT}/build/1panel-agent" ./cmd/server/main.go

echo "==> Stage package"
rm -rf "${STAGE}" "${RELEASE_DIR}/${PKG_NAME}.tar.gz"
mkdir -p "${STAGE}"
cp -r "${ROOT}/deploy/pkg-base/." "${STAGE}/"
cp "${ROOT}/build/1panel-core" "${ROOT}/build/1panel-agent" "${STAGE}/"
chmod +x "${STAGE}/1panel-core" "${STAGE}/1panel-agent" "${STAGE}/install.sh" "${STAGE}/1pctl"

echo "==> Archive + checksums"
cd "${RELEASE_DIR}"
tar czf "${PKG_NAME}.tar.gz" "${PKG_NAME}"
sha256sum "${PKG_NAME}.tar.gz" > checksums.txt
printf '%s' "${VERSION}" > "${ROOT}/deploy/stable/latest"

echo "==> Done"
echo "    Release:  ${RELEASE_DIR}/${PKG_NAME}.tar.gz"
echo "    SHA256:   $(awk '{print $1}' checksums.txt)"
echo "    latest:   ${VERSION}"
