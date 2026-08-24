# Engineering Handoff Document: Reefora Care Loop & Rendering

**Author:** Reno & Antigravity  
**Recipient:** Bishal  
**Date:** August 24, 2026  
**Current Polish Branch:** `feat/reno/TASK-MVP-polish-and-cleanup`  
**Pull Request:** [PR #22](https://github.com/Renoceros/marinesandbox/pull/22) (`feat/reno/TASK-MVP-302-care-loop-integration` $\rightarrow$ `main`)  
**Platform / Target:** iOS 26.5, Xcode 26.6, Swift 6.0 Strict Concurrency  

---

## 1. Executive Summary

Over the recent sprint, we completed the core interactive gameplay and care loop, integrated the official `dotlottie-ios` (ThorVG engine) runtime for DotLottie 2.0 vector animations with theme slots, implemented off-screen crawling snail pests with tactile smush/flick feedback, pull-to-pop sponge cleaning tools, cold-open rubble mechanics, simulation speed controls, ambient/tactile SFX and haptics, geometric seabed hitbox gating, and fully refactored `SandboxViewModel` and `SandboxView` into modular sub-300-line components.

This document outlines everything built, how the systems interact, the bug fixes resolved, and the verified gameplay/progression dynamics in Reefora.

---

## 2. Issues & Backlog Resolution (All Complete ✅)

### ✅ Issue 1: Bottom-Anchored Upward Growth
- **Resolved:** Locked bottom-center alignment (`ZStack(alignment: .bottom)` and `.frame(..., alignment: .bottom)`) in `marinesandbox/Views/Canvas/SandboxView.swift`. Corals expand upward and outward into open water as they grow from baby to adult, remaining strictly grounded to `baseY = seabedY - yPos`.

### ✅ Issue 2: Dynamic Seabed Hitbox Growth Gating (No Hardcoded Y-Thresholds)
- **Resolved:** Replaced static coordinate checks (e.g. `yPos < 60.0`) with `isPlanted: Bool` model state and `CoralGeometry.isCoralInSeabedHitbox(coral:seabedSurfaceHeight:)` in `marinesandbox/Domain/CoralGeometry.swift` and `marinesandbox/Domain/EcoEngine.swift`. Unplanted floating fragments drifting in open water (`yPos: 380.0`) freeze at $0.0$ growth with zero algae accrual until firmly planted into the seabed sand profile.

### ✅ Issue 3: Coral Reward Progression & Species Gating
- **Resolved:** In `marinesandbox/ViewModels/SandboxViewModel+Simulation.swift` (`checkTeenageSpawns`), rewards default to Staghorn Coral only in early gameplay. Once the player cultivates $\ge 5$ living Staghorn corals, `BrainCoral` unlocks and joins the spawn rotation.

### ✅ Issue 4: Coral Crowding & Overgrowth / Smothering Dynamics
- **Resolved:** In `marinesandbox/Domain/EcoEngine.swift`, added spatial crowding analysis between seabed corals ($< 80\,\text{pt}$ distance). Overcrowded corals suffer reduced growth rates (down to $0.4\times$) and increased algae accrual ($+40\%$), rewarding players for spacing out corals along the seabed.

### ✅ Issue 5: Audio SFX Sync & Touchdown Timing
- **Resolved:** In `marinesandbox/ViewModels/SandboxViewModel+CareLoop.swift`, `brush_swipe.wav` triggers directly whenever swiping across any coral with the sponge, and `sparkle_clean.wav` plays upon reaching $\le 2\%$ algae. Planting touchdown audio (`frag_plant.wav`) triggers immediately ($0.01\text{s} - 0.08\text{s}$) upon ground impact.

### ✅ Issue 6: Deterministic `colorTheme` Data Model & Vector Synchronization
- **Resolved:** Added explicit `colorTheme: String` property onto `CoralFrag` (`@Model`) and `CoralState` (`default` Blue, `pink`, `purple`, `yellow`), completely eliminating runtime UUID-hashing guesswork and asynchronous ThorVG color swaps. Synchronized 4-slot theme definitions (`highlight`, `shadow`, `base`, `splotches`) across all DotLottie vector assets (`staghorn_coral_lh.lottie`, `staghorn_coral_rh.lottie`, `brain_coral.lottie`).

### ✅ Issue 7: Snail Interaction, Touch Boundaries, & Haptic Feedback
- **Resolved:** Attached `.highPriorityGesture` for both `TapGesture` (smush) and `DragGesture` (flick) on `PestOverlayView` and `CrawlingSnailView` with enlarged $52\times52\,\text{pt}$ hit areas, preventing coral drag gestures from swallowing snail taps. Created `@MainActor` `HapticService.swift` providing UIKit tactile feedback (`UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`, `UISelectionFeedbackGenerator`).

---

## 3. What Has Been Implemented & Working

### 🪸 A. Multi-Species DotLottie 2.0 Runtime (`DEC-037`, `DEC-040`, `DEC-042`)
- **Runtime:** Official `dotlottie-ios` (ThorVG engine) for native support of DotLottie 2.0 track mattes, theme slots, and continuous frame scrubbing.
- **Species Implemented:**
  1. **Brain Coral (`marinesandbox/Resources/Lottie/brain_coral.lottie`):**
     - Total duration: $20.0\text{s}$ ($600$ frames at $30\text{ FPS}$, `0 ... 599`).
     - Real-world ecology rate: $10\times$ slower calcification rate (`speciesGrowthRateMultiplier = 0.10`).
     - Quarter stages: Baby (`0`), Toddler (`150`), Teenager (`300`), Adult (`450`), Mature Adult (`599`).
     - Dome footprint: $88\times 88\text{ pt}$ (Baby) $\rightarrow$ $215\times 215\text{ pt}$ (Adult).
  2. **Staghorn Coral (`marinesandbox/Resources/Lottie/staghorn_coral_lh.lottie` / `staghorn_coral_rh.lottie`):**
     - Total duration: $2.0\text{s}$ ($60$ frames at $30\text{ FPS}$, `0 ... 59`).
     - Growth rate: $1.0\times$ baseline.
     - Quarter stages: Baby (`0`), Toddler (`15`), Teenager (`30`), Adult (`45`), Mature Adult (`59`).
     - Branching footprint: $88\times 132\text{ pt}$ (Baby) $\rightarrow$ $195\times 245\text{ pt}$ (Adult).
- **Deterministic Color Theming (`DEC-042`):**
  - Stored permanently in SwiftData via `CoralFrag.colorTheme`.
  - Cold open survivor and standard Staghorns default to `"default"` (Blue).
  - Applied synchronously into `AnimationConfig(themeId:)` on `LottieCoralView.swift` without color-jumping.

---

### 🧤 B. On-Canvas Care Loop & Gestures (`DEC-012`, `DEC-034`, `DEC-042`)
- **Sponge Bubble Tool (`marinesandbox/Views/Canvas/SandboxToolOverlayView.swift`):**
  - Top-leading iridescent aqua bubble encapsulating the sponge tool.
  - Pulling the sponge pops the bubble with particle ring & splash SFX (`pest_splash.wav`).
  - Swiping across corals clears algae cells along the drag path (`applyBrushSegment` in `marinesandbox/ViewModels/SandboxViewModel+CareLoop.swift`) with `brush_swipe.wav`.
  - On release, smoothly springs back to the top-leading anchor (`(48, 88)`), and the bubble re-encapsulates the sponge with `sparkle_clean.wav`.
- **Crawling Snail Waves (`marinesandbox/Views/Canvas/SandboxPestView.swift`):**
  - `DrupellaSnail` enemies spawn at off-screen margins and crawl along the sand band toward vulnerable young corals over 7 seconds (`marinesandbox/Domain/CrawlingSnail.swift`).
  - **Tap-to-Smush:** High-priority tap with vertical height squash animation (`scaleEffect(y: 0.2)`), `pest_smush.wav`, and medium tactile impact haptics.
  - **Flick-to-Throw:** High-priority drag with ballistic throw arc off-screen, `pest_flick.wav`, and rigid tactile impact haptics.
  - **Spawn Gating:** Only corals that are firmly planted and $\ge 20\%$ grown are targeted by pests, protecting fresh sprouts.
  - **Non-Lethal Tuning (`DEC-033`):** Snails slow down coral growth via tissue damage modifiers without causing sudden death.
- **Toddler Stage Rooting:**
  - Corals can be repositioned during the Fragment/Baby stage (`growthProgress < 0.25`).
  - Once reaching the **Toddler stage** (`growthProgress >= 0.25`), dragging is disabled and the coral is permanently rooted in place ("where they land is where they grow").
- **Teenage Milestone Spawn Rewards:**
  - When any coral matures to **Teenager** (`growthProgress >= 0.75`), a new living fragment drifts down in open water (`yPos: 380.0`) with a cyan beacon halo for the player to drag and plant.

---

### 🪨 C. Cold-Open Rubble Mechanics (`DEC-009`)
- **Rubble Pile (`marinesandbox/Views/Canvas/RubblePileOverlayView.swift`):**
  - Scaled to $2\times$ scale ($72\times 108\text{ pt}$) shifted left/up on the sand band (`xPos: 120, yPos: 35`).
  - Pulsing highlight glow (`phaseAnimator` with soft white/cyan shadow) on dead rubble pieces.
  - Player flicks away dead rubble pieces to reveal the living survivor fragment.
  - Clear state prompts guided drag-to-plant with pulsing seabed target zone.

---

### ⏩ D. Simulation Speed Controls & Exhibition Mode (`DEC-031`)
- **Top-Trailing HUD (`marinesandbox/Views/Canvas/SandboxToolOverlayView.swift`):**
  - **10x Fast Forward Button:** 30-second countdown boost advancing growth by $\approx 1$ full stage in 30s.
  - **100x Hold Button:** Turbo debug button (hold to speed up, release to return to 1x).
  - **Reset Button:** Quickly restarts the cold-open rubble state for testing.
- **5-Year Reflection Card (`marinesandbox/Views/Modals/DiagnosticCardView.swift`):**
  - Kolb experiential learning diagnostic modal shown after 5-year Fast Forward jumps.

---

### 🎵 E. Audio & Haptics Services (`DEC-035`, `DEC-042`)
- **Audio (`marinesandbox/Services/AudioPlayerService.swift`):** Manages ambient ocean loop (`ambient_ocean_loop.wav`) and interaction SFX (`frag_lift`, `frag_plant`, `sparkle_clean`, `pest_smush`, `pest_flick`, `pest_splash`, `brush_swipe`, `tool_switch`, `threat_warning`).
- **Haptics (`marinesandbox/Services/HapticService.swift`):** Manages tactile feedback for snail smush (`.medium`), snail flick (`.rigid`), coral planting (`.success`), and tool switching (`.selectionChanged`).

---

### 🏗 F. Modular Architecture (<300 LOC/file) (`DEC-039`)
- **`marinesandbox/ViewModels/`**:
  - `SandboxViewModel.swift` (250 lines): Core state, SwiftData persistence, `ReefState` snapshot adapter.
  - `SandboxViewModel+Planting.swift` (205 lines): Cold-open, rubble flicking, frag dragging & settling.
  - `SandboxViewModel+CareLoop.swift` (155 lines): Snail wave spawning, algae brush clearing, hit routing, haptics.
  - `SandboxViewModel+Simulation.swift` (160 lines): Clock ticks, 10x/100x speed multipliers, teenage rewards, diagnostics.
- **`marinesandbox/Views/Canvas/` & `Views/Modals/`**:
  - `SandboxView.swift` (295 lines): Entity layer, parallax viewport, gesture routing.
  - `SandboxToolOverlayView.swift` (240 lines): Sponge bubble tool, speed controls HUD.
  - `SandboxPestView.swift` (135 lines): On-coral pest overlay, crawling snails, tooltips.
  - `RubblePileOverlayView.swift` (90 lines): Cold open rubble pile, instruction pill, guide pulse.
  - `DiagnosticCardView.swift` (31 lines): 5-Year reflection card modal.

---

## 4. What Has NOT Been Implemented Yet (Future Roadmap)

| Feature | Notes / Current State |
| :--- | :--- |
| **Additional Coral DotLotties** | Elkhorn, Sponge, Table corals are defined in `CoralSpecies` and catalog, but currently use SVG placeholders or staghorn animations until designers supply their `.lottie` files. |
| **Shannon Index Recruited Fauna Silhouettes** | Domain math computes `herbivoreRecruitment` and `predatorRecruitment` from $H$, but background/midground swimming fish silhouettes have not yet been rendered in `ParallaxScrollView`. |
| **CloudKit Sync & Sign-In (`DEBT-002`)** | SwiftData persistence is currently local-only. Post-exhibition cloud sync is scheduled for future milestones. |
| **Thermal Bleaching (`DEC-025`)** | The `EcoEngine` heat-stress calculation is complete, but dormant for the Bali exhibition build (`waterTemperature <= 30°C`). |
| **ShareCardView (9:16 Export)** | The 9:16 social share snapshot card stub remains to be implemented (`marinesandbox/Views/Modals/ShareCardView.swift`). |

---

## 5. Architectural Checklist for Incoming Changes

1. **Swift 6 Concurrency:** Never reference `@MainActor` static properties from nonisolated contexts; use `nonisolated static let` / `nonisolated static func` (`DEC-038`).
2. **File-System Synchronized Groups:** Any `.swift` file added on disk automatically joins the target. **Never edit `project.pbxproj` directly** to avoid merge conflicts (`DEC-022`).
3. **File Size Limits:** Keep all newly created or refactored files under **300–400 lines of code** (`DEC-039`).
4. **Hit Testing:** Always hit-test against model geometry via `CoralGeometry`, never visual artwork bounds (`DEC-019`).
5. **Always Push Every Commit:** Ensure every commit is proactively pushed to origin.
