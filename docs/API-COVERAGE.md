# GitHub capability and API coverage

Research snapshot: 12 November 2026. This is a planning inventory, not a claim that endpoints have been exercised. Documentation review is complete for the linked core sources; authenticated compatibility tests remain implementation work.

## 1. What parity means

Track **user operations**, not website pages or a raw count of HTTP routes. “Review a PR” includes fetching all relevant files, anchoring comments correctly, submitting a review, and handling permission and revision changes. One read endpoint does not satisfy it.

Coverage classifications:

- **Native:** all defined operation steps are implemented and tested in the app.
- **Partial:** some steps are native; the remaining steps and limitations are explicit.
- **Handoff:** the app opens the relevant GitHub page or external tool.
- **Deferred:** a documented or plausible API capability is scheduled later.
- **Unverified:** the exact operation/token/host combination has not been proved.
- **Unavailable:** no supported public interface has been identified after investigation; record evidence and recheck date.

The table below defines **planned release coverage**, not current support. The local prototype implements read-only portions of CAP-03/CAP-04 and public metadata lookup from CAP-02; see [prototype evidence](PROTOTYPE.md). No complete API family or authenticated capability is verified. A browser handoff never contributes to the native coverage numerator. Some GitHub operations require administrative roles, paid features, organization approval, or a different token type; access must be evaluated per account, host, resource, and operation.

## 2. Capability map

**D** = relevant documentation reviewed; endpoint/token behavior still needs tests. **I** = inventory candidate requiring a deeper endpoint audit. R1 means after 1.0; R2 means broader administration/enterprise work, with no committed date.

