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
LOGO_RESOURCE="${PROJECT_DIR}/Sources/Edge/Resources/edge-logo-extracted.png"

VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST}")}"
BUILD_NUMBER="${BUILD_NUMBER:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${INFO_PLIST}")}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
ARCHS="${ARCHS:-arm64 x86_64}"

export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/private/tmp}/edge-clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="${TMPDIR:-/private/tmp}/edge-swiftpm-cache"
mkdir -p "${CLANG_MODULE_CACHE_PATH}" "${SWIFTPM_MODULECACHE_OVERRIDE}"

cd "${PROJECT_DIR}"
typeset -a ARCH_LIST BINARIES
ARCH_LIST=(${=ARCHS})
if (( ${#ARCH_LIST[@]} == 0 )); then
    print -u2 "ARCHS must contain at least one architecture"
    exit 1
fi

for architecture in "${ARCH_LIST[@]}"; do
    swift build --disable-sandbox -c release --arch "${architecture}"
    BIN_DIR="$(swift build --disable-sandbox -c release --arch "${architecture}" --show-bin-path)"
    BINARIES+=("${BIN_DIR}/edge")
done

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"
if (( ${#BINARIES[@]} == 1 )); then
    cp "${BINARIES[1]}" "${MACOS_DIR}/edge"
else
    command -v lipo >/dev/null || { print -u2 "lipo is required to combine app architectures"; exit 1; }
    lipo -create "${BINARIES[@]}" -output "${MACOS_DIR}/edge"
fi
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
