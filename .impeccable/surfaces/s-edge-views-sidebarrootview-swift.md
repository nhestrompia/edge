---
version: 1
slug: "s-edge-views-sidebarrootview-swift"
primary_target: "Sources/Edge/Views/SidebarRootView.swift"
related_targets: ["Sources/Edge/Views/RailView.swift","Sources/Edge/Views/HoverCardView.swift","Sources/Edge/Views/ExpandedSidebarView.swift","Sources/Edge/Views/MarketViews.swift","Sources/Edge/Views/OnboardingView.swift","Sources/Edge/Views/NotchView.swift","Sources/Edge/Window/EdgePanel.swift"]
---

# Edge Sidebar

## Scope and mode

Native macOS operating surface covering the idle notch, compact asset rail, per-asset inspector, and expanded overview. The same anchored geometry switches between Hyperliquid Positions and a Binance-powered BTC, ETH, and SOL Market lens. Visitor mode: Operate.

## Audience and job

Active Hyperliquid perpetual traders need to monitor open risk and core market direction while working elsewhere. They should read PnL or spot movement at a glance, reveal exact context without changing apps, and expand only when comparing the whole account or all three markets.

## Task and content

Positions presents connection freshness, PnL, leverage, size, entry, mark, liquidation price, and liquidation distance. Market presents public Binance spot price, 24-hour change, open, high, low, and position within the daily range. The utility can open a Hyperliquid market but never performs trading or requests wallet or exchange authority.

## Chosen direction

The supplied edge-cockpit and onboarding references are the visual authority: graphite instrument surfaces, mint live/profit treatment, red loss/risk treatment, tabular figures, restrained borders, a tall trust-forward wallet form, and progressive disclosure from notch to rail to inspector to overview.

## Memorable moment

Moving the pointer between asset marks keeps one inspector alive while its content and vertical anchor settle over 460ms. Notch and rail resizing use a slower 480–500ms no-bounce curve, so the utility shifts attention rather than tearing down and rebuilding.

## Constraints

Remain native, low-noise, low-overhead, keyboard accessible, readable without color alone, and usable across Spaces and full-screen apps. The AppKit host must accept its SwiftUI frame so the notch and rail never retain an invisible larger interaction rectangle. Temporary connection failures preserve the last positions and market quotes.

## Unresolved decisions

Production app icon/signing identity and automatic screen-sharing privacy detection are intentionally deferred.
