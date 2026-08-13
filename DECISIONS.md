# Decision Register

Single source of truth for **why** the Marine Sandbox is built the way it is. If a choice changes scope, architecture, or user experience, it belongs here — otherwise it gets re-litigated every sprint.

## How the team maintains this file

1. **Who:** whoever makes or discovers the decision writes the entry. Not the PM's job alone.
2. **When:** in the same PR as the change (see [CONTRIBUTING.md](CONTRIBUTING.md)). A PR that alters scope, architecture, or UX without a `DEC-` entry is incomplete.
3. **IDs are sequential and permanent.** Next free ID: **DEC-024**. If two open PRs claim the same number, the one merged first keeps it and the other renumbers.
4. **Never rewrite an accepted entry.** To change a decision, add a new one and set the old entry's status to `Superseded by DEC-0XX`. The wrong turns are the valuable part of the record.
5. **Cite the source** — commit hash, doc section, or transcript file — so anyone can trace it back.
6. Decisions taken verbally in a meeting must land here before the branch merges, or they will be forgotten (this file exists because several already were).

**Status vocabulary**

| Status | Meaning |
| --- | --- |
| `Accepted` | Agreed and in force. Build against it |
| `Proposed` | Recommended but not yet ratified by the team. Do not treat as settled |
| `Open` | Being decided. Blocking work — resolve it before building the affected area |
| `Superseded` | Replaced. Kept for history, points at the replacement |
| `Rejected` | Considered and declined. Kept so it is not re-proposed |

---

## Index

| ID | Decision | Status | Source |
| --- | --- | --- | --- |
| DEC-001 | Pedagogical sandbox, not a real-world predictor or "virtual CCTV" | Accepted | PRD §1.3 |
| DEC-002 | Entertainment-first, subliminal education | Accepted | `63fe98a` / PRD §3.6 |
| DEC-003 | 2-week MVP scope boundaries | Accepted | PRD §1.5 |
| DEC-004 | Skip the TechDemo phase; build MVP views directly | Accepted | `66e4843` |
| DEC-005 | Hard Reset removed from gameplay UI, Settings only | Accepted | `eb151e8` |
| DEC-006 | No plantation sub-zones; plant anywhere | Accepted | `3f890aa` |
| DEC-007 | No side dashboard or sliders; on-canvas overlays | Accepted | `626ea33` |
| DEC-008 | No Location Selection screen; two-screen flow | Accepted | `8f0e915` |
| DEC-009 | Dead-rubble cold open with one surviving fragment | Accepted | Team-Discussion-12Aug |
| DEC-010 | Defer bleaching / heatwave for the exhibition build | Accepted | Team-Discussion-12Aug |
| DEC-011 | Sign in with Apple over Passkeys | Accepted | Team-Discussion-12Aug |
| DEC-012 | Care tools: brush-swipe algae, tap-smush or flick pests | Accepted | Team-Discussion-12Aug |
| DEC-013 | MVVM+S with SwiftUI and SwiftData, local-first | Accepted | TDD §2 |
| DEC-014 | Continuous `xPos` coordinates, no grid | Accepted | TDD §2.3 |
| DEC-015 | Fixed 3-segment parallax, not infinite tiling | Accepted | `dc631c5` |
| DEC-016 | iOS 26.5 target, Swift 5 mode, zero third-party dependencies | Open | project settings |
| DEC-017 | Lottie via `lottie-spm` 4.6.1 for coral and pest art | Proposed | this session |
| DEC-018 | Layered Lottie compositions + coverage-grid mask for dirt | Proposed | this session |
| DEC-019 | Art behind a `ReefArtProvider` seam | Proposed | this session |
| DEC-020 | EcoEngine operates on value snapshots, not `@Model` classes | Proposed | this session |
| DEC-021 | Ownership of parallax `scrollX` | Open | this session |
| DEC-022 | Domain-layer test strategy | Open | this session |
| DEC-023 | Feature-branch workflow, always based off latest `main` | Accepted | `CONTRIBUTING.md` |
| DEC-024 | Direct seabed planting, PlacedStructure and ReefStar removal | Accepted | `6623751` |

---

## Product & Scope

### DEC-001 — Pedagogical sandbox, not a real-world predictor
**Status:** Accepted · **Source:** PRD §1.3, §3 validation framework

