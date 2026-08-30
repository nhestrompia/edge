---
version: 1
slug: "s-hyperliquidpositions-views-sidebarrootview-swift"
primary_target: "Sources/HyperliquidPositions/Views/SidebarRootView.swift"
related_targets: ["Sources/HyperliquidPositions/Views/RailView.swift","Sources/HyperliquidPositions/Views/HoverCardView.swift","Sources/HyperliquidPositions/Views/ExpandedSidebarView.swift","Sources/HyperliquidPositions/Views/NotchView.swift"]
---

# Edge Sidebar

## Scope and mode

Native macOS operating surface covering the idle notch, compact position rail, per-asset hover inspector, and expanded all-position overview. Visitor mode: Operate.

## Audience and job

Active Hyperliquid perpetual traders need to monitor open risk while working elsewhere. They should read direction and PnL at a glance, reveal exact position context without changing apps, and expand only when comparing the account as a whole.

## Task and content

The surface presents live normalized positions, connection freshness, PnL, leverage, size, entry, mark, liquidation price, and liquidation distance. It opens the corresponding Hyperliquid market but never performs trading or requests authority.

## Chosen direction

The supplied edge-cockpit mockup is the visual authority: graphite instrument surfaces, mint live/profit treatment, red loss/risk treatment, tabular figures, restrained borders, and progressive disclosure from notch to rail to inspector to overview.

## Memorable moment

Moving the pointer between asset marks causes one anchored inspector to fluidly replace its contents, preserving place while the market context changes.

## Constraints

Remain native, low-noise, low-overhead, keyboard accessible, readable without color alone, and usable across Spaces and full-screen apps. Temporary connection failures keep the last positions visible.

## Unresolved decisions

Production app icon/signing identity and automatic screen-sharing privacy detection are intentionally deferred.
