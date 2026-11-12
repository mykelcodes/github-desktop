# Product requirements document

Version 0.1 · 12 November 2026 · Draft for product review

## 1. Product definition

Build a native macOS application in Swift that lets individual developers and small teams manage their GitHub work and local repositories in one place. A developer should be able to move from an issue to a branch, implement and organize changes, request review, resolve feedback, inspect CI, and merge without repeatedly changing applications.

The user's confirmed requirements are a native Swift app, a target audience of individuals and small teams, and a **full Git client including advanced history editing in the first public release**. The initial alphas may deliver subsets; public 1.0 may not silently remove advanced Git to meet a date.

The product should follow macOS conventions while preserving GitHub's permissions and semantics. Reproduce useful operations and outcomes, rather than copying the website's page layout.

## 2. Problem and audience

| User | Problem | Desired outcome |
| --- | --- | --- |
| Individual developer | Work is scattered across a browser, Git client, terminal, and editor | One workspace linking local changes to issues, PRs, and CI |
| Small-team maintainer | Review requests, failing checks, and issue triage are difficult to prioritize across repositories | A focused work inbox with fast keyboard navigation |
| Experienced Git user | Simple clients cannot safely organize complex commit histories | Visual rebase, cherry-pick, conflict handling, and explicit recovery |
| Contributor with multiple accounts | Personal and work identities are easy to mix up | Visible account context, isolated credentials, and repository-specific identity |

Initial host: GitHub.com, including accessible organization repositories. GitHub Enterprise Server and other enterprise-specific hosts are later compatibility work; enterprise ownership of a repository does not itself exclude it from 1.0.

## 3. Goals and boundaries

### Goals

- Make the complete issue → code → review → merge loop possible in a native application.
- Deliver a capable local Git client that works with existing repositories and external editors/terminals.
- Make permissions, stale data, destructive effects, and operation progress understandable.
- Preserve user work through application crashes, network failures, and interrupted Git operations.
- Expand GitHub coverage systematically using documented REST and GraphQL interfaces.

### Boundaries

- Do not build a replacement IDE, Git server, CI runner, or cloud development environment.
- Use external editors for normal coding; provide focused patch, commit-message, and merge-result editing.
- Browser handoffs remain appropriate for identity-provider flows and features without a verified public API. They do not count as native coverage.
- No promise of immediate push notifications while the app is quit; the initial design refreshes while running and reconciles after wake.
- Do not scrape private web endpoints to manufacture parity.
- Advanced Git means the explicit operations below, not a UI for every Git command-line flag. Email patch workflows, server administration, repository-wide history filtering, and bisect automation are later candidates.

## 4. Release scope

| Area | Public 1.0 requirement | Later expansion |
| --- | --- | --- |
| Accounts | Multiple GitHub.com accounts, secure sign-in, sign-out, permission recovery | Enterprise Server and enterprise-specific host profiles |
| Work inbox | Notifications where auth is verified; review requests, assigned work, saved filters | Team dashboards, rules, synchronized snoozing |
| Repositories | Discover, clone, open, initialize, create/publish, fork, browse code/history | Full administration, bulk operations, advanced insights |
| Issues | Search, create/edit/close/reopen, comments, reactions, labels, assignees, milestones | Sub-issues, dependencies, issue types, advanced forms |
| Pull requests | Create/edit, draft/ready, review, line comments, checks, merge, local checkout | Full queue/auto-merge management, stacked-PR orchestration |
| Actions | Runs/jobs/checks, available logs/artifacts, dispatch inputs, rerun/cancel | Environment approvals, workflow administration, runners |
| Local Git | Core and advanced operations in section 6 | Bisect, patch mail, sparse-checkout UI, specialized maintenance |
| Local folders | Connect existing folders to GitHub repositories through a Local tab; clone, initialize/publish, locate moved folders, and select among checkouts | Optional parent-folder discovery with explicit user selection |
| Projects/Discussions | Contextual browser handoffs | Native project tables/boards and discussion workflows |
| Releases/security/settings | Relevant links and read context where needed for core workflows | Native CRUD, alert triage, rules, settings, organization operations |

