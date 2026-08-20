# 🌊 Interactive Marine Sandbox

An entertainment-first, implicitly educational iOS sandbox where you plant corals, brush off algae, and let a living reef grow under your fingertips. Built for high-school conservation-workshop alumni who want to keep playing with the ecosystem after they fly home — not read another newsletter about it.

> **Not a quiz. Not an encyclopedia.** If it ever feels like one, that's a bug ([DEC-002](DECISIONS.md#dec-002)).

---

## What it is

A two-screen, SwiftUI + SwiftData app for iPhone and iPad (targeting iPhone 17). You land on a single coral survivor in a dead rubble field, plant your first frag, and enter a tactile care loop:

- **Brush** algae off corals, stroke by stroke, with sparkle feedback.
- **Plant** new fragments anywhere along the continuous foreground.
- **Smush & flick** Drupella snails before they graze your reef to rubble.
- **Fast Forward** the simulation and read a plain-language diagnostic card of what happened.
- **Unlock** a frag palette once your first coral reaches teenager stage.

Beneath the polish runs a pure, unit-tested `EcoEngine`: Shannon diversity, herbivore/predator recruitment scaled by biodiversity, algae overgrowth, pest damage, and (dormant, post-MVP) thermal bleaching. Threat vectors in the Bali/Living Seas exhibition preset never exceed 30 °C, so bleaching is parked for a future "prestige restart" loop ([DEC-025](DECISIONS.md#dec-025)).

## Why it exists

Field conservation programs (e.g. Living Seas, Bali) create strong emotional bonds on-site — and then engagement collapses the moment students go home. Passive follow-ups (emails, social posts) can't match the hands-on, decision-driven nature of real restoration. Marine Sandbox closes that gap with a toy-box reef you *want* to open recreationally, where the ecology is learned by feel, not by reading. See the [PRD](Documentation/prd_marine_sandbox.md) for the full vision and the "Maximia" persona.

## Tech stack

| | |
| --- | --- |
| Platform | iOS 26.5, Xcode 26.6, Swift 5.0 language mode |
| UI | SwiftUI, MVVM+S |
| Persistence | SwiftData |
| Dependencies | [`lottie-spm` 4.6.1](https://github.com/airbnb/lottie-spm) for coral lifecycle rendering (DEC-017). |
| Tests | Domain layer, via a sidecar SPM package ([DEC-022](DECISIONS.md#dec-022)) |
| Bundle | `com.molamola.marinesandbox` |

The domain layer (`marinesandbox/Domain/`) is pure Swift — no SwiftUI, no SwiftData — so it can be reasoned about and tested in isolation ([DEC-020](DECISIONS.md#dec-020)). A sidecar package (`MarineSandboxDomain/`) symlinks those same files and runs 36 tests against engine maths, algae-grid brushing, flick physics, and coral hit-testing — without ever touching `project.pbxproj`.

## Project layout

```
marinesandbox/
├── marinesandbox/            # App target (file-system synchronized groups)
│   ├── Domain/               # Pure Swift: EcoEngine, Physics, AlgaeCoverage, CoralGeometry
│   ├── Models/               # SwiftData models: ReefCanvas, CoralFrag, UserProfile, NGOConfig
│   ├── ViewModels/           # SandboxViewModel
│   ├── Views/                # Canvas, Modals, GlobalMap
│   ├── Services/             # CloudKitSync, QRScannerService (post-MVP seams)
│   ├── RootView.swift        # Launch router: saved canvas vs. onboarding
│   └── Assets.xcassets/      # BG/MG/FG parallax SVGs, coral growth stages, frags
├── MarineSandboxDomain/      # Sidecar SPM test package (symlinks Domain/)
├── Documentation/            # PRD, TDD, user workflow, sprint plan, transcripts
├── AGENTS.md                 # Working-in-this-repo context
├── CONTRIBUTING.md           # Branch → PR → merge workflow
├── DECISIONS.md              # Decision register (the source of truth)
└── CHANGELOG.md              # Keep a Changelog
```

## Build

```bash
xcodebuild -project marinesandbox.xcodeproj -scheme marinesandbox \
  -destination 'generic/platform=iOS Simulator' build
```

Filter the noise with `| tail -20` and look for `** BUILD SUCCEEDED **`. This is the verification gate for every PR.

## Test the domain layer

```bash
cd MarineSandboxDomain && swift test
```

## Documentation

Where docs disagree, [DECISIONS.md](DECISIONS.md) wins — and the loser gets fixed in the same PR.

| File | Purpose |
| --- | --- |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Branch, commit, review, and merge workflow |
| [DECISIONS.md](DECISIONS.md) | Why things are the way they are (decision register + tech debt) |
| [CHANGELOG.md](CHANGELOG.md) | What changed, and when |
| [Documentation/prd_marine_sandbox.md](Documentation/prd_marine_sandbox.md) | Product requirements, persona, pedagogy |
| [Documentation/tdd_marine_sandbox.md](Documentation/tdd_marine_sandbox.md) | Technical design, data models, parallax maths, backlog |
| [Documentation/user_workflow_marinesandbox.md](Documentation/user_workflow_marinesandbox.md) | End-to-end screen flow and interactions |
| [Documentation/frontend_handoff.md](Documentation/frontend_handoff.md) | What's built vs. mock in the current UI |
| [Documentation/sprint_task_breakdown.md](Documentation/sprint_task_breakdown.md) | Day-by-day plan and task ownership |

## Contributing

Five people commit in parallel on a two-week sprint, so the workflow is strict:

1. **Never commit to `main`.** All work happens on a feature branch.
2. **Always branch off the latest `main`** — every time, including the next morning.
3. **Every change reaches `main` through a pull request.**

```bash
git checkout main && git pull origin main
git checkout -b feat/<your-name>/TASK-MVP-104-physics
# ...commit...
git push -u origin <branch>
# open a PR → review + green build → merge, delete branch
```

Branches follow `feat/{developer-name}/{TASK-ID-description}`. Commits use `type: Imperative summary` (`feat`, `fix`, `docs`, `refactor`, `style`, `chore`, `merge`).

Every PR adds a line to `[Unreleased]` in [CHANGELOG.md](CHANGELOG.md). Anything that changes scope, architecture, or UX also adds a `DEC-` entry to [DECISIONS.md](DECISIONS.md). Full rules in [CONTRIBUTING.md](CONTRIBUTING.md).

### Adding Swift files

The project uses file-system synchronized groups (`objectVersion 77`), so any `.swift` file created on disk inside `marinesandbox/` joins the app target automatically — **no `.pbxproj` edit needed.** That file is the most merge-conflict-prone artifact in the repo; avoid touching it.

## Roadmap

**In scope (2-week MVP):** core care loop, pure `EcoEngine`, 3-layer parallax seabed, Bali/Living Seas preset, local saves, vertical share card.

**Deferred:** thermal bleaching / marine-heatwave recovery (engine-ready, dormant), Jeju & Caribbean region modules, QR "amiibo" scan rewards, CloudKit sync, global social map.

## License

Proprietary. All rights reserved by the Marine Sandbox team. See the repo maintainers before reusing assets or source.
