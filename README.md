# skills

[![verify](https://github.com/joshrendek/skills/actions/workflows/verify.yml/badge.svg)](https://github.com/joshrendek/skills/actions/workflows/verify.yml)

Published, version-controlled [agent skills](https://docs.claude.com/en/docs/claude-code/skills)
for **Claude Code** and **Codex**.

This repo is the single source of truth for each skill. The live tool
directories don't hold copies — they hold symlinks pointing back here:

```
~/.claude/skills/<name>  ->  this-repo/<name>
~/.codex/skills/<name>   ->  this-repo/<name>
```

Edit a skill once; both tools see the change immediately. Claude and Codex share
the same `SKILL.md` format, so a single directory serves both.

## Skills

Run `make list`, or browse the top-level directories — each one with a `SKILL.md`
is a published skill.

| Skill | What it does |
|---|---|
| [`handoff`](handoff/) | Condense a session into a durable note the next context resumes from (`/handoff`, `/handoff resume`). |

## Install

```sh
git clone git@github.com:joshrendek/skills.git
cd skills
make install     # symlinks every skill into ~/.claude/skills and ~/.codex/skills
```

`make install` is idempotent and won't clobber an existing real directory — if a
skill name already exists as a real folder, it tells you to `make move` it in (or
re-run with `FORCE=1` to back it up and replace).

## Publishing a skill you already have

```sh
make move SKILL=<name>   # moves ~/.claude or ~/.codex skill into the repo, symlinks both ways
make check               # validate + prove it installs cleanly
git add <name> && git commit -m "Publish <name> skill"
```

## Make targets

```
make help          # list targets
make validate      # check every SKILL.md is well-formed (name == dir, has description)
make install       # symlink all skills into Claude + Codex
make install-test  # prove install works against a throwaway HOME (no side effects)
make check         # validate + install-test  (what CI runs)
make move SKILL=x  # adopt an existing skill into the repo, symlink back
make uninstall     # remove the symlinks that point into this repo
make list          # list published skills
```

## How it's verified

Every push and pull request runs [`make check`](.github/workflows/verify.yml):
`shellcheck` on the scripts, structural validation of every skill, and an
end-to-end install into a sandbox `HOME` that asserts each symlink resolves to a
readable `SKILL.md`. No real home directory is touched in CI.

See [AGENTS.md](AGENTS.md) for the full contributor/agent guide.