Full coverage is an ongoing program. [API-COVERAGE.md](API-COVERAGE.md) defines the distinction between a planned native feature, a partial implementation, and an unverified capability.

## 5. GitHub and application requirements

Every identifier in this document maps to tasks in [TASKS.md](TASKS.md). All requirements in sections 5–8 are required for 1.0 unless their text explicitly says “later.”

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| APP-01 | Account onboarding and isolation | User signs in using GitHub's authorization experience; cancelling is harmless; two accounts can coexist; all windows show their active identity; sign-out clears that account's tokens and private cache without touching local repositories. |
| APP-02 | Native workspace and navigation | Sidebar, content list, detail/inspector, multi-window support, menu commands, toolbar, back/forward, open-in-browser, and contextual menus work with keyboard and VoiceOver. A window retains its account/repository context. |
| APP-03 | Command palette, search, and links | Search repositories/issues/PRs; retain saved queries; open supported GitHub URLs in the correct context; unsupported paths offer a browser handoff. Local cached results are distinguished from remote results. |
| APP-04 | Permission-aware actions | Explain denied, missing-scope, organization-policy, unsupported-host, and unknown states; do not treat every 404 as deletion. A server denial never produces a local success state. |
| APP-05 | Offline continuity and drafts | Cached data displays last-refresh time. Issue/comment/review drafts survive relaunch and account switching. Remote writes require connectivity and explicit submission; reconnection never silently publishes drafts. |
| HUB-01 | Repository discovery and code browsing | List accessible repositories with pagination; distinguish local and remote repositories; browse README/tree/files/commits/branches and compare refs; handle binary, large, or truncated content explicitly. |
| HUB-02 | Notification triage | List/filter notifications and perform supported read/done/subscription actions after authentication compatibility is proven; show source and refresh time; deduplicate native alerts. If the auth spike fails, change the release contract explicitly instead of calling an assigned-work list “notifications.” |
| HUB-03 | Issue lifecycle | Create from supported Markdown templates, edit, close/reopen with reason where supported, comment/react, and manage existing labels/assignees/milestones. Provide label/milestone creation and editing for authorized users. Unsupported form features open their exact GitHub page. |
| HUB-04 | PR lifecycle and collaboration | Create across branches/forks; edit title/body/base, manage draft state and reviewers; render timeline/checks; support general comments and reviews. Use issue endpoints for shared issue/PR metadata where required. |
| HUB-05 | Accurate code review | Browse changed files and unified/side-by-side diffs; add single/multi-line comments with correct side and revision; batch pending comments into approve/request-changes/comment reviews; reply to and resolve threads where authorized. Preserve drafts when the head changes. |
| HUB-06 | Safe merge | Refresh mergeability/checks/rules and expected head before submission; offer permitted merge/squash/rebase methods; handle stale or unknown state; report server rejection accurately. Queue-required repositories receive an explicit handoff until queue support is implemented. |
| HUB-07 | Actions operations | Inspect runs, jobs and check annotations; fetch available logs and artifacts; dispatch workflows with supported inputs/ref; rerun failed/all jobs and cancel with explicit context. Accepted requests remain pending until server state confirms their outcome. |
| HUB-08 | Local/remote workflow bridge | Create branch from issue, checkout PR safely, open editor/terminal, create PR from pushed branch, and navigate from a commit to related PR/checks when known. Fork remotes and account choice are explicit. |