The app illustrates generalised ecological cause-and-effect. It explicitly does **not** predict outcomes for students' real restoration plots, and is not a monitoring tool for them ("virtual CCTV").

*Why:* predicting real-world results sets false expectations and cannot be scientifically honest at this fidelity. Recorded as **Invalidated: Real-world CCTV** in the validation framework.

*Consequence:* no live data feeds, no plot tracking, no claims of predictive accuracy anywhere in UI copy.

### DEC-002 — Entertainment-first, subliminal education
**Status:** Accepted · **Source:** `63fe98a`, PRD §3.6

Success is measured by retention and enjoyment first. Learning happens through action-reaction mechanics and visual feedback, never text-heavy popups, flashcards, or quizzes.

*Consequence:* mechanics must teach unaided. Any screen that reads like an encyclopedia or a test has failed the brief. Motion polish is a requirement, not a nice-to-have.

### DEC-003 — 2-week MVP scope boundaries
**Status:** Accepted · **Source:** PRD §1.5

Deferred: multi-region configs (Jeju, Caribbean), QR scan rewards, iCloud/CloudKit sync, Global Social Map.

### DEC-004 — Skip the TechDemo phase
**Status:** Accepted · **Source:** `66e4843`

Work starts directly on main MVP views. `Documentation/techdemo_tdd_marinesandbox.md` was deleted on `main` as a consequence.

### DEC-005 — Hard Reset removed from the gameplay UI
**Status:** Accepted · **Source:** `eb151e8`, PRD §4.7

Accessible only from Settings, behind confirmation.

*Why:* accidental taps wiped the user's whole reef.

### DEC-006 — No plantation sub-zones
**Status:** Accepted · **Source:** `3f890aa`

Users plant anywhere along the continuous foreground.

*Consequence:* spatial planning (spacing fast vs slow growers) becomes a real skill rather than a slot-filling exercise. Pairs with DEC-014.

### DEC-007 — No side dashboard or sliders
**Status:** Accepted · **Source:** `626ea33` (TASK-TD-104)

Controls live as mid-fidelity overlays directly on the canvas.

*Why:* a dashboard of numeric sliders is the clinical UI DEC-002 rules out, and PRD §3.3 argues numbers fatigue the prefrontal cortex where visuals do not.

### DEC-008 — No Location Selection screen; two-screen flow
**Status:** Accepted · **Source:** `8f0e915`, `Documentation/user_workflow_marinesandbox.md`

The flow is Onboarding Page → Coral Screen. Nothing else. Bali/Living Seas is the implicit default; other regions stay config-only, never a user-facing choice.

*Consequence:* **supersedes the routing described in PRD §4.2.** `TASK-MVP-204` ("Build Location Selection Screen and user routing") is void as written and needs rescoping.

### DEC-009 — Dead-rubble cold open with one surviving fragment
**Status:** Accepted · **Source:** Team-Discussion-12Aug, refined this session

The user opens on a dead white-rubble seabed holding one living Staghorn fragment. They tap it, the Reef Star base highlights, they drag the fragment onto it. *(Amended by DEC-024: the ground highlights instead of a Reef Star base.)*

*Why:* it mirrors what Living Seas actually does — real practitioners recover living fragments from rubble and tie them to structures — so the mechanic teaches a true fact with no text. Highlighting the base after the tap is implicit scaffolding (PRD §3.5) instead of a tutorial.

### DEC-010 — Defer bleaching and heatwave mechanics
**Status:** Accepted · **Source:** Team-Discussion-12Aug

Focus on active care of one coral type first. Bleaching may later return as a "prestige restart" achievement loop.

> **Unresolved conflict — now in shipped code.** PRD §4.6 and §1.5 still treat thermal bleaching as MVP scope, and `EcoEngine.swift` section D (`b4845f2`) implements heat stress, bleaching, recovery, and bleached-coral mortality. Either the deferral is dead and the docs are right, or the engine is carrying unused scope. Whoever resolves it: add the superseding entry here and reconcile the PRD in the same PR.

### DEC-011 — Sign in with Apple over Passkeys
**Status:** Accepted · **Source:** Team-Discussion-12Aug

