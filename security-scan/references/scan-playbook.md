# Security Scan Playbook

Use this reference when a scan is broad, high impact, or subtle enough to need a disciplined procedure. The loop, worklist, and stop rules are summarized in `SKILL.md`; this file is the detail.

## Goal Setup

Create a scan goal when goal tools are available and the user has asked for a planned scan. Phrase the objective around the authorized target and outcome:

`Run a defensive security scan of <repo/scope>, validate credible findings, and report prioritized remediation guidance.`

Keep only one active workstream in progress at a time. If the scan is too large for one turn, finish the current pass, summarize coverage in the ledger, and leave the goal active unless the user pauses or changes scope.

## Worklist and Ledger

The loop runs off a durable ledger (template: `scan-ledger-template.md`), written to `<repo>/SCAN.md` or a user-given path. Treat it as the source of truth, not your short-term memory: it must survive context compaction, a `/clear`, or handing the scan to a fresh session.

- **Seed the worklist** from three sources: the file ranker (rank-5 and rank-4 files), the entry-point families in `risk-signals.md`, and the vulnerability classes. Each becomes a prioritized worklist item with a hypothesis.
- **One item, one pass.** Mark an item `doing` when you pop it and `done` when its hypothesis is resolved (confirmed, rejected, or parked as needs-validation).
- **The worklist grows.** Confirmed findings and newly discovered surfaces add items. The scan is not driven by a fixed checklist; it expands as you learn the code.
- **Dry-pass counter** lives in the ledger. A pass is "dry" when it adds no new confirmed finding and no new worklist item.

## Planning Template

Before deep review, establish (record in the ledger):

- Scope: repo path, branch/diff, packages, services, or files in bounds.
- Threat model: external user, authenticated user, tenant admin, malicious contributor, local attacker, or supply-chain actor.
- Assets: secrets, customer data, compute, billing, permissions, integrity, availability.
- Entry points: network handlers, queues, CLI input, file parsing, webhooks, plugin APIs, background jobs.
- Trust boundaries: authn/authz, tenant ownership, sandboxing, process boundaries, serialization, native/FFI boundaries.
- Constraints: time/pass budget, commands allowed, whether dependency installs or long fuzzing are allowed.

## Planned Passes

Use short passes with explicit hypotheses and stop conditions. Good pass shapes:

- File-focused: one rank 5 or rank 4 file plus direct callers/callees.
- Surface-focused: one entry-point family such as upload, webhook, auth, billing, or parser.
- Vulnerability-class-focused: command injection, SSRF, authorization bypass, unsafe deserialization, memory corruption, secrets leakage.
- Regression-focused: compare changed files to previous behavior and test expected controls.
- Variant-focused: the same source/sink shape as a confirmed finding, hunted across the whole repo (see Variant Hunting).

For each pass, record: target files/surface, attacker capability assumed, controls expected, evidence needed to confirm or reject, and commands/tests to run.

### Running passes as subagents

When sub-agents are available, run each pass as a focused investigation subagent: give it one target, the relevant `risk-signals.md` checks, and the validation standard, and have it return structured candidate findings. The orchestrator keeps the ledger, dedupes findings, makes the validation call, enqueues variant hunts, and decides when to stop. Independent passes can run in parallel. Fall back to sequential inline passes when sub-agents are not available; the loop and ledger are identical either way.

## Investigation Loop

For each pass:

1. Trace source to sink: user-controlled input, normalization, validation, authorization, dangerous operation, output.
2. Identify invariants: ownership checks, length bounds, encoding assumptions, path roots, type guarantees, lifetime rules.
3. Try to falsify the invariant with code-level reasoning or a local test.
4. Prefer existing tests and local harnesses; add temporary test logic only when needed and avoid committing it unless the user asked for fixes.
5. Record rejected hypotheses briefly so later passes do not repeat the same path.

## Variant Hunting

Every confirmed finding is a template for more bugs. The moment you confirm one, enqueue a variant-hunt worklist item before moving on:

- Extract the shape: the dangerous sink (`os.popen`, `subprocess(..., shell=True)`, raw query builder, `send_file` on a joined path, server-side fetch of a user URL, object lookup without an ownership predicate).
- Sweep the whole repo for that shape (grep/ripgrep on the sink plus its common variants), not just the file you were in.
- Triage each hit through the same Validation Ladder. Confirmed siblings spawn their own variant hunts only if their shape differs.
- Clear the safe look-alikes explicitly in the ledger's Rejected section (for example a parameterized query or an argv-form subprocess) so later passes do not re-flag them.

A scan that finds one SQL injection and stops has failed at variant hunting. Find the family, not the instance.