The API distinguishes PR review comments from general issue comments, and issue APIs also return PRs. These distinctions must be preserved in data models. [Pull requests API](https://docs.github.com/en/rest/pulls/pulls), [Issues API](https://docs.github.com/en/rest/issues/issues).

## 6. Full local Git requirements

These are first-public-release requirements, including recovery and tests. “Open in Terminal” is useful interoperability, but does not satisfy a required native Git operation.

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| GIT-01 | Repository setup and transport | Initialize, add existing, clone HTTPS/SSH, create/publish a GitHub repository, fork, edit remotes, and set upstreams. Local Git works without a GitHub session. Operation progress/cancel is visible; partial clones can be cleaned up deliberately; a fresh Mac can use the shipped Git runtime. |
| GIT-02 | Working tree and selective staging | Show staged/unstaged/untracked/ignored states; stage/unstage files, hunks, and supported text-line selections; display renames, binary changes, mode changes, symlinks, and deleted files. Recompute patches when files change. Support ignore-rule editing and explicit restore/discard previews. |
| GIT-03 | Commits and identity | Commit staged changes, amend, edit message, configure repository author identity, and display signing result. Show exactly what will be committed and whether an amend rewrites a published commit. |
| GIT-04 | Branches, tags, and synchronization | Create/rename/switch/delete branches; create/list/delete tags; fetch, prune, push, and pull with explicit merge/rebase/fast-forward preference. Show ahead/behind and detached-HEAD states. Protect dirty work and explain remote rejection. |
| GIT-05 | History and comparison | Virtualized commit graph, filters, commit detail, file history/blame, compare branches/commits, and copy SHAs. Large histories load incrementally without blocking input. |
| GIT-06 | Stash | Create named stash with explicit untracked inclusion, inspect, apply, pop, and drop. A failed/conflicted application remains recoverable; indexed and unstaged differences are explained. |
| GIT-07 | Merge and conflict resolution | Start/continue/abort merges; show base/ours/theirs/result for text; resolve add/delete/rename and binary conflicts with explicit choices; support external merge tools. Preserve conflicts through restart. Never silently resolve using one side. |
| GIT-08 | Interactive rebase | Select base/onto target, preview affected commits, reorder, reword, squash, fixup, drop, edit, and split commits; continue/skip/abort after conflicts. Detect merge-containing ranges and provide a tested preserve-merges path or explicitly block that variant with explanation. Autosquash is supported. |
| GIT-09 | Cherry-pick, revert, and reset | Select one/multiple commits in a defined order; cherry-pick/revert with conflict recovery; explain merge-parent selection; offer soft/mixed/hard reset with separate index/worktree effects and protection for overwritten work. |
| GIT-10 | Recovery and published-history protection | Record recovery refs and operation journal before rewriting history; inspect reflog and restore commits to a new branch; recover after application crash; present published-history effects; use an explicit expected remote SHA for force-with-lease. Uncommitted files require their own checkpoint. |
| GIT-11 | Worktrees | Create/list/open/move/remove worktrees; detect shared refs and branch occupancy; refuse unsafe removal without a specific user decision; refresh when another worktree changes the repository. |
| GIT-12 | Real repository compatibility | Support common LFS and submodule clone/status/update flows, submodule navigation and superproject pointer commits, SSH agents, credential helpers, commit/tag signing with configured GPG/SSH tools, trusted hooks, and external changes. Unsupported or missing helper configurations get an actionable state. |
| GIT-13 | Connect local folders to GitHub repositories | From a repository's Local tab or the Local Folders sidebar, select a folder, inspect its Git state, verify the intended GitHub repository/account and preview any remote changes. Support existing clones, local Git repos without a matching remote, ordinary folders, and multiple local checkouts. Connecting alone never commits, pushes, replaces files or rewrites history. Locate moved folders and remove app links without deleting files or changing Git remotes. |

Git's rebase and worktree behavior are the underlying semantics, not behavior to approximate in application code. [Rebase reference](https://git-scm.com/docs/git-rebase), [Worktree reference](https://git-scm.com/docs/git-worktree.html).

### Local tab and folder connection

Add **Local** alongside the repository's Overview, Issues, Pull Requests and Actions destinations. Its empty state offers **Connect Folder** and **Clone Repository**. Once connected, show a folder/checkout picker, path, selected remote/account, current branch, ahead/behind state, last fetch and connection status. Changes, History and Branches/Worktrees live within this tab, with stage/commit/fetch/pull/push and Open in Finder/Editor/Terminal actions.

Also provide a global **Local Folders** sidebar entry so users can start with a folder before choosing a GitHub repository, or work locally without signing in. Support more than one checkout/worktree for a GitHub repository while keeping each folder's branch and changes separate.

| Selected folder state | Connection flow |
| --- | --- |
| Existing clone with a matching remote | Detect the Git root and existing remotes; verify the GitHub target, then register the folder without recloning. |
| Existing Git repository without a matching remote | Let the user select/create the GitHub repository and preview adding a named remote. Preserve existing remotes; fetch and assess history before offering pull/push. Divergent or unrelated histories require a separate reconciliation flow. |
| Ordinary folder and a new or verified-empty GitHub repository | Preview initialization, ignore rules and remote configuration. After setup, let the user review/stage files and explicitly commit/push. No automatic first commit or bulk upload. |
| Ordinary folder and a GitHub repository with existing history | Offer to clone into a separate destination, then preview copying selected project files onto a new branch. Preserve both folders, exclude Git metadata and show filename collisions; review changes before committing. Never clone over a populated folder or silently replace remote history. |
| Folder missing, moved, inaccessible, or inside another repository | Offer Locate/Grant Access or select the detected Git root. Verify identity before relinking; never silently initialize a nested repository. |

Refresh local changes when an editor modifies files. Network synchronization remains explicit Git fetch/pull/push; folder connection is not automatic bidirectional file synchronization. Disconnecting removes the app's association only; editing/removing a Git remote is a separate action.

## 7. Primary user journeys

### Connect an existing project folder

Open the GitHub repository → Local → Connect Folder → select the project folder → review detected Git state and the target repository → confirm the proposed setup → inspect local changes → explicitly commit/push when ready. Alternatively, start in Local Folders and choose the GitHub target afterward. A repository with existing remote history takes the appropriate history-check or separate-clone import path.

### Start work on an issue

Choose the account → open assigned issue → select local repository or clone → create a branch with an editable suggested name → open editor → inspect changes → stage intended lines → commit → push → create a PR linked to the issue. At every write, account, repository, and branch remain visible.

### Review and merge

Open a review request → inspect description/checks → navigate files and add pending comments → submit review → revisit after changes → merge if permitted. If new commits appear, show that the review revision is stale and keep draft comments available for reconciliation.

### Repair a commit series

Select a branch → open interactive rebase → choose base → preview reordered/squashed/split commits → checkpoint → execute → resolve conflicts → inspect resulting history → push with an expected remote revision. If anything fails, resume or abort from the operation panel. Recovery creates a branch from a checkpoint; it does not secretly reset other people's work.

### Diagnose failed CI

Open failed check → inspect job/step output → search available logs → jump to the affected local file → fix and push, or rerun the selected job/workflow. A rerun is a remote action that may consume CI resources; the UI shows the target before dispatch.

### Switch work without losing changes

Open another repository/window or create a worktree → keep drafts and working changes in their original context → return using the command palette. Switching accounts cannot cause a draft or credential to cross account boundaries.

## 8. Quality requirements

Targets below are design budgets to validate in M0 and benchmark thereafter; they are not measured results.

| ID | Requirement | Initial acceptance target |
| --- | --- | --- |
| NFR-01 | Performance | On an Apple Silicon Mac with 16 GB RAM: cached launch p95 ≤2 s; cached list navigation p95 ≤150 ms; warm status on a 10,000-file fixture p95 ≤2 s; first viewport of a 100,000-commit history ≤2 s. Large diffs/history use bounded loading. Network latency is reported separately. |
| NFR-02 | Accessibility and native quality | Complete issue → review and stage → commit → push paths with keyboard and VoiceOver; respect contrast, reduced motion, scalable text, focus order, light/dark appearance, and system shortcuts. State never depends on color alone. |
| NFR-03 | Correctness and recovery | No known release-blocking data-loss, credential-isolation, or incorrect-review-position defects. Every mutating Git operation has success, conflict/error, cancellation, and restart coverage where applicable. No automatic retry of an ambiguous remote write. |
| NFR-04 | Security and privacy | Tokens in Keychain; no credentials in URLs, process arguments, diagnostics, telemetry, or repository config. Repository execution features require a trust decision. Account removal clears private caches/drafts after an export choice. Private repository content never enters analytics. |
| NFR-05 | Network and energy | Respect server rate/poll instructions, cancel obsolete requests, limit concurrent work, and back off on errors. No default periodic network work while quit. Refresh after wake without replaying stale writes. |
| NFR-06 | Compatibility and distribution | Proposed minimum macOS 15; validate supported OS/CPU matrix before freezing it. Ship signed/notarized direct-download builds with verified updates, migration tests, and reproducible Git/helper provenance. Intel support is conditional on a viable current toolchain and test hardware. |
| NFR-07 | Supportability | Redacted diagnostic export with preview, operation IDs, recoverable error guidance, schema/API upgrade policy, and documented cache/recovery retention controls. |

Idle CPU target: ≤1% averaged over five minutes with one quiet repository and no operation in progress. Memory target: ≤350 MB steady state for the reference workspace, excluding bounded large-file operations. Rebaseline with recorded fixture, OS, hardware, and build configuration if these targets prove unrealistic.

## 9. Experience and differentiation

Recommended 1.0 differentiators: a keyboard command palette, multi-window repository workspaces, an integrated issue-to-branch flow, durable review drafts, a clear commit-rewrite preview, and a recovery timeline. These directly support required workflows.

Later experiments: review queues grouped by urgency, local notification snooze, saved team workspaces, a menu-bar CI indicator, Shortcuts/App Intents, local search indexing, stacked-PR views, and release checklists. Validate each with users before promoting it to required scope.

AI summaries, suggested commit messages, and review assistance are optional later experiments. They must be opt-in, previewable, and have an explicit data-sharing model. They must never auto-approve reviews, merge, or rewrite history. Do not assume a GitHub Copilot subscription provides a general-purpose chat API for this app.

## 10. Success measures

- **Activation:** at least 70% of invited beta testers finish sign-in, open/clone a repository, and complete a review or push within their first session.
- **Workflow coverage:** at least 90% of a predefined set of 20 core workflow scripts finish natively at 1.0; every required requirement must still pass its acceptance criteria. Browser handoffs are counted separately.
- **Usability:** at least 8 of 10 moderated testers complete the six journeys without facilitator intervention; recovery must be understandable to both novice and advanced Git users.
- **Reliability:** ≥99.5% crash-free beta sessions over a meaningful sample (target ≥500 sessions); no unresolved release-blocking integrity or privacy defects.
- **Retention hypothesis:** ≥50% of activated beta testers use the app weekly for four weeks. Revisit after the first cohort instead of treating an unvalidated target as market evidence.

Measure through opted-in aggregate telemetry and moderated sessions; no repository names, paths, bodies, patches, or credentials are needed. Define a workflow-coverage denominator before beta testing so easier tasks cannot inflate the result.

## 11. Public 1.0 release contract

All APP, HUB, GIT, and NFR requirements above have an owning task and evidence. All M0–M7 gates pass. Authentication/notification feasibility is resolved. Advanced Git recovery passes the destructive-operation fixture suite. A clean supported Mac can install, authenticate, clone, commit, review, and update the app. Known API gaps are visible in help and the coverage register.

Broad GitHub parity continues after 1.0. Changes to the confirmed audience, native Swift requirement, or full-Git first-release scope require an explicit product decision recorded in [DECISIONS.md](DECISIONS.md).