| ID | User operations | Interface/evidence | Intended delivery and important limitation |
| --- | --- | --- | --- |
| CAP-01 | Sign in, identify user, switch accounts, reconnect | OAuth authorization + REST viewer; D | 1.0. Final app/token architecture decided by DISC-02. |
| CAP-02 | List/search/create/update repositories, fork, browse metadata | REST Repositories, GraphQL; D | 1.0 discovery/create/fork; R1 settings; destructive administration later. [Repository API](https://docs.github.com/en/rest/repos/repos?apiVersion=2026-03-10). |
| CAP-03 | Read files/README/tree, commits, refs, compare, blame | REST Contents/Git/Commits + GraphQL + local Git; D | 1.0 reading/local editing. Large content needs alternate loading and truncation states. [Contents API](https://docs.github.com/en/rest/repos/contents). |
| CAP-04 | Connect local folders/remotes, clone, stage, commit, branch, push, rebase, recover | Local Git executable and Git transport; GitHub identity lookup through API; D | Full defined Git scope in 1.0, including the Local tab (GIT-13). Folder association is app-managed; local Git operations are not implemented by GitHub REST/GraphQL. |
| CAP-05 | Issues, comments, labels, assignees, milestones, reactions | REST Issues and related families; D | 1.0 core lifecycle. Shared PR metadata must use the appropriate issue operations. [Issues API](https://docs.github.com/en/rest/issues/issues). |
| CAP-06 | Issue hierarchy, dependencies, types, advanced forms | REST Sub-issues/Dependencies; other exact routes I | R1. Forms rendering and submission semantics need separate validation. [Sub-issues](https://docs.github.com/en/rest/issues/sub-issues), [Dependencies](https://docs.github.com/en/rest/issues/issue-dependencies). |
| CAP-07 | Create/edit PR, draft state, reviewers, checkout, close/reopen | REST Pulls + GraphQL + local Git; D | 1.0. Validate fork permissions, missing branches, and draft-state mutations. [Pulls API](https://docs.github.com/en/rest/pulls/pulls). |
| CAP-08 | Review, line comments, replies, resolve threads | REST Reviews/Review comments + GraphQL; D | 1.0. Exact mutation availability and revision anchoring are acceptance gates. [Review API](https://docs.github.com/en/rest/pulls/reviews). |
| CAP-09 | Merge, inspect protections, auto-merge, merge queue | REST merge/rules + GraphQL; D/I | 1.0 permitted direct merges and rule context; R1 native auto-merge/queue actions. Queue-required cases hand off at 1.0. [Rules API](https://docs.github.com/en/rest/repos/rules). |
| CAP-10 | Notifications, read/done, subscribe/unsubscribe | REST Notifications; D | 1.0 subject to OAuth proof. Do not substitute repository events for the user's inbox. See auth caveat below. |
| CAP-11 | Search repositories, issues, PRs, users, code | REST Search + selected GraphQL; D | 1.0 repositories/issues/PRs; R1 users/code UI. Result limits and incomplete results must be visible. [Search API](https://docs.github.com/en/rest/search/search). |
| CAP-12 | Actions runs/jobs/logs, rerun/cancel, dispatch | REST Actions + Checks/Statuses; D | 1.0. Available log downloads/polling are not guaranteed browser-equivalent live streaming. [Runs API](https://docs.github.com/en/rest/actions/workflow-runs). |
| CAP-13 | Download artifacts; manage caches and runners | REST Actions subfamilies; I | 1.0 artifact downloads; R1 caches; R2 runner administration. Audit redirects, expiry, and access per endpoint. |
| CAP-14 | Create/edit workflow files | Git file changes + Contents API; D | 1.0 via normal local Git/editor flow; R1 focused editor. Workflow modification permission differs from running a workflow. |
| CAP-15 | Projects items, fields, tables, boards, drafts | Projects V2 GraphQL; D | R1. Implement supported field/item operations; do not promise web view/layout/automation parity. [Projects guide](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects). |
| CAP-16 | Discussions, replies, answers, categories | GraphQL Discussions; D | R1 discussions/answers; validate category administration separately. [Discussions guide](https://docs.github.com/en/graphql/guides/using-the-graphql-api-for-discussions). |
| CAP-17 | Releases, assets, generated notes, prereleases | REST Releases + local tags; D | R1 native release lifecycle; 1.0 tags/local Git. Respect immutable releases and workflow-related permissions. [Releases API](https://docs.github.com/en/rest/releases/releases). |
| CAP-18 | Deployment status, environments, protection approvals | REST Deployments/Environments/Actions; I | R1 after exact reviewer and permission audit. Display pending state rather than claiming successful deployment. |
| CAP-19 | Manage Actions variables and secrets | REST Actions Secrets/Variables; D/I | R1 repository/environment controls; R2 organization controls. Secrets support metadata and replacement, not retrieval of plaintext values. [Secrets API](https://docs.github.com/en/rest/actions/secrets). |
| CAP-20 | Dependabot/code-scanning/secret-scanning triage | REST security families; D | R1 alerts and supported state changes; R2 advanced configuration. Plan/role checks and sensitive-data handling required. [Dependabot](https://docs.github.com/en/rest/dependabot), [Code scanning](https://docs.github.com/en/rest/code-scanning), [Secret scanning](https://docs.github.com/en/rest/secret-scanning). |
| CAP-21 | Rulesets, branch protection, collaborators, hooks, keys | REST Repositories/Rules/Collaborators/Webhooks; D/I | 1.0 read context for safe operations; R1 repository administration. Extra permissions must be requested in context. |
| CAP-22 | Repository traffic, contributors, insights | REST Metrics/Statistics; I | R1 selected reports; web charts are not automatically reproducible from API data. |
| CAP-23 | Packages and versions, delete/restore | REST Packages + registry protocols; D | R1 metadata/version management; publishing is registry-specific, not one generic REST upload. [Packages API](https://docs.github.com/en/rest/packages). |
| CAP-24 | Pages status, builds, configuration | REST Pages + repository/workflow changes; I | R1 supported controls; host/domain verification may retain handoffs. |
| CAP-25 | Wiki reading/editing | Separate wiki Git repository + rendering; I | R1 dedicated audit; no assumption of a general Wiki CRUD REST API. |
| CAP-26 | Gists, stars, follows, watching, profile updates | REST Gists/Activity/Users; I | R1. Keep private gist semantics and account-level permissions explicit. |
| CAP-27 | Organization/team memberships, invites, permissions | REST Organizations/Teams; D/I | R2 administrative workspace; basic org discovery in 1.0. [Organizations API](https://docs.github.com/en/rest/orgs). |
| CAP-28 | Enterprise policies, audit, SCIM, billing/usage/budgets | Enterprise REST/GraphQL families; I | R2. Token, host, plan, and administrator requirements differ. Payment-method/subscription changes hand off unless a supported interface is verified. |
| CAP-29 | Codespace lifecycle and access | REST Codespaces; D | R1/R2 list/start/stop/create/delete; open coding environment externally. [Codespaces API](https://docs.github.com/en/rest/codespaces). |
| CAP-30 | Copilot policies, configuration, metrics, agent capabilities | REST Copilot and other documented interfaces; D/I | R2 endpoint audit. Existing management APIs do not establish general chat/completion entitlement. [Copilot API](https://docs.github.com/en/rest/copilot). |
| CAP-31 | App installations, integrations, Marketplace, Sponsors | REST/GraphQL where documented; I | R2 audit; authorization, purchases, payment setup, and installation consent may require browser flows. |
| CAP-32 | Account security, 2FA/passkeys, SSO, recovery | Browser identity/security flows; I | Handoff in all initial releases. Never collect GitHub passwords or impersonate an identity provider. |
| CAP-33 | Archive/transfer/delete repository, moderation, custom properties | REST/GraphQL per operation; I | R1/R2. Inspect actual role requirements and irreversible effects before adding a native action. |
| CAP-34 | New API families, attestations, dependency graph, advisories | REST OpenAPI/GraphQL schema inventory; I | Ongoing coverage program. Every unclassified operation is assigned a decision and owner rather than disappearing from scope. |

## 3. Authentication is an early product decision

GitHub generally recommends GitHub Apps for fine-grained permissions and constrained repository access. Broad personal workflows may need a different approach. The provisional choice for this product is an **OAuth app**, subject to the M0 compatibility spike; GitHub App support remains a later option for scoped organization installations. [GitHub Apps versus OAuth apps](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/differences-between-github-apps-and-oauth-apps).

There is a documentation caveat worth testing directly: the notifications reference excludes GitHub App tokens and fine-grained PATs and describes classic PAT support, while the OAuth scopes reference defines a `notifications` scope. Treat OAuth notifications as unverified until a real registered-app test passes. Do not silently require a classic PAT for normal onboarding. [Notifications reference](https://docs.github.com/en/rest/activity/notifications), [OAuth scopes](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps).

GitHub documents PKCE parameters and recommends PKCE for public clients, but its code-exchange/refresh tables also specify a client secret. M0 must establish the supported native flow, including refresh. Never assume PKCE alone proves secretless exchange. If a confidential exchange is required, use a small reviewed broker or revisit the flow explicitly; do not ship a supposed confidential secret in the app. Device flow is not the default for this browser-capable app. [Authorization flow](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps), [OAuth best practices](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/best-practices-for-creating-an-oauth-app).

### Provisional permission requests

Request additional capabilities at the relevant feature, disclose the returned grant, and support refusal. Actual endpoint permissions must be captured in the capability registry.

| Need | OAuth scope candidate | Decision |
| --- | --- | --- |
| Basic public identity/browsing | No scope; `read:user` only if required fields need it | Start with minimal access. |
| Public repository writes | `public_repo` | Ask when enabling write workflows. |
| Private repository collaboration/Git | `repo` | Broad access; clearly explain it. |
| Notifications | `notifications`, or qualifying repository scope | Validate in DISC-02. |
| Workflow-file modification | `workflow` | Separate from reading/rerunning Actions. |
| Organization/team context | `read:org` where needed | Do not request organization-admin access for normal use. |
| Projects, packages, gists, security/admin | Feature-specific scopes/permissions | Defer until the feature ships. |

Scope names are starting points, not a blanket authorization guarantee. [OAuth scope definitions](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps).

## 4. API engineering requirements

1. **Version explicitly.** Candidate GitHub.com REST version: `2026-03-10`, currently listed as supported. Validate it in M0, pin per host, track deprecation/sunset headers, and test upgrades. GraphQL schema changes require their own monitoring. [API versions](https://docs.github.com/en/rest/about-the-rest-api/api-versions?apiVersion=2026-03-10).
2. **Paginate completely where completeness is promised.** Follow REST links and GraphQL cursors; distinguish partial lists from complete lists. Cancel stale pagination on context changes. [REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api).
3. **Budget requests per credential/host.** REST and GraphQL budgets differ; secondary limits also apply. Respect returned headers and use bounded concurrency/backoff rather than fixed hardcoded quotas. [REST limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api), [GraphQL limits](https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api).
4. **Poll deliberately.** Revalidate active views and inbox with conditional requests; honor `X-Poll-Interval` for notifications. Back off in background and after wake. [Notification polling](https://docs.github.com/en/rest/activity/notifications).
5. **Treat search as search.** Surface result caps, incomplete results, supported query syntax, and eventual indexing; do not use it as the only authoritative inventory. [Search limitations](https://docs.github.com/en/rest/search/search).
6. **Do not promise arbitrary attachments or live log streaming.** Validate supported upload paths. Release assets and Actions artifacts have different semantics from issue-body attachments. Unsupported uploads retain drafts and provide a browser handoff.
7. **Keep write outcomes explicit.** Handle HTTP and GraphQL errors, including HTTP 200 with partial GraphQL errors; reconcile timeouts before offering a retry. Honor server permissions even when a cached capability looked valid.
8. **Keep webhook infrastructure optional.** Webhooks deliver to a server. A future relay adds hosting, signatures, replay protection, privacy, and operating cost; a laptop app alone is not a continuously reachable webhook receiver. [Webhook model](https://docs.github.com/en/webhooks/about-webhooks).

## 5. Endpoint registry to build in M0

Generate an inventory from a pinned GitHub REST OpenAPI description plus selected GraphQL queries/mutations; augment it with web workflows, local Git, and browser-only operations. The REST catalog identifies an official OpenAPI description. [REST documentation](https://docs.github.com/en/rest).

Each registry record must include: operation ID, CAP/PRD identifiers, user outcome, method/path or GraphQL operation, API version/schema snapshot, token type, scopes/permissions, required role/plan, host support, read/write/destructive classification, pagination/limits, native coverage state, fallback URL, verification date, fixture/live-test evidence, owner, and milestone.

Compatibility fixtures must cover a personal public repo, private repo, fork, organization member account, read-only collaborator, organization restriction/SSO scenario, missing scope, revoked access, and accounts with identical repository names. Private operations use dedicated disposable test resources, never production data.

A capability is eligible for a native-coverage claim only when its happy path, denied path, stale state, and meaningful failure/recovery paths pass. Publish separate metrics for core workflows, eligible API operations, and browser handoffs. Re-audit before each minor release and when GitHub announces relevant changes.
