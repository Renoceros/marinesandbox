# Contributing

How we work on the Interactive Marine Sandbox. Five people are committing in parallel on a two-week sprint, so the rules below exist to keep `main` releasable and merges boring.

## The three rules

1. **Never commit to `main`.** All work happens on a feature branch.
2. **Always branch off the latest `main`** — every single time you start work, including when you come back to a task the next morning.
3. **Every change reaches `main` through a pull request.**

## The loop

```
  git checkout main            ┌──────────────────────────────┐
  git pull origin main   ──▶   │  branch off the LATEST main  │
                               └───────────────┬──────────────┘
                                               ▼
                                   feat/bishal/TASK-MVP-104-physics
                                               │  commit ... commit
                                               ▼
                                   git push -u origin <branch>
                                               │
                                               ▼
                                      Pull Request → main
                                               │  review + green build
                                               ▼
                                            merge, delete branch
```

### 1. Start from the latest main

Do this **before every new piece of work**. Branching off a stale `main` is how you end up resolving someone else's merge conflicts inside your own feature.

```bash
git checkout main
git pull origin main
git checkout -b feat/bishal/TASK-MVP-104-physics
```

### 2. Branch naming

`{type}/{your-name}/{TASK-ID}-{short-description}` — per TDD §6.

| Type | Use for |
| --- | --- |
| `feat` | New functionality |
| `fix` | Bug fixes |
| `docs` | Documentation only |
| `refactor` | Restructuring with no behaviour change |
| `ui` | Visual and layout work |

Examples: `feat/bishal/TASK-MVP-104-physics`, `ui/zarina/TASK-MVP-102-parallax`, `docs/reno/decision-register`.

For unplanned work, drop the task ID: `fix/bobo/coral-tap-target`.

### 3. Commit messages

`type: Imperative summary of what changed`

```
feat: Add coverage-grid algae model and brush stroke clearing
fix: Stop foreground images letterboxing on tall devices
docs: Record Lottie composition decision as DEC-018
```

Explain **why** in the body when the reason is not obvious from the diff. Your teammates read these to understand decisions six days later.

### 4. Keep your branch current

If your branch has been open for more than a day, or `main` has moved:

```bash
git checkout main && git pull origin main
git checkout <your-branch>
git merge main            # resolve conflicts here, not in the PR
```

**Do not rebase or force-push a branch you have already pushed.** Someone may have it checked out, and rewriting shared history is how work disappears. Merging `main` in is always safe.

### 5. Open the pull request

Base is always `main`. Fill in the template — it is short on purpose.

Your PR is ready when:

- [ ] It builds: `xcodebuild -project marinesandbox.xcodeproj -scheme marinesandbox -destination 'generic/platform=iOS Simulator' build`
- [ ] You ran it on a simulator and the core loop still works
- [ ] `CHANGELOG.md` has an entry under `[Unreleased]`
- [ ] `DECISIONS.md` has a `DEC-` entry if you changed scope, architecture, or UX
- [ ] The branch is based off a recent `main`

Keep PRs small. A 200-line PR gets reviewed properly; a 2,000-line PR gets an approving emoji.

### 6. Review and merge

- At least one teammate reviews before merge. On a hackathon clock, "read it and say go" is a legitimate review — a rubber stamp is not.
- The author merges once approved and green. Do not merge someone else's PR without asking.
- Delete the branch after merging.
- If you must merge something urgently without review, say so in the PR and tag the affected owner.

## Repository access

`main` lives in `Renoceros/marinesandbox`.

**With write access:** push branches directly to `origin` and open the PR from there.

**Without write access:** fork, push branches to your fork, and open the PR against `Renoceros/marinesandbox:main`.

```bash
gh repo fork Renoceros/marinesandbox        # once
git remote add fork https://github.com/<you>/marinesandbox.git
git push -u fork <your-branch>
gh pr create --repo Renoceros/marinesandbox --base main --head <you>:<your-branch>
```

Ask Reno for collaborator access if you are pushing regularly — the fork flow adds friction to every PR.

## Xcode-specific gotchas

**Do not touch `project.pbxproj` unless you have to.** It is the most merge-conflict-prone file in the repo. You usually do not need to: the project uses **file-system synchronized groups**, so any `.swift` file you create inside `marinesandbox/` joins the target automatically. Adding a new *target* (e.g. tests) does require it — flag that in the PR so others can rebase.

Never commit `xcuserdata/`, `DerivedData/`, or `.DS_Store`. They are gitignored; keep it that way.

Two people editing the same view file will conflict. Coordinate in chat before working inside `ParallaxScrollView.swift`, `SandboxView.swift`, or `SandboxViewModel.swift`.

## Resolving conflicts in the shared records

For `CHANGELOG.md` and `DECISIONS.md`, **keep both sides**. These are append-only logs; a conflict means two people documented different things, not that one is wrong. Never resolve by deleting a teammate's entry.

If two people claim the same `DEC-` number, the one merged first keeps it; the other renumbers.

## Definition of done

A task is done when it is **merged into `main`**, builds clean, and the decision and changelog records reflect it. Not when it works on your machine.
