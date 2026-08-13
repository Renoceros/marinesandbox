# Changelog

All notable changes to the Interactive Marine Sandbox are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The project is pre-release and unversioned, so entries are grouped by date until the first tagged build.

## How the team maintains this file

1. **Every PR adds a line to `[Unreleased]`.** No exceptions — a PR with no user- or developer-visible effect probably should not exist.
2. Write for **the person who has to explain the build to someone else**, not for the compiler. "Fixed coral flicker while panning" beats "removed @ViewBuilder".
3. Use the standard groups: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.
4. If the change also settles a scope, architecture, or UX question, add a `DEC-` entry in [DECISIONS.md](DECISIONS.md) and reference it here.
5. On release, rename `[Unreleased]` to the version and date, and open a fresh `[Unreleased]`.
6. Resolve merge conflicts in this file by **keeping both lines**. Never drop a teammate's entry.

---

## [Unreleased]

### Added
- Contributing guide (`CONTRIBUTING.md`): feature-branch workflow, always branch off the latest `main`, PR into `main`, branch naming, conflict handling for the shared records, and the fork flow for contributors without write access (DEC-023).
- Decision register (`DECISIONS.md`) consolidating every scope, architecture, and UX decision from the docs, the 12 Aug team discussion, and the commit history, plus the tech-debt register (DEBT-001, DEBT-002) and a superseded/rejected log.
- This changelog.
- End-to-end user workflow spec (`Documentation/user_workflow_marinesandbox.md`): two-screen flow, per-screen contents and interactions, the four modals, and an explicit out-of-scope list (DEC-008).

### Changed
- Onboarding routes straight into the Coral Screen; Bali/Living Seas is now an implicit default rather than a user choice (DEC-008).
- Sprint plan now links the workflow spec instead of a "User Journey specification" that never existed.
- TDD §6 now points at `CONTRIBUTING.md` for the full development workflow.
- `ReefCanvas` database model links `coralFrags` directly instead of wrapping them in `placedStructures` (DEC-024).
- `CoralFrag` schema tracks `xPos` and `yPos` coordinates directly on the seabed, supporting vertical wall positioning (DEC-024).
- `EcoEngine` processes `coralFrags` directly instead of mapping placed structures (DEC-024).

### Deprecated
- `TASK-MVP-204` ("Build Location Selection Screen and user routing") is void as written and needs rescoping (DEC-008).

### Removed
- `PlacedStructure` SwiftData model class (DEC-024).
- Reef Star structural frames from database schemas, user workflow, and PRD descriptions (DEC-024).

### Open questions blocking work
- **DEC-016** — iOS 26.5 deployment target, Swift 5 language mode, and iPhone+iPad device family have never been explicitly agreed; they are Xcode template defaults.
- **DEC-021** — who owns parallax `scrollX`. Blocks the interactive entity layer.
- **DEC-022** — domain test strategy; no test target exists yet.
- **DEC-010 conflict** — PRD §4.6 and §1.5 treat thermal bleaching as MVP scope and `EcoEngine` now implements it, but the 12 Aug discussion deferred it. Must be reconciled before Phase 3.
- **DEC-020** — `EcoEngine` documents itself as stateless but mutates its `@Model` input in place, so Fast Forward cannot preview a steady state without committing it.

---

## 2026-08-13

### Added
- SwiftData domain models: `UserProfile`, `ReefCanvas`, `PlacedStructure`, `CoralFrag`, plus `ThreatVector` for environmental parameters (TASK-MVP-201).
- `EcoEngine` stateless simulation maths: Shannon diversity index, biodiversity-scaled herbivore and predator recruitment, growth constrained by algae and pest damage, agricultural-runoff nutrient shocks, heat-stress bleaching with a recovery path, and mortality triggers (TASK-MVP-101).
- Rubber-band overscroll resistance on the parallax canvas, so panning past either boundary resists instead of stopping dead.
- Inline documentation and header comments across the new source files.

### Changed
- Parallax segment width now scales per layer, so slower-ratio layers can pan all 3 stitched segments into view (DEC-015 amendment).
- Sprint calendar skips the TechDemo phase and starts directly on MVP views; team roles updated to the five-member roster (DEC-004).
- Planting is now freeform anywhere along the continuous foreground — sub-zones removed (DEC-006).
- Canvas controls are mid-fidelity on-canvas overlays instead of a side dashboard with sliders (DEC-007).

### Added
- 2D canvas physics specification: entity state vectors, drag and flick interaction modes, Euler integration with friction damping, a 100 pt/s flick threshold, and despawn boundaries (TDD §5.3).

### Deprecated
- Hard Reset removed from the core gameplay UI; it now lives only in the Settings menu to prevent accidental data loss (DEC-005).

### Removed
- `Documentation/techdemo_tdd_marinesandbox.md` — the TechDemo phase was skipped (DEC-004).

---

## 2026-08-12

### Added
- BG, MG, and FG parallax art assets, with image sets and directories wired into `Assets.xcassets`.
- `Team-Discussion-12Aug` transcript and summary — the source for the dead-rubble cold open, the care tools, and the authentication decision (DEC-009, DEC-011, DEC-012).
- Entertainment-first and subliminal-learning positioning documented in the PRD (DEC-002).

### Changed
- Parallax is now exactly 3 stitched segments with horizontal scrolling clamped to `[minScroll, 0.0]`, and each column gets a mutually exclusive layer variant so identical vertical stacks cannot occur (DEC-015).
- Rebuilt `ParallaxScrollView` around static view-index recycling for smooth, glitch-free scrolling.
- Layout spec settled on top-pinned BG/MG and bottom-pinned FG.

### Fixed
- Images no longer crossfade while panning: `ForEach` binds to column IDs and identity transitions suppress implicit animations.
- Image assets load by direct global name, working around the xcassets folder-namespace restriction.
- Resolved the iOS 26+ `UIScreen` deprecation by taking viewport size from a `GeometryReader` binding instead.
- Several compiler errors from `@ViewBuilder` misuse in `renderBlockView`.

---

## 2026-08-11

### Added
- Initial MVVM+S source structure and the first `EcoEngine` implementation (DEC-013).
- Infinitely tiling `ParallaxScrollView` with 3 layers and 9 block views, plus natural swipe handling — later replaced by the fixed 3-segment approach (DEC-015).
- `ContentView` renders `ParallaxScrollView` as the root view.
- Warm tropical palette and momentum-glide scroll physics.
- PRD, TDD, and sprint task breakdown, including the advanced parallax micro-animation roadmap.
- Team profiles and task-board assignments aligned across the TDD and sprint plan.

### Changed
- Parallax retargeted to the iPhone 17 base model at 1.5× viewport segment width, accepting asymmetrical generation as technical debt (DEBT-001).

### Fixed
- `path.close()` → `path.closeSubpath()` compiler errors.
- Restored `LightRayShape` and `FishSilhouette` and fixed `Angle` type-inference errors.
