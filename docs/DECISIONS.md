# Decisions, assumptions, and risks

12 November 2026 · Living register

## 1. Confirmed requirements

| ID | Decision | Evidence/status |
| --- | --- | --- |
| DEC-01 | Build a native macOS application in Swift | Confirmed in the original request. |
| DEC-02 | Serve individual developers and small teams first | Confirmed in the user's clarification. |
| DEC-03 | Include a full Git client and advanced history editing in the first public release | Confirmed in the user's clarification; phased internal alphas do not change this. |
| DEC-04 | Prepare the plan, PRD and task lists before starting application implementation | Documentation was delivered first; the user subsequently authorized the prototype implementation and parallel agents. |
| DEC-05 | Aim for broad GitHub website/API workflow coverage over time | Confirmed ambition; exact release sequencing and technical feasibility are proposed in this package. |
| DEC-17 | Let users connect their local project folders to GitHub repositories | Confirmed in the follow-up request; incorporated into 1.0 repository setup as GIT-13. |

## 2. Proposed defaults

These defaults let planning proceed. They are recommendations, not statements that the user approved them or that a spike has passed.

| ID | Proposal | Reason | Decide by / owner role |
| --- | --- | --- | --- |
| DEC-06 | SwiftUI with selective AppKit; small local Swift packages | Native behavior and performance without a web shell | M0 / macOS lead |
| DEC-07 | macOS 15 baseline; Apple Silicon first, Intel if viable | Bound testing while retaining reasonable compatibility | M0 / product + engineering |
| DEC-08 | GitHub.com first; host model extensible | Deliver the main audience before version-specific enterprise support | M0 / product |
| DEC-09 | Bundled Git CLI and validated helper runtime | Mature advanced Git semantics | M0 / Git lead |
| DEC-10 | OAuth app for broad user workflows, pending auth proof | Inbox/account-wide use cases need endpoint-specific compatibility | M0 / integration lead |
| DEC-11 | Direct-download signed/notarized app; sandbox decision tested | Git helpers and repository access influence packaging | M0 / macOS lead |
| DEC-12 | SQLite cache; Keychain secrets; offline drafts without silent write replay | Predictable ownership and synchronization | M0 / engineering |
| DEC-13 | Poll/revalidate initially; no webhook relay dependency | Smaller operating footprint and clear lifecycle behavior | M0 / integration lead |
| DEC-14 | Preserve/recover work before advanced mutations | A full Git client's trust depends on correctness | M0 / Git lead |
| DEC-15 | A distinct public product name | Avoid confusion with the existing official product | Before external beta / product |
| DEC-16 | AI assistance is optional post-1.0 work | Keep core scope and private-code handling explicit | R1 or later / product |
| DEC-18 | Repository Local tab plus global Local Folders entry | User suggested a separate tab; this layout supports both repository-first and folder-first workflows | M1/M3 / product + macOS lead |

## 3. Open decisions and required evidence

| ID | Question to resolve | Default direction | Evidence needed / owning task |
| --- | --- | --- | --- |
| OPEN-01 | Which exact authorization exchange/refresh flow is supported and appropriate? | System browser + PKCE; broker if confidential exchange is required | Registered-app tests, security review, cancellation/replay/refresh/revocation evidence / DISC-02 |
| OPEN-02 | Can the production token access and mutate the notification inbox correctly? | Prove OAuth behavior before freezing onboarding | Live read/read-state/subscription tests and restriction cases / DISC-02 |
| OPEN-03 | Can the Git runtime ship with desired helpers and signatures? | Bundle tested Git/LFS; integrate user signing/SSH tools | Clean-machine clone/push/sign, license inventory, signed package / DISC-03 |
| OPEN-04 | What platform/CPU and distribution matrix can the team support? | macOS 15+, direct download; test Intel feasibility | Toolchain and test hardware assessment / DISC-06 |
| OPEN-05 | Which diff/history and persistence implementations meet budgets? | Native text/table controls and SQLite | Measured prototypes, migration exercise, dependency review / DISC-04, DISC-06 |
| OPEN-06 | Is a backend needed, and who operates it? | None unless authentication requires it | Chosen auth architecture, privacy boundaries, hosting cost and owner / DISC-02, DISC-06 |
| OPEN-07 | What are the staffing, budget, license and business model? | Two-engineer estimate; no monetization restriction in core design yet | Product decision before committing a delivery date or public launch / DISC-01, SHIP-03 |
| OPEN-08 | What is the product name and visual identity? | Temporary neutral working label | Availability and branding review; no implied GitHub affiliation / DISC-01, SHIP-03 |
| OPEN-09 | What content-cache and recovery-retention policy fits real usage? | User-visible controls, finite retention, protected recovery checkpoints | Storage/disk-full tests and user comprehension / CORE-10, QUAL-03 |

