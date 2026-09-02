# edge for macOS

A read-only macOS edge utility for monitoring open Hyperliquid perpetual positions plus live BTC, ETH, and SOL spot prices. It uses a public wallet address only—no wallet connection, signature, private key, or trading API key.

## Requirements

- macOS 14 or later
- Xcode 16 or later with the Swift toolchain installed

## Run from source

```sh
swift run
```

For a local interface demo with sample positions:

```sh
HYPERLIQUID_DEMO=1 swift run
```

To exercise rapid notch, rail, inspector, asset, and expanded-panel resizing with the five-position regression fixture:

```sh
HYPERLIQUID_DEMO=1 EDGE_LAYOUT_STRESS=1 swift run
```

## Build the app bundle

```sh
Scripts/build-app.sh
open "dist/edge.app"
```

The bundle is created at `dist/edge.app`, includes the generated `edge.icns` icon and native `Assets.car` catalog, and is ad-hoc signed for local use. `VERSION`, `BUILD_NUMBER`, and `CODESIGN_IDENTITY` can be provided as environment variables.

## Package a macOS installer

Create both a drag-to-Applications disk image and a standard package installer:

```sh
Scripts/release.sh
open "dist/edge-0.1.0.dmg"
```

The release artifacts are written to `dist/`:

- `edge-<version>.dmg` — drag `edge.app` to Applications.
- `edge-<version>.pkg` — installs `edge.app` into `/Applications`.
- `edge-<version>.sha256` — checksums for both installers.

For signed distribution, set a Developer ID application identity and an optional package identity:

```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
PKG_SIGNING_IDENTITY="Developer ID Installer: Your Name (TEAMID)" \
NOTARY_PROFILE="notarytool-profile" \
VERSION=1.0.0 BUILD_NUMBER=1 \
Scripts/release.sh
```

`Scripts/make-app-icon.sh`, `Scripts/package-dmg.sh`, and `Scripts/package-pkg.sh` are also callable independently.

## Data flow

- `POST https://api.hyperliquid.xyz/info` with `clearinghouseState` reconciles open positions.
- `wss://api.hyperliquid.xyz/ws` streams `allMids` and `clearinghouseState` updates.
- `GET https://data-api.binance.vision/api/v3/ticker/24hr` seeds the BTC/USDT, ETH/USDT, and SOL/USDT market view.
- `wss://data-stream.binance.vision` streams one-second mini-ticker updates for those three public markets.
- BTC, ETH, and SOL use exact CoinGecko asset image URLs; other Hyperliquid symbols use official marks from `https://app.hyperliquid.xyz/coins/{symbol}.svg`. Asset marks render from those image URLs, with a neutral first-letter mark only while an image is loading or unavailable. Neither the Binance ticker payload nor the Hyperliquid position payload includes an icon URL.
- The UI consumes stable `Position` and `MarketQuote` models rather than exchange response types.
