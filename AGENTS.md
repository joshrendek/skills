# AGENTS.md

Guidance for AI agents (Codex, Claude Code, and others) working in this repository.
`CLAUDE.md` is a symlink to this file, so both tools read the same conventions.

## What this repo is

This is the **single source of truth** for the skills Josh (`joshrendek`) chooses
to publish. Each skill lives in its own top-level directory and is **symlinked
into the live tool directories** rather than copied:

```
~/.claude/skills/<name>  ->  <repo>/<name>
~/.codex/skills/<name>   ->  <repo>/<name>
```

Editing a skill here changes it everywhere at once. There is exactly one real
copy of each skill — the one in this repo.

## Layout

```
<repo>/
├── AGENTS.md            # this file (canonical agent guide)
├── CLAUDE.md            # symlink -> AGENTS.md
├── README.md            # human-facing overview
├── Makefile             # task runner (see `make help`)
├── scripts/             # POSIX sh implementation of every make target
├── .github/workflows/   # CI: runs `make check` on every PR
└── <skill-name>/        # one directory per published skill
    └── SKILL.md         # required; may also have references/, scripts/, agents/
```

**A directory is a skill if and only if it contains a `SKILL.md`.** That is how
the tooling tells skills apart from infrastructure (`scripts/`, `.github/`) — so
there is no manifest or allowlist to keep in sync. Don't add a `SKILL.md` to a
non-skill directory.

## The SKILL.md contract

Every skill's `SKILL.md` must:

1. Begin with a YAML frontmatter block delimited by `---` on line 1.
2. Have a `name:` that **exactly equals the directory name**.
3. Have a non-empty `description:` (this is what the agent matches on to decide
   when to use the skill — make it trigger-oriented and specific).

```markdown
---
name: my-skill
description: Use when <concrete trigger conditions>. ...
---

# My Skill
...
```

Claude and Codex use the identical `SKILL.md` format, which is why one file
serves both. Keep skills tool-agnostic where possible; if a skill references a
specific tool's API, note it in the body.

## Workflows

Run `make help` for the current list. The important ones:

| Command | What it does |
|---|---|
| `make validate` | Structural check: frontmatter present, `name` == dir, `description` set. |
| `make install` | Symlink every skill into `~/.claude/skills` and `~/.codex/skills`. Idempotent and non-destructive (refuses to clobber a real dir unless `FORCE=1`). |
| `make install-test` | Run the real install against a throwaway `HOME` and assert every symlink resolves to a valid `SKILL.md`. No side effects. |
| `make check` | `validate` + `install-test`. **This is what CI runs — keep it green.** |
| `make move SKILL=<name>` | Adopt an existing skill from `~/.claude/skills` or `~/.codex/skills` into the repo, then symlink it back into both. |
| `make uninstall` | Remove only the symlinks that point into this repo. |
| `make list` | List published skills. |

## Adding a skill

- **New skill:** create `<name>/SKILL.md`, run `make check`, commit, then
  `make install` to symlink it locally.
- **Existing skill** (already in `~/.claude/skills` or `~/.codex/skills`):
  run `make move SKILL=<name>`, then `make check`, then commit.

## Rules for agents editing this repo

- **Run `make check` before committing.** Never commit a state where `make check`
  fails — CI gates every PR on it.
- **Keep `scripts/*.sh` POSIX and portable.** They must run on both macOS (BSD
  userland, e.g. `readlink` has no `-f`) and Linux CI. `shellcheck scripts/*.sh`
  must pass.
- **Don't hand-edit symlinks.** Use the make targets so the safety checks apply.
- **Skill changes are live** the moment they're saved (real dir is symlinked), so
  treat edits to `<skill>/SKILL.md` as production changes.