## Validation Ladder

Use the lowest-risk validation that proves impact:

1. Static proof: exact branch/path shows a missing control and reachable sink.
2. Unit test: safe failing test proves bypass or crash.
3. Local reproduction: harmless request/input triggers wrong behavior in a local dev service.
4. Sanitizer/crash trace: ASan/UBSan/race detector or equivalent confirms memory/concurrency issue.
5. Minimal PoC: input demonstrates impact without payloads for persistence, exfiltration, privilege abuse, or weaponized exploitation.

Default a candidate to "needs validation" until a reachable path AND a concrete impact are both shown. Do not escalate beyond what is needed to prove the bug defensively.

## Proof of Concept

Every confirmed finding ships with a benign test that demonstrates it. The test is the proof and the regression guard; authoring it is part of confirming the finding.

- **Floor: a runnable test.** Prefer a unit test on the vulnerable function or handler that feeds a minimal, benign input and asserts the wrong behavior. When the bug only shows at the HTTP/integration layer, write that test instead. Shape it so that, once the bug is fixed, the same test inverts into a passing regression assertion.
- **Minimal and benign.** Use the smallest input that proves impact: `;id` or `$(id)` for command injection (expect the injected command to run), `' OR '1'='1` against a local test table for SQL injection (expect all rows), `../../etc/passwd` or an absolute path read locally for traversal, a request to `http://169.254.169.254/` or `http://127.0.0.1:<port>/` for SSRF (expect the server-side fetch). Never a reverse shell, data exfiltration, persistence, a privilege-escalation chain, or any payload aimed past demonstration. Never target a third-party system.
- **Unreachable or latent sinks.** Write a unit test that calls the sink directly with the crafted input and label it: it demonstrates the sink is vulnerable, and the finding becomes live the moment an entry point reaches it. State that condition.
- **Running it needs a target, so ask.** A pure unit test with no external effect can be run locally without asking. Anything that needs a running service, a dependency install, network egress, or otherwise has side effects: stop and ask the user, and let them choose the environment (local / staging / prod). Default to and strongly prefer local/dev. Never run a PoC against staging or production autonomously, and never against systems the user does not control.
- **Do not modify application source.** Write the test into the project's test suite or a clearly-labeled scratch path (for example next to the ledger), and reference its path in the finding.
- **Can't build even a benign test?** Then the finding is unproven. Move it to Needs Validation and say what blocked the demonstration.

## Triage

Severity depends on both reachability and impact:

- Critical: unauthenticated or low-privileged remote code execution, cross-tenant data access, auth bypass to admin/system privileges, supply-chain compromise.
- High: broad sensitive data exposure, tenant isolation break, persistent XSS in privileged context, SSRF to sensitive internal resources, significant write/delete without authorization.
- Medium: scoped authorization bug, reflected XSS with realistic exploitation, denial of service with practical trigger, secrets leakage in limited context.
- Low: hardening issue, defense-in-depth gap, low-impact info leak, unrealistic or highly constrained abuse path. A real bug in unreachable/dead code is Low until something wires it to a surface; note the trigger condition.

Downgrade findings with strong prerequisites, non-default configuration, local-only reachability, or impact limited to already-trusted users. Mark uncertain items as "Needs validation" instead of inflating severity.

## Responsible Handling

For third-party or open-source vulnerabilities found in authorized local code:

- Do not publish exploit details in the final answer.
- Provide enough maintainer-facing reproduction detail to fix the issue safely.
- Recommend coordinated disclosure when the vulnerability is not already public.
- Avoid dumping secrets, private data, or full exploit chains into logs or chat.

## Loop Stop Conditions

The scan runs autonomously until it converges. Stop and write the report when **both** hold:

1. The worklist is empty (every seeded and enqueued item is `done`).
2. The last two passes were dry (no new confirmed finding, no new worklist item).

Also stop, and say why, when:

- A pass budget or token cap set at the start is reached. Report coverage and what remains.
- A step is blocked on the user: a destructive command, an out-of-scope target, or missing authorization.

Do not stop merely because findings exist or because one sweep finished. Finding a bug enqueues work; it does not end the scan. When stopping early, the ledger's Coverage and Worklist sections show exactly what was and was not reviewed.

## Completion Criteria

A converged scan has:

- Covered the agreed scope, or explicitly narrowed it in the ledger.
- Given every high-priority ranked file/surface at least one focused pass.
- Run a variant hunt for every confirmed finding.
- Attached a benign demonstrating test to every confirmed finding.
- Validated credible findings or labeled them with remaining uncertainty.
- Produced a report with findings, coverage, commands run, and residual risk.
