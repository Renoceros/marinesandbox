# Decision Register

Single source of truth for **why** the Marine Sandbox is built the way it is. If a choice changes scope, architecture, or user experience, it belongs here — otherwise it gets re-litigated every sprint.

## How the team maintains this file

1. **Who:** whoever makes or discovers the decision writes the entry. Not the PM's job alone.
2. **When:** in the same PR as the change (see [CONTRIBUTING.md](CONTRIBUTING.md)). A PR that alters scope, architecture, or UX without a `DEC-` entry is incomplete.
3. **IDs are sequential and permanent.** Next free ID: **DEC-037**. If two open PRs claim the same number, the one merged first keeps it and the other renumbers.
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
| DEC-016 | iOS 26.5 target, Swift 5 mode, zero third-party dependencies | Accepted | project settings, this session |
| DEC-017 | Lottie via `lottie-spm` 4.6.1 for coral and pest art | Accepted (gated) | this session |
| DEC-018 | Layered Lottie compositions + coverage-grid mask for dirt | Accepted | this session |
| DEC-019 | Art behind a `ReefArtProvider` seam | Accepted | this session |
| DEC-020 | EcoEngine operates on value snapshots, not `@Model` classes | Accepted | this session |
| DEC-021 | Ownership of parallax `scrollX` | Accepted | this session, #6 |
| DEC-022 | Domain-layer test strategy | Accepted | this session |
| DEC-023 | Feature-branch workflow, always based off latest `main` | Accepted | `CONTRIBUTING.md` |
| DEC-024 | Direct seabed planting, PlacedStructure and ReefStar removal | Accepted | `6623751` |
| DEC-025 | Exhibition threat vectors benign; bleaching engine ships dormant | Accepted | this session |
| DEC-026 | Gesture routing: tool gestures win on coral hit, pan wins on empty water | Accepted | this session |
| DEC-027 | Tick cadence: 1 sim month per 5 real seconds on the Coral Screen | Accepted | this session |
| DEC-028 | Pest spawning: 25%/tick on vulnerable corals, cap 2 per coral | Accepted | this session |
| DEC-029 | Additional planting unlocks when the first coral reaches Teenager | Accepted | this session |
| DEC-030 | Pest damage retuned to 0.02/month for demo-paced reaction time | Accepted | this session, simulator playtest |
| DEC-031 | 7-day per-coral real-time lifecycle; backend growth + graceful catch-up | Accepted | this session |
| DEC-032 | Single Sponge cleaning tool + bare-hand pest smush | Accepted | this session |
| DEC-033 | Non-lethal pest impact: growth slowdown only, mortality disabled | Accepted | this session |
| DEC-034 | Off-screen snail wave spawning and height-squash smush interaction | Accepted | this session |
| DEC-035 | Audio SFX and ambient ocean loop integration | Accepted | this session |
| DEC-036 | Multi-species SVGs, NGO Config, and Shannon fauna visuals deferred | Accepted | this session |

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

> **Resolved by DEC-025.** The deferral stands: exhibition threat vectors never exceed 30°C, so the shipped bleaching code in `EcoEngine.swift` §D runs dormant. PRD reconciliation rides with DEC-025.

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
**Status:** Accepted · **Source:** `marinesandbox.xcodeproj`, resolved this session

Verified settings: deployment target **iOS 26.5**, Swift language mode **5.0**, device family iPhone + iPad, bundle `com.molamola.marinesandbox`, team `N8Y7P4HS74`, **no SPM packages**, **no test target**, file-system synchronized groups (`objectVersion 77`).

*Resolved this session:*
- **iOS 26.5 is intentional** — the exhibition runs on team-controlled devices, so excluding older OS versions costs nothing.
- **Device family keeps iPhone + iPad.** iPad stays in scope: the parallax math is viewport-relative (DEC-015), so it should run un-tuned; a visual pass on iPad size classes is tracked in issue #6 alongside the `scrollX` handoff.
- **Swift 5 mode is a conscious sprint trade-off.** Strict concurrency checking is revisited post-exhibition.

*Note:* synchronized groups mean **new `.swift` files on disk join the target automatically** — no `.pbxproj` edits, so no merge conflicts for source files. Adding a test target *does* require a `.pbxproj` change (see DEC-022).

### DEC-017 — Lottie via `lottie-spm` 4.6.1
**Status:** Accepted (gated) · **Source:** this session

