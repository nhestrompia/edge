#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
DIST_DIR="${PROJECT_DIR}/dist"
APP_DIR="${DIST_DIR}/edge.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
INFO_PLIST="${PROJECT_DIR}/AppResources/Info.plist"
ICON_PATH="${DIST_DIR}/edge.icns"
ASSETS_CAR_PATH="${DIST_DIR}/Assets.car"
LOGO_RESOURCE="${PROJECT_DIR}/Sources/HyperliquidPositions/Resources/edge-logo-extracted.png"

VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST}")}"
BUILD_NUMBER="${BUILD_NUMBER:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${INFO_PLIST}")}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/private/tmp}/hyperliquid-positions-clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="${TMPDIR:-/private/tmp}/hyperliquid-positions-swiftpm-cache"

cd "${PROJECT_DIR}"
swift build --disable-sandbox -c release
BIN_DIR="$(swift build --disable-sandbox -c release --show-bin-path)"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"
cp "${BIN_DIR}/HyperliquidPositions" "${MACOS_DIR}/HyperliquidPositions"
cp "${INFO_PLIST}" "${CONTENTS_DIR}/Info.plist"
cp "${LOGO_RESOURCE}" "${RESOURCES_DIR}/edge-logo-extracted.png"

"${SCRIPT_DIR}/make-app-icon.sh" "${ICON_PATH}"
cp "${ICON_PATH}" "${RESOURCES_DIR}/edge.icns"
cp "${ASSETS_CAR_PATH}" "${RESOURCES_DIR}/Assets.car"

/usr/bin/plutil -replace CFBundleShortVersionString -string "${VERSION}" "${CONTENTS_DIR}/Info.plist"
/usr/bin/plutil -replace CFBundleVersion -string "${BUILD_NUMBER}" "${CONTENTS_DIR}/Info.plist"

if [[ "${CODESIGN_IDENTITY}" == "-" ]]; then
    codesign --force --deep --sign - "${APP_DIR}"
else
    codesign --force --deep --options runtime --timestamp --sign "${CODESIGN_IDENTITY}" "${APP_DIR}"
fi

print "Built ${APP_DIR} (${VERSION}, build ${BUILD_NUMBER})"
