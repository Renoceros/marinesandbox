# User Workflow: Interactive Marine Sandbox (End-to-End)

**Document Version:** v1.0
**Status:** Approved (Supersedes PRD §4.2 Location Selection routing)
**Source Decisions:** Team-Discussion-12Aug (dead-rubble start, one survivor frag, tap-then-drag planting, single care screen) + PRD v1.3 + TDD v1.3

---

## 1. Flow Overview

The product is deliberately reduced to **one onboarding page and one interactive screen**. All gameplay, feedback, and progression happen on the Coral Screen; everything else is a modal layered on top of it.

```
+------------------+        +-----------------------------------------------+
|  0. LAUNCH       |        |  ROUTING (no screen)                          |
|  App opens       |------->|  First launch  -> Onboarding Page             |
+------------------+        |  Returning     -> Coral Screen (saved state)  |
                            +---------------------+-------------------------+
                                                  |
                                                  v
+---------------------------------------------------------------------------------+
|  1. ONBOARDING PAGE  (first launch only, single tap)                            |
|  Dead ocean visual. One line of context. "Tap to begin." No forms, no location  |
|  selection, no tutorial text.                                                    |
+---------------------------------------+-----------------------------------------+
                                        |
                                        v
+---------------------------------------------------------------------------------+
|  2. CORAL SCREEN  (THE screen — everything happens here)                        |
|                                                                                 |
|  First-launch state:  Dead seabed. White coral rubble. ONE surviving live       |
|                       Staghorn frag in the rubble.                              |
|                                                                                 |
|  Guided first plant:  tap frag -> frag lifts -> targeted ground pulses/glows    |
|                       -> user drags frag onto ground -> planted -> growth begins|
|                                                                                 |
|  Steady state:        Care loop, threats, growth stages, fauna recruitment,     |
|                       fast forward, share — all on this screen.                 |
+---------------------------------------+-----------------------------------------+
                                        |
              +-------------------------+-------------------------+
              |                         |                         |
              v                         v                         v
+----------------------------+ +-----------------------+ +------------------------+
| MODAL: Diagnostic Card     | | MODAL: Share Card     | | MODAL: Registration    |
| (after Fast Forward)       | | (camera button, 9:16) | | (first Adult coral)    |
+----------------------------+ +-----------------------+ +------------------------+
                                        |
                                        v
                            +------------------------+
                            | SETTINGS (gear icon)   |
                            | Hard Reset lives here  |
                            | only. Delete profile.  |
                            +------------------------+
```

---

## 2. Screen-by-Screen Specification

### 2.1. Screen 0 — Launch & Routing (no UI)

| Aspect | Specification |
| --- | --- |
| Purpose | Route the user without adding friction |
| Logic | `UserProfile` / saved `ReefCanvas` exists in SwiftData? -> Coral Screen : Onboarding Page |
| Interactions | None |

### 2.2. Screen 1 — Onboarding Page (first launch only)

| Aspect | Specification |
| --- | --- |
| Purpose | Set the emotional tone (a dead ocean waiting to be revived), then get out of the way |
| Contains | Full-bleed dead-reef visual; app title; a single line of context copy; one continue affordance |
| Interactions | **Single tap** anywhere (or one button) -> transition into Coral Screen. No location selection, no account form, no multi-page tutorial |
| Notes | Follows the no-classroom mandate (PRD §3.5–3.6): zero briefings, zero quizzes. Returning users never see this again |

### 2.3. Screen 2 — Coral Screen (the core screen)

**Layout:** `SandboxView` layered over `ParallaxScrollView` — 3 parallax layers (BG ratio 0.20, MG ratio 0.50, FG ratio 1.00 over `#3BAFED` backdrop), 3 stitched segments of 1.5x viewport width, scroll clamped to `[-3.5 x viewportWidth, 0]`.

#### A. First-launch state: "Dead Ocean"

| Aspect | Specification |
| --- | --- |
| Contains | White coral rubble across the foreground; exactly **one living Staghorn (Acropora) fragment** visible in the rubble (the only color in the scene); sparse blue water and sand in BG/MG |
| Interactions | **Horizontal drag-pan** with momentum glide (clamped at both ends); **tap the live frag** to begin the guided plant |

#### B. Guided first plant (implicit tutorial, no text)

1. User **taps the surviving frag** -> it visually lifts / highlights.
2. A **targeted area on the seabed pulses and glows** — the only other highlighted element, so the user instinctively connects the two.
3. User **drags the frag onto the highlighted seabed** -> frag snaps in, planting confirmed with a small satisfying feedback (settle animation / particle puff).
4. Growth begins; the screen transitions into steady state.

*Optional fallback:* if the user taps the glowing ground area instead of dragging, the frag auto-flies into place. Never hard-block the user.

#### C. Steady state: the care loop

