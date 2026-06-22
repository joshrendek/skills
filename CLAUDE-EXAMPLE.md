
## Subagent & Process Management

- **Always clean up subagents.** After parallel work completes, verify no orphaned processes remain. Run `ps aux | grep 'output-format stream-json' | grep -v grep | wc -l` and kill any orphans.
- **Graceful shutdown required.** When using agent teams, always send shutdown requests to all teammates and wait for confirmation before ending the session.
- **Worktree cleanup.** After worktree-based parallel work, verify all worktrees are removed with `git worktree list` and clean up any that remain.

## Git & Commits

- Do not add a Co-Authored-By trailer to commits.
- Run tests before committing. Do not commit code that breaks existing tests.
- Run linters and security scanners before committing when available (e.g. `make check`, `rubocop`, `brakeman`).
- **No "pre-existing" failures.** If tests are failing — regardless of when they broke — fix them before pushing. There is no such thing as a pre-existing failure that can be ignored.

## Task Tracking

- Use 'bd' for task tracking.

## Development Workflow

- **PRD-driven development**: Create a numbered PRD in the project's `prd/` (or `PRD/`) directory before implementing new features or non-trivial changes. Follow the existing naming convention (e.g. `NNN-feature-name.md`).
- **Linear**: Used for project tracking in several projects. Reference team-specific identifiers (e.g. `BARK-N`, `GGG-N`) when applicable.
- **No manual verification steps.** Always write automated tests (unit, integration, or system tests) to verify changes. Never suggest manual click-through verification like "sign in → create org → check dashboard." If something needs verifying, write a test for it.
- **Drive a real browser for frontend changes.** For any visible UI change (component render, overlay, dropdown, form, navigation), unit tests are necessary but never sufficient — they miss provider/injection errors, focus management, real keyboard events, and CDK Overlay mounting. Verify in a real browser via `gstack` (`Skill: gstack`, then `$B`), the Playwright MCP, or a Playwright spec — whichever is available — BEFORE reporting done. Then codify the verification as a regression test (e.g. a Playwright spec under `frontend/e2e/`). Never claim "I can't test the UI" when these tools exist; if they're genuinely unavailable in the current environment, stop and ask.
- **Plans must include test plans.** Every implementation plan must include a concrete test plan section specifying which tests to write (unit, integration, etc.), what they cover, and where they live. Never ship a plan with only build/lint verification — always plan for automated tests that validate the new behavior.

## Kubernetes & Deployment

- **Talos cluster**: kubeconfig at `~/.kube/talos`. Flux CD config lives in `~/dev/infra-k8s/flux/clusters/proxmox-talos/`.
- **SysWard cluster**: kubeconfig at `~/.kube/sysward-kubeconfig.yml`.
- **GitOps pattern**: Helm charts in project repo under `charts/`, Docker images pushed to `ghcr.io`, Flux CD handles deployment via image automation.
- **CI/CD**: GitHub Actions builds Docker images on push to main.

## Go Projects

- Use `internal/` package layout.
- Thin HTTP handlers: validate input, call service, return JSON. Business logic lives in services.
- Use `sqlc` for type-safe database queries. Never hand-edit generated sqlc code; run `make generate` after editing SQL.
- PostgreSQL as primary database.
- Structured logging (slog or zerolog). Wrap errors with context.
- Use `make` targets: `make test`, `make lint`, `make check`, `make dev`.

## Astro Projects

- Static output only (no SSR). Standard commands: `npm run dev`, `npm run build`, `npm run preview`.
- File-based routing in `src/pages/`, components in `src/components/`, layouts in `src/layouts/`.
- SEO: include structured data (JSON-LD), Open Graph tags, Twitter Cards, sitemaps, semantic HTML.
- Tailwind CSS 4 with Vite plugin for styling when present.

## iOS / SwiftUI Projects

- XcodeGen for project generation (`xcodegen generate` after adding/removing files).
- MVVM or Clean Architecture with strict layer boundaries.
- Theme system with semantic colors (`Color.theme.*`). Use hex values directly, not named asset catalog colors.
- PRDs required before feature work.

	

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately – don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

## Security Patterns (apply to any web app / API)

### Authorization
- **Ownership predicate as a service-layer invariant.** Every authenticated service method that accepts a resource UUID must also accept the caller's `userID` and push the predicate into SQL (e.g. `WHERE id = $1 AND user_id = $2`). Never rely on a handler-side ownership check that the SQL doesn't enforce — the two will drift. Exceptions for system catalog data (rows with `user_id IS NULL`) must be marked with a `// security: system catalog, no user_id` comment.
- **Foreign-UUID and unknown-UUID return the same not-found shape.** Don't distinguish 403 ("not yours") from 404 ("doesn't exist") — the difference is a UUID-existence oracle. Pick one (404) and always return it.
- **Validate ALL caller-supplied UUIDs, not just the URL param.** If the body contains a `plant_id`/`plot_id`/etc., the service must verify ownership before persisting — even if the parent resource is owned. (Update paths often miss this.)

### Error handling
- **Typed error sentinels at the service-layer boundary.** Define `ErrNotFound`/`ErrForbidden`/`ErrValidation`/`ErrConflict` in an `errs` package. Service methods wrap with `fmt.Errorf("...: %w", errs.Err...)`. Handlers use `errors.Is` to branch on them. Map: `ErrNotFound`→404, `ErrValidation`→400 (message safe to surface), `ErrConflict`→409, else→500 generic.
- **Never echo `err.Error()` to clients except for typed validation errors.** Log the wrapped error server-side; return a stable error code + generic message. Wrapped errors leak DB schema (constraint names = column names), upstream provider bodies, library internals.
- **Map `pgx.ErrNoRows`/`sql.ErrNoRows` explicitly.** Otherwise the natural-flow 500 becomes a user-existence oracle on every endpoint that takes a UUID.

