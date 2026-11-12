# Implementation backlog

12 November 2026 · 19 completed subtasks · 1 parent task complete · 13 parent tasks in progress · 69 parent tasks not started

This is an execution checklist for the [PRD](PRD.md) and [delivery plan](PLAN.md). Documentation preparation does not mark application tasks complete. Dependencies use task IDs; requirement references use the APP/HUB/GIT/NFR IDs in the PRD. CAP IDs refer to the [API coverage map](API-COVERAGE.md).

Completed work is checked off beneath the corresponding parent task, with implementation and verification links. Discovery and the local inspection prototype have **19 completed subtasks**, with **1 parent complete, 13 in progress and 69 not started**. No full release milestone has passed yet. See [prototype evidence](PROTOTYPE.md) and the [M0 acceptance audit](M0-FEASIBILITY.md).

Parent IDs retain their original scope and dependencies. Numbered child IDs such as FND-01.1 record completed slices and the remaining acceptance work without marking an unfinished parent done. These prototype slices were authorized before the full M0 gate; the gate still applies to production readiness. Subtask counts are tracking detail, not a percentage of the whole product.

## How to use this backlog

- **P0:** required for public 1.0, including feasibility and quality gates. **P1:** prioritized post-1.0 coverage. **P2:** exploratory/later scope.
- **S/M/L:** relative implementation complexity. L items are epics that must be split into reviewable subtasks before starting; these labels are not committed day estimates.
- Update the relevant subtask checkbox and evidence in the same change that delivers the work. Check a parent only when all of its acceptance criteria pass. Each checkbox needs links to implementation and verification evidence before completion. A task's named acceptance criteria supplement the common definition of done in the plan.
- Owner roles below are responsibilities, not assigned people. Track assignee, status, estimate, blocking decision and evidence in the issue tracker when implementation begins.
- Depends on “M0”, “M1”, or another milestone means its gate in PLAN.md must pass; task dependencies can be worked in parallel only when their prerequisites are satisfied.

| Group | Milestone | Default priority | Owner role |
| --- | --- | --- | --- |
| DISC | M0 | P0 | Product + technical leads |
| FND | M1 | P0 | macOS/integration engineers |
| COL | M2 | P0 | GitHub integration + UI |
| CORE | M3 | P0 | Git engine + UI |
| ADV | M4 | P0 | Git engine + UI + QA |
| INT | M5 | P0 | Cross-feature engineering |
| QUAL | M6, started throughout | P0 | QA + engineering + accessibility/security support |
| SHIP | M7, packaging started in M0 | P0 | Release engineering + product |
| EXT | R1/R2 | P1 unless marked P2 | Product + relevant feature owner |

## M0 — Discovery and feasibility

- [x] **DISC-01 — Freeze the first-release workflow contract.** Size M; depends on none; covers all PRD requirements. Defined 20 manual acceptance scripts, representative cohort roles/fixtures, screen map, staffing assumptions, name shortlist and scope exclusions, retaining full Git in 1.0. Evidence: [workflow contract](WORKFLOW-CONTRACT.md), [acceptance audit](M0-FEASIBILITY.md). **Status: complete.**

    - [x] **DISC-01.1 — Document the confirmed product scope and delivery baseline.** Completed the PRD, native Swift architecture proposal, delivery plan, risks and full-Git/local-folder requirements. Evidence: [PRD](PRD.md), [architecture](ARCHITECTURE.md), [plan](PLAN.md), [decisions](DECISIONS.md).

    - [x] **DISC-01.2 — Complete discovery acceptance.** Froze the 20 step-by-step manual scripts and scoring denominator, ten-person cohort criteria, fixture matrix, screen map and name shortlist. Participant recruitment and execution remain beta work. Evidence: [workflow contract](WORKFLOW-CONTRACT.md), [acceptance audit](M0-FEASIBILITY.md).

- [ ] **DISC-02 — Prove production authentication and notifications.** Size L; depends on none; covers APP-01, HUB-02, NFR-04, CAP-01/CAP-10. Test registered-app authorization, PKCE/exchange, refresh, revoke, notification mutations, organization restrictions and two accounts. Produce redacted evidence and the native/broker decision; no confidential secret embedded in a prototype intended for distribution. **Status: in progress.**

    - [x] **DISC-02.1 — Research the native OAuth flow and document its prerequisites.** Reviewed official authorization, callback, refresh and notification documentation; recorded the unresolved notification compatibility and developer-owned registration requirements. Evidence: [authentication feasibility](AUTH-FEASIBILITY.md). This completes research only, not sign-in verification.

    - [ ] **DISC-02.2 — Prove registered-app authentication.** Register the developer integration, establish callback/exchange infrastructure and exercise real sign-in, refresh/revoke, permissions, notifications and account isolation.

    - [x] **DISC-02.3 — Prepare and verify the local OAuth harness.** Recorded the user-provided Client ID and loopback callback contract. Implemented local PKCE/browser/exchange/refresh/revocation tooling with hidden secret input. Two synthetic tests cover callback rejection/replay, cleanup and credential-output redaction. Live results remain pending. Evidence: [harness](../scripts/m0/oauth.py), [tests](../scripts/m0/test-oauth.py), [authentication setup and audit](M0-FEASIBILITY.md).

