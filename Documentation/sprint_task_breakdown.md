# 2-Week Sprint Plan & Task Breakdown

This document provides a detailed, day-by-day task breakdown for the 2-week sprint to deliver the **Interactive Marine Sandbox MVP**, aligned with the PRD, TDD, and [User Workflow](user_workflow_marinesandbox.md) specification. All directory paths start at the repository target directory root (`marinesandbox/`).

---

## Team Roles & Specializations

* **Reno (PM-Coder Hybrid):** Focuses on product development, project coordination, and core interactive views.
* **Bishal (Backend & Physics):** Focuses on the math engine, SwiftData models, view models, and simplified 2D physics simulation (dragging and flicking mechanics).
* **Zarina (Parallax View Coder):** Focuses on the multi-layer parallax scroll view (`ParallaxScrollView.swift`), regional preset configurations, and share card generation.
* **Bobo (Mid-Fi Layout Coder):** Focuses on SwiftUI UI layouts (using placeholder assets), Lottie integrations, and recruited fish layers.
* **Sam (Asset Designer):** Focuses on visual design, UX guidelines, mockups, final asset production (SVG/PNG), and share card layouts.

---

## Sprint Calendar Overview

```mermaid
gantt
    title Marine Sandbox MVP 2-Week Sprint
    dateFormat  D
    axisFormat Day %d
    
    section Phase 1
    Core Architecture & Mid-Fi Setup :active, 1, 3
    
    section Phase 2
    SwiftData & Persistence Layer : 4, 6
    
    section Phase 3
    UI Polish, Lottie & Share Cards : 7, 10
    
    section Phase 4
    Integration & Testing : 11, 14
```

---

## Phase 1: Core Architecture & Mid-Fi Setup (Days 1–3)
**Objective:** Set up the main sandbox view architecture, parallax scrolling, and mid-fidelity layout using placeholder assets. (TechDemo is skipped to start work directly on the main MVP views).

### Day 1: Setup & Core Math
* **TASK-MVP-101 (Bishal):** Implement `marinesandbox/Services/EcoEngine.swift` core stateless math:
  * Shannon Index computation: $H = -\sum (p_i \ln p_i)$.
  * Time-step formulas for growth progress (Baby $\rightarrow$ Teenager $\rightarrow$ Adult), algae accumulation, and bleaching triggers.
