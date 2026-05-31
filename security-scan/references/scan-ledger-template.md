# Scan Ledger — <repo> @ <branch> — <scope/date>

Durable memory for the security-scan loop. Update it after every pass. It must
survive context resets, so keep it on disk (do not track this only in your head).

## Scope and threat model

- In bounds: <paths / services / diff>
- Out of bounds: <do-not-touch>
- Threat model: <external user | authenticated user | tenant admin | malicious contributor | local attacker | supply-chain>
- Assets at risk: <secrets, customer data, billing, integrity, availability>
- Constraints: <commands allowed, installs allowed?, pass/token budget>

## Worklist

Priority Px, status `todo | doing | done`. Seed from the file ranker, the
entry-point families, and the vulnerability classes. Every confirmed finding
adds a same-class variant-hunt item here.

- [ ] P1 <file / surface / vuln-class> — <hypothesis to test> — todo
- [ ] P2 <...> — todo

## Findings

### Confirmed
- [SEVERITY] <class> — <file:line> — impact — evidence — remediation
  - PoC test: <path::test_name> — asserts <wrong behavior> — run: <command> — env: <not-run | local | staging | prod>

### Needs validation
- <class> — <file:line> — what is still unproven (reachability? impact?)

### Rejected
- <class> — <file:line> — why it is not a bug (so later passes skip it)

## Coverage

- Files / surfaces reviewed: <...>
- Commands run: <...>
- Unreviewed / residual risk: <...>

## Loop state

- Passes run: <n>
- Consecutive dry passes: <k>   (stop when worklist is empty AND k >= 2)
- Pass/token budget: <cap, if any>
