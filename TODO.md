# TODO

Ordered work queue for the Marine Sandbox exhibition build. Build order: **testing → domain layer → frontend skeleton → polish**.

Decisions are settled in [`DECISIONS.md`](DECISIONS.md) (DEC-016 through DEC-025) — check there before re-litigating anything. Day-by-day detail lives in [`Documentation/sprint_task_breakdown.md`](Documentation/sprint_task_breakdown.md).

**Ownership:** this queue marks who executes each item. **Our lane (Bishal)** is backend & physics: engine, models, view models, 2D physics, testing infrastructure. Teammate items are listed for sequencing only — we do not build them.

Legend: `[ ]` not started · `[~]` in progress · `[x]` done · `[—]` teammate's lane

---

## Phase 0 — Housekeeping

- [x] **Merge PR #7** — decision resolutions DEC-016–DEC-022 + DEC-025 bleaching dormancy. Merged as `e7422c0`.
- [—] **Issue #6 (Zarina)** — PR her fork's parallax work (rubber-band overscroll `0.55`, per-layer segment widths from `1a9eeb7`) to `main`, then change `ParallaxScrollView` to take `@Binding var scrollX: CGFloat` (DEC-021). Wrap, don't rewrite. Includes an iPad size-class visual pass. **We depend on the `Binding` signature for Phase 2; until it lands we code against a local `scrollX` `@State` and swap to the binding when her PR merges.**

---

## Phase 1 — Testing infrastructure (DEC-022, DEC-020) · OUR LANE

### 1.1 Sidecar SPM package ✅ DONE

- **Goal:** real `swift test` for the domain layer with zero `project.pbxproj` changes (DEC-022). The Xcode project uses file-system synchronized groups (DEC-016 note), so anything under `marinesandbox/` auto-joins the app target — the package must therefore live at **repo root**, outside the synced group.
- **Files:**
  - `MarineSandboxDomain/Package.swift` — swift-tools-version 5.9, Swift 5 language mode (matches DEC-016), one library target + one test target.
  - `MarineSandboxDomain/Sources/Domain` — **symlink** to `../../marinesandbox/Domain` (SPM forbids target paths outside the package root; a symlink keeps a single source of truth on disk).
  - `MarineSandboxDomain/Tests/DomainTests/` — test files live here.
- **Acceptance:**
  - `cd MarineSandboxDomain && swift test` compiles and runs (even with zero tests).
  - `xcodebuild -project marinesandbox.xcodeproj -scheme marinesandbox -destination 'generic/platform=iOS Simulator' build` still succeeds — no `.pbxproj` diff.
  - `MarineSandboxDomain/` is not picked up by the app's synchronized group (it sits outside `marinesandbox/`).
- **Normative:** DEC-022, DEC-016 (synchronized groups note).

### 1.2 EcoEngine value-snapshot refactor ✅ DONE

- **Goal:** `EcoEngine` operates on `ReefState` value snapshots, not `@Model` classes (DEC-020). **Maths stays exactly as written** — only the boundary changes.
- **Files:**
  - `marinesandbox/Domain/EcoEngine.swift` — new home; pure functions over value types. `public enum EcoEngine { static func step(state: ReefState, threats: ThreatVector, months: Int) -> ReefState }` plus `static func shannonIndex(of state: ReefState) -> Double`.
  - `marinesandbox/Services/EcoEngine.swift` — deleted (replaced, not wrapped: nothing else references it yet — verified).
  - `marinesandbox/Domain/ThreatVector.swift` — **moved** from `Models/` (it is already a value struct; it belongs to the domain, not persistence). No code changes needed.
- **Mapping rules from the old engine (must hold exactly):**
  - Constants unchanged: `beta 0.5`, `baseGrowthRate 0.08`, `baseAlgaeGrowthRate 0.06`, `baseGrazingRate 0.03`, `basePredatorDamageRate 0.05`, `basePredatorControlRate 0.04`.
  - Recruitment: adults only; `herbivore = adultCount × (1 + 0.5 × H)`, same for predators.
  - Growth: `0.08 × (1 − algaePercentage) × (1 − predatorDamage)` per month, clamped to `1.0`.
  - Algae: baby/teenager rate ×1.5; runoff ×2.5; net = growth − recruitment × 0.03, clamped `[0,1]`. Applied via `coverage.grow(by:)` / `coverage.graze(by:)` so the spatial grid stays authoritative (DEC-018); `grow`'s base-bias averages to 1.0 so aggregate behavior is unchanged.
  - Pests: net damage = `0.05 × count − predatorRecruitment × 0.04`, floored at 0, clamped to 1.0.
  - §D heat stress: ported verbatim but **dormant in exhibition** (DEC-025) — no exhibition caller ever passes `waterTemperature > 30` or `isHeatwaveActive: true`. Code stays, untested.
  - Mortality: bleached + algae > 0.8 → dead; predatorDamage ≥ 1.0 → dead.
- **Acceptance:**
  - No `import SwiftData` anywhere under `marinesandbox/Domain/`.
  - `step` is a pure function: same input → same output, input value unmutated (value semantics).
  - Old `Services/EcoEngine.swift` is gone; app target still builds (synchronized groups pick up `Domain/` automatically).
