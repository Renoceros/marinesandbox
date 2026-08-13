## What changed

<!-- One or two sentences. What does this do for the player or the developer? -->

## Task

<!-- e.g. TASK-MVP-104. Use "none" for unplanned work and say why. -->

## Checklist

- [ ] `CHANGELOG.md` — added an entry under `[Unreleased]` in the right group
- [ ] `DECISIONS.md` — added a `DEC-` entry **if** this changes scope, architecture, or UX (or ticked N/A below)
- [ ] N/A — no scope, architecture, or UX decision in this PR
- [ ] Builds clean: `xcodebuild -project marinesandbox.xcodeproj -scheme marinesandbox -destination 'generic/platform=iOS Simulator' build`
- [ ] Ran it on a simulator and the core loop still works
- [ ] New technical debt is recorded in the `DECISIONS.md` debt register with a `DEBT-` ID

## Decisions taken here

<!-- List DEC- IDs added or superseded. Verbal meeting decisions count — write them down here
     before merging, or they get lost (which is exactly why DECISIONS.md exists). -->

## Notes for reviewers

<!-- Anything load-bearing, risky, or worth a second opinion. -->