Unresolved implementation choices do not prevent drafting or reviewing these documents. OPEN-01–OPEN-06 must be resolved before their dependent production implementation. Budget, naming and business-model decisions can progress alongside early prototypes.

## 4. Risk register

| ID | Risk | Likelihood / impact | Mitigation and exit evidence | Owner role |
| --- | --- | --- | --- | --- |
| RISK-01 | Literal web/API parity creates an unbounded product | High / High | Maintain operation inventory, define releases, count handoffs separately; review scope at every gate | Product |
| RISK-02 | Token model fails inbox or organization access | Medium / High | Registered-app auth matrix in M0; no PAT-only onboarding surprise | Integration |
| RISK-03 | Git history editing loses uncommitted or committed work | Medium / Critical | Checkpoint design, real-Git fixtures, failure injection, recovery UX; no unresolved integrity defects | Git |
| RISK-04 | External tools/worktrees invalidate internal state | High / High | Common-repository coordination, ref/index rechecks, filesystem invalidation and stale-state tests | Git |
| RISK-05 | Native diff/review line mapping is wrong | Medium / High | Revision-specific mapping, renamed/deleted/large-file fixtures, incomplete-diff guard | UI + Integration |
| RISK-06 | App Sandbox/helpers/signing conflict with distribution | Medium / High | Ship minimal signed bundle in M0; verify fresh Mac, SSH, GPG and LFS | macOS |
| RISK-07 | Private content or credentials leak across accounts/logs | Medium / Critical | Host/account keys, scoped tokens, redirect policy, diagnostics redaction, erasure tests | Security + Engineering |
| RISK-08 | Hooks/filters/config or malformed content execute unexpectedly | Medium / High | Repository trust model, safe read flags, no shell interpolation, sanitized rendering | Git + Security |
| RISK-09 | API limits/deprecations or incomplete results break workflow | High / Medium | Budgets, pagination, explicit completeness, version/schema monitoring and fallback states | Integration |
| RISK-10 | Large repositories drain memory/CPU/battery | High / Medium | Bounded/virtualized rendering, fixture benchmarks, debounced watchers and adaptive refresh | macOS |
| RISK-11 | Ambiguous remote write retries duplicate comments or operations | Medium / High | Reconcile before retry; outcome-unknown state; never replay destructive writes silently | Integration |
| RISK-12 | Full Git plus collaboration exceeds capacity | High / High | Re-estimate after spikes, reserve contingency, defer optional/post-1.0 scope, preserve confirmed requirements | Product + Engineering |
| RISK-13 | Unmaintained dependencies or invalid updates compromise distribution | Medium / High | Version/provenance inventory, signed updater, update rejection tests and patch ownership | Release |
| RISK-14 | “GitHub Desktop” working name implies official affiliation | High / Medium | Choose a distinct public name; review applicable branding guidance before launch | Product |

## 5. Product and operational considerations

- Prefer a small set of polished end-to-end workflows over exposing endpoint-shaped forms. Capability coverage still remains visible and accountable.
- Keep an app account separate from a repository's author email, transport credential, and signing identity. Display each where it matters.
- Decide how support handles recovery data without collecting private code. Diagnostic bundles should be previewable and redacted.
- If telemetry is used, obtain opt-in consent and retain only the operational information needed for the stated measures.
- Select a license and dependency-distribution approach before publishing code or binaries. No license or pricing decision has been assumed in these docs.
- GitHub's branding policies should be reviewed before choosing the final name/assets; this document makes no legal clearance claim. [GitHub trademark policy](https://docs.github.com/en/site-policy/content-removal-policies/github-trademark-policy).
- Plan a maintenance budget for OS/SDK, Git/helper updates, API changes, regressions and support after launch. Feature parity is a continuing responsibility.

## 6. Recording a resolved decision

For each material decision, record date, owner, options, chosen approach, evidence, consequences, affected requirements/tasks, and conditions for revisiting it. A recommendation becomes “accepted” only after an explicit product decision or the designated technical validation; do not rewrite the user's confirmed requirements as assumptions.

## 7. M0 evidence update

On 12 November, DISC-01 established the [20-workflow contract](WORKFLOW-CONTRACT.md), representative cohort/fixtures, screen map, name shortlist and staffing assumptions. The Git Workspace label remains provisional pending product selection and availability review.

Local experiments support the bundled-CLI direction in DEC-09. Git 2.56.1 and Git LFS 3.8.1 run after relocation inside the ad-hoc hardened-runtime app, and synthetic mutation/checkpoint recovery passed. The rendering recommendation is bounded native text pages with a virtualized history table, pending interaction/accessibility validation. These findings narrow the candidates for DEC-06/DEC-09 and OPEN-03/OPEN-05. Clean-machine, production auth, platform matrix and signed distribution gates remain open. The [feasibility report](M0-FEASIBILITY.md) records dependency provenance, measurements, limitations and remaining decisions. No production architecture proposal has been accepted through a documentation-only change.
