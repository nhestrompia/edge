---
name: Hyperliquid Positions
description: A quiet native edge instrument for ambient Hyperliquid position monitoring.
colors:
  graphite-canvas: "#060a0a"
  graphite-surface: "#0b100f"
  graphite-raised: "#121716"
  graphite-pressed: "#1b1f1e"
  instrument-rule: "rgba(255, 255, 255, 0.13)"
  instrument-rule-strong: "rgba(255, 255, 255, 0.25)"
  text-primary: "#f4f9f6"
  text-secondary: "#a8b8b3"
  live-mint: "#1fe09e"
  live-mint-muted: "#0d4d38"
  risk-red: "#ff474f"
  risk-red-muted: "#571417"
  warning-amber: "#ffad33"
typography:
  headline:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "27px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.02em"
  title:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "normal"
  body:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.35
    letterSpacing: "normal"
  label:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "normal"
rounded:
  control: "9px"
  field: "12px"
  card: "14px"
  inspector: "18px"
  panel: "24px"
  rail: "32px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "22px"
  xxl: "28px"
components:
  panel:
    backgroundColor: "{colors.graphite-canvas}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.panel}"
    padding: "16px"
  position-card:
    backgroundColor: "{colors.graphite-surface}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.card}"
    padding: "13px"
  button-primary:
    backgroundColor: "{colors.live-mint}"
    textColor: "{colors.graphite-canvas}"
    rounded: "{rounded.field}"
    padding: "14px 16px"
  side-badge-long:
    backgroundColor: "{colors.live-mint-muted}"
    textColor: "{colors.live-mint}"
    rounded: "{rounded.pill}"
    padding: "4px 8px"
  side-badge-short:
    backgroundColor: "{colors.risk-red-muted}"
    textColor: "{colors.risk-red}"
    rounded: "{rounded.pill}"
    padding: "4px 8px"
---

# Design System: Hyperliquid Positions

## Overview

**Creative North Star: "The Quiet Edge Instrument"**

Hyperliquid Positions behaves like a small instrument mounted at the edge of a trader's workspace. It is precise and continuously available, but it refuses to compete with the work already on screen. Its identity comes from progressive disclosure: a narrow mint signal becomes a position rail, one rail item grows an anchored inspector, and deliberate expansion reveals the full account.

The system is native, dense, and restrained. Graphite layers provide the physical body; mint, red, and amber carry live market meaning; fine rules and stable figures carry structure. Expression belongs in the silhouette and state transitions rather than decorative chrome.

**Key Characteristics:**

- Four-state disclosure: notch, rail, inspector, expanded board.
- Graphite instrument surfaces with one mint live voice.
- Tabular financial figures that do not shift as prices update.
- Authored asset marks and explicit freshness/demo truth.
- Native controls, keyboard paths, and Reduce Motion behavior.

## Colors

The palette is restrained: dark graphite owns almost the entire surface, while market colors are reserved for state and measurement.

### Primary

- **Live Mint** (`#1fe09e`): live connectivity, positive PnL, active position outlines, the primary onboarding action, and the Hyperliquid mark.
- **Deep Mint** (`#0d4d38`): long-direction badges and low-emphasis mint fills.

### Secondary

- **Risk Red** (`#ff474f`): negative PnL, short direction, stale connectivity, and close-liquidation warnings.
- **Warning Amber** (`#ffad33`): intermediate liquidation proximity and synthetic demo disclosure.

### Neutral

- **Graphite Canvas** (`#060a0a`): panel body and the deepest surface.
- **Graphite Surface** (`#0b100f`): cards and grouped financial regions.
- **Graphite Raised** (`#121716`): quiet button and field surfaces.
- **Graphite Pressed** (`#1b1f1e`): hover and pressed feedback.
- **Primary Instrument Text** (`#f4f9f6`): asset names, values, and primary actions.
- **Secondary Instrument Text** (`#a8b8b3`): labels, wallet metadata, and connection copy.
- **Instrument Rules** (`rgba(255,255,255,0.13)` and `rgba(255,255,255,0.25)`): dividers and structural outlines.

**The Semantic Separation Rule.** PnL color and liquidation-risk color are calculated independently; profitability never implies safety.

## Typography

**Display Font:** SF Pro with the native macOS system fallback.
**Body Font:** SF Pro with the native macOS system fallback.
**Label/Mono Font:** SF Pro with monospaced digits or the system monospaced face for wallet addresses.

**Character:** The type system is compact and workmanlike. Hierarchy comes from weight, size, and alignment; financial content uses tabular figures so live changes do not disturb the scan path.

### Hierarchy

- **Headline** (700, 27px, 1.15): onboarding title and the largest single PnL value.
- **Title** (700, 16–18px, 1.2): product, asset, and position names.
- **Summary Value** (700, 18–24px, tabular): account and position outcomes.
- **Body** (400–600, 13–14px, 1.35): explanatory copy, actions, and metric values.
- **Label** (600–700, 8–12px): metric labels, state badges, demo disclosure, and compact status text.