- [ ] **DISC-03 — Prove the shipped Git runtime.** Size L; depends on none; covers GIT-01, GIT-10, GIT-12, NFR-06. Bundle Git and required helpers in a minimal Swift app; exercise HTTPS/SSH, signing and LFS on a clean Mac; attempt signing/notarization and review dependency distribution. Prototype an interrupted rebase and checkpoint recovery in disposable repositories. Record missing tool requirements and a viable shipping path. **Status: in progress.**

    - [x] **DISC-03.1 — Build and verify a local development app bundle.** The development bundle builds with installed Git; Info.plist and the ad-hoc signature validate, and native launch was observed. Evidence: [packaging script](../scripts/build-app.sh), [bundle metadata](../Resources/Info.plist), [verification record](PROTOTYPE.md).

    - [ ] **DISC-03.2 — Prove the distributable Git runtime and recovery experiment.** Bundle Git/helpers, review distribution obligations, test HTTPS/SSH/signing/LFS on a clean Mac, validate Developer ID/notarization, and demonstrate interrupted rebase/checkpoint recovery.

    - [x] **DISC-03.3 — Verify a bundled runtime and interrupted recovery locally.** Built pinned Git 2.56.1 and staged Git LFS 3.8.1 inside an ad-hoc hardened-runtime app. Verified relocation, local LFS push/clone, SSH commit/tag signatures, public HTTPS read, native repository/diff display, interrupted rebase abort/continue and dirty checkpoint restoration. Evidence: [runtime build](../scripts/m0/build-git-runtime.sh), [app packaging](../scripts/m0/build-runtime-app.sh), [runtime checks](../scripts/m0/runtime-check.py), [recovery harness](../scripts/m0/recovery.py), [runtime manifest](evidence/runtime-manifest.json), [results](evidence/recovery.json). Clean-machine and signed distribution acceptance remain in DISC-03.2.

- [ ] **DISC-04 — Benchmark diff and history controls.** Size M; depends on none; covers HUB-05, GIT-05, NFR-01/NFR-02. Measure SwiftUI/native text-table approaches on large, binary, renamed and Unicode files plus 100,000 commits. Record rendering/accessibility results and choose controls against the PRD budgets. **Status: in progress.**

    - [x] **DISC-04.1 — Measure control and Git fixture performance.** Ran 20 optimized offscreen trials per control/fixture and compared 200-line text pages. Measured bounded history retrieval from 100,000 real commits and warm status on 10,000 files using the built Git runtime. Recorded p50/p95 and process memory. Evidence: [control harness](../scripts/m0/ControlsBenchmark.swift), [Git harness](../scripts/m0/git-benchmark.py), [raw measurements](evidence/controls-results.json), [Git results](evidence/git-benchmark.json), [interpretation](M0-FEASIBILITY.md).

    - [ ] **DISC-04.2 — Validate interaction/accessibility and finalize controls.** Test visible scrolling/selection, keyboard and VoiceOver, reference 16 GB hardware, combined history loading/rendering and memory. Confirm the bounded diff/history control decision.

- [ ] **DISC-05 — Create the endpoint/capability registry.** Size L; depends on DISC-01; covers APP-04 and CAP-01–CAP-34. Pin REST/schema sources; record operations, token/permission/host combinations, limits, fallback and evidence status. Verify representative 1.0 endpoints live on disposable resources; mark all untested combinations honestly. **Status: in progress.**

    - [x] **DISC-05.1 — Create the initial GitHub capability inventory.** Documented 34 capability areas with proposed releases, public API sources, authentication caveats and handoff boundaries. Evidence: [capability map](API-COVERAGE.md).

    - [ ] **DISC-05.2 — Complete the operation-level compatibility registry.** Generate and pin endpoint/schema inventory, record operation-specific permissions/hosts and prove representative authenticated operations using disposable resources.

    - [x] **DISC-05.3 — Generate the pinned schema inventory.** Hash-verified official schema inputs and generated 1,280 REST operation records and 315 GraphQL root fields. Recorded candidate mappings, API version, schema flags, pagination parameters, documentation fallback, owner and unknown compatibility fields. Evidence: [source pins](api-sources.json), [generator](../scripts/m0/api-inventory.py), [REST records](evidence/rest-operations.csv), [GraphQL records](evidence/graphql-operations.json). Manual permission/host review and live coverage remain in DISC-05.2.

- [ ] **DISC-06 — Resolve platform and architecture decisions.** Size M; depends on DISC-02, DISC-03, DISC-04; covers NFR-04/NFR-06. Record OS/CPU/toolchain, distribution/sandbox, persistence, updater, Git versions and broker ownership if needed. Each selected dependency has provenance, license, maintenance and replacement considerations. **Status: in progress.**

    - [x] **DISC-06.1 — Record observed platform and dependency evidence.** Documented toolchain, runtime provenance/licenses, rendering recommendation, distribution constraints and updater/persistence candidates. Evidence: [runtime manifest](evidence/runtime-manifest.json), [dependency and architecture review](M0-FEASIBILITY.md). This is preparatory review while dependent spikes remain open.

    - [ ] **DISC-06.2 — Resolve dependent production choices.** Complete the platform/CPU matrix, signed distribution and auth decisions, validate persistence/updater choices and assign operational ownership before accepting the architecture.

