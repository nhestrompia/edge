# Hyperliquid Positions for macOS

A read-only macOS edge utility for monitoring open Hyperliquid perpetual positions. It uses a public wallet address only—no wallet connection, signature, private key, or trading API key.

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

## Build the app bundle

```sh
chmod +x Scripts/build-app.sh
Scripts/build-app.sh
open "dist/Hyperliquid Positions.app"
```

The bundle is created at `dist/Hyperliquid Positions.app` and ad-hoc signed for local use. A Developer ID signature and notarization are still required for distribution outside the Mac that built it.

## Data flow

- `POST https://api.hyperliquid.xyz/info` with `clearinghouseState` reconciles open positions.
- `wss://api.hyperliquid.xyz/ws` streams `allMids` and `clearinghouseState` updates.
- The UI consumes the normalized `Position` model and does not depend on Hyperliquid response types.