*Why:* Passkeys give cryptographic credentials but do not reliably return an email, making account mapping in the database complicated. Apple Sign-In verifies with Face ID and returns a stable user ID plus email.

*Consequence:* for the exhibition, storage stays local and info cards stay hardcoded. Incurs **DEBT-002**.

### DEC-012 — Care tools: brush-swipe algae, tap-smush or flick pests
**Status:** Accepted · **Source:** Team-Discussion-12Aug

Algae is cleaned by swiping a brush tool over the coral (sparkle on success). Pests are removed by tapping to smush or swiping to fling them off-screen. First pest encounter shows a one-time tooltip.

---

## Architecture & Technical

### DEC-013 — MVVM+S with SwiftUI and SwiftData, local-first
**Status:** Accepted · **Source:** TDD §2

Four layers: View → ViewModel → Services → Storage. SwiftData holds local state; CloudKit sync is deferred (DEC-003).

### DEC-014 — Continuous `xPos` coordinates, no grid
**Status:** Accepted · **Source:** TDD §2.3

Seabed positions are floating-point horizontal offsets. *(Amended by DEC-024: coordinates are now 2D — `xPos` and `yPos` — stored on `CoralFrag`.)*

### DEC-015 — Fixed 3-segment parallax, not infinite tiling
**Status:** Accepted · **Source:** `dc631c5`

Exactly 3 stitched segments of 1.5× viewport width (4.5× total). `scrollX` clamped to `[-3.5 × viewportWidth, 0]`. Draw order: `#3BAFED` backdrop → MG (0.50, top-pinned) → BG (0.20, top-pinned) → FG (1.00, bottom-pinned). Per-column variant indices are a mutually exclusive permutation of `{0,1,2}` so no `0-0-0` vertical stack can occur. Columns render in a static `ForEach(0..<3)` with `.transition(.identity)` for seamless panning.

*Supersedes:* the procedural infinite tiling approach (`2a53cce`, `929376f`), which produced visible seams and crossfades during panning.

*Amended `1a9eeb7`:* segment width is now scaled per layer so slower-ratio layers can still pan all 3 segments into view, and overscroll past either boundary applies rubber-band resistance (coefficient `0.55`) rather than a hard stop.

*Consequence:* the playable world is bounded, so the foreground must be clamped in the view model. Incurs **DEBT-001**.

### DEC-016 — iOS 26.5 target, Swift 5 mode, zero third-party dependencies
**Status:** **Open** — currently the observed project state, never explicitly agreed · **Source:** `marinesandbox.xcodeproj`

Verified settings: deployment target **iOS 26.5**, Swift language mode **5.0**, device family iPhone + iPad, bundle `com.molamola.marinesandbox`, team `N8Y7P4HS74`, **no SPM packages**, **no test target**, file-system synchronized groups (`objectVersion 77`).

*Needs a decision on:*
- iOS 26.5 excludes every device below it. Intentional, or an artifact of the Xcode template?
- Device family claims iPad while the parallax spec targets iPhone 17 only.
- Swift 5 mode means no strict concurrency checking. Fine for the sprint, but should be a choice.

*Note:* synchronized groups mean **new `.swift` files on disk join the target automatically** — no `.pbxproj` edits, so no merge conflicts for source files. Adding a test target *does* require a `.pbxproj` change (see DEC-022).

### DEC-017 — Lottie via `lottie-spm` 4.6.1
**Status:** Proposed · **Source:** this session

Designers are authoring in Lottie, so the app needs a runtime. Use `https://github.com/airbnb/lottie-spm.git` from `4.6.1` (published 2026-06-13) — the precompiled XCFramework resolves far faster than building lottie-ios from source.

*Consequence:* breaks the zero-dependency status quo in DEC-016. Perf ceiling to watch: N corals × multiple compositions; paused/scrubbed comps are cheap, looping ones are not. Measure with ~10 corals before art is finalised.

### DEC-018 — Layered compositions + coverage-grid mask for dirt
**Status:** Proposed · **Source:** this session

Each coral is composited by us from **separate** Lottie files — growth body (playhead scrubbed to `growthProgress`), algae overlay (looping, **masked**), FX one-shots, with pests as independent entities. Dirt coverage lives in the domain as a 6×6 `AlgaeCoverage` grid; the brush clears the cells a stroke crosses; `algaePercentage` is *derived* from the grid.

