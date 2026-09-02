#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
DIST_DIR="${PROJECT_DIR}/dist"
INFO_PLIST="${PROJECT_DIR}/AppResources/Info.plist"
APP_DIR="${DIST_DIR}/edge.app"
VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST}")}"
OUTPUT_PATH="${1:-${DIST_DIR}/edge-${VERSION}.dmg}"

command -v hdiutil >/dev/null || { print -u2 "hdiutil is required to build the DMG"; exit 1; }
if [[ ! -d "${APP_DIR}" ]]; then
    print -u2 "Missing app bundle: ${APP_DIR}. Run Scripts/build-app.sh first."
    exit 1
fi

mkdir -p "${OUTPUT_PATH:h}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/private/tmp}/edge-dmg.XXXXXXXX")"
trap 'rm -rf "${WORK_DIR}"' EXIT

ditto "${APP_DIR}" "${WORK_DIR}/edge.app"
ln -s /Applications "${WORK_DIR}/Applications"

rm -f "${OUTPUT_PATH}"
hdiutil create \
    -quiet \
    -volname "edge ${VERSION}" \
    -srcfolder "${WORK_DIR}" \
    -ov \
    -format UDZO \
    "${OUTPUT_PATH}"

print "Built ${OUTPUT_PATH}"