*Gate:* a 10-coral render perf check must pass before final art assets are committed. If it fails, `SkeletonArtProvider` (DEC-019) carries the exhibition — we lose polish, not the product.

Designers are authoring in Lottie, so the app needs a runtime. Use `https://github.com/airbnb/lottie-spm.git` from `4.6.1` (published 2026-06-13) — the precompiled XCFramework resolves far faster than building lottie-ios from source.

*Consequence:* breaks the zero-dependency status quo in DEC-016. Perf ceiling to watch: N corals × multiple compositions; paused/scrubbed comps are cheap, looping ones are not. Measure with ~10 corals before art is finalised.

### DEC-018 — Layered compositions + coverage-grid mask for dirt
**Status:** Accepted · **Source:** this session

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
**Status:** Accepted · **Source:** this session

Interactions hit-test against **model geometry**, never artwork bounds. Art is supplied by a `ReefArtProvider` injected via the environment: `SkeletonArtProvider` (SwiftUI shapes) now, final art later.

*Consequence:* the team can build and playtest the full loop before assets exist, and swapping art is a one-line change that touches no gesture, physics, or engine code.

### DEC-020 — EcoEngine operates on value snapshots
**Status:** Accepted · **Source:** this session · **Applies to shipped code:** `marinesandbox/Services/EcoEngine.swift` (`b4845f2`)

`EcoEngine` should take and return plain `struct` state, with the view model mapping SwiftData ↔ snapshots.

*Why:* the engine documents itself as "completely stateless — taking the current state of a `ReefCanvas` … and returning an updated `ReefCanvas`", but `ReefCanvas` is a `@Model` **class**. It mutates `canvas.placedStructures[].coral` in place and returns the same reference. The API promises a pure function and delivers in-place mutation, which means:
- callers cannot preview a result without committing it — this breaks Fast Forward, which needs to *compute* a steady state before showing the timelapse;
- it cannot be unit-tested without a `ModelContainer`;
- SwiftData change notifications fire mid-simulation for all 60 steps of a timelapse sweep.

*Fix:* keep the maths exactly as written — it is sound — and change only the boundary: `step(state: ReefState, threats:) -> ReefState` over value types, with a thin SwiftData adapter.

### DEC-021 — Ownership of parallax `scrollX`
**Status:** Accepted · **Source:** this session · **Tracking:** issue #6 (assigned to Zarina)

`scrollX` is hoisted out of `ParallaxScrollView` into `SandboxViewModel` and passed down as a `Binding`. The entity layer needs the scroll offset to hit-test corals and pests; a second gesture handler would desync exactly where it hurts (momentum glide, rubber-band overscroll).

*Consequence:* `ParallaxScrollView` becomes a black box that receives a binding; all internal pan/clamp/overscroll logic is Zarina's and stays as written — wrap, do not rewrite. Her fork's newer work (rubber-band overscroll, per-layer segment widths) lands upstream first, then the signature change (~2 lines in her file). Bonus: `scrollX` becomes unit-testable from the sidecar package (DEC-022).

### DEC-022 — Domain-layer test strategy
**Status:** Accepted · **Source:** this session

Testing uses a **sidecar SPM package** with real `swift test` — zero `project.pbxproj` changes, so the most conflict-prone file in a 5-person sprint stays untouched. A proper Xcode test target and `#if DEBUG` harnesses were considered and rejected on conflict-risk and fidelity grounds respectively.

*Consequence:* the package can only compile against plain value types, which makes DEC-020 non-optional: `EcoEngine` moves to `step(state: ReefState, threats:) -> ReefState` over value snapshots, with a thin SwiftData adapter living in the app target. The refactor and the test suite land together.

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

### DEC-025 — Exhibition threat vectors benign; bleaching engine ships dormant
**Status:** Accepted · **Source:** this session

Resolves the DEC-010 conflict. The exhibition build's `ThreatVector`s never carry a heatwave — `waterTemperature` stays ≤ 30°C and `isHeatwaveActive` is never set. EcoEngine §D (heat stress, bleaching, recovery, bleached-coral mortality) therefore ships **dormant**: present in the binary, never triggered, untested, and invisible in UI.

*Why:* the maths is sound and matches the expert-validated 30°C threshold (Alex interview, 9 Aug). Ripping it out would discard correct work and guarantee a rewrite when bleaching returns as the prestige-restart loop. Keeping it dormant costs nothing at runtime.

