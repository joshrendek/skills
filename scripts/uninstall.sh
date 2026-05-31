#!/usr/bin/env sh
# uninstall.sh — remove the skill symlinks that point into THIS repo.
# Leaves real directories and foreign symlinks untouched.
#
# Override targets via env (same as install.sh):
#   CLAUDE_SKILLS  default: $HOME/.claude/skills
#   CODEX_SKILLS   default: $HOME/.codex/skills
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

for name in $targets; do
	for base in "$CLAUDE_SKILLS" "$CODEX_SKILLS"; do
		link="$base/$name"
		[ -L "$link" ] || continue
		tgt=$(readlink "$link")
		case "$tgt" in
			"$REPO_ROOT"/* | "$REPO_ROOT")
				rm -f "$link"
				echo "removed $link"
				;;
			*)
				echo "skip    $link (points to $tgt, not this repo)"
				;;
		esac
	done
done