- [ ] **DISC-07 — Approve the feasibility report and revised plan.** Size S; depends on DISC-01–DISC-06; covers the M0 gate. Consolidate spike evidence, unresolved constraints, scope effects and estimates. Done when a real authenticated workflow and a recoverable Git mutation have been demonstrated and dependent choices can be implemented. **Status: in progress.**

    - [x] **DISC-07.1 — Consolidate the current feasibility evidence.** Recorded each task's delivered evidence, unresolved acceptance, measured scope effects and remaining execution order. Retained provisional estimates while critical-path inputs remain unknown. Evidence: [M0 report](M0-FEASIBILITY.md), [revised M0 sequence](PLAN.md).

    - [ ] **DISC-07.2 — Approve M0 after the remaining evidence passes.** Demonstrate the registered-token workflow, close DISC-02–DISC-06 and revise estimates/decisions against the completed spikes. Record product/engineering approval.

## M1 — Foundations

- [ ] **FND-01 — Create the Swift app/package workspace and CI.** Size M; depends on M0; covers NFR-06. Pin toolchain/dependencies, add app/test targets, build/test commands and CI. A clean checkout builds and runs core tests with no developer-specific paths or credentials. **Status: in progress.**

    - [x] **FND-01.1 — Create the Swift app, library and test targets.** Added a Swift 6 package targeting macOS 15 with the executable, GitEngine, GitHubKit, WorkspaceCore and three test targets; the local build succeeds. Evidence: [package manifest](../Package.swift), [verification record](PROTOTYPE.md).

    - [x] **FND-01.2 — Add build/run/test commands and the CI workflow definition.** Created executable development scripts and a macOS workflow with explicit CI Xcode selection. Local scripts were exercised; remote CI execution is pending. Evidence: [build](../scripts/build-app.sh), [run](../scripts/run.sh), [test](../scripts/test.sh), [workflow](../.github/workflows/macos.yml).

    - [ ] **FND-01.3 — Validate the clean-checkout and remote CI baseline.** Run the workflow on the configured repository, verify a clean checkout with the supported toolchain and finalize production toolchain policy after M0.

- [ ] **FND-02 — Build native navigation and command routing.** Size L; depends on FND-01; covers APP-02/APP-03, NFR-02. Implement account/repository routing, sidebar, inspector, multi-window restoration, menus and command palette shell. Keyboard/VoiceOver can navigate sample content and unsupported links hand off explicitly. **Status: in progress.**

    - [x] **FND-02.1 — Build the native workspace shell and local views.** Implemented the sidebar, welcome screen, Local/GitHub destinations, folder-picker command, refresh command and native diff view. Build and native welcome-screen launch were verified. Evidence: [workspace view](../Sources/GitWorkspace/WorkspaceView.swift), [repository view](../Sources/GitWorkspace/RepositoryView.swift), [app commands](../Sources/GitWorkspace/GitWorkspaceApp.swift), [verification record](PROTOTYPE.md). Full UI journey validation remains open.

    - [ ] **FND-02.2 — Complete navigation and interaction acceptance.** Add account routing, independent window contexts/restoration, inspector and command palette; validate folder-picker-to-diff, keyboard/VoiceOver and unsupported-link handoffs.

- [ ] **FND-03 — Implement account and credential lifecycle.** Size L; depends on FND-01, DISC-02; covers APP-01, NFR-04. Add system-browser auth, Keychain, refresh serialization, sign-out/reconnect and broker integration if selected. Test two accounts, replay/cancel, expiry and revocation; tokens remain absent from logs and URLs.

- [ ] **FND-04 — Implement typed REST and GraphQL transport.** Size L; depends on FND-01, FND-03; covers APP-04, NFR-03/NFR-05. Add versioning, pagination, bounded requests, partial GraphQL errors and typed denial/rate/timeout states. Fixtures prove cross-host redirects cannot inherit credentials and malformed responses remain actionable. **Status: in progress.**

    - [x] **FND-04.1 — Implement the public repository REST client.** Added strict repository URL parsing, a versioned read-only request, typed decoding and denied/rate-limit/offline handling. Thirteen Swift Testing tests pass, including parameterized cases. Evidence: [client](../Sources/GitHubKit/GitHubClient.swift), [models](../Sources/GitHubKit/GitHubRepository.swift), [tests](../Tests/GitHubKitTests/GitHubClientTests.swift).

    - [ ] **FND-04.2 — Complete authenticated REST and GraphQL transport.** Add account credentials, endpoint pagination, GraphQL/partial errors, request scheduling, cancellation/retry policy and authenticated cross-host isolation tests.

- [ ] **FND-05 — Implement capability and permission evaluation.** Size M; depends on FND-04, DISC-05; covers APP-04. Represent allowed/denied/unknown/unsupported separately; combine role, token, host and resource evidence. UI actions show accurate explanations; unknown state never grants permission by assumption.

- [ ] **FND-06 — Implement cache, drafts and migrations.** Size L; depends on FND-01, FND-03; covers APP-05, NFR-04. Add account-owned records, revision/completeness metadata, atomic draft saving, export and erasure. Prove relaunch persistence, migration, cache corruption recovery and removal of one account without touching another.

