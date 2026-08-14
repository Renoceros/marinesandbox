# TODO

Ordered work queue for the Marine Sandbox exhibition build. Build order: **testing → domain layer → frontend skeleton → polish**.

Decisions are settled in [`DECISIONS.md`](DECISIONS.md) (DEC-016 through DEC-025) — check there before re-litigating anything. Day-by-day detail lives in [`Documentation/sprint_task_breakdown.md`](Documentation/sprint_task_breakdown.md).

Legend: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Phase 0 — Housekeeping (blockers for everything below)

- [ ] **Merge PR #7** — decision resolutions DEC-016–DEC-022 + DEC-025 bleaching dormancy. Everything below assumes these are in force.
- [ ] **Issue #6 (Zarina)** — PR her fork's parallax work (rubber-band overscroll, per-layer segment widths) to `main`, then hoist `scrollX` into a `Binding` (DEC-021). Wrap, don't rewrite. Includes an iPad size-class visual pass.
- [ ] Pull latest `main` after both land and re-cut feature branches (DEC-023).

## Phase 1 — Testing infrastructure (DEC-022)

- [ ] **Create the sidecar SPM package** pointing at the domain sources. Real `swift test`, zero `project.pbxproj` changes.
- [ ] **Refactor `EcoEngine` to value snapshots** (DEC-020 — forced by the sidecar package): `step(state: ReefState, threats: ThreatVector) -> ReefState` over plain structs; thin SwiftData adapter stays in the app target. Keep the maths exactly as written. Fix the stale "completely stateless" doc comment in the same change.
- [ ] **Rewrite `CoralFrag` doc comments** — they hard-code the single-playhead Lottie mapping superseded by DEC-018.
- [ ] **Core engine test suite:** Shannon index (empty canvas, monoculture H=0, diverse reef), growth increments vs. algae/predator modifiers, algae grazer dynamics with/without recruitment, pest damage and mortality at 100%, deterministic multi-step timelapse sweeps (60 steps).
- [ ] **No tests for §D** (heat stress/bleaching) — dormant in the exhibition build per DEC-025. Coverage arrives with the prestige-restart revival.

## Phase 2 — Domain layer ("backend")

Maps to sprint Phase 2 (Days 4–6). Note: `TASK-MVP-201` is stale — it references `PlacedStructure`, removed in DEC-024.

- [ ] **Finish SwiftData models:** `NGOConfig` (the last empty model — Bali/Living Seas presets: species list, baseline temperature 27°C, runoff/pest threat catalog).
- [ ] **`SandboxViewModel`** (TASK-MVP-202): owns `scrollX` (DEC-021), coordinates SwiftData ↔ `EcoEngine` snapshots, translates care actions (brush stroke, pest smush/flick, planting) into state mutations. Hard Reset stays in Settings only (DEC-005).
- [ ] **Drag/flick 2D physics** (TASK-MVP-104): drag frags onto seabed (`xPos`/`yPos`), flick pests off-screen (release velocity > 100 pt/s → physics throw, despawn past viewport bounds).
- [ ] **6×6 `AlgaeCoverage` grid** in the domain (DEC-018): brush clears cells a stroke crosses; `algaePercentage` derives from the grid. Interpolate brush strokes between drag samples.
- [ ] **Seed loader for the Bali preset** (TASK-MVP-203) from static resources on launch.
- [ ] **First-launch routing** (TASK-MVP-204, rescoped per DEC-008): saved `ReefCanvas` exists → Coral Screen, else Onboarding Page.

## Phase 3 — Frontend skeleton (DEC-019)

Build the full loop against `SkeletonArtProvider` — playtestable end-to-end before any final art exists.

- [ ] **`ReefArtProvider` protocol + `SkeletonArtProvider`** (SwiftUI shapes). Hit-testing against model geometry, never artwork bounds.
- [ ] **`SandboxView`** layered over `ParallaxScrollView` (receives `scrollX` binding): dead-rubble cold open with one surviving Staghorn frag (DEC-009), guided tap → pulse → drag-plant first plant, steady-state care loop.
- [ ] **On-canvas tool overlays** (DEC-007 — no dashboards/sliders): Brush Tool, Hand Tool, Fast Forward, camera, night-mode toggle, settings gear.
- [ ] **Modals:** `DiagnosticCardView` (after every Fast Forward), `ShareCardView` (9:16), registration prompt at first Adult coral (TASK-MVP-305), Settings with Hard Reset behind confirmation.
- [ ] **Recruited fauna layer** (TASK-MVP-303): midground fish silhouettes matching growth stages; adult corals automate care via the same grid-clearing code path as the brush (DEC-018).
- [ ] **Clamp foreground to playable bounds** (DEBT-001).

## Phase 4 — Polish & integration (sprint Days 7–14)

- [ ] **10-coral Lottie perf check** — the DEC-017 gate. Must pass before final art assets are committed; if it fails, `SkeletonArtProvider` carries the exhibition.
- [ ] **Lottie integration** (TASK-MVP-301, superseded mapping): layered compositions per DEC-018 — growth scrubbed, algae looping-masked, FX one-shots. Asset contract is in DEC-018 for Sam.
- [ ] **Care tool polish** (TASK-MVP-302): brush sparkle, pest smush/flick feedback, one-time pest tooltip.
- [ ] **Share card with final art** (TASK-MVP-304, Zarina + Sam).
- [ ] **Stress tests** (TASK-MVP-401): long simulations, division-by-zero, out-of-bounds metrics.
- [ ] **Memory audit** (TASK-MVP-403): `[weak self]` on all async tasks.

## Docs debt (not blocking the build)

- [ ] **Reconcile orphaned interview concepts into the specs** — 12 expert-interview concepts live only in transcripts: anthropogenic threats list, coral reproduction (Alex 9 Aug); funding/ROI, rapid-response maintenance, regenerative business model, pontoon trade-off, macroalgae distinction (Leon 23 Jul); post-visit engagement gap, alumni pipeline, audience spectrum, visual-before/after (Leon 1 Aug). Each should either land in the PRD/TDD with a citation or be explicitly rejected in DECISIONS.md.
- [ ] **`graphify update`** after each merged PR to keep the knowledge graph current (code-only changes rebuild free; doc changes need a full update).

## Explicitly out of scope (exhibition build)

- Bleaching/heatwave UI (engine dormant, DEC-025) · QR scanning, CloudKit sync, Global Map (DEC-003; stubs only) · Location selection screen (DEC-008) · Reef Star structures (DEC-024) · server backend of any kind (DEC-013 local-first).
