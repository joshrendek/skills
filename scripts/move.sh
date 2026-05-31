#!/usr/bin/env sh
# move.sh — adopt an existing real skill directory into this repo, then symlink
# it back into both Claude and Codex. This is the "publish a skill I already
# have" workflow: the repo becomes the single source of truth and the live tool
# dirs become symlinks pointing here.
#
# Usage: make move SKILL=<name>   (or: scripts/move.sh <name>)
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

name="${1:-${SKILL:-}}"
[ -n "$name" ] || { echo "usage: make move SKILL=<name>" >&2; exit 2; }

dest="$REPO_ROOT/$name"
[ ! -e "$dest" ] || { echo "ERROR: $dest already exists in the repo" >&2; exit 1; }

# Find a real (non-symlink) source directory, preferring Claude then Codex.
src=""
for base in "$CLAUDE_SKILLS" "$CODEX_SKILLS"; do
	cand="$base/$name"
	if [ -d "$cand" ] && [ ! -L "$cand" ]; then
		src="$cand"
		break
	fi
done
[ -n "$src" ] || {
	echo "ERROR: no real skill dir '$name' under $CLAUDE_SKILLS or $CODEX_SKILLS" >&2
	exit 1
}

echo "move:  $src -> $dest"
mv "$src" "$dest"

echo "link:  '$name' into Claude + Codex (any conflicting real dir is backed up)"
FORCE=1 sh "$SCRIPT_DIR/install.sh" "$name"

echo "done. Next: 'make check', then commit '$name/'."