- [ ] **FND-07 — Implement the Git process boundary and fixture harness.** Size L; depends on FND-01, DISC-03; covers GIT-01, NFR-03/NFR-04. Add structured arguments, bounded output, progress/cancellation, trust policy, host-scoped credentials and temporary repos/remotes. Unusual filenames and malicious-looking refs cannot become shell commands. **Status: in progress.**

    - [x] **FND-07.1 — Implement and test the read-only Git boundary.** Added structured process arguments, bounded output, cancellation, safe preview handling, configured-helper suppression, redacted remotes and disposable real-Git fixtures. The clean/process-filter regression is covered by a passing test. Evidence: [process runner](../Sources/GitEngine/GitProcess.swift), [service](../Sources/GitEngine/GitRepositoryService.swift), [integration tests](../Tests/GitEngineTests/GitRepositoryServiceTests.swift).

    - [ ] **FND-07.2 — Complete the production process and credential boundary.** Add the full repository trust model, host-scoped transport credentials, mutation/helper lifecycle support and required runtime/error coverage using the selected shipped Git distribution.

- [ ] **FND-08 — Implement refresh scheduling and connectivity state.** Size M; depends on FND-04, FND-06; covers APP-05, NFR-05. Deduplicate/revalidate reads; obey polling/backoff headers; handle sleep/wake, offline and obsolete searches. Reconnection never submits a draft or stale mutation automatically.

- [ ] **FND-09 — Implement operation diagnostics and error presentation.** Size M; depends on FND-04, FND-07; covers NFR-07. Add structured redacted events, operation IDs, outcome-unknown states and diagnostic preview. Fixtures containing fake tokens/private paths prove redaction; errors preserve useful recovery context.

## M2 — GitHub collaboration alpha

- [ ] **COL-01 — Add repository discovery and content browsing.** Size L; depends on M1; covers HUB-01, CAP-02/CAP-03. Implement paginated accessible-repo lists, README/tree/file/branch/commit views and ref comparisons. Large/binary/truncated files and inaccessible repositories show explicit states.

- [ ] **COL-02 — Add global search and saved work queues.** Size M; depends on COL-01; covers APP-03. Search issues/PRs/repos; save filters and show assigned/review-requested work. Debounce requests; display incomplete/capped results and distinguish local from remote search.

- [ ] **COL-03 — Add notification inbox and native alerts.** Size L; depends on FND-08, DISC-02, COL-01; covers HUB-02. Implement verified list/read/done/subscription actions and source/reason filters. Test conditional polling, read-state reconciliation and alert deduplication; user can disable native alerts.

- [ ] **COL-04 — Add issue lifecycle and metadata management.** Size L; depends on COL-01, FND-05/FND-06; covers HUB-03. Implement issue CRUD/state, comments/reactions, labels/assignees/milestones and supported templates. Validate denied edits, concurrent changes and unsupported form fallback without losing input.

- [ ] **COL-05 — Build reusable Markdown composition and durable drafts.** Size M; depends on FND-06; covers APP-05, HUB-03/HUB-04. Add preview, mentions/links and recoverable drafts. Sanitized rendering and unsupported attachments do not execute content or discard text; explicit submission is required after reconnect.

- [ ] **COL-06 — Add PR list, detail and lifecycle operations.** Size L; depends on COL-01, COL-05; covers HUB-04. Implement create/edit/base selection, fork source, close/reopen, draft/ready, reviewers, timeline and shared metadata. Verify denied and stale states against selected API operations.

- [ ] **COL-07 — Build accurate PR diff and review submission.** Size L; depends on COL-06, DISC-04; covers HUB-05. Implement changed-file navigation, both diff modes, single/multi-line drafts, batched reviews, replies and thread resolution. Fixtures verify exact side/path/SHA/ranges after renames, new commits and incomplete patches.

- [ ] **COL-08 — Add checks, rules and safe direct merge.** Size L; depends on COL-06, FND-05; covers HUB-06. Refresh head/checks/rules; offer permitted methods; send expected-head precondition where supported. Test unknown mergeability, rejected/stale merges, queue-required handoff and optional branch cleanup.

- [ ] **COL-09 — Add Actions run/job/check visibility.** Size M; depends on COL-01, FND-04; covers HUB-07. Show run/job/step status and annotations with refresh state. Handle missing/expired output, pagination and denied access; no unsupported live-streaming claim.

- [ ] **COL-10 — Validate collaboration alpha end to end.** Size M; depends on COL-01–COL-09; covers APP-01–APP-05, HUB-01–HUB-07. Run contributor/read-only/restricted-org scripts, keyboard review journey and restart/offline draft checks. Store evidence and resolve release-blocking alpha defects.

## M3 — Core local Git

- [ ] **CORE-01 — Discover and register local repositories.** Size M; depends on M1; covers GIT-01/GIT-11. Detect normal repositories, linked worktrees, common Git directories and detached HEAD. Map remotes to GitHub explicitly; moved/missing directories do not corrupt registry state. **Status: in progress.**

    - [x] **CORE-01.1 — Discover existing repository roots and Git metadata.** Real-Git tests cover subfolder/root resolution, normal/linked worktrees, unborn/detached HEAD, remotes and plain/missing folders. Evidence: [repository service](../Sources/GitEngine/GitRepositoryService.swift), [parsers](../Sources/GitEngine/GitOutputParser.swift), [tests](../Tests/GitEngineTests/GitRepositoryServiceTests.swift).

    - [ ] **CORE-01.2 — Complete discovery and registration lifecycle acceptance.** Add moved-folder identity verification/relinking and validated account-aware remote associations; test the complete registry lifecycle under external changes.