* **TASK-MVP-102 (Zarina):** Implement the skeleton of `marinesandbox/Views/Canvas/ParallaxScrollView.swift` as a single view stitched from exactly **3 segments** (columns `0, 1, 2`), resulting in a total content width of $4.5\times$ viewport width (1.5x screen width per segment). Viewport offset `scrollX` is strictly clamped in the range `[-3.5 * viewportWidth, 0.0]`. The layers are drawn over a solid color backdrop (#3BAFED) in the order: backdrop -> MG (ratio 0.50, top-pinned) -> BG (ratio 0.20, top-pinned) -> FG (ratio 1.00, bottom-pinned). Inside each segment, layer image variant indices `{0, 1, 2}` are mutually exclusive (permutated per column index) to prevent identical vertical layers (e.g. no `0-0-0` or `1-1-1` stacks). Note and handle asymmetrical state technical debt (`DEBT-001`).

### Day 2: Interactive Canvas & Physics
* **TASK-MVP-103 (Bobo):** Create mid-fidelity canvas layouts (`marinesandbox/Views/Canvas/MockCoralView.swift` and `marinesandbox/Views/Canvas/SandboxView.swift`) using placeholder assets, integrating tool selection overlays.
* **TASK-MVP-104 (Bishal):** Implement the simplified 2D physics simulation (dragging and flicking dynamics) inside `marinesandbox/ViewModels/SandboxViewModel.swift` to support dragging structures/fragments and flicking pests (snails/rubble) off-screen.

### Day 3: Assets Integration & Mid-Fi Milestone
* **TASK-MVP-105 (Sam):** Produce initial placeholder assets and layout visual drafts for the Background, Midground, and Foreground layers.
* **TASK-MVP-106 (Reno):** Integrate basic notifications/alerts for active threats (algae overgrowth or snail pests) onto the mid-fidelity canvas views.
* **Deliverable:** Main sandbox view compiles and runs with 3-layer parallax scrolling, placeholder assets, and basic active care tool selections.

---

## Phase 2: SwiftData & Persistence Integration (Days 4–6)
**Objective:** Replace in-memory states with local SwiftData persistent models and enable basic local saves.

### Day 4: Schema Implementation
* **TASK-MVP-201 (Bishal):** Flesh out SwiftData models inside the `marinesandbox/Models/` directory:
  * [`UserProfile`](file:///Users/moreno_m5/Projects/CH5/marinesandbox/marinesandbox/Models/UserProfile.swift): Local profile, unlocked cosmetics.
  * [`ReefCanvas`](file:///Users/moreno_m5/Projects/CH5/marinesandbox/marinesandbox/Models/ReefCanvas.swift): Horizontal boundaries, NGO region config.
  * [`PlacedStructure`](file:///Users/moreno_m5/Projects/CH5/marinesandbox/marinesandbox/Models/PlacedStructure.swift): Placed coordinate `xPos`.
  * [`CoralFrag`](file:///Users/moreno_m5/Projects/CH5/marinesandbox/marinesandbox/Models/CoralFrag.swift): Active growth parameters, predator damage, and active predator array.

### Day 5: ViewModel Coordination
* **TASK-MVP-202 (Bishal):** Implement `marinesandbox/ViewModels/SandboxViewModel.swift` to coordinate between SwiftData contexts and `marinesandbox/Services/EcoEngine.swift`. Translate canvas adjustments (fragging, cleaning) into database inserts/updates. (Note: Relegate Hard Reset operation to Settings panel).
* **TASK-MVP-203 (Zarina):** Setup local file loaders to seed the mock Bali NGO preset from static resources on launch.

### Day 6: Onboarding Selection View
* **TASK-MVP-204 (Reno / Bobo):** Build the Location / NGO Selection Screen and user routing system using Sam's UX specifications.
  * New users see selector $\rightarrow$ Seabed canvas $\rightarrow$ guided to plant exactly **one Staghorn frag** to start.
  * Returning users bypass selector and load saved context directly.
* **Deliverable:** Sandbox configurations successfully save and reload offline.

---

## Phase 3: UI Polish, Lottie Integration & Sharing (Days 7–10)
**Objective:** Replace placeholder views with final visual assets, Lottie vector animations, and social exports.

### Day 7: Lottie Frame Scrubbing
* **TASK-MVP-301 (Bobo):** Implement `marinesandbox/Views/Canvas/LottieCoralView.swift` wrappers. Map playheads dynamically based on the state (Growth $0.0 \rightarrow 0.6$, Bleaching $0.6 \rightarrow 0.8$, Algae $0.6 \rightarrow 1.0$, Dead $1.0$).

### Day 8: Active Care Tools Polish
* **TASK-MVP-302 (Reno):** Add custom animations and touch feedback for the **Brush Tool** (wiping away green algae moss) and **Hand Tool** (tapping to smash or flicking snails/starfish).
* **TASK-MVP-303 (Bobo):** Connect the midground layer to render custom recruited fauna silhouettes (small reef fish, tiny gobies, or schools) matching the active growth stages.

### Day 9: Share Card Generator
* **TASK-MVP-304 (Zarina):** Design and build `marinesandbox/Views/Modals/ShareCardView.swift` (9:16 layout) capturing a high-definition snapshot of the reef canvas, local score metrics, and NGO signature tags, based on Sam's visual asset mocks.

### Day 10: Registration & Polish
* **TASK-MVP-305 (Bishal):** Connect the **Local Registration Prompt** dialog. Prompt users to register a local profile name to "save progress" after their first adult coral matures.
* **Deliverable:** High-fidelity UI is complete. Social card export is functional.

---

## Phase 4: Validation & Release Preparation (Days 11–14)
**Objective:** Run exhaustive test scenarios, fix memory leaks, and stabilize compile targets.

### Days 11–12: Stress Testing & Optimization
* **TASK-MVP-401 (Bishal / Zarina):** Verify EcoEngine calculations under long simulations: check for division-by-zero errors or out-of-bounds metrics.
* **TASK-MVP-402 (Bobo / Zarina):** Optimize `ParallaxScrollView` render frames to ensure fluid 60fps scrolling when rendering multiple fish layers.

### Days 13–14: Bug Fixes & Code Cleanup
* **TASK-MVP-403 (All):** Code review cleanup. Ensure all async tasks (`Task`) utilize `[weak self]` memory safety rules.
* **Deliverable:** Fully functional, compiler-error-free Marine Sandbox iOS application ready for deployment.

---

## Deferred Roadmap Items (Future Sprints)
* **TASK-ROAD-501 (Bishal / Zarina):** Enforce COPPA guidelines: encrypt saved data and isolate user profiles inside local container storage.
* **TASK-ROAD-502 (Bishal):** Build Apple native iCloud / CloudKit syncing layer for profiles and settings.
* **TASK-ROAD-503 (Bobo):** Implement advanced parallax micro-animations (swaying seaweed/seagrass blades, custom spline swimming fish paths) inside horizontal scroll layers.