*Supersedes:* the single-playhead mapping in **TDD §3.2** (growth `0.0–0.6`, bleaching `0.6–0.8`, algae `0.8–1.0`), which cannot work because:
1. Growth and dirt are simultaneous independent dimensions — a teenager coral at 60% dirt has no valid playhead value.
2. Cleaning is *local*; a scalar playhead can only express a global amount, which reads as the coral flickering rather than the user cleaning it.
3. Verified Lottie API: setting `currentProgress` **stops playback**, so one composition cannot both scrub growth and loop an idle sway.

*Consequences:*
- Idle sway comes from SwiftUI transforms, not from inside the growth composition.
- Helper-fish automation clears grid cells through the **same code path** as the brush — identical visuals, different driver. This is what makes the manual→automated reward arc (PRD §3.2) nearly free.
- Brush strokes must be **interpolated between drag samples**; `DragGesture` emits discrete locations and a fast swipe would otherwise leave uncleaned stripes.
- Asset contract for designers: one concern per file, transparent backgrounds, uniform full-coverage algae (we mask it — do not animate coverage growth in After Effects), consistent canvas size per species anchored bottom-centre, markers `baby`/`teen`/`adult` and `idle`/`squash`/`tumble`, no AE expressions or unsupported effects.

### DEC-019 — Art behind a `ReefArtProvider` seam
**Status:** Proposed · **Source:** this session

Interactions hit-test against **model geometry**, never artwork bounds. Art is supplied by a `ReefArtProvider` injected via the environment: `SkeletonArtProvider` (SwiftUI shapes) now, final art later.

*Consequence:* the team can build and playtest the full loop before assets exist, and swapping art is a one-line change that touches no gesture, physics, or engine code.

### DEC-020 — EcoEngine operates on value snapshots
**Status:** Proposed · **Source:** this session · **Applies to shipped code:** `marinesandbox/Services/EcoEngine.swift` (`b4845f2`)

`EcoEngine` should take and return plain `struct` state, with the view model mapping SwiftData ↔ snapshots.

*Why:* the engine documents itself as "completely stateless — taking the current state of a `ReefCanvas` … and returning an updated `ReefCanvas`", but `ReefCanvas` is a `@Model` **class**. It mutates `canvas.placedStructures[].coral` in place and returns the same reference. The API promises a pure function and delivers in-place mutation, which means:
- callers cannot preview a result without committing it — this breaks Fast Forward, which needs to *compute* a steady state before showing the timelapse;
- it cannot be unit-tested without a `ModelContainer`;
- SwiftData change notifications fire mid-simulation for all 60 steps of a timelapse sweep.

*Fix:* keep the maths exactly as written — it is sound — and change only the boundary: `step(state: ReefState, threats:) -> ReefState` over value types, with a thin SwiftData adapter.

### DEC-021 — Ownership of parallax `scrollX`
**Status:** **Open** — blocks the entity layer · **Source:** this session