*Consequence:*
- Exhibition gameplay scope is runoff shocks + pests only.
- **PRD §4.6 and §1.5 must be reconciled in the same PR** that lands this entry: bleaching moves from "MVP scope" to "engine-supported, exhibition-dormant."
- No test coverage required for §D in the DEC-022 suite; the prestige-restart revival will add it.

### DEC-026 — Gesture routing: tool gestures win on coral hit, pan wins on empty water
**Status:** Accepted · **Source:** this session

The parallax canvas pans on drag, and the Brush/Hand tools also act on drags — two gestures competing for the same finger. Routing is by *where the drag starts*: a drag beginning inside a coral's hit rect (DEC-019 model geometry) belongs to the active tool; a drag beginning on empty water or sand pans the world. There is no mode lock-in, and the user never has to think about which gesture layer is active.

*Why:* the alternatives all violate DEC-002 (entertainment-first). A "pan mode" toggle adds UI chrome the workflow doc bans; requiring tool deselection to pan punishes exploration; letting both fire means the world slides out from under a cleaning stroke.

*Consequence:* brush strokes and pest flicks are only recognized inside coral hit rects. Wide-spaced planting (DEC-006) keeps hit rects small relative to open water, so panning is never starved of space.

### DEC-027 — Tick cadence: 1 sim month per 5 real seconds
**Status:** Superseded by DEC-031 · **Source:** this session

While the Coral Screen is visible, the engine ticks one simulation month every 5 real seconds. One constant (`tickInterval`) owns the pacing.

*Why:* the maths was tuned for monthly steps (`baseGrowthRate 0.08` → ~12 months to maturity). At 5 s/month a well-cared coral reaches Adult in ~1 minute and neglect shows visible algae in ~30 s — fast enough for an exhibition demo loop, slow enough that care actions feel causal rather than frantic. Slower pacing (e.g. 30 s/month) would make a 5-minute visit show nothing, which breaks the visual-feedback mandate (PRD §3.3).

*Consequence:* Fast Forward remains the long-horizon view (5-year sweeps); ticks are the live texture. Exhibition hardware runs unattended for hours — pacing constants must stay in one place so a floor-test can retune without a code dive.

### DEC-028 — Pest spawning: 25%/tick on vulnerable corals, cap 2 per coral
**Status:** Accepted · **Source:** this session

Each tick, every living Baby/Teenager coral with no pests has a 25% chance to gain a Drupella snail. Maximum 2 pests per coral; Adults are spared (their recruited wrasses narratively keep them clean — this is the manual→automated arc made literal, PRD §3.2).

*Why:* pests must be frequent enough that the Hand tool gets used in a short visit, rare enough that a first-time player isn't ambushed during the guided plant. The vulnerability gate teaches the ecology (young corals need protection) without a word of text. The cap prevents a neglected coral from becoming an unsaveable pest pile in one absent stretch.

*Consequence:* spawning lives in `SandboxViewModel` (session behavior), not `EcoEngine` (which consumes `activePredators` as given). The one-time pest tooltip (DEC-012) triggers on the first spawn.

### DEC-029 — Additional planting unlocks at first Teenager coral
**Status:** Accepted · **Source:** this session

The frag palette (additional planting, workflow §2.3C) appears only after the first planted coral reaches the Teenager stage. Before that, planting is the guided cold open only.

*Why:* the workflow says planting opens "after the first coral proves healthy" but never defines healthy. Teenager (growth ≥ 0.3, ~4 well-kept months) is the first stage transition the player witnesses — the unlock *is* the reward for the first visible success, which is the Kolb loop (act → see result → new capability) in one beat. Unlocking earlier (on plant) spends the reward before it is earned; later (Adult) delays the core creative verb past a demo session's attention budget.

*Consequence:* "proves healthy" = reaches Teenager. If user testing shows players stall in Baby, revisit the threshold — it is one comparison in the view model.

### DEC-030 — Pest damage retuned to 0.02/month for demo-paced reaction time
**Status:** Accepted · **Source:** this session, found in simulator playtest

`basePredatorDamageRate` drops from 0.05 to 0.02 tissue/month per pest.

*Why:* playtesting on the simulator showed the original rate kills a two-snail coral in ~50 real seconds at the DEC-027 demo pace (5 s/month) — faster than a first-time player can discover the Hand tool, which violates the lean-toward-optimism difficulty rationale (Alex interview, 9 Aug) and makes the workflow's 75% damage warning pointless (only ~25 s separated warning from death). At 0.02, one snail threatens a coral over ~4 minutes of neglect, the warning leaves ~1 minute to react, and recruited wrasses (control 0.04) now fully neutralize a single snail — making the manual→automated arc (PRD §3.2) literally true: an adult's fish keep it pest-free.

