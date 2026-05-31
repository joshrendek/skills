#!/usr/bin/env sh
# install.sh — symlink published skills into the Claude and Codex skill dirs.
# With no args, installs every skill; with args, installs only those named.
#
# Override targets via env (used by install-test.sh and CI):
#   CLAUDE_SKILLS  default: $HOME/.claude/skills
#   CODEX_SKILLS   default: $HOME/.codex/skills
#   FORCE=1        replace a conflicting real dir / foreign symlink (backs up)
set -eu

# Resolve paths independent of any inherited CDPATH.
unset CDPATH
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd -P)
export REPO_ROOT
# shellcheck source=scripts/lib.sh
. "$SCRIPT_DIR/lib.sh"

CLAUDE_SKILLS="${CLAUDE_SKILLS:-$HOME/.claude/skills}"
CODEX_SKILLS="${CODEX_SKILLS:-$HOME/.codex/skills}"

if [ "$#" -gt 0 ]; then
	targets="$*"
else
	targets="$(list_skills)"
fi

rc=0
for name in $targets; do
	if [ ! -f "$REPO_ROOT/$name/SKILL.md" ]; then
		echo "ERROR: '$name' is not a skill in this repo" >&2
		rc=1
		continue
	fi
	link_skill "$name" "$CLAUDE_SKILLS" || rc=1
	link_skill "$name" "$CODEX_SKILLS" || rc=1
done

exit "$rc"
