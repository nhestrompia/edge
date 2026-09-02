#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
SOURCE_IMAGE="${PROJECT_DIR}/Sources/HyperliquidPositions/Resources/edge-logo-extracted.png"
CONTENTS_JSON="${PROJECT_DIR}/AppResources/Assets.xcassets/edge.appiconset/Contents.json"
OUTPUT_PATH="${1:-${PROJECT_DIR}/dist/edge.icns}"
OUTPUT_DIR="${OUTPUT_PATH:h}"

if [[ ! -f "${SOURCE_IMAGE}" ]]; then
    print -u2 "Missing logo source: ${SOURCE_IMAGE}"
    exit 1
fi
if [[ ! -f "${CONTENTS_JSON}" ]]; then
    print -u2 "Missing app icon catalog metadata: ${CONTENTS_JSON}"
    exit 1
fi

command -v ffmpeg >/dev/null || { print -u2 "ffmpeg is required to build the app icon"; exit 1; }
command -v sips >/dev/null || { print -u2 "sips is required to build the app icon"; exit 1; }
xcrun --find actool >/dev/null || { print -u2 "actool is required to build the app icon"; exit 1; }

mkdir -p "${OUTPUT_DIR}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/private/tmp}/edge-icon.XXXXXXXX")"
trap 'rm -rf "${WORK_DIR}"' EXIT

BASE_ICON="${WORK_DIR}/edge-1024.png"
ASSET_CATALOG_DIR="${WORK_DIR}/Assets.xcassets"
ICONSET_DIR="${ASSET_CATALOG_DIR}/edge.appiconset"
COMPILE_DIR="${WORK_DIR}/compiled"
PARTIAL_INFO_PLIST="${WORK_DIR}/partial-info.plist"
mkdir -p "${ICONSET_DIR}"
mkdir -p "${COMPILE_DIR}"
cp "${CONTENTS_JSON}" "${ICONSET_DIR}/Contents.json"

# Build a clean graphite app tile from the extracted mark, then let Apple's
# asset compiler generate the native Assets.car app icon catalog.
ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "color=c=0x0b100f:s=2048x2048,format=rgba,geq=r='11':g='16':b='15':a='if(lte(hypot(max(abs(X-1024)-624,0),max(abs(Y-1024)-624,0)),400),255,0)'" \
    -i "${SOURCE_IMAGE}" \
    -filter_complex "[1:v]scale=1000:-1:flags=lanczos[logo];[0:v][logo]overlay=(W-w)/2:(H-h)/2:format=auto,scale=1024:1024:flags=lanczos,format=rgba" \
    -frames:v 1 "${BASE_ICON}"

make_variant() {
    local pixel_size="$1"
    local filename="$2"
    sips --resampleHeightWidth "${pixel_size}" "${pixel_size}" "${BASE_ICON}" --out "${ICONSET_DIR}/${filename}" >/dev/null
}

make_variant 16   icon_16x16.png
make_variant 32   icon_16x16@2x.png
make_variant 32   icon_32x32.png
make_variant 64   icon_32x32@2x.png
make_variant 128  icon_128x128.png
make_variant 256  icon_128x128@2x.png
make_variant 256  icon_256x256.png
make_variant 512  icon_256x256@2x.png
make_variant 512  icon_512x512.png
make_variant 1024 icon_512x512@2x.png

ACTOOL="$(xcrun --find actool)"
"${ACTOOL}" \
    --compile "${COMPILE_DIR}" \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --app-icon edge \
    --compress-pngs \
    --output-partial-info-plist "${PARTIAL_INFO_PLIST}" \
    "${ASSET_CATALOG_DIR}" >/dev/null

cp "${COMPILE_DIR}/edge.icns" "${OUTPUT_PATH}"
cp "${COMPILE_DIR}/Assets.car" "${OUTPUT_DIR}/Assets.car"
print "Built ${OUTPUT_PATH}"