- [ ] **CORE-02 — Coordinate mutations and external change detection.** Size L; depends on CORE-01; covers NFR-03, GIT-10/GIT-11. Serialize writes across shared Git directories, watch/debounce changes and recheck refs/index. Test external Git, multiple windows/worktrees, lock contention and app restart.

- [ ] **CORE-03 — Implement clone/init/open/create/fork and transport setup.** Size L; depends on CORE-01, FND-03/FND-07, COL-01; covers GIT-01, HUB-01. Provide destination/remotes/upstream/account selection, HTTPS/SSH progress/cancel and fresh-Mac onboarding. Local-only Git works without GitHub sign-in. Never store tokens in remote URLs; interrupted clones have explicit cleanup.

- [ ] **CORE-04 — Parse and display worktree/index state.** Size L; depends on CORE-02; covers GIT-02. Distinguish staged/unstaged/untracked/ignored, renames, mode/symlink/binary/submodule changes. Fixtures include whitespace, non-UTF-8 paths, case-only renames and simultaneous editor changes. **Status: in progress.**

    - [x] **CORE-04.1 — Parse and preview core local change states.** Implemented staged/unstaged/untracked states, rename paths, conflicts and separate text previews; tests cover unusual paths and unsafe/large/binary untracked previews. Evidence: [parser](../Sources/GitEngine/GitOutputParser.swift), [diff service](../Sources/GitEngine/GitRepositoryService.swift), [tests](../Tests/GitEngineTests/GitRepositoryServiceTests.swift).

    - [ ] **CORE-04.2 — Complete the full file-state compatibility matrix.** Add ignored-file presentation, complete mode/symlink/binary/submodule behavior, non-UTF-8 filename support, case-only rename fixtures and simultaneous-editor-change validation.

- [ ] **CORE-05 — Implement selective staging and safe restore.** Size L; depends on CORE-04, CORE-10; covers GIT-02. Stage/unstage files/hunks/valid line selections, edit ignore rules and preview discards. Changed source invalidates stale patches; discarded content is checkpointed or the action is blocked with explanation.

- [ ] **CORE-06 — Implement commits, identities and amend.** Size M; depends on CORE-05; covers GIT-03. Show staged payload and author/signing intent; validate message; commit and amend with history warning/checkpoint. Failed hooks/signing preserve staged changes and recoverable draft messages.

- [ ] **CORE-07 — Implement branches, tags and remote configuration.** Size L; depends on CORE-02, CORE-10; covers GIT-04. Create/rename/switch/delete branches, create/delete tags, edit remotes/upstreams and show branch occupancy. Protect dirty trees, unmerged branches and remote deletion targets.

- [ ] **CORE-08 — Implement fetch/pull/push and divergence states.** Size L; depends on CORE-03, CORE-06, CORE-07; covers GIT-04. Fetch/prune, display ahead/behind, choose pull policy, push explicit target and report server rejection. Conflict states transfer to the operation panel; never hide a non-fast-forward by forcing.

- [ ] **CORE-09 — Implement commit graph, file history and comparisons.** Size L; depends on CORE-01, DISC-04; covers GIT-05. Add incremental graph/filtering, commit/file detail, blame and ref comparisons. Confirm correct graph relationships and bounded loading with the benchmark fixtures.

- [ ] **CORE-10 — Implement checkpoints and operation journal.** Size L; depends on CORE-02; covers GIT-10, NFR-03/NFR-07. Preserve relevant refs, index/worktree and selected untracked data; define retention and storage limits. Disk-full/failed backups block destructive operations; restart discovers incomplete operations without overwriting external changes.

- [ ] **CORE-11 — Implement stash lifecycle.** Size M; depends on CORE-04, CORE-10; covers GIT-06. Name/inspect/create/apply/pop/drop with explicit untracked/index treatment. Conflicts and failure retain recovery data; UI distinguishes apply from drop.

- [ ] **CORE-12 — Validate core Git alpha.** Size M; depends on CORE-01–CORE-11, CORE-13, CORE-14; covers GIT-01–GIT-06, GIT-10, GIT-13. Verify tree/index/ref results against real Git across clean, dirty, detached and divergent fixtures. Run clean-machine clone → partial stage → commit → push and folder-connection cases; record safety failures.

- [ ] **CORE-13 — Build the Local tab and folder associations.** Size L; depends on CORE-01, CORE-03, FND-02; covers GIT-13, APP-02. Add repository-first Connect Folder/Clone and global Local Folders entry points, inspect Git roots/remotes, verify target/account, and show checkout/path/branch/sync state. Test multiple checkouts, remote mismatch, nested folders, access denial, moved-folder relinking and unlinking without changing remotes or deleting files. **Status: in progress.**

    - [x] **CORE-13.1 — Persist and safely remove local folder associations.** Added canonical-path deduplication, atomic storage and app-only disconnect. Three tests verify persistence, permissions, corruption preservation and disconnect without file deletion. Evidence: [folder registry](../Sources/WorkspaceCore/FolderRegistry.swift), [tests](../Tests/WorkspaceCoreTests/FolderRegistryTests.swift), [command wiring](../Sources/GitWorkspace/WorkspaceModel.swift).

    - [ ] **CORE-13.2 — Complete the end-to-end folder connection experience.** Validate folder-picker/diff/reconnect/disconnect UI flows; implement clone and repository-first target/account selection, multiple-checkout picker, remote mismatch handling, access-denied recovery and moved-folder relinking.

