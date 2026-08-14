# Frontend Handoff: What's Built, What's Mock, What's Yours

**Audience:** Reno, Bobo, Zarina, Sam · **Author:** Bishal's lane (backend & physics) · **Date:** 2026-08-14

The domain layer, physics, and a **playable mid-fi care loop** are built and tested. Everything visual in `SandboxView` is deliberately **mock-quality** — it exists to prove the interaction logic and give you something to reskin, not to ship. This doc is the map of what to keep, what to replace, and what contracts are stable.

---

## 1. What's real (keep — tested, decision-backed)

| Piece | Where | Notes |
| --- | --- | --- |
| Simulation engine | `Domain/EcoEngine.swift` | Pure `step(state:threats:months:)`, 43 tests green via `MarineSandboxDomain/` package (DEC-020/022) |
| Algae spatial grid | `Domain/AlgaeCoverage.swift` | 6×6 per coral; brush + fish graze the same grid (DEC-018). **Final art must mask per-cell** — the grid API is stable |
| Hit-test geometry | `Domain/CoralGeometry.swift` | Per-stage footprints from Sam's SVG viewBoxes. Hit-test this, never artwork (DEC-019) |
| Physics | `Domain/Physics.swift` | Flick threshold 100 pt/s, ballistic throw, drop clamping — pinned by tests |
| Session/gameplay logic | `ViewModels/SandboxViewModel.swift` | Guided plant, tool actions, pest spawning, tick, Fast Forward, diagnostic text |
| Routing | `RootView.swift` | Saved canvas → Coral Screen, else onboarding (DEC-008) |
| Assets | `Assets.xcassets/Coral/` | Sam's SVGs, vector-preserved. Stage→asset mapping lives in `CoralGeometry` |

## 2. What's mock (replace freely — nothing here is a contract)

| Mock | Replace with | Contract to preserve |
| --- | --- | --- |
| Algae = blurred brown rounded-rect haze | DEC-018 layered Lottie: looping algae overlay masked by the 6×6 grid | `CoralFrag.algaeCells` / `AlgaeCoverage` per-cell clearing |
| Pests = brown circles positioned by index | Real snail/starfish art (independent entities per DEC-018) | `activePredators` array; removal via `removePest(at:on:)` |
| Tool overlay = three SF Symbol circles | Designed tool picker | Tools stay on-canvas overlays — no dashboard, no sliders (DEC-007) |
| Fast Forward = plain capsule button | Designed control | Calls `performFastForward()`; diagnostic card appears after |
| Diagnostic Card = plain material card | Designed card + visual before/after (workflow §3.1) | Plain-language text from `diagnosticMessage`; dismiss → back to canvas |
| Frag palette = Fragment1 thumbnails in a row | Designed palette/rubble drag source | Appears only when `isPlantingUnlocked` (DEC-029) |
| Guide pulse = white ellipse | Designed glow/pulse on seabed | Tapping it auto-plants (workflow §2.3B fallback — never hard-block) |
| Onboarding = dark screen + 3 lines of text | Sam's dead-reef visual | Single tap, zero forms/tutorials (DEC-002, workflow §2.2) |
| Pest flick throw = fixed 900pt hop | Ballistic arc from `Physics.throwPosition` / `despawnTime` | 100 pt/s flick threshold; despawn past viewport (DEC-012) |

## 3. Interaction rules that are *not* mock (don't redesign these without a DEC)

- **Gesture routing (DEC-026):** touches starting on a coral belong to the active tool; drags on empty water pan the world. Coral views carry their own gestures — preserve that stacking when you restyle.
- **Tick cadence (DEC-027):** 1 sim month per 5 s, single constant `SandboxViewModel.tickInterval`. Retune the constant after floor-testing, not the structure.
- **Cold open is paused:** nothing grows/spawns/dies until the survivor is planted. The tutorial cannot kill the coral.
- **Survivor glow:** the unplanted survivor is the only color in the scene (DEC-009). Living babies render colored (`ShinyFragment`), dead babies render gray rubble (`Fragment1`) — mapping is in `CoralGeometry.footprint`, keyed off `isDead`.
- **Pest difficulty (DEC-030):** 0.02 damage/month — found via playtest; 0.05 killed corals in under a minute.

## 4. Known seams & conflicts

- **Zarina's PR #10 vs this branch:** both hoist `scrollX` into `SandboxViewModel`. Hers uses `CGFloat`, this branch currently bridges `Double`. **Merge #10 first**; this branch will adopt her `ParallaxScrollView` verbatim and switch the view model to `CGFloat`.
- **`Color(hex:)`** still lives in `ParallaxScrollView.swift` — move it to a design-system file when someone creates one (known issue in DECISIONS.md).
- **iPad:** in scope (DEC-016) but visually unchecked — the care loop is viewport-relative so it should run; needs a size-class pass.
- **Vermin/tooltip copy** is placeholder-terse. Final copy is a product call.

## 5. Verify your changes

```bash
# Build gate (every PR)
xcodebuild -project marinesandbox.xcodeproj -scheme marinesandbox \
  -destination 'generic/platform=iOS Simulator' build

# Domain tests (touch Domain/? run these)
cd MarineSandboxDomain && swift test
```
