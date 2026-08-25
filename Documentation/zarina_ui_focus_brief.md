# Task Assignment & Handoff Brief: Zarina (UI & Visual Experience)

**Assignee:** Zarina  
**Coordinator:** Reno  
**Date:** August 24, 2026  
**Current Branch:** `feat/reno/TASK-MVP-polish-and-cleanup`  
**Base Pull Request:** [PR #22](https://github.com/Renoceros/marinesandbox/pull/22)  

---

## 📂 100% Owned File Boundaries (Zero Overlap with Bishal)

| Owned File | Responsibility |
| :--- | :--- |
| `marinesandbox/Views/Canvas/ParallaxScrollView.swift` | Parallax layer scaling, letterbox fixes, and midground swimming fauna silhouettes |
| `marinesandbox/Views/Canvas/RubblePileOverlayView.swift` | Cold-open guidance text, instruction pills, and pulsing seabed target zone |
| `marinesandbox/Views/Canvas/SandboxToolOverlayView.swift` | Sponge bubble shader/gradient, pop particle burst, and speed controls HUD |
| `marinesandbox/Views/Canvas/PestTooltipView.swift` | Snail warning tooltip layout, glass bubble styling, and dismiss animations |
| `marinesandbox/Views/Modals/ShareCardView.swift` | 9:16 social share snapshot card & `UIActivityViewController` presentation |
| `marinesandbox/DesignSystem/Color+Hex.swift` | Shared design-system color extension |
| `marinesandbox/Views/Onboarding/` | First-launch dead reef visual transition and typography |

---

## 🎯 Specific Tasks & Deliverables

### 1. 🫧 Lower UI Text Placement & Glass Bubble Styling
> *"in general should bring down lower — not sure if itll kill readability but i js had a thought can change to glass ui so it looks like a bubble…?"*

- **Lower Vertical Placement:** Move on-canvas guidance text and instruction pills (`ColdOpenInstructionView`, `PestTooltipView`) down into the upper-mid water column (e.g. `padding(.top, 108)` instead of `56`) so they don't block the top HUD bar and sponge bubble tool.
- **Glass Bubble Aesthetic:** Style text pills and cards with a soft frosted glass bubble aesthetic:
  - Background material: `.ultraThinMaterial` / `.thinMaterial` inside rounded capsules or bubble shapes.
  - Bubble stroke: Soft translucent white/cyan border (`Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1.2)`).
  - Subtle drop shadow and specular highlight to feel like buoyant underwater bubbles.

### 2. 🐌 Snail Warning Tooltip Behavior
> *"also the snail eating text i think should only appear first time, and text doesn't disappear on its own"*

- **Show Only Once:** Ensure the pest eating tooltip (`PestTooltipView`: *"A snail is eating your coral! Tap it to smush it, or flick it away."*) only displays on the player's **first-ever pest encounter** (`hasSeenPestTooltip = true`), rather than popping up every time a snail crawls in.
- **Auto-Dismiss & Tap-Dismiss:** The tooltip should dismiss immediately when tapped or when a snail is killed, and should automatically fade out after ~6 seconds so it never gets stuck permanently on the canvas.

### 3. 🖼️ Parallax Scaling & Recruited Fauna (`Views/Canvas/ParallaxScrollView.swift`)
- **Full-Bleed Layer Scaling:** Ensure Background, Midground, and Foreground layers fill their segments cleanly without letterboxing across iPhone 17 and iPad aspect ratios.
- **Extract Shared Helpers:** Move `Color(hex:)` out of `ParallaxScrollView.swift` into `DesignSystem/Color+Hex.swift` to prevent symbol collisions.
- **Midground Recruited Fauna:** Render swimming fish silhouettes in the midground parallax layer driven by `EcoEngine.shannonIndex` and herbivore recruitment counts.

### 4. 📱 9:16 Share Card (`Views/Modals/ShareCardView.swift`)
- Implement the 9:16 aspect ratio social share card with snapshot render of the user's canvas, biodiversity stats, reef health percentage, and native iOS share sheet integration (`UIActivityViewController`).

---

## 🛠️ View Contracts & Architecture Rules
- Bind views against `@Bindable var viewModel: SandboxViewModel`.
- Always hit-test against model footprints (`CoralGeometry.footprint`), never raw artwork boundaries (`DEC-019`).
- Maintain modular file limits (< 300 LOC per view file) (`DEC-039`).
- Zero domain/engine business logic inside SwiftUI views.
