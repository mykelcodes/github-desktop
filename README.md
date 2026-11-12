# Native GitHub client for macOS

Local prototype 0.1 · 12 November 2026 · Product name to be decided

A Swift macOS application that brings GitHub collaboration and a full local Git client into one native workspace. The intended audience is individual developers and small teams. Advanced Git history editing is required for the first public release.

The first runnable prototype is **Git Workspace** (a working name). It connects existing local Git repositories, remembers folders, shows branch/remotes/tracking state, and previews staged, unstaged and untracked changes. A GitHub tab can look up public repository metadata. See [prototype status](docs/PROTOTYPE.md) for verified behavior and remaining work.

## Run the prototype

Requires macOS 15 or later, a Swift 6 toolchain, and installed Git through Xcode or the Xcode Command Line Tools. Open `Package.swift` in Xcode to edit, or run these commands from this directory:

```sh
./scripts/test.sh
./scripts/run.sh
```

The build script creates `.build/app/Git Workspace.app`. Quit an already-running development instance before rebuilding to use the new binary. To build without launching, run `./scripts/build-app.sh`; add `release` for an optimized build.

In the app, choose **Connect Folder** (⌘O) and select an existing Git repository or a folder inside one. Use **Local** to inspect files and switch between staged/unstaged diffs. Refresh with ⌘R; returning to the app also refreshes. **GitHub** shows configured remotes and offers a public repository check. Disconnect Folder removes the saved app association only.

This build does not initialize/clone repositories, edit remotes, stage, commit, push/pull or sign in. Plain folders receive an explanation instead of being initialized automatically. It uses installed Git, has a local ad-hoc signature, and is not a notarized distribution build. Production architecture choices remain proposals unless explicitly accepted in the decision register.

## Read in this order

| Document | Purpose |
| --- | --- |
| [Product requirements](docs/PRD.md) | Audience, scope, workflows, acceptance criteria, and success measures |
| [GitHub capability coverage](docs/API-COVERAGE.md) | Native coverage roadmap, API/authentication constraints, and browser handoffs |
| [Technical architecture](docs/ARCHITECTURE.md) | Swift application design, Git engine, API clients, storage, security, and distribution |
| [Delivery plan](docs/PLAN.md) | Milestones, sequencing, staffing assumptions, estimates, and release gates |
| [Implementation tasks](docs/TASKS.md) | Prioritized checklist with dependencies, acceptance criteria, and requirement references |
| [Decisions and risks](docs/DECISIONS.md) | Confirmed requirements, proposed defaults, open decisions, and mitigations |
| [Prototype status](docs/PROTOTYPE.md) | Implemented slice, verification evidence, and next steps |
| [Authentication feasibility](docs/AUTH-FEASIBILITY.md) | Developer OAuth setup and unresolved live sign-in checks |

## Release direction

1. **Collaboration alpha:** accounts, repositories, inbox, issues, pull request reviews, and Actions visibility.
2. **Git alpha:** a Local tab for connecting folders to GitHub repositories, local changes, selective staging, commits, branches, synchronization, and history.
3. **Feature-complete beta:** advanced history editing, conflict resolution, recovery, worktrees, signing, LFS/submodules, and GitHub workflow integration.
4. **Public 1.0:** all required workflows validated, accessible native UI, signed distribution, updates, and support documentation.
5. **Broader GitHub coverage:** Projects, Discussions, releases, security, repository administration, and eventually organization/enterprise operations.

The long-term ambition is broad coverage of documented GitHub operations. Public 1.0 is a defined product milestone, not a claim of complete website or endpoint parity. The capability register will record every discovered operation as native, partial, browser handoff, deferred, or unavailable through supported public interfaces.

## Recommended starting point

Continue the remaining **M0** feasibility tasks, particularly developer-owned OAuth registration and Git runtime distribution. The local inspection prototype is an early vertical slice, not completion of M0 or M3. Next, verify the complete folder-connection experience and establish mutation/recovery safeguards before adding staging, commits and synchronization. Authenticated collaboration follows the sign-in feasibility gate.

The folder name is a working label. Choose a distinct public product name before distribution to avoid confusion with the existing GitHub Desktop product.
