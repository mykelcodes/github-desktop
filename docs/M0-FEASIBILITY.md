# M0 feasibility report

12 November 2026 · Gate open · Evidence from branch `feat/m0-feasibility`

The discovery contract and local runtime experiments are available for review. Production authentication, signed distribution, clean-machine compatibility and accessibility validation remain unresolved. DISC-07 cannot pass until the remaining evidence below exists.

## Acceptance audit

| Task | Evidence delivered | Remaining acceptance |
| --- | --- | --- |
| DISC-01 | Frozen set of 20 manual scripts, role-based ten-person cohort, fixtures, screen map, staffing baseline, name shortlist and scope exclusions in the workflow contract | Recruit participants and execute sessions during implementation/beta. Names and session results have not been invented. |
| DISC-02 | User supplied OAuth Client ID `Ov23lit2u709b0ZDyGxQ`. Local browser/PKCE, refresh and revocation harness; two passing synthetic fixture tests | Live registered-app output, notification mutations, private/organization restrictions, two accounts, signed native callback, refresh races and broker ownership |
| DISC-03 | Pinned source-built Git 2.56.1 and Git LFS 3.8.1 in an ad-hoc hardened-runtime app; native repository/diff observation; relocated runtime checks; public HTTPS read; interrupted rebase recovery | Authenticated HTTPS/SSH, SSH agents/GPG, clean macOS 15 test machine, Developer ID/notarization, complete dependency/license/source distribution review |
| DISC-04 | 20 trials per control/fixture, bounded-text comparison, 100,000 actual commits and 10,000-file status fixture, timings and process memory | Keyboard/VoiceOver, visible scrolling/selection, reference 16 GB hardware, integrated history retrieval/rendering and final control acceptance |
| DISC-05 | Hash-pinned official REST/GraphQL inputs, generated 1,280 REST operations and 315 GraphQL root fields | Manual CAP/PRD mapping review, operation-specific token/permission/role/host/plan limits, concrete fallback destinations and representative live operations |
| DISC-06 | Dependency candidates, observed toolchain/runtime, provisional control/platform decisions and evidence below | Resolve auth/distribution dependencies, updater/persistence validation, macOS 15 and CPU support matrix, named operational owners |
| DISC-07 | This acceptance audit, evidence links and ordered remaining work | Authenticated workflow demonstration, closure of DISC-02–DISC-06, revised estimates based on those results, final feasibility approval |

[Workflow contract](WORKFLOW-CONTRACT.md), [authentication research](AUTH-FEASIBILITY.md), [runtime manifest](evidence/runtime-manifest.json), [runtime checks](evidence/runtime-check.json), [recovery results](evidence/recovery.json), [REST inventory](evidence/rest-operations.csv), [GraphQL inventory](evidence/graphql-operations.json).

## Authentication setup

