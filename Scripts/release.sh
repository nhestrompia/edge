#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
DIST_DIR="${PROJECT_DIR}/dist"
INFO_PLIST="${PROJECT_DIR}/AppResources/Info.plist"
VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST}")}"
BUILD_NUMBER="${BUILD_NUMBER:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${INFO_PLIST}")}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
DMG_PATH="${DIST_DIR}/edge-${VERSION}.dmg"
PKG_PATH="${DIST_DIR}/edge-${VERSION}.pkg"
CHECKSUM_PATH="${DIST_DIR}/edge-${VERSION}.sha256"

export VERSION BUILD_NUMBER CODESIGN_IDENTITY

"${SCRIPT_DIR}/build-app.sh"
"${SCRIPT_DIR}/package-dmg.sh" "${DMG_PATH}"
"${SCRIPT_DIR}/package-pkg.sh" "${PKG_PATH}"

shasum -a 256 "${DMG_PATH}" "${PKG_PATH}" > "${CHECKSUM_PATH}"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    if [[ "${CODESIGN_IDENTITY}" == "-" ]]; then
        print -u2 "NOTARY_PROFILE requires a Developer ID CODESIGN_IDENTITY"
        exit 1
    fi

    xcrun notarytool submit "${DMG_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait
    xcrun stapler staple "${DMG_PATH}"
    xcrun notarytool submit "${PKG_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait
    xcrun stapler staple "${PKG_PATH}"
fi

print "Release artifacts:"
print "  ${DMG_PATH}"
print "  ${PKG_PATH}"
print "  ${CHECKSUM_PATH}"