- [ ] **CORE-14 — Implement safe folder initialization and import.** Size L; depends on CORE-13, CORE-06, CORE-10; covers GIT-13. Preview initialization/ignore rules and remote additions for local folders; inspect remote history before offering publication. For ordinary folders targeting populated repositories, clone separately and preview selected file imports/collisions onto a branch. Preserve source folders and Git metadata; unknown remote state cannot mean empty. Tests prove linking never commits, pushes or overwrites history automatically.

## M4 — Advanced Git and recovery

- [ ] **ADV-01 — Implement merge operation lifecycle.** Size L; depends on M3; covers GIT-07. Start merges with explicit target/mode; continue/abort and resume after restart. Test fast-forward, normal merge, dirty-tree refusal, conflict and failed abort without claiming an unverified restoration.

- [ ] **ADV-02 — Implement typed interactive rebase planning.** Size L; depends on M3; covers GIT-08. Select base/onto, preview commits and edit order/reword/squash/fixup/drop plan. Validate ranges, published refs and autosquash; generated sequence instructions cannot inject arbitrary commands.

- [ ] **ADV-03 — Implement rebase execution, edit and split.** Size L; depends on ADV-02, ADV-05; covers GIT-08. Execute checkpointed plans, support edit/split/continue/skip/abort and restart recovery. Test root/empty/merge-containing ranges; preserve-merges variant is tested or explicitly blocked rather than flattened silently.

- [ ] **ADV-04 — Implement cherry-pick and revert.** Size L; depends on ADV-05, M3; covers GIT-09. Apply ordered selections with explicit merge-parent choice when required. Conflict/empty-commit/restart/abort tests verify final refs and working state.

- [ ] **ADV-05 — Build the native conflict-resolution workspace.** Size L; depends on M3, DISC-04; covers GIT-07. Show base/ours/theirs/result, edit result, stage resolved files and integrate approved external tools. Test rename/delete/add/binary/submodule conflicts and explain side semantics during rebase.

- [ ] **ADV-06 — Implement reset and destructive change previews.** Size L; depends on CORE-10, M3; covers GIT-09/GIT-10. Explain soft/mixed/hard effects on refs/index/tree and protect overwritten content. Reject stale preconditions and failed checkpoints; verify rollback limits and external-change cases.

- [ ] **ADV-07 — Build reflog and recovery timeline.** Size M; depends on CORE-10, ADV-06; covers GIT-10. Show checkpoint/ref history and create recovery branches; preview restore effects and retention. Tests prove committed and dirty-work recovery separately and never imply untracked content is protected by reflog alone.

- [ ] **ADV-08 — Implement published-history and lease protection.** Size M; depends on ADV-02, CORE-08; covers GIT-10. Capture reviewed remote SHA, show affected published history and use explicit expected-SHA force-with-lease. A competing push or background fetch cannot silently widen overwrite permission.

- [ ] **ADV-09 — Implement worktree management.** Size L; depends on CORE-01/CORE-02, M3; covers GIT-11. Add/list/open/move/remove, detect occupied branches and shared refs, protect dirty trees. Test concurrent windows, external moves and locked/missing worktrees.

- [ ] **ADV-10 — Unify operation continuation and cancellation UI.** Size M; depends on ADV-01, ADV-03, ADV-04; covers GIT-07–GIT-10, APP-02. Show current step, conflict needs, continue/skip/abort choices and restart discovery. Process cancellation cannot be mislabeled as an already completed Git abort.

- [ ] **ADV-11 — Add destructive-operation fault tests.** Size L; depends on ADV-01–ADV-10; covers NFR-03/NFR-04. Inject crash, disk full, stale ref/index, corrupt recovery metadata and concurrent Git processes. Assert final repository content/ref invariants and understandable recovery outcomes.

- [ ] **ADV-12 — Validate advanced Git usability.** Size M; depends on ADV-11; covers GIT-07–GIT-11, NFR-02. Users reorder/split/squash commits, resolve conflict, recover a commit and handle rejected lease using keyboard/native controls. Fix critical comprehension and accessibility failures before beta.

## M5 — Integrated workflows and compatibility

- [ ] **INT-01 — Connect issues to local branches and editors.** Size M; depends on M2, M3; covers HUB-08. From an issue, select/clone repo, create branch, open selected editor/terminal and retain issue link. Validate duplicate names, dirty worktrees and multiple accounts.

- [ ] **INT-02 — Connect local branches, forks and pull requests.** Size L; depends on M2, M4; covers HUB-04/HUB-08. Checkout PR into branch/worktree, configure fork remotes deliberately, push and create linked PR. Test deleted heads, insufficient access and mismatched GitHub/transport identities.

- [ ] **INT-03 — Complete Actions control and downloads.** Size L; depends on COL-09, FND-09; covers HUB-07. Implement typed dispatch inputs/ref, rerun failed/all, cancel, log search and artifact download. Validate pending/expired/unknown outcomes, redirected downloads and archive traversal/size protections.

- [ ] **INT-04 — Complete signing and credential interoperability.** Size L; depends on M3, DISC-03; covers GIT-03/GIT-12. Exercise configured GPG/SSH commit/tag signing, agents, Keychain bridge and approved helpers from a GUI-launched app. Missing/passphrase/cancel cases are actionable and never downgrade signing silently.