*Consequence:* tests pin the new rate (`EcoEngineTests.snailInflictsBaseDamageWithoutWrasses`); if floor-testing shows pests feel toothless, retune the constant, not the structure. Related: the reef is paused during the guided cold open (ticks do nothing until the survivor is planted) so the tutorial can never kill the survivor — implemented with DEC-009's flow.

### DEC-031 — 7-day per-coral real-time lifecycle; backend growth + graceful catch-up
**Status:** Accepted · **Source:** this session

Each coral fragment has its own 7-day lifecycle anchored to its planting moment (`plantedAt`). 7 days is the **healthy best case** — algae smothering and pest damage *slow* the per-coral growth clock (prolong maturation, don't pause it); extreme neglect still kills. Care makes a coral grow faster. The old global sim-month clock and `tickInterval` (DEC-027) are gone.

**Backend growth + graceful catch-up on launch.** Growth advances on wall-clock time, including while the app is closed. Each `ReefCanvas` persists `lastSeenAt`. On launch, the engine computes elapsed real time since `lastSeenAt` and advances every coral — growth accrues and algae accumulates (nobody was brushing), **but nothing dies offline**. The return moment is a delightful reveal ("see how your reef changed"), not a punishment — algae creates an immediate care task (engagement), and the graceful no-death cap keeps the lean-toward-optimism rationale (Alex interview, 9 Aug) intact.

**Exhibition mode replaces the auto-tick with a Fast Forward button.** Visitors don't keep the app open for 7 days, and a 5-minute museum visit shows ~0 wall-clock growth. Instead of DEC-027's 5-sec/month auto-tick, the exhibition build exposes a **Fast Forward button** the visitor taps to jump the reef ahead through growth stages — the "grow it" dopamine beat. The personal (post-exhibition) app uses the 7-day real-time lifecycle + catch-up.

*Why:* "each coral grows for 7 days, start to finish" is the lifecycle age the product wants. It is ~10,000× slower than DEC-027's 5 s/month, so DEC-027's exhibition-demo rationale (a well-kept coral hits Adult in ~1 minute) cannot coexist with it. The split — real-time for the personal app, tap-to-advance for the exhibition — keeps both the long-term attachment fantasy (your reef lives over a week) and the museum demo loop (a visitor sees stages change in one tap).

*Consequences:*
- `CoralFrag` (SwiftData) and `CoralState` (domain) gain `plantedAt: Date`. `ReefCanvas` gains `lastSeenAt: Date`.
- `EcoEngine` growth becomes time-based: a coral's `growthProgress` is derived from elapsed healthy time since `plantedAt`, not an accumulating monthly scalar. The algae/pest slowdown modifiers from the monthly model are preserved as rate multipliers on the per-coral clock, so the pedagogy (care → faster growth) survives the rewrite. One constant (`maturationInterval`, 7 days) owns the healthy best-case pacing.
- Algae and pest dynamics keep their spatial-grid model (DEC-018) and rates (DEC-030), but advance by elapsed real time during catch-up and by the live tick during play — they are no longer coupled to the growth month count.
- The live tick (`tickLive`) stays, but it now advances a short wall-clock slice (the tick interval) instead of one sim month; it remains the driver for pest spawning (DEC-028) and the visual texture while the screen is visible. `tickInterval` is retuned from "1 sim month" to "the live refresh slice" — a small fraction of real time.
- Fast Forward is repurposed for exhibition: a tap jumps growth forward by a tunable stage increment (not the old 5-year sweep). The 5-year Diagnostic Card (workflow §2.3C) is revisited in a follow-up; for the MVP it becomes the stage-jump preview.
- DEC-030's pest rate (0.02/month) was calibrated against 5 s/month. Under real-time pacing the per-snail threat window is now ~days, not ~minutes — retune the constant after floor-testing, not the structure (same guidance as DEC-030).
- The reef stays paused during the guided cold open (DEC-009): catch-up does not run, and the survivor's clock does not start, until the survivor is planted.
- Tests: `EcoEngineTests` rewrite the growth assertions to elapsed-time form; new tests cover catch-up (offline growth, offline algae accrual, no offline death, per-coral independent clocks). `plantedAt` default keeps existing snapshots valid.

*Supersedes:* **DEC-027** (5 s/month auto-tick). DEC-030's *rate value* is revisited but its *structure* (modifier-based slowdown, no offline death during the tutorial) is preserved.

### DEC-032 — Single Sponge cleaning tool + bare-hand pest smush
**Status:** Accepted · **Source:** this session

The active tool palette is simplified to a single cleaning tool: the **Sponge** (`Tool/Sponge.imageset/sponge.svg`). When no tool is selected (default bare-hand state), clicking/tapping pests (snails) directly smushes them. Swiping with the Sponge cleans algae on the corals.

*Why:* Reduces cognitive overload and gesture conflicts for first-time exhibition players. Having a single clear cleaning tool alongside direct-touch interactions aligns with DEC-002 (entertainment-first, intuitive physical mechanics).

*Consequence:* The tool overlay displays the Sponge tool; when unselected (or in bare-hand mode), tapping on snails smushes them directly without having to switch to a Hand tool first.

### DEC-033 — Non-lethal pest impact: growth slowdown only, mortality disabled
**Status:** Accepted · **Source:** this session

Pests (snails) slow down coral growth rate rather than killing corals. Total tissue mortality from pest accumulation (`predatorDamage >= 1.0 -> isDead`) is disabled for the current sprint.

*Why:* Premature coral death during early discovery causes frustration before players learn the cleaning and smushing loops. Corals remain alive but visibly delayed in growth progress when infested, encouraging pest management without punishing curiosity.

*Consequence:* `EcoEngine` growth calculation preserves the slowdown factor `(1.0 - predatorDamage)` but removes the fatal mortality trigger on pests.

### DEC-034 — Off-screen snail wave spawning and height-squash smush interaction
**Status:** Accepted · **Source:** this session

Snails (`Enemy/Snail.imageset/snail.svg`) no longer instantly appear statically on coral bounding boxes. Instead, they spawn via a randomized timer in waves from off-screen margins, crawling towards active coral frags. When clicked/tapped, snails compress vertically (height-squash animation) and fade away.

*Why:* Creates dynamic visual life in the aquarium canvas and gives players a clear threat-approach window to react before pests attach and slow coral growth.

*Consequence:* Snail rendering uses the dedicated vector asset `Image("Snail")` instead of placeholder circles, with height-scale spring compression upon smush.

### DEC-035 — Audio SFX and ambient ocean loop integration
**Status:** Accepted · **Source:** this session, `Audio.md`

All 10 sound assets compiled in `Resources/Audio/` (`ambient_ocean_loop.wav`, `brush_swipe.wav`, `sparkle_clean.wav`, `frag_lift.wav`, `frag_plant.wav`, `pest_smush.wav`, `pest_flick.wav`, `pest_splash.wav`, `plant_reject.wav`, `threat_warning.wav`) are wired via a lightweight `AudioPlayerService` / `AVAudioPlayer` manager.

*Why:* Tactile and auditory feedback are critical for DEC-002 (entertainment-first satisfaction). Water immersion requires continuous subtle ocean ambience and immediate haptic/audio response on touch.

*Consequence:* Audio service lifecycle is managed in the view model / view layer, auto-starting ambient loop on canvas appearance.

### DEC-036 — Multi-species SVGs, NGO Config, and Shannon fauna visuals deferred
**Status:** Accepted · **Source:** this session

Multi-species SVG asset mapping (Brain, Elkhorn, Sponge, Table), external NGO configuration loading, and visual fauna silhouette spawning driven by the Shannon Index are deferred to the next sprint cycle. For this sprint, visual growth animation focuses on the Staghorn Lottie compositions (`coral.lottie`, `coral_lh.lottie`).

*Why:* Allows the team to complete and polish the end-to-end "sponge cake" care loop (sponge cleaning, snail waves, audio, growth pacing) before broadening the taxonomic palette and external configuration layers.

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
* `EcoEngine`'s doc comment claims it is stateless while it mutates its input in place. Direction resolved (DEC-020, Accepted): the refactor to value snapshots lands with the DEC-022 test work, and the comment is corrected in the same change.
* `CoralFrag`'s doc comments hard-code Lottie frame ranges (e.g. "algae ≥ 0.5 transitions playhead to frames 81–100"), baking the single-playhead model into the data layer. DEC-018 (Accepted) supersedes that approach — these comments describe a mapping we no longer use and should be rewritten with the layered-composition model.

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