### Authentication tokens
- **JWT validation must pin alg, issuer, and audience.** Pass `WithValidMethods(["HS256"])`, `WithIssuer(...)`, `WithAudience(...)` to your parser. Default behavior accepts any HMAC variant — different audiences using the same signing secret then become forgeable. Stamp `iss` + `aud` in the issuer.
- **Refresh-token rotation with reuse detection.** `used_at`/`revoked_at`/`parent_id` columns. Rotate inside a transaction with `SELECT … FOR UPDATE`. On reuse (already-used token re-presented), revoke the entire family via recursive CTE on `parent_id`. Emit a structured log event so an alert can fire.
- **Don't use a raw resource identifier as an auth token.** UUIDs, primary keys, etc. leak through logs, referer headers, browser history, support tickets. Sign a short-TTL JWT with explicit `purpose`/`aud`/`exp` instead.
- **Single-use tokens need a `jti` + consumed-set.** OAuth pending blobs, billing checkout tokens, etc. — `INSERT … ON CONFLICT DO NOTHING RETURNING jti`; rows-affected = 0 means replay → reject.

### OAuth / OIDC
- `state` required at `/authorize`. PKCE `code_challenge` shape enforced (43 base64url chars for S256).
- Redirect URI **re-validated** at decide time, not just at authorize time. A registered URI removed mid-flight must invalidate in-flight blobs.
- Per-client `allowed_scopes` allowlist; intersect requested with allowed at every step (authorize, issue, refresh).
- Token revocation: rate-limit, honor `token_type_hint`, **strict `client_id` binding** for refresh-token revocation (no fallback to unscoped revoke when `client_id` is missing).
- Dynamic OAuth client `client_name` is **untrusted self-declared input** — show it muted in consent UI; the redirect host is the trustworthy signal. Maintain an allowlist of verified client names.

### Input validation
- **Never `fmt.Sprintf` user input into a URL.** Build URLs via `net/url.Values{}.Encode()`. Validate inputs against strict regexes (e.g., ZIP `^[A-Za-z0-9 \-]{3,12}$`, ISO 3166 `^[A-Z]{2}$`).
- **MIME-sniff uploaded files.** Use the framework's content-type detector on the first 512 bytes; reject anything outside an explicit image/file allowlist. Don't trust `Content-Type`.
- **Cap pagination on admin endpoints.** `per_page=10000000` should silently cap, not return the whole table.
- **Cap webhook body size in the helper itself.** Don't rely on global request-size middleware — defense in depth means each helper sets its own cap.

### Login / session
- **Email enumeration via timing.** On email-miss, run a fixed-cost dummy bcrypt against a precomputed hash so latency matches the wrong-password branch. Generic `INVALID_CREDENTIALS` for every miss reason. Per-account email-keyed rate limit in addition to per-IP.
- **Constant-time secret comparison** (e.g. `subtle.ConstantTimeCompare`) for any token / signature compare.

### Outbound HTTP (SSRF)
- **For any URL influenced by user input, build the HTTP client with a custom DialContext** that resolves the host before dialing and refuses RFC1918, loopback, link-local, cloud-metadata IPs (`169.254.169.254`, `fd00:ec2::254`). This is required even with a host allowlist — DNS can rebind. HTTPS-only.
- **Don't bubble upstream HTTP error bodies into your API response.** Combined with even a partial SSRF, that's a read primitive. Log upstream bodies server-side, return generic upstream error to caller.

### Atomicity
- When ownership-check + mutation must be linked, do it in **one transaction** with `SELECT … FOR UPDATE` on the parent — or use a single statement (`INSERT … SELECT WHERE owner_id = $userID`). Two statements = TOCTOU race.
- Denormalized state updates (counters, last-X timestamps) live in the **same transaction** as the source-of-truth write. If they fail, propagate the error and roll back — don't `_ = tx.Exec(...)` or `slog.Warn` and commit anyway.

### Logging
- **Strip credential-bearing query params before logging request URIs.** Build a denylist (`token`, `access_token`, `refresh_token`, `code`, `id_token`, `api_key`, etc.) and redact every match — not just `api_key`.
- Don't log full request bodies. Don't log password hashes, raw API keys, or session tokens even at DEBUG.

### Partial updates
- For HTTP `PATCH`-style endpoints: fields the caller didn't send must preserve current values. Use either pointer-typed input fields (nil = absent) or `COALESCE(NULLIF($n, ''), col)` in SQL. Full-replace from a partial JSON body silently zeros every omitted column.

### Admin actions
- Every admin mutation runs inside a transaction with an `admin_audit_log` insert capturing actor, target, action, old value, new value, timestamp. Snapshot the old value via `SELECT` inside the same tx.
- Service-layer setters clamp inputs at the service boundary — handler-side clamping bypasses non-handler callers (tests, future internal callers).

### Test discipline for security fixes
- **Three-commit cadence per finding:** (1) characterization tests pinning existing safe surrounding behavior; (2) exploit test demonstrating the bug; (3) the fix, after which characterization still passes and exploit tests are inverted into regression assertions.
- Keep regression tests in a dedicated package (e.g. `internal/security_regression/`) so a `make sec-test` target gives fast feedback. One test file per finding ID, with the finding ID in a comment header.
- Where behavioral tests need infra (DB, network), use **source-level pins** — `strings.Contains` the SQL fragment / function-signature reflection — so a future refactor that drops the fix fails CI loudly.
- A single CI job that runs `make test` + `make sec-test` + lint, blocking merge on any failure.
