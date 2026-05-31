# Risk Signals

Use this checklist to select focused scan checks. It is not a finding by itself; validate reachability and impact.

## Entry Points

- HTTP routes, GraphQL resolvers, RPC methods, WebSocket handlers.
- Webhooks, message queues, cron jobs, background workers.
- CLI flags, environment variables, config files, plugin interfaces.
- File uploads, archive extraction, image/media/document parsing.
- Deserializers, protocol decoders, native bindings, FFI boundaries.

## Authorization

- Object lookup before ownership check.
- Admin or internal route guarded only in UI.
- Tenant/workspace/org IDs accepted from the request.
- Role checks missing on update/delete/export paths.
- Confused deputy flows across service accounts, webhooks, or integrations.

## Injection

- Shell/process calls with interpolated input.
- SQL/NoSQL/template/query strings built by concatenation.
- Unsafe HTML rendering, markdown rendering, DOM sinks, or CSP bypasses.
- LDAP, XPath, YAML, command-line, or expression-language evaluators.

## SSRF and Network Egress

- Server-side fetches of user-provided URLs.
- Redirect following without host/IP revalidation.
- Missing blocklist for link-local, loopback, private ranges, metadata services.
- DNS rebinding risk or validation done before resolution.

## File and Path Handling

- Path joins using user input without canonical root enforcement.
- Archive extraction without traversal checks.
- Symlink/hardlink races in temp directories.
- User-controlled filenames used in headers, storage keys, or shell commands.

## Secrets and Supply Chain

- Secrets in repo, logs, tests, example configs, CI output.
- Dependency install scripts, postinstall hooks, unpinned actions/images.
- Broad CI tokens available to pull requests or untrusted forks.
- Signing, release, or publish steps without provenance checks.

## Native, Memory, and Parser Code

- `unsafe`, FFI, raw pointers, unchecked indexing, manual allocation.
- Integer overflow in length, offset, capacity, or protocol arithmetic.
- Sentinel values crossing signed/unsigned or width boundaries.
- Parser state machines with rare transitions, partial frames, or nested lengths.
- Error paths that skip cleanup, bounds updates, locking, or authorization.

## Crypto and Authentication

- Custom crypto, nonces reused, weak randomness, timing-sensitive compares.
- JWT/session validation that skips issuer, audience, expiry, algorithm, or key ID checks.
- Password reset, invite, email change, MFA, and OAuth callback edge cases.
- Trust placed in unsigned headers, client-side claims, or proxy metadata.