- [ ] **INT-05 — Complete LFS and submodule workflows.** Size L; depends on M3, DISC-03; covers GIT-12. Clone/update LFS/submodules, show pointer status, open submodule repos and commit superproject pointers. Test nested/private remotes, missing helpers, dirty submodules and limited connectivity.

- [ ] **INT-06 — Complete repository trust and external-tool handling.** Size M; depends on FND-07, INT-04, INT-05; covers GIT-12, NFR-04. Make hooks/filters/helpers/merge tools opt into an understandable trust model. Test hostile configuration and external changes; browsing does not execute arbitrary repository commands.

- [ ] **INT-07 — Complete onboarding and workspace continuity.** Size M; depends on FND-02, COL-02, INT-01/INT-02; covers APP-01–APP-03. Add setup diagnostics, account/author explanations, saved workspace restoration and deep links. A new user reaches their first useful GitHub/local action without configuring hidden internals.

- [ ] **INT-08 — Validate the feature-complete beta contract.** Size L; depends on M4, INT-01–INT-07; covers all APP/HUB/GIT requirements. Run the six PRD journeys and 20 workflow scripts, including folder connection, update native/handoff counts and close feature gaps. Advanced Git remains mandatory for the 1.0 gate.

## M6 — Quality and private beta

- [ ] **QUAL-01 — Meet performance and energy budgets.** Size L; depends on M5; covers NFR-01/NFR-05. Measure PRD fixtures on supported hardware, including idle, wake, large history/diff and long logs. Resolve regressions; record p50/p95, memory and CPU with reproducible procedures.

- [ ] **QUAL-02 — Complete accessibility and native interaction audit.** Size M; depends on M5; covers NFR-02, APP-02. Test VoiceOver, keyboard-only, focus restoration, text sizing, contrast/reduced motion and multi-window commands. Fix blocking journey failures and document tested environments.

- [ ] **QUAL-03 — Audit privacy, trust boundaries and diagnostics.** Size L; depends on M5; covers NFR-04/NFR-07. Test cache/draft erasure, cross-account isolation, redirects, auth replay, malicious content/config, download safety and diagnostic redaction. Verify recovery retention does not silently consume unbounded disk space.

- [ ] **QUAL-04 — Run the compatibility and failure matrix.** Size L; depends on M5; covers NFR-03/NFR-06. Test supported OS/CPU, large repos, LFS/submodules, SSH/signing, forks, restricted orgs, offline/revoke/rate-limit/ambiguous writes and external Git. Record exact supported/unsupported configurations.

- [ ] **QUAL-05 — Run moderated private beta.** Size M; depends on INT-08; covers PRD success measures. Recruit representative testers, obtain consent, observe journeys and collect opt-in reliability data. Validate recovery comprehension; report sample sizes rather than unsupported success percentages.

- [ ] **QUAL-06 — Close release blockers and verify fixes.** Size L; depends on QUAL-01–QUAL-05; covers NFR-01–NFR-07. Triage defects by impact, add appropriate regression checks, rerun affected workflows and audit requirement evidence. No unresolved integrity, credential or misplaced-review blocker may be waived as polish.

- [ ] **QUAL-07 — Publish the release readiness report.** Size S; depends on QUAL-06; covers M6 gate. Summarize requirement coverage, benchmark results, reliability sample, known limitations and residual risks. Update API registry states from evidence, not feature labels.

## M7 — Distribution and launch

- [ ] **SHIP-01 — Finalize signed/notarized release packaging.** Size M; depends on DISC-03, M5; covers NFR-06. Sign app/helpers, enable chosen runtime protections, notarize/staple and verify on a clean supported Mac. Package provenance, licenses and required source/distribution materials are included.

- [ ] **SHIP-02 — Implement and verify signed updates.** Size L; depends on DISC-06, SHIP-01; covers NFR-06. Test beta → release update, interrupted download/install, rejected signatures and migration/rollback policy. A bad update feed cannot install an untrusted binary.

- [ ] **SHIP-03 — Finalize product identity, license and privacy/support policy.** Size M; depends on DISC-01, QUAL-03; covers DEC-15, NFR-04. Choose distinct name/assets, business/license model and privacy terms reflecting actual data flows; establish support owner and broker operating policy if applicable.

- [ ] **SHIP-04 — Write onboarding, workflow and recovery help.** Size M; depends on INT-08, ADV-12; covers APP-04, GIT-10, NFR-07. Document account/author distinctions, permissions, conflict/rebase recovery, cache/retention and known API handoffs. Verify instructions against the release build.

- [ ] **SHIP-05 — Prepare diagnostics, incident and maintenance procedures.** Size M; depends on FND-09, SHIP-02; covers NFR-07. Rehearse update revocation/support escalation; assign API/Git/dependency monitoring and patch ownership. Diagnostic submission remains explicit and previewable.

- [ ] **SHIP-06 — Execute public 1.0 release gate.** Size S; depends on M6, SHIP-01–SHIP-05; covers all PRD requirements. Verify release artifact, requirement evidence, support links and coverage report. Record release decision and publish through the agreed distribution process only when implementation reaches this milestone.

## R1/R2 — Broader GitHub coverage

These are roadmap epics, not fully estimated sprint tickets. Each starts with an endpoint/permission audit, explicit requirements and a smaller implementation breakdown. Size L unless stated otherwise; all depend on public 1.0 and DISC-05's registry. No completion of these items is implied by the planning work.

