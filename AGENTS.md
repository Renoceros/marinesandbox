# Working in this repository

Context for humans and AI coding agents. Read this before making changes.

## Non-negotiable

**Work on a feature branch cut from the latest `main`, and merge back through a pull request.** Never commit to `main`. Full workflow in **[CONTRIBUTING.md](CONTRIBUTING.md)** (DEC-023).

Every change updates **[CHANGELOG.md](CHANGELOG.md)** under `[Unreleased]`.
Every change that alters scope, architecture, or UX also adds a `DEC-` entry to **[DECISIONS.md](DECISIONS.md)**.

Decisions made in meetings must be written to `DECISIONS.md` before the branch merges. Several early decisions were only captured in a transcript and were nearly lost — that is why the register exists. Never rewrite an accepted decision; supersede it with a new entry instead.

## Project facts (verified 2026-08-13)

| Item | Value |
| --- | --- |
| Platform | iOS **26.5** deployment target, Xcode 26.6, Swift **5.0** language mode |
| Stack | SwiftUI + SwiftData, MVVM+S (see TDD §2) |
| Dependencies | **None.** No SPM packages. Lottie is *not* installed yet (see DEC-017) |
| Test target | **None** (see DEC-022) |
| Bundle / team | `com.molamola.marinesandbox` / `N8Y7P4HS74` |
| Devices | iPhone + iPad family, though the parallax spec targets iPhone 17 |

## Build & verify

```bash
# Build (this is the verification gate for every PR)
xcodebuild -project marinesandbox.xcodeproj -scheme marinesandbox \
  -destination 'generic/platform=iOS Simulator' build
```

Filter noisy output with `| tail -20`; look for `** BUILD SUCCEEDED **`.

## Adding files

The project uses **file-system synchronized groups** (`objectVersion 77`), so **any `.swift` file created on disk inside `marinesandbox/` joins the target automatically** — no `.pbxproj` edit needed. This matters: `project.pbxproj` is the most merge-conflict-prone file in the repo with five people working in parallel. Avoid touching it. Adding a test target is the one case that requires it, which is why DEC-022 is still open.

## Documentation map

| File | Purpose |
| --- | --- |
| `CONTRIBUTING.md` | How we branch, commit, review, and merge |
| `DECISIONS.md` | Why things are the way they are. Decision register + tech debt |
| `CHANGELOG.md` | What changed, when |
| `Documentation/prd_marine_sandbox.md` | Product requirements, personas, pedagogy |
| `Documentation/tdd_marine_sandbox.md` | Technical design, data models, parallax maths, task backlog |
| `Documentation/user_workflow_marinesandbox.md` | End-to-end screen flow and interactions |
| `Documentation/frontend_handoff.md` | What's built vs. mock in the current UI, and the stable contracts frontend builds against |
| `Documentation/sprint_task_breakdown.md` | Day-by-day plan and task ownership |
| `Documentation/Transcription/` | Interview and meeting transcripts (source material for decisions) |

Where docs disagree, `DECISIONS.md` wins, and the loser should be fixed in the same PR.

## Conventions

- **Branches:** `feat/{developer-name}/{TASK-ID-description}` (TDD §6), e.g. `feat/bishal/TASK-MVP-104-physics`.
- **Commits:** `type: Imperative summary` — `feat`, `fix`, `docs`, `refactor`, `style`, `chore`, `merge`.
- **Design system:** spacing on a 4/8 grid, semantic colours, one font family. Shared helpers (e.g. `Color(hex:)`) belong in a design-system file, not inside a view.
- **Interactions hit-test model geometry, never artwork bounds** (DEC-019) — art must stay swappable while designers iterate.
- **The domain layer stays pure:** no SwiftUI or SwiftData imports in ecology or physics code, so it can be reasoned about and tested (DEC-020).
- **This is an entertainment-first product** (DEC-002). Motion polish and tactile feedback are requirements. Anything that reads like a quiz or an encyclopedia is a bug.