- **Normative:** DEC-020, DEC-018, DEC-025.

### 1.3 Core engine test suite ✅ DONE (36 tests green)

- **Goal:** pin the engine's behavior so the refactor and all future tuning are verifiable. Swift Testing framework (`@Test`, `#expect`).
- **Files:** `MarineSandboxDomain/Tests/DomainTests/EcoEngineTests.swift`, `AlgaeCoverageTests.swift`.
- **Acceptance — concrete cases:**
  - Shannon: empty reef → `H = 0`; monoculture (4× Acropora) → `H = 0`; 2 species × 2 frags → `H = ln 2 ≈ 0.693`.
  - Growth: clean healthy coral gains exactly `0.08`/month; fully smothered (algae 1.0) gains `0`; 12 months from 0 → `0.96` (≈ the documented year-to-maturity).
  - Algae: baby with runoff → `+0.225`/month gross (0.06 × 1.5 × 2.5); one adult in monoculture grazes `0.03`/month (H=0 → recruitment ×1).
  - Pests: 1 snail, no adults → `+0.05`/month damage; damage ≥ 1.0 → dead; bleached + algae > 0.8 → dead (construct bleached state directly in the fixture — do **not** trigger §D via temperature, it is dormant per DEC-025).
  - Grid: brush stroke through a cell clears it and returns its index; fast swipe (distant from/to) leaves no uncleaned stripe; graze ordering deterministic (thickest first); `grow` bias averages 1.0 (uniform grow by `x` moves `percentage` by ≈ `x`).
  - Timelapse: `step(months: 60)` on a diverse reef converges without crash, NaN, or out-of-`[0,1]` values; repeated runs are identical (determinism).
- **Normative:** DEC-020 (testability was the motive), DEC-025 (no §D coverage), `EcoEngine.swift` doc comments.

---

## Phase 2 — Domain layer ("backend") · OUR LANE unless marked

### 2.1 `NGOConfig` SwiftData model + Bali preset seed ✅ DONE (schema half)

