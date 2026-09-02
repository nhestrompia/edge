#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
DIST_DIR="${PROJECT_DIR}/dist"
INFO_PLIST="${PROJECT_DIR}/AppResources/Info.plist"
VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST}")}"
BUILD_NUMBER="${BUILD_NUMBER:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${INFO_PLIST}")}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
PKG_SIGNING_IDENTITY="${PKG_SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
NOTARY_KEYCHAIN="${NOTARY_KEYCHAIN:-}"
REQUIRE_SIGNING="${REQUIRE_SIGNING:-0}"
RELEASE_DMG_ONLY="${RELEASE_DMG_ONLY:-0}"
DMG_PATH="${DIST_DIR}/edge-${VERSION}.dmg"
PKG_PATH="${DIST_DIR}/edge-${VERSION}.pkg"
CHECKSUM_PATH="${DIST_DIR}/edge-${VERSION}.sha256"

if [[ "${REQUIRE_SIGNING}" == "1" ]]; then
    if [[ "${CODESIGN_IDENTITY}" != "Developer ID Application:"* ]]; then
        print -u2 "REQUIRE_SIGNING needs a Developer ID Application CODESIGN_IDENTITY"
        exit 1
    fi
    if [[ "${RELEASE_DMG_ONLY}" != "1" && "${PKG_SIGNING_IDENTITY}" != "Developer ID Installer:"* ]]; then
        print -u2 "REQUIRE_SIGNING needs a Developer ID Installer PKG_SIGNING_IDENTITY"
        exit 1
    fi
    if [[ -z "${NOTARY_PROFILE}" ]]; then
        print -u2 "REQUIRE_SIGNING needs a NOTARY_PROFILE"
        exit 1
    fi
fi

export VERSION BUILD_NUMBER CODESIGN_IDENTITY PKG_SIGNING_IDENTITY

"${SCRIPT_DIR}/build-app.sh"
"${SCRIPT_DIR}/package-dmg.sh" "${DMG_PATH}"
if [[ "${RELEASE_DMG_ONLY}" != "1" ]]; then
    "${SCRIPT_DIR}/package-pkg.sh" "${PKG_PATH}"
fi

if [[ -n "${NOTARY_PROFILE}" ]]; then
    if [[ "${CODESIGN_IDENTITY}" == "-" ]]; then
        print -u2 "NOTARY_PROFILE requires a Developer ID CODESIGN_IDENTITY"
        exit 1
    fi

    typeset -a NOTARY_ARGS
    NOTARY_ARGS=(--keychain-profile "${NOTARY_PROFILE}")
    if [[ -n "${NOTARY_KEYCHAIN}" ]]; then
        NOTARY_ARGS+=(--keychain "${NOTARY_KEYCHAIN}")
    fi

    xcrun notarytool submit "${DMG_PATH}" "${NOTARY_ARGS[@]}" --wait
    xcrun stapler staple "${DMG_PATH}"
    xcrun stapler validate "${DMG_PATH}"
    if [[ "${RELEASE_DMG_ONLY}" != "1" ]]; then
        xcrun notarytool submit "${PKG_PATH}" "${NOTARY_ARGS[@]}" --wait
        xcrun stapler staple "${PKG_PATH}"
        xcrun stapler validate "${PKG_PATH}"
    fi
fi

if [[ "${RELEASE_DMG_ONLY}" == "1" ]]; then
    (
        cd "${DIST_DIR}"
        shasum -a 256 "${DMG_PATH:t}"
    ) > "${CHECKSUM_PATH}"
else
    (
        cd "${DIST_DIR}"
        shasum -a 256 "${DMG_PATH:t}" "${PKG_PATH:t}"
    ) > "${CHECKSUM_PATH}"
fi

print "Release artifacts:"
print "  ${DMG_PATH}"
if [[ "${RELEASE_DMG_ONLY}" != "1" ]]; then
    print "  ${PKG_PATH}"
fi
print "  ${CHECKSUM_PATH}"