| Element | Specification |
| --- | --- |
| Coral growth | Baby -> Teenager -> Adult, rendered by `LottieCoralView` frame-scrubbing (`growthProgress` 0.0 -> 0.6). Baby/Teenager corals are algae-vulnerable |
| Threats | Algae moss layer (`algaePercentage`), snail/starfish pests (`predatorDamage` > 75% triggers warning). First-time pest encounter shows a one-time tooltip |
| Care tools | On-canvas tool overlays (no side dashboard, no sliders): **Brush Tool** and **Hand Tool** |
| Fauna recruitment | Midground renders recruited fish matching growth stage: small reef fish -> gobies/damselfish -> schools, parrotfish, wrasses. Adult corals automate care (herbivores graze algae, wrasses eat pests) |
| World feedback | As the reef matures: water visibly clears, more fauna appears. Monoculture/neglect -> brown algae graveyard. Success -> vibrant automated reef |
| Additional planting | After the first coral proves healthy, the user may plant additional frags **anywhere** on the continuous foreground (no grid, no sub-zones) |
| Controls | Fast Forward button; camera (share) button; bioluminescent night-mode toggle; settings gear |

| Interaction | Detail |
| --- | --- |
| Drag-pan | Horizontal pan with momentum glide; hard clamp at segment boundaries |
| Brush algae | Select Brush -> swipe over mossy coral -> algae wipes away per-swipe; sparkle effect on fully clean |
| Remove pests | Select Hand -> **tap to smush** a snail/starfish, or **drag-flick** it off-screen (release velocity > 100 pt/s -> physics throw; despawn past viewport bounds; sparkle on success) |
| Plant frag | Drag frag from rubble/palette onto any empty position on the seabed foreground |
| Fast Forward | Simulates 5–10 years -> plays visual timelapse morph of the reef -> opens Diagnostic Card |

---

## 3. Modals (layered on the Coral Screen)

### 3.1. Diagnostic Card (`DiagnosticCardView`)

| Aspect | Specification |
| --- | --- |
| Trigger | Automatically after every Fast Forward timelapse completes |
| Contains | Plain-language ecological reflection of the steady-state outcome (e.g. "Your Brain Coral was smothered — Acropora planted too close grows faster"). Visual before/after, not number dashboards |
| Interactions | Read -> **dismiss** back to canvas to adjust the reef (Kolb: reflective observation -> active experimentation) |

### 3.2. Registration Prompt

| Aspect | Specification |
| --- | --- |
| Trigger | First coral reaches Adult stage |
| Contains | "Create a login to save your reef" — MVP: local profile name only. Production: Sign in with Apple (Face ID); local mapping is tracked as tech debt `DEBT-002` |
| Interactions | Register, or **dismiss and keep playing locally** — never blocks gameplay |

### 3.3. Share Card (`ShareCardView`)

| Aspect | Specification |
| --- | --- |
| Trigger | Camera button on the Coral Screen |
| Contains | 9:16 vertical postcard: HD snapshot of the reef, reef name, diversity score, NGO tag ("Padangbai, Living Seas") |
| Interactions | Preview -> **export via iOS share sheet** (Instagram Stories / Snapchat / Messages) -> dismiss |

### 3.4. Settings

| Aspect | Specification |
| --- | --- |
| Trigger | Gear icon on the Coral Screen |
| Contains | **Hard Reset** (wipe to barren rubble — deprecated from gameplay UI, lives here exclusively); delete profile & data (App Store / COPPA-GDPR compliance); account management |
| Interactions | Each destructive action behind a confirmation sheet |

---

## 4. Explicitly Removed / Out of Scope

* **Location / NGO Selection Screen** — removed. No location picker anywhere in the flow (Bali/Living Seas is the implicit default for MVP; Jeju and Caribbean remain roadmap config items, not user-facing choices).
* **Reef Star structures** — removed. Users plant coral fragments directly on the seabed ground/rubble, simplifying the interaction model.
* **Hard Reset in gameplay UI** — Settings only.
* **Plantation sub-zones** — planting is freeform anywhere on the foreground.
* **Number dashboards / sliders** — all feedback is visual (timelapse morphs, world-state changes) plus the Diagnostic Card.
* **Bleaching / Marine Heatwave loop** — deferred for the exhibition build per Team-Discussion-12Aug; may return as a "prestige restart" achievement loop. (Note: PRD §4.6 still lists bleaching as MVP — docs to be reconciled.)
* **Global Map, QR scanning, CloudKit sync** — roadmap stubs only (`GlobalMapView`, `QRScannerService`, `CloudKitSync`).

---

## 5. Design Invariants (apply to every screen)

1. **Entertainment first:** every interaction must feel satisfying to touch (momentum, springs, particles). If it feels like homework, it has failed.
2. **No classrooms:** no multi-step tutorials, briefings, or quizzes. Scaffolding is implicit — glow, pulse, and immediate visual reaction.
3. **One screen:** never navigate the user away from the Coral Screen for core gameplay; use overlays/modals instead.
4. **Mechanics are the teacher:** every ecological concept is taught by cause-and-effect on screen, never by text walls.