- **Goal:** the last empty model gets a schema; the Bali/Living Seas default config seeds on first launch (TASK-MVP-203 is Zarina's file-loading half — **our half is the schema**).
- **Files:** `marinesandbox/Models/NGOConfig.swift`.
- **Spec:** `@Model` class. Fields: `regionName: String` (unique, e.g. `"Bali"`), `availableSpecies: [String]` (`["Acropora", "BrainCoral"]` for Bali per PRD §4), `baselineTemperature: Double` (`27.0`), `runoffShockAllowed: Bool` (`true`), `heatwaveAllowed: Bool` (**`false` for the exhibition** — DEC-025 makes this the enforcement point for dormancy), `pestCatalog: [String]` (`["DrupellaSnail", "CrownOfThornsStarfish"]`).
- **Acceptance:** model compiles into the app target; a `NGOConfig(regionName: "Bali")` fixture documents the exhibition defaults; `heatwaveAllowed == false` is asserted in a comment citing DEC-025.
- **Normative:** DEC-003 (Bali implicit default, other regions config-only), DEC-025, PRD §4, TASK-MVP-201 note (PlacedStructure removed — DEC-024).

### 2.2 `SandboxViewModel` ✅ DONE

- **Goal:** the View↔Domain coordinator (TASK-MVP-202). Owns `scrollX` (DEC-021), maps SwiftData ↔ snapshots, translates care actions into state mutations.
- **Files:** `marinesandbox/ViewModels/SandboxViewModel.swift`.
- **Spec:**
  - `@Observable` class (Swift 5 mode, so no strict concurrency requirements — DEC-016).
  - **Published surface:** `scrollX: Double` (owned here per DEC-021; passed to `ParallaxScrollView` as a `Binding` once issue #6 lands — until then the view keeps its local state and we integrate on merge), `canvas: ReefCanvas?`, `selectedTool: Tool` (`brush`/`hand`/`plant`), threat state for the session.
  - **Adapter (the DEC-020 seam):** `snapshot() -> ReefState` (model → value), `commit(_ state: ReefState)` (value → model). Matching is by `CoralFrag` identity — `CoralState.id` must be threaded through (see risk note below).
  - **Actions:** `plantFrag(species:at:)`, `brushStroke(from:to:on:)` → mutates `AlgaeCoverage` via segment clear, `smushPest(_:on:)`, `flickPest(_:velocity:on:)` (release > 100 pt/s → physics throw, despawn past viewport), `fastForward(years:)` → `EcoEngine.step(months: years × 12)` on a snapshot, then commit → triggers Diagnostic Card.
  - **Hard Reset is NOT here** (DEC-005 — Settings only).
- **Acceptance:** every user-visible mutation flows through snapshot → domain logic → commit; no view touches `EcoEngine` or `AlgaeCoverage` directly; foreground positions clamped to canvas bounds (DEBT-001).
- **Risk:** `CoralFrag` currently has **no stable `UUID`** — add `id: UUID` to the model so snapshot↔model matching survives round trips. Small schema change; note it in the PR.
- **Normative:** DEC-005, DEC-013, DEC-018, DEC-021, DEBT-001, workflow doc §2.3C.

### 2.3 Drag/flick 2D physics ✅ DONE

- **Goal:** TASK-MVP-104 — the tactile layer for planting and pest removal.
- **Files:** `marinesandbox/Domain/Physics.swift` (pure, testable) + consumed by `SandboxViewModel`.
- **Spec:**
  - `FragDrag`: track drag offset in canvas coordinates (screen point − `scrollX`), snap-to-ground on release (nearest valid seabed `yPos` at that `xPos`), reject drops outside playable bounds.
  - `PestFlick`: on release, velocity > 100 pt/s → ballistic throw (simple Euler integration, gravity ~2000 pt/s² for feel), despawn once past viewport bounds; below threshold → pest stays (tap = smush instead, per DEC-012).
  - Pure functions: `flickTrajectory(from:velocity:) -> [CGPoint]`-style sampling or closed-form position-at-time; no view dependencies.
- **Acceptance:** `Physics.swift` has no SwiftUI/SwiftData imports; flick threshold behavior unit-tested (99 pt/s stays, 101 pt/s throws); trajectory deterministic.
- **Normative:** DEC-012, workflow doc §2.3C interaction table, TASK-MVP-104.

### 2.4 First-launch routing ✅ DONE (routing half; onboarding visuals are Reno/Bobo)

- **Goal:** TASK-MVP-204 as rescoped (DEC-008): route without a router screen. **Our half is the routing logic; the Onboarding Page visuals are Reno/Bobo's.**
- **Files:** `marinesandbox/marinesandboxApp.swift` (or `App/MarineSandboxApp.swift` — reconcile the duplicate App entry points as part of this; one must go), `ContentView.swift`.
- **Spec:** SwiftData fetch — saved `UserProfile`/`ReefCanvas` exists → Coral Screen; else → Onboarding Page. That is the entire router (workflow doc §2.1).
- **Acceptance:** cold launch with empty store shows onboarding; relaunch with saved canvas goes straight to Coral Screen; no Location Selection anywhere (DEC-008).
- **Normative:** DEC-008, workflow doc §1–2.

---

## Phase 3 — Frontend skeleton (DEC-019) · shared lane, we support

Build the full loop against `SkeletonArtProvider` — playtestable end-to-end before any final art exists. Layouts are Bobo's lane, art is Sam's; **our contribution is the `ReefArtProvider` protocol + domain hooks.** Sequencing note: everything here needs Phase 2.2's view model surface.

- [—] `ReefArtProvider` protocol + `SkeletonArtProvider` (SwiftUI shapes). Hit-testing against model geometry, never artwork bounds.
- [—] `SandboxView` over `ParallaxScrollView` (binding per #6): dead-rubble cold open (DEC-009), guided first plant, steady-state care loop.
- [—] On-canvas tool overlays (DEC-007): Brush, Hand, Fast Forward, camera, night-mode, gear.
- [—] Modals: `DiagnosticCardView`, `ShareCardView` (9:16), registration prompt at first Adult (TASK-MVP-305), Settings with Hard Reset behind confirmation.
- [—] Recruited fauna layer (TASK-MVP-303); adult-driven automation uses the same grid-clearing path as the brush (DEC-018).

## Phase 4 — Polish & integration (sprint Days 7–14) · shared lane

- [—] **10-coral Lottie perf check** — the DEC-017 gate. Must pass before final art is committed; if it fails, `SkeletonArtProvider` carries the exhibition.
- [—] Lottie integration per DEC-018 layered compositions (TASK-MVP-301's single-playhead mapping is superseded).
- [—] Care tool polish (TASK-MVP-302), share card with final art (TASK-MVP-304).
- [x/—] Engine stress coverage: folded into Phase 1.3 (determinism + 60-step sweep). TASK-MVP-401's remaining half (render-frame optimization) is Bobo/Zarina.
- [—] Memory audit (TASK-MVP-403): `[weak self]` on all async tasks.

## Docs debt (not blocking the build)

- [ ] **Reconcile orphaned interview concepts into the specs** — 12 expert-interview concepts live only in transcripts: anthropogenic threats list, coral reproduction (Alex 9 Aug); funding/ROI, rapid-response maintenance, regenerative business model, pontoon trade-off, macroalgae distinction (Leon 23 Jul); post-visit engagement gap, alumni pipeline, audience spectrum, visual-before/after (Leon 1 Aug). Each lands in the PRD/TDD with a citation or is explicitly rejected in DECISIONS.md.
- [ ] **`graphify update`** after each merged PR (code-only changes rebuild free; doc changes need a full update).

## Explicitly out of scope (exhibition build)

Bleaching/heatwave UI (engine dormant, DEC-025) · QR scanning, CloudKit sync, Global Map (DEC-003; stubs only) · Location Selection screen (DEC-008) · Reef Star structures (DEC-024) · server backend of any kind (DEC-013 local-first).
