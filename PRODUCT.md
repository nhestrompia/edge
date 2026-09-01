# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

<!-- The shipped surface is native macOS SwiftUI/AppKit; adaptive is the closest supported platform value in this artifact schema. -->

## Stack

SwiftUI with AppKit integration, confirmed by the user. SwiftUI owns the UI and state; AppKit owns the floating panel, screen-edge placement, utility-window behavior, and other macOS-specific integration.

## Users

Active Hyperliquid perpetual traders who keep positions open while using a Mac for work, coding, Discord, or other tasks. Their job is to monitor risk and PnL without repeatedly switching to a browser or trading terminal.

## Product Purpose

Keep a trader's Hyperliquid positions and the core BTC, ETH, and SOL market prices continuously glanceable at the edge of the Mac. Success means setup takes only a public wallet address, live market changes remain visible without interrupting work, and the product is useful without any trading permissions.

## Positioning

edge is an ambient native macOS market instrument: it collapses to a quiet screen-edge notch and reveals either Hyperliquid position context or a focused Binance market view in place. It is not a portfolio dashboard or a trading client.

## Operating Context

The app remains running throughout the day while the user works in other applications. It defaults to the right-center of the primary display, can float above normal windows, and remains active after settings windows close. Users move between an idle notch, a compact position rail, per-position hover details, and an expanded all-positions view.

## Capabilities and Constraints

- v0 is strictly read-only and accepts one public Ethereum wallet address.
- It retrieves public Hyperliquid perpetual account state, normalizes open positions, updates prices and PnL, reconciles account changes periodically, and opens relevant Hyperliquid pages in the default browser.
- It retrieves public Binance spot market data for BTC/USDT, ETH/USDT, and SOL/USDT through an initial REST snapshot plus live WebSocket mini-ticker updates. It never requests a Binance account or API key.
- Users can switch the rail and expanded sidebar between Positions and Market views without moving or reopening the utility.
- The sidebar displays asset and live PnL. Hovering reveals PnL percentage, position size, entry price, mark price, liquidation price, leverage, and liquidation distance.
- The utility supports launch at login, always-on-top behavior, screen-edge placement, vertical dragging, bounded scrolling, empty and stale states, and smooth transitions between hovered assets.
- v0 excludes trading, signing, private keys, API keys, deposits, withdrawals, charts, portfolio analytics, user spot holdings, vaults, copy trading, and multi-exchange account aggregation.
- Privacy mode and customization are planned follow-on work; the architecture should not make them costly to add.
- Low idle CPU, minimal memory, efficient network updates, and no continuous decorative animation are hard requirements.

## Brand Commitments

- Product name: edge.
- Core proposition: “Your Hyperliquid positions, always in sight.”
- Trust message: read-only, no wallet connection, no private keys.
- The supplied visual reference is binding for the initial interaction language: a dark graphite utility surface, mint positive states, red negative/risk states, an idle edge notch, a compact asset rail, a left-opening hover card, and an expanded overview.

## Evidence on Hand

- Detailed product requirements supplied in the conversation.
- Visual reference: `/Users/nhestrompia/.t3/userdata/attachments/6f98a374-4554-46bb-bb72-a7c37e5d685f-11a2a2ea-36eb-4c6f-ad8d-22473437cc6f.png`.
- No production logo, customer claims, benchmarks, pricing, or distribution assets are available and none should be fabricated.

## Product Principles

1. Glanceability before density: the resting state reveals only what matters now.
2. Reveal detail in place: monitoring should not become another context switch.
3. Read-only by construction: never request secrets, signatures, or trading authority.
4. Quiet until important: market movement updates the data, not the visual noise.
5. Preserve context through failure: stale positions stay visible while connectivity recovers.

## Accessibility & Inclusion

Color is never the only carrier of PnL, direction, connection, or liquidation state. Controls use native semantics, keyboard access, sufficient contrast, and reduced-motion behavior. Financial numbers use tabular alignment for stable scanning.
