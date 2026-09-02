# edge

edge is a native macOS utility that keeps your open Hyperliquid perpetual positions visible at the edge of your screen. It also shows live BTC, ETH, and SOL spot prices.

Add a public Ethereum wallet address to start. edge is read-only. It never asks for a wallet connection, private key, signature, or trading API key.

## Install

1. Open the [latest release](https://github.com/nhestrompia/edge/releases).
2. Download `edge-<version>.dmg`.
3. Open the disk image and drag `edge.app` to Applications.
4. Open edge and paste your public Hyperliquid wallet address.

The `v0.1.1` release predates the signing setup and may show a Gatekeeper warning. Future releases are configured to publish only after Developer ID signing and Apple notarization are set up.

edge requires macOS 14 or later and runs on Apple silicon and Intel Macs.

## What edge shows

- Open Hyperliquid positions with live mark prices, PnL, leverage, and liquidation distance.
- BTC, ETH, and SOL prices with 24-hour change and daily range.
- A compact edge rail, hover details, and an expanded account view.
- Settings for auto-hide, position display, screen edge, always-on-top, and launch at login.

## Build from source

You need Xcode 16 or later.

```sh
swift test
swift run
```

Run the local demo without a wallet or network data:

```sh
HYPERLIQUID_DEMO=1 swift run
```

Build a universal app and DMG:

```sh
VERSION=0.1.0 BUILD_NUMBER=1 RELEASE_DMG_ONLY=1 Scripts/release.sh
```

The command writes `edge-<version>.dmg` and `edge-<version>.sha256` to `dist/`. Set `CODESIGN_IDENTITY` and `NOTARY_PROFILE` for signed and notarized distribution. The optional PKG installer remains available through `Scripts/package-pkg.sh`.

GitHub release signing is configured in [docs/releasing.md](docs/releasing.md). The workflow refuses to publish an ad-hoc build.

## Publish a release

Push a version tag to run the GitHub release workflow:

```sh
git tag v0.1.0
git push origin v0.1.0
```

GitHub Actions runs the tests, builds a universal DMG, and attaches the DMG and checksum file to the release. You can also run the workflow manually with a version number.

## Data and privacy

edge sends the public address you enter to Hyperliquid's public API. It reads public market data from Binance and loads asset marks from public image URLs. It does not handle private keys, signing, trades, deposits, or withdrawals.
