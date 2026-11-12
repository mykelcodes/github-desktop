# Authentication feasibility

12 November 2026 · DISC-02 research evidence; registered-app verification outstanding

## Current prototype

The prototype can request metadata for a public GitHub.com repository without signing in. It sends `GET /repos/{owner}/{repo}`, pins REST version `2026-03-10`, and uses no access token. GitHub currently lists this version as supported. Public lookup is not evidence of authentication, private repository access, or inbox support. [Repository endpoint](https://docs.github.com/en/rest/repos/repos#get-a-repository), [API versions](https://docs.github.com/en/rest/about-the-rest-api/api-versions).

The client rejects credentialed URLs and non-GitHub hosts, disables request cookies, and refuses HTTP redirects through its per-task delegate, including when a test supplies a URLSession. A renamed repository therefore needs its current URL. Supplying a session is a dependency-injection seam: callers must not configure authentication headers or credentials on it. The application uses the default session with no added credentials. Offline errors and permission/availability failures are separate from rate-limit responses. A 404 does not establish whether a repository exists or is private. GitHub's unauthenticated budget is normally 60 requests per hour per originating IP; the client reports retry timing and does not automatically retry. [Rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api).

## Documentation findings

| Area | Verified from official documentation | Consequence |
| --- | --- | --- |
| OAuth authorization code | S256 PKCE is supported; the exchange table still requires `client_secret`. | PKCE does not establish that secretless code exchange is supported. |
| Refresh | Web-flow refresh requires the secret. Device-flow refresh is exempt. Expiring tokens can be requested with `offline_access`; refresh rotates both tokens. | Serialize refresh and atomically replace the pair. Handle responses without refresh tokens. |
| Callback | With wildcard matching disabled, GitHub requires an exact registered callback. Loopback ports have a documented exception. | Register an exact callback; do not enable wildcard matching. |

These findings come from [GitHub's authorization reference](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps). They have not been exercised with a registered app.

GitHub's best-practices page acknowledges that native clients cannot keep a shipped secret confidential, discusses PKCE for such clients, and discourages device flow for browser-capable environments. Our architecture choice is to keep the secret server-side; this is a product security decision, not a claim that GitHub mandates a broker. A PAT entry form is not the proposed normal onboarding. [OAuth best practices](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/best-practices-for-creating-an-oauth-app).

## Smallest proposed production architecture

1. The native client creates one unpredictable state value and PKCE verifier per attempt, then starts `ASWebAuthenticationSession` for GitHub authorization. It retains the attempt until completion or cancellation.
2. Use an exact HTTPS callback on an app-associated domain. Apple's HTTPS callback matching is available from macOS 14.4, fitting our macOS 15 minimum. It requires an associated domain. The default browser must support callback matching or the system uses Safari. A custom-scheme callback is an alternative to evaluate, not an implemented fallback. [Apple authentication session](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession), [HTTPS callbacks](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/callback/https(host:path:)), [Callback support](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/callback).
3. A narrow HTTPS broker owns the fixed OAuth client secret and performs exchange, refresh, and requested revocation. Bind exchanges to short-lived, single-use transactions and the original PKCE challenge/callback. Reject arbitrary upstream hosts, client IDs, callback URLs, and replay. Do not log codes, verifiers, or tokens. Avoid retained repository data; document the broker's transient token exposure and operational owner.
4. Store token pairs in Keychain under host and stable account ID. Revalidate `/user` after sign-in before associating any content with an account. Keep account authentication separate from Git transport and commit identity. Resolve refresh races within one account actor.
5. Distinguish local sign-out from server revocation. Clearing local credentials must not imply revocation succeeded. GitHub's token/grant deletion API requires client-secret authentication, so broker support or a GitHub authorization-settings handoff is needed. [OAuth token and grant deletion](https://docs.github.com/en/rest/apps/oauth-applications#delete-an-app-token).

## Inbox compatibility remains unresolved

The notifications reference says these endpoints support classic PAT authentication and excludes GitHub App and fine-grained PAT tokens. The OAuth scope reference nevertheless describes notification reading, read-state updates, and subscription operations. Documentation review cannot settle that discrepancy. Verify each intended operation using our registered OAuth app before marking inbox support available; do not silently replace the user's inbox with events or require a PAT. [Notifications reference](https://docs.github.com/en/rest/activity/notifications), [OAuth scopes](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps).

## Prerequisites and acceptance evidence

Authentication implementation needs an owned OAuth app registration and client ID, exact callback/domain configuration, Apple signing/associated-domain setup, and a broker deployment with its secret stored server-side. None has been created or accessed by this prototype. No account credentials, existing tokens, or Keychain entries were read.

DISC-02 remains open until a registered-app test records:

- Successful browser sign-in and `/user` identity check, repository listing, private/organization repository visibility, and required scopes.
- Callback cancellation, wrong state, wrong PKCE verifier, replay, two simultaneous windows, and changed browser account.
- Expiration, refresh rotation, interrupted refresh recovery, revoked authorization, local sign-out, and explicit server revocation.
- Notification listing, read/unread/done operations, subscriptions, insufficient scopes, and relevant organization restrictions.
- A signed macOS build completing callback handling in supported browsers. An unsigned development binary or mocked exchange is insufficient evidence.

Automated GitHubKit tests exercise fixtures, URL validation, pinned requests, decoding, HTTP failures, rate-limit timing, and offline errors. They do not contact GitHub or prove any authenticated flow.
