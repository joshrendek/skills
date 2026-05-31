---
name: handoff
description: Use when the user is about to clear or compact the context window, is wrapping up a work session, asks to "hand off" / "save context for next time" / "prep for a fresh session", or types /handoff. With argument `resume` (or `load`/`continue`), use when a fresh session must pick up prior work. Covers context-clearing and continuity-across-contexts situations.
---

# Handoff

## Overview

Condense the current session into a durable note the **next** context resumes from. Write for a capable agent that has the full repo and git history but **zero memory of this session**: capture only what it cannot cheaply rediscover, and point to the rest. A handoff is a high-signal briefing, never a transcript.

Two modes: **write** (default) prepares the handoff; **resume** (`/handoff resume`) loads the latest one into a fresh context.

## Write mode (default)

1. **Gather from the live environment — run, don't recall** (adapt to the project):
   - `git rev-parse --abbrev-ref HEAD`, `git status -s`, `git log --oneline -8`, and whether a remote exists / there are unpushed commits.
   - Background processes & dev servers still running, and their ports.
   - Task-tracker state (e.g. `bd ready` / in-progress issues, TodoWrite, ticket IDs).
   - The last test / lint / build result you know.
2. **Condense** with the table below — keep only high-signal lines.
3. **Persist** to a durable doc that survives `/clear`. Location, first match wins:
   (1) a path given in the args, (2) an existing `HANDOFF.md` (update it), (3) `<repo-root>/HANDOFF.md` — or `./HANDOFF.md` outside a repo. If the project has durable memory (e.g. `bd remember`), also mirror a 2–3 line pointer. Keep ONE canonical doc. Mention the file can be `.gitignore`d if they want it local-only.
4. **Safety gate — a handoff is worthless if work is lost.** If there is uncommitted or unpushed work, put it at the TOP of the doc and tell the user to commit before clearing. Do NOT auto-commit. Note any servers that outlive the session.
5. **Confirm** — print the file path, a ~5-line preview, and the resume command: `/handoff resume`.

## Capture vs cut

| Capture (expensive to rediscover) | Cut (recoverable or noise) |
|---|---|
| The single next action — file/function/command | Narrative ("first I…, then I…") |
| Run & verify commands; env quirks; ports | Full `git log` / file trees — point to them |
| Gotchas / footguns learned this session | Anything trivially re-derived from the code |
| Decisions + the *why* (not visible in code) | Resolved dead-ends (unless worth retrying) |
| Uncommitted / unpushed / running state | The spec restated verbatim — link it |
| Pointers: plan/spec, issue IDs, key files | |

## Handoff template

```markdown
# Handoff — <project> @ <branch> — <UTC datetime>

## ⚠️ Before you clear
- Uncommitted: <none | N files: …>   Unpushed: <none | N commits | no remote>
- Still running: <servers / ports / procs, or none>

## State (≤3 sentences)
<what's done; what's in flight right now>

## Resume here
<the single next concrete step + the file/function/command to touch>

## Run & verify
<commands to bring up the stack and run tests/lint; env quirks>

## Gotchas (don't relearn these)
- …

## Decisions & rationale
- …

## Next steps
1. …  2. …  3. …

## Pointers
- plan/spec, issue IDs, key files
```

## Resume mode (`/handoff resume`)

1. Locate the latest handoff (same resolution order) and read it.
2. Reconcile with reality: branch, `git status`, running procs — flag any drift from the note.
3. State the resume point, then continue (confirm first if the next step is destructive or ambiguous).

## Common mistakes

- Dumping the transcript instead of condensing — the next agent has the repo, not your patience.
- Re-listing `git log` / the file tree instead of pointing to them.
- Omitting run/verify commands and env quirks — the #1 thing the next context wastes time rediscovering.
- Not flagging uncommitted/unpushed work before a clear — silent data loss.
- Returning the handoff only as chat text, or writing it somewhere volatile that won't survive the clear.
