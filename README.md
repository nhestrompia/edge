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
chmod +x Scripts/build-app.sh
Scripts/build-app.sh
open "dist/edge.app"
```

The bundle is created at `dist/edge.app` and ad-hoc signed for local use. A Developer ID signature and notarization are still required for distribution outside the Mac that built it.

## Data flow

- `POST https://api.hyperliquid.xyz/info` with `clearinghouseState` reconciles open positions.
- `wss://api.hyperliquid.xyz/ws` streams `allMids` and `clearinghouseState` updates.
- `GET https://data-api.binance.vision/api/v3/ticker/24hr` seeds the BTC/USDT, ETH/USDT, and SOL/USDT market view.
- `wss://data-stream.binance.vision` streams one-second mini-ticker updates for those three public markets.
- BTC, ETH, and SOL use exact CoinGecko asset image URLs; other Hyperliquid symbols use official marks from `https://app.hyperliquid.xyz/coins/{symbol}.svg`. Asset marks render from those image URLs, with a neutral first-letter mark only while an image is loading or unavailable. Neither the Binance ticker payload nor the Hyperliquid position payload includes an icon URL.
- The UI consumes stable `Position` and `MarketQuote` models rather than exchange response types.
