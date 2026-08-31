#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
APP_DIR="${PROJECT_DIR}/dist/edge.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"

export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/private/tmp}/hyperliquid-positions-clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="${TMPDIR:-/private/tmp}/hyperliquid-positions-swiftpm-cache"

cd "${PROJECT_DIR}"
swift build --disable-sandbox -c release
BIN_DIR="$(swift build --disable-sandbox -c release --show-bin-path)"

mkdir -p "${MACOS_DIR}"
cp "${BIN_DIR}/HyperliquidPositions" "${MACOS_DIR}/HyperliquidPositions"
cp "${PROJECT_DIR}/AppResources/Info.plist" "${CONTENTS_DIR}/Info.plist"

codesign --force --deep --sign - "${APP_DIR}"

print "Built ${APP_DIR}"