**The Stable Figure Rule.** Every changing financial value uses monospaced or tabular digits and numeric content transitions.

## Layout

The interface is anchored to one screen edge with a consistent 7px overlap. The notch is `30×118`; the compact rail is 112px wide; its height is driven by position count and capped at 630px. The inspector adds 386px toward the desktop while preserving the rail's anchor. The expanded board is 438px wide and caps at 710px or the visible screen height minus 20px.

Spacing follows a compact 4/8/12/16/22/28 rhythm. Metric groups are tight; state changes receive more separation. Position stacks scroll inside the panel rather than growing past the display. Left-edge mode mirrors horizontal growth while preserving the same state geometry.

**The One Edge Rule.** Window size may change, but its chosen screen edge and vertical context do not.

## Elevation & Depth

Depth is structural. Near-black tonal layers separate the panel, grouped summary, cards, fields, and pressed controls. The floating instrument receives one broad, offset black shadow (`0.44` opacity, 20–24px radius, 8–12px vertical offset); inner components generally use a rule instead of another shadow.

### Shadow Vocabulary

- **Floating Panel:** soft black shadow, 20–24px radius, slight left offset, 8–12px downward offset. Used only by the notch, rail, inspector, expanded board, and onboarding shell.
- **Tonal Lift:** `graphite-raised` and `graphite-pressed`. Used for controls inside a panel instead of nested shadow stacks.

**The One Floating Body Rule.** Elevation belongs to the utility against the desktop; content inside it is separated by tone and fine rules.

## Shapes

Corner scale tracks containment. Controls use 9–12px continuous corners, position cards use 14px, the inspector uses 18px plus a directional pointer, full panels use 24–25px, and the compact rail uses a 32px rounded desktop-facing edge with a nearly square screen-facing edge. Direction badges and progress tracks are pills. Asset marks remain circular and use authored internal geometry.

The notch is deliberately asymmetric: its desktop edge is fully rounded while its screen edge disappears beyond the display. Borders remain sub-pixel to 1px instrument rules.

## Components

### Buttons

- **Primary:** mint fill, graphite text, 12px continuous corners, and a 45px target height.
- **Quiet:** raised graphite fill with primary text; pressed or hovered state moves to `graphite-pressed`.
- **Icon:** native SF Symbol, 34px circular target when standalone, always carrying an accessibility label.
- **Focus:** native keyboard semantics; the wallet field adds a 1.5px mint focus rule.

### Chips

- **Long:** deep-mint pill with mint uppercase text.
- **Short:** muted-red pill with red uppercase text.
- **Demo:** amber, small, tracked text. Synthetic data is never presented as live production data without this label.

### Cards / Containers

- **Position Card:** 14px continuous corners, graphite surface at 62–86% opacity, 13px padding, and one fine rule.
- **Summary Region:** 14px corners and a quiet graphite fill; it groups account outcomes without competing with positions.
- **Hover Inspector:** 18px rounded body with a right-facing pointer and one floating-body shadow.

### Inputs / Fields

- **Style:** 12px corners, raised graphite fill, 46px height, monospaced public address text.
- **Focus:** mint 1.5px rule and matching wallet icon treatment.
- **Error:** red icon and recovery-oriented copy below the field; the field does not disappear or reset.

### Navigation

The notch opens on pointer approach. Rail assets are native buttons and Up/Down commands move the active inspector. Escape collapses one level. The rail footer expands the complete board; the expanded footer exposes collapse, connection state, and settings.

### Liquidation Bar

A low pill track measures liquidation distance independently from PnL. Red marks under 12%, amber marks 12–18%, and mint marks safer distances. A numeric label always accompanies color.

### Connection State

Live, Connecting, Reconnecting, and Waiting use a dot plus text wherever panel space permits. Existing positions remain visible during reconnection. The collapsed notch retains a state-colored signal with an accessibility label.

## Do's and Don'ts

### Do:

- **Do** preserve the notch → rail → inspector → expanded disclosure sequence.
- **Do** keep financial values aligned with tabular digits and update only the affected position.
- **Do** pair market colors with signs, labels, direction text, or numeric distance.
- **Do** label stale and synthetic states in words.
- **Do** replace move and scale transitions with opacity or immediate changes when Reduce Motion is enabled.
- **Do** use authored vector geometry for recognizable asset marks.

### Don't:

- **Don't** turn the utility into a general dashboard, chart surface, or trading terminal.
- **Don't** add decorative animation, glow, or shadow to every internal component.
- **Don't** use positive PnL color as a proxy for liquidation safety.
- **Don't** let a state resize detach the utility from its selected screen edge.
- **Don't** expose deferred features such as privacy mode or trading controls in the v0 interface.
- **Don't** replace native control semantics with gesture-only interaction.