The repository URL `https://github.com/mykelcodes/github-desktop` serves as the development homepage. Register `http://127.0.0.1:49152/oauth/callback` for the local harness, with wildcard matching disabled. Confirm the actual registration matches before running. GitHub documents loopback redirects for desktop applications. The HTTPS callback/broker proposal remains the production candidate pending signed native validation. [GitHub registration](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app), [loopback callbacks](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#loopback-redirect-urls).

Run from an interactive terminal. The script prompts for the developer-owned secret with hidden input, opens browser consent, reads identity and one page of repositories/notifications, refreshes when supported, and attempts revocation of its test token. It prints statuses and suppresses tokens, codes and response bodies. It keeps credentials in process memory. The default requested scopes are `read:user notifications offline_access`; private-repository coverage needs a separate deliberate grant/test with `repo`. The harness reads notification content transiently while decoding the response. It does not mutate inbox threads.

```sh
python3 scripts/m0/test-oauth.py
python3 scripts/m0/oauth.py --client-id Ov23lit2u709b0ZDyGxQ
```

Use dedicated accounts and fixtures for the broader acceptance matrix. Save only the redacted output. The harness has synthetic tests for callback state/path/host/replay, PKCE parameters, refresh lifecycle, cleanup and output redaction. It has no live result yet. It uses a local developer secret for a feasibility test. A distributed client needs the separately validated production exchange architecture.

## Runtime and recovery results

Source archive SHA-256 and official Git LFS asset digest are recorded in the manifest. The build targets macOS 15 and was executed on arm64 macOS 27.0.1 with Xcode 27.2 / Swift 6.4.2. Git and its HTTPS helper linked only Apple system library paths on this machine. Git resolves its helper directory inside the relocated app. Git LFS is staged alongside it. The spike's bundle metadata selects the bundled executable through the existing app entry point. Ordinary development builds retain their installed-Git configuration.

The relocated runtime passed local bare-remote push/clone, LFS pointer and content retrieval, commit/tag signing and verification with a disposable SSH key, and Git/LFS integrity checks. Its HTTPS helper read the public Git upstream ref without credentials. Native app observation showed the repository, branch, file list and selected diff. The signature passed `codesign --verify --deep --strict`. This is ad-hoc signing. `security find-identity -v -p codesigning` reported zero valid identities.

The recovery harness wrote committed and dirty checkpoints before rebase, killed the Git process group after a commit replay, and detected rebase state from a fresh process. Abort restored the original HEAD. Applying the dirty checkpoint with index restoration reproduced the staged patch, unstaged patch, porcelain state and untracked bytes. A second interruption resumed successfully, and the committed checkpoint was restored to a separate branch. The application mutation coordinator and journal remain implementation work. Power loss, disk full and shared-repository contention remain outside this experiment.

The build intentionally excludes Tcl/Tk, Perl and Python Git tooling. Verify every required helper, hook and submodule path on the clean-machine matrix before freezing the distribution. The source archive remains in `.build/m0`; no developer Git or system installation was modified.

## Control measurements and selection

The optimized control harness renders a 1000 × 700 offscreen bitmap after layout. Each case runs 20 times with fresh views/windows and run-loop cleanup between samples. The fixture contains 20,000 large/Unicode diff lines, rename metadata, a binary summary, and 100,000 synthetic history rows. The Git benchmark separately retrieves 200 entries from 100,000 real linear commits and measures a clean 10,000-file worktree after warmup.

| Operation | p50 ms | p95 ms |
| --- | --- | --- |
| Current NSTextView, 20,000 ASCII diff lines | 349.51 | 374.36 |
| Current NSTextView, 20,000 Unicode diff lines | 874.52 | 1265.97 |
| NSTextView, 200-line ASCII page | 21.37 | 26.95 |
| NSTextView, 200-line Unicode page | 31.39 | 36.43 |
| SwiftUI lazy rows, Unicode fixture | 14.22 | 20.39 |
| NSTableView, first viewport of 100,000 rows | 29.04 | 38.26 |
| SwiftUI lazy rows, first viewport of 100,000 rows | 12.70 | 18.50 |
| Git 2.56.1, first 200 of 100,000 commits | 6.04 | 6.42 |
| Git 2.56.1, warm status of 10,000 files | 21.61 | 22.80 |

The technical recommendation is bounded AppKit text pages for selectable diffs and a virtualized native table for history. The lazy SwiftUI comparison also merits interaction testing. Its rows omit the existing diff styling and continuous text selection, so timings measure different rendering workloads. Validate selection, line anchoring and VoiceOver before adopting either final control. Paging must preserve whole-file navigation and review positions. No page truncation may imply a complete diff.

The final whole-suite run reached 500,432,896 bytes maximum RSS and 329,139,568 bytes peak memory footprint. These are peak process measures across multiple cases. The PRD's 350 MB steady-workspace target still needs its own measurement. This Mac has 48 GiB RAM, so these results do not establish the 16 GB reference-machine budget. Launch, idle CPU and full application history remain unmeasured. [Raw control results](evidence/controls-results.json), [resource measurements](evidence/controls-resource.txt), [Git benchmark](evidence/git-benchmark.json).

## Dependency and architecture review

| Component | Provenance and maintenance evidence | Decision and replacement consideration |
| --- | --- | --- |
| SwiftUI/AppKit/URLSession/Keychain | Apple SDKs from observed Xcode 27.2; package has no external Swift dependencies | Retain native architecture. macOS 15 and Intel compatibility need execution evidence. Revisit high-volume controls after accessibility tests. |
| Git 2.56.1 | Pinned kernel.org release and checksum; source built locally, `COPYING` retained | Viable local bundled-CLI candidate. Review full runtime dependencies and supply corresponding source/build materials before distribution. A runtime substitution would need the same mutation/recovery suite. [Source distribution](https://www.kernel.org/pub/software/scm/git/), [Git license](https://github.com/git/git/blob/v2.56.1/COPYING). |
| Git LFS 3.8.1 | Official arm64 release digest and version; license retained | Local transfer proven. Complete transitive notices/source audit and remote service tests before distribution. Preserve an actionable missing-helper state. [Release](https://github.com/git-lfs/git-lfs/releases/tag/v3.8.1), [license](https://github.com/git-lfs/git-lfs/blob/v3.8.1/LICENSE.md). |
| SQLite | Existing architecture candidate; no package/version adopted | Compare direct system SQLite with GRDB through migration/corruption/draft recovery tests before selecting the persistence layer. Current folder registry remains atomic JSON. |
| Sparkle 2.10.1 | Official release published 25 October 2026; project documents MIT and EdDSA/code signatures | Candidate updater, with integration and rejection/interruption tests outstanding. Keep update logic behind the selected distribution boundary. [Project](https://sparkle-project.org/), [release](https://github.com/sparkle-project/Sparkle/releases/tag/2.10.1). |
| OAuth broker | Proposed narrow exchange/refresh service; no deployment/owner supplied | Resolve hosting/domain, retention, incident ownership and cost after live tests. No confidential secret belongs in the distributed binary. |

## Remaining execution order

1. Record the registered-app harness result. Complete native callback, negative cases, refresh/revocation, inbox mutations and both-account/restricted-organization cases. Select production auth and assign broker ownership if adopted.
2. Test the actual runtime app on a clean supported Mac with authenticated HTTPS/SSH, agents, GPG, LFS and submodules. Obtain a Developer ID identity and notarize/staple/validate the same package. Complete notices and corresponding-source distribution review.
3. Run keyboard/VoiceOver and visible interaction checks for diff/history controls on reference hardware. Validate the platform/CPU and toolchain matrix, persistence migration candidate and signed updater.
4. Curate operation-level permissions/hosts/limits/fallbacks from the pinned inventory. Exercise representative 1.0 reads and mutations on disposable GitHub resources with the registered token. Preserve denied/stale/outcome-unknown evidence.
5. Close the architecture decisions against those results and revise the plan. Product/engineering roles approve DISC-07 only after the authenticated workflow and runtime/recovery evidence meet the original gate.

The existing 66–102 engineer-week product estimate remains provisional. Local measurements reduce uncertainty around runtime relocation and bounded controls. Auth infrastructure, distribution and compatibility still determine the critical path, so a new delivery date would be premature. Participant recruitment, staffing availability, product-name selection and operational ownership remain product inputs.

## Reproducing the local spikes

The tools use Python's standard library and the existing Swift toolchain. Keep downloaded inputs in `.build/m0`. Git/LFS staging verifies the pinned hashes before installation into that build directory. The runtime app script produces `.build/m0/Git Runtime Spike.app`. Full transitive licensing review remains a shipping prerequisite.

```sh
mkdir -p .build/m0
curl --fail --location https://www.kernel.org/pub/software/scm/git/git-2.56.1.tar.xz -o .build/m0/git-2.56.1.tar.xz
curl --fail --location https://github.com/git-lfs/git-lfs/releases/download/v3.8.1/git-lfs-darwin-arm64-v3.8.1.zip -o .build/m0/git-lfs-darwin-arm64-v3.8.1.zip
curl --fail --location https://raw.githubusercontent.com/git-lfs/git-lfs/v3.8.1/LICENSE.md -o .build/m0/Git-LFS-LICENSE.md
bash scripts/m0/build-git-runtime.sh
bash scripts/m0/stage-lfs.sh
bash scripts/m0/build-runtime-app.sh
python3 scripts/m0/runtime-check.py --runtime '.build/m0/Git Runtime Spike.app/Contents/Resources/GitRuntime'
python3 scripts/m0/recovery.py --git "$PWD/.build/m0/Git Runtime Spike.app/Contents/Resources/GitRuntime/bin/git"
python3 scripts/m0/git-benchmark.py --git "$PWD/.build/m0/git-runtime/bin/git"
swiftc -O -module-cache-path .build/clang-module-cache -o .build/m0/controls-benchmark scripts/m0/ControlsBenchmark.swift Sources/GitWorkspace/NativeDiffView.swift
/usr/bin/time -l .build/m0/controls-benchmark
```

Download the REST input from the immutable URL in `api-sources.json` as `.build/m0/openapi.json`, then run `python3 scripts/m0/api-inventory.py`. The generator can use the retained compressed GraphQL snapshot when `.build/m0/schema.graphql` is absent. A different local schema fails hash verification, requiring an explicit review and pin update.