`scrollX` is `private @State` inside `ParallaxScrollView`, but the entity layer must know the scroll offset to hit-test corals and pests. Options: hoist into `SandboxViewModel` and pass a `Binding` (~2 lines changed in Zarina's file, single source of truth) versus a second gesture handler in the entity layer (touches nothing, risks desync).

*Note:* Zarina's fork carries newer parallax work (rubber-band overscroll, per-layer segment widths) not yet upstream. Whoever resolves this must coordinate with her — wrap that view, do not rewrite it.

### DEC-022 — Domain-layer test strategy
**Status:** **Open** · **Source:** this session

No test target exists, and adding one requires editing `project.pbxproj` — the most conflict-prone file in a 5-person sprint. Options: a sidecar SPM package pointing at the existing `Domain/` sources (real `swift test`, zero `.pbxproj` change), a proper Xcode test target, or a `#if DEBUG` assertion harness.

*Related:* DEC-020 — the engine currently cannot be tested at all without a `ModelContainer`, so resolving that unblocks this.

---

## Process

### DEC-023 — Feature-branch workflow, always based off the latest `main`
**Status:** Accepted · **Source:** [CONTRIBUTING.md](CONTRIBUTING.md)

Nobody commits to `main`. All work happens on a feature branch cut from the **latest** `main` at the moment work begins, and reaches `main` only through a pull request. Branch naming follows `{type}/{name}/{TASK-ID}-{description}` (TDD §6). Already-pushed branches are merged forward from `main`, never rebased or force-pushed.

*Why:* five people are committing in parallel on a two-week sprint. Branching off a stale `main` means resolving someone else's conflicts inside your own feature, and `ParallaxScrollView.swift` has already been through two conflict-resolution merges (`4aeda93`, `c04c6de`). Requiring a PR also gives the changelog and this register a natural enforcement point — see the PR template.

*Consequences:*
- `main` stays releasable; the exhibition build can be cut at any time.
- Definition of done is "merged into `main`", not "works on my machine".
- Contributors without write access use the fork flow (documented in CONTRIBUTING.md).

### DEC-024 — Direct seabed planting, PlacedStructure and ReefStar removal
**Status:** Accepted · **Source:** `6623751`, `63ea0c4`

We completely removed the `PlacedStructure` database schema and Reef Star structural frames from the database models, user onboarding, and core gameplay interactions. Corals are planted directly on the seabed ground/rubble, with continuous coordinates `xPos` and `yPos` stored directly in the `CoralFrag` model.

*Why:* Placing metal Reef Star frames as a required step added unnecessary mechanical complexity and clashed with our direct direct-on-seabed visual aesthetic. Adding verticality (`yPos`) supports roadmapped species (like fan corals) nesting on boulders or vertical reef walls.

*Consequence:*
- The `PlacedStructure.swift` model file is deleted.
- `ReefCanvas` maintains a direct cascade relationship to `coralFrags: [CoralFrag]`.
- The onboarding tutorial flow is simplified: *tap surviving frag -> highlighted ground pulses -> drag frag onto ground to confirm planting*.
- **Amends DEC-014:** seabed coordinates are now 2D (`xPos`, `yPos`) rather than horizontal-only.
- **Amends DEC-009:** the cold-open interaction highlights the ground, not a Reef Star base.

---

## Technical Debt Register

| ID | Debt | Incurred by | Impact |
| --- | --- | --- | --- |
| **DEBT-001** | Asymmetrical state management: background columns are stateless and derived from coordinates, foreground structures need full SwiftData CRUD — two coordination systems | DEC-015 | Visual drift between layers; playable bounds must be clamped to foreground coordinates |
| **DEBT-002** | Hardcoded info cards and local-only SwiftData caches will need remapping to sync with a remote database once Apple Sign-In lands | DEC-011 | Storage-layer rewrite after the exhibition |

### Known code issues (not yet decisions)

*Verified against `main` at `94a1ea8`.*

* `ParallaxScrollView` uses `.resizable().aspectRatio(contentMode: .fit)` on full-bleed layers, which letterboxes instead of filling the segment.
* `Color(hex:)` is defined inside `ParallaxScrollView.swift`; it will collide the moment a second file defines it. Belongs in a design-system file.
* `EcoEngine`'s doc comment claims it is stateless while it mutates its input in place (DEC-020). Whichever way that is resolved, the comment and the behaviour must agree.
* `CoralFrag`'s doc comments hard-code Lottie frame ranges (e.g. "algae ≥ 0.5 transitions playhead to frames 81–100"), baking the single-playhead model into the data layer. If DEC-018 is accepted, these comments describe an approach we no longer use.

---

## Superseded & Rejected

| Decision | Outcome |
| --- | --- |
| Procedural infinite parallax tiling (`2a53cce`, `929376f`) | Superseded by DEC-015 — visible seams and crossfades while panning |
| Location Selection screen routing (PRD §4.2) | Superseded by DEC-008 |
| Single-playhead Lottie state mapping (TDD §3.2) | Superseded by DEC-018 *(pending ratification)* |
| Plantation sub-zones (PRD, pre-`3f890aa`) | Superseded by DEC-006 |
| Hard Reset in the gameplay canvas | Superseded by DEC-005 |
| Passkeys for authentication | Rejected in DEC-011 — no reliable email for account mapping |
| Real-world plot prediction / "virtual CCTV" | Rejected in DEC-001 — sets false expectations |
| Numeric dashboards and sliders for reef state | Rejected in DEC-007 — clinical, and slow symbolic processing (PRD §3.3) |
