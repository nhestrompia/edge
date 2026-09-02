#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
DIST_DIR="${PROJECT_DIR}/dist"
INFO_PLIST="${PROJECT_DIR}/AppResources/Info.plist"
APP_DIR="${DIST_DIR}/edge.app"
VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST}")}"
OUTPUT_PATH="${1:-${DIST_DIR}/edge-${VERSION}.pkg}"
PKG_IDENTIFIER="${PKG_IDENTIFIER:-com.hyperliquid.positions}"
PKG_SIGNING_IDENTITY="${PKG_SIGNING_IDENTITY:-}"

command -v pkgbuild >/dev/null || { print -u2 "pkgbuild is required to build the installer package"; exit 1; }
if [[ ! -d "${APP_DIR}" ]]; then
    print -u2 "Missing app bundle: ${APP_DIR}. Run Scripts/build-app.sh first."
    exit 1
fi

mkdir -p "${OUTPUT_PATH:h}"
rm -f "${OUTPUT_PATH}"

if [[ -n "${PKG_SIGNING_IDENTITY}" ]]; then
    pkgbuild \
        --component "${APP_DIR}" \
        --install-location /Applications \
        --identifier "${PKG_IDENTIFIER}" \
        --version "${VERSION}" \
        --sign "${PKG_SIGNING_IDENTITY}" \
        "${OUTPUT_PATH}"
else
    pkgbuild \
        --component "${APP_DIR}" \
        --install-location /Applications \
        --identifier "${PKG_IDENTIFIER}" \
        --version "${VERSION}" \
        "${OUTPUT_PATH}"
fi

print "Built ${OUTPUT_PATH}"