- [ ] **EXT-01 — Projects V2.** R1/P1; CAP-15. Build supported project list/table/board/item/field/draft operations. Done when selected field types round-trip correctly, inaccessible items stay protected, and unsupported layouts/automation are labeled.

- [ ] **EXT-02 — Discussions and richer issues.** R1/P1; CAP-06/CAP-16. Add discussions/replies/answers and sub-issues/dependencies/types. Validate permissions, hierarchy changes and form limitations with explicit acceptance fixtures.

- [ ] **EXT-03 — Releases, assets and deployment workflows.** R1/P1; CAP-17/CAP-18. Add draft/publish/generated notes/assets and supported environment approvals. Verify immutable/published-state restrictions, upload failure handling and approval roles.

- [ ] **EXT-04 — Security and dependency workflows.** R1/P1; CAP-20/CAP-34. Add alert triage, supported dismissal/reopen and selected advisory/dependency operations. Keep sensitive alert data out of logs and validate plan/role restrictions.

- [ ] **EXT-05 — Repository administration and advanced Actions.** R1/P1; CAP-09/CAP-13/CAP-14/CAP-19/CAP-21/CAP-33. Add settings/rules/collaborators, supported auto-merge/queues, secrets/variables and workflow controls. Destructive/admin writes show precise effects; secret values are never offered for read-back.

- [ ] **EXT-06 — Developer utilities and content coverage.** R1/P1; CAP-11/CAP-22–CAP-26. Prioritize gists/stars/profile, richer search/insights, packages, Pages and wiki after audits. Distinguish registry protocols, wiki Git and public API operations; no generic upload assumption.

- [ ] **EXT-07 — Enterprise hosts and team administration.** R2/P1; CAP-27/CAP-28. Define supported Enterprise Server versions/extra hosts, per-host auth/API URLs and team/org permissions. Prove host isolation and role restrictions on real supported environments before claiming compatibility.

- [ ] **EXT-08 — Enterprise/service/API inventory completion.** R2/P2; CAP-28–CAP-34. Audit billing/audit/SCIM, Codespaces, Copilot management, Apps/Marketplace/Sponsors and remaining OpenAPI/schema operations. Assign each operation native, partial, handoff, deferred or unavailable with evidence and owner; implement prioritized supported workflows.

- [ ] **EXT-09 — Native productivity extensions.** R1/R2/P2; APP-02/APP-03. Validate menu-bar status, App Intents/Shortcuts, richer saved workspaces and local indexing with user research. Define privacy, background lifetime and keyboard/accessibility behavior before implementing.

- [ ] **EXT-10 — Optional AI and advanced developer experiments.** R2/P2; covers PRD section 9. Investigate opt-in summaries, commit assistance, stacked PRs and specialized Git tools. Require a separate PRD, data-sharing/entitlement proof and measurable value; never auto-approve, merge or rewrite history.

## Requirement traceability

Primary task ownership is listed below; quality and release tasks apply across all requirements.

| PRD requirement | Primary tasks |
| --- | --- |
| APP-01 | DISC-02, FND-03, INT-07 |
| APP-02 | FND-02, ADV-10, QUAL-02 |
| APP-03 | FND-02, COL-02, INT-07 |
| APP-04 | DISC-05, FND-04, FND-05 |
| APP-05 | FND-06, FND-08, COL-05 |
| HUB-01 | COL-01, CORE-03 |
| HUB-02 | DISC-02, COL-03 |
| HUB-03 | COL-04, COL-05 |
| HUB-04 | COL-06, INT-02 |
| HUB-05 | DISC-04, COL-07 |
| HUB-06 | COL-08 |
| HUB-07 | COL-09, INT-03 |
| HUB-08 | INT-01, INT-02 |
| GIT-01 | DISC-03, FND-07, CORE-01, CORE-03 |
| GIT-02 | CORE-04, CORE-05 |
| GIT-03 | CORE-06, INT-04 |
| GIT-04 | CORE-07, CORE-08 |
| GIT-05 | DISC-04, CORE-09 |
| GIT-06 | CORE-11 |
| GIT-07 | ADV-01, ADV-05, ADV-10 |
| GIT-08 | ADV-02, ADV-03 |
| GIT-09 | ADV-04, ADV-06 |
| GIT-10 | CORE-10, ADV-07, ADV-08 |
| GIT-11 | CORE-01, CORE-02, ADV-09 |
| GIT-12 | INT-04, INT-05, INT-06 |
| GIT-13 | CORE-13, CORE-14, CORE-12 |
| NFR-01 | DISC-04, QUAL-01 |
| NFR-02 | FND-02, ADV-12, QUAL-02 |
| NFR-03 | FND-07, CORE-12, ADV-11, QUAL-04 |
| NFR-04 | FND-03, FND-06, INT-06, QUAL-03 |
| NFR-05 | FND-08, QUAL-01 |
| NFR-06 | DISC-03, DISC-06, FND-01, QUAL-04, SHIP-01, SHIP-02 |
| NFR-07 | FND-09, QUAL-03, SHIP-04, SHIP-05 |

## Before starting any implementation task

Check prerequisites and the relevant capability evidence; split L epics; identify the smallest useful vertical slice; define a meaningful validation path. Update acceptance criteria if a verified API constraint changes the design, and record any effect on the 1.0 release contract before considering the feature complete.
