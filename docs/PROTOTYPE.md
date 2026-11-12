# Local workspace prototype

12 November 2026 · Version 0.1 · Working app name: Git Workspace

## Implemented

- Swift 6 package with a native SwiftUI macOS app, AppKit folder picker and selectable diff text view; macOS 15 deployment target.
- Connect existing repositories or a subfolder; resolve the Git root; retain connected folders across launches; deduplicate canonical paths; disconnect without deleting repository files.
- Show branch, detached/unborn HEAD, remotes, upstream and locally known ahead/behind counts. No remote fetch is performed, so those counts reflect the last external fetch.
- Display staged/unstaged/untracked changes, rename paths and conflict status; preview staged and unstaged diffs separately; bound untracked and text previews.
- Refresh explicitly or when the app becomes active. Live filesystem watching is not implemented yet.
- Read-only Git process boundary using structured arguments, output limits, cancellation, disabled optional index locks, and redacted remote credentials. Configured hooks/fsmonitor/external diff/textconv and known clean/process filters are disabled for these reads. Symlink traversal is rejected for untracked previews.
- Public GitHub repository metadata lookup, strict repository URL parsing, pinned API version, rate-limit/permission/offline handling, and no automatic redirects or authenticated requests.
- Build/test/run scripts and a CI workflow definition. Development app packaging with an ad-hoc signature.

## Verification evidence

Local toolchain: Xcode 27.2, Swift 6.4.2, Apple Git 2.54.0, Apple Silicon. These are the tools actually used; other supported platforms still need validation.

- `./scripts/test.sh`: 28 Swift Testing tests pass (12 Git engine, 13 GitHub client, 3 folder registry; several tests also run multiple parameter cases).
- Git fixtures exercise temporary real repositories, staged/unstaged changes, unusual filenames and renames, unborn/detached HEAD, linked worktrees, conflicts, ahead counts, plain/missing folders, unsafe previews, credential redaction and cancellation.
- A filter-execution regression was reproduced with a temporary marker-writing helper, fixed with explicit filter overrides, and verified with clean/process/required filter settings.
- API tests use URLProtocol fixtures. They are not live GitHub sign-in or private-repository evidence.
- The development app bundle builds, its plist validates, and its ad-hoc signature verifies. Native UI inspection confirmed launch and the welcome screen/folder controls. Full folder-picker-to-diff interaction and accessibility acceptance remain to be recorded.
- CI is configured but has not run remotely. There is no GitHub repository remote configured for this workspace.

## Limits of this slice

This is a read-only local prototype, not the public 1.0 release. No cloning/initializing, remote editing, staging, commits, network Git operations, history editing, authenticated GitHub collaboration, or recovery mutations are exposed yet. Existing remote configuration is detected; choosing a different GitHub repository for an arbitrary folder is still pending.

Custom Git filters are suppressed, so filtered/LFS files may appear modified compared with filter-aware Git status; the app explains this when filters are configured. Submodule working trees are not inspected. Open a submodule as its own local repository if needed. Unsupported filename encodings produce an explicit error. Large output is bounded rather than fully virtualized.

Folder associations currently use a small atomic JSON file at `~/Library/Application Support/GitWorkspace/folders.json`, not the future content-cache database. A corrupt registry is reported and preserved. No GitHub tokens or private API cache are stored. App windows currently share the selected workspace; independent per-window contexts remain planned.

The prototype uses `/usr/bin/git` from the installed developer tools. Bundled Git/LFS/helper distribution, Developer ID signing, notarization, Intel testing, performance budgets, and clean-machine compatibility remain unproven. The developer OAuth integration has not been registered; users will eventually connect through an ordinary **Sign in with GitHub** flow, without registering their own OAuth app or supplying tokens.

## Next implementation steps

1. Record folder-picker, diff switching, reconnect and disconnect UI acceptance; add application-state race tests and live filesystem refresh.
2. Finish DISC-02 with one developer-owned OAuth app and the chosen callback/exchange infrastructure; prove real browser sign-in, refresh/revoke and permissions.
3. Finish DISC-03 packaging and interruption/recovery experiments using the intended shipped Git runtime.
4. Add the repository-operation coordinator and recovery checkpoints, then staging/commits and explicit remote configuration/clone flows.

The backlog now records 12 completed subtasks with source/test evidence under 11 in-progress parent tasks: DISC-01, DISC-02, DISC-03, DISC-05, FND-01, FND-02, FND-04, FND-07, CORE-01, CORE-04 and CORE-13. Each parent also has an explicit unchecked subtask for its remaining acceptance criteria. See [completed work and remaining tasks](TASKS.md).
