#!/usr/bin/env sh
# install-test.sh — prove that skills install correctly without touching the
# real home. Points the install targets at a throwaway temp dir, runs the real
# install logic, then asserts every expected symlink resolves to a readable
# SKILL.md. This is the end-to-end install check CI runs on every PR.
set -eu

# Resolve paths independent of any inherited CDPATH.
unset CDPATH
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd -P)
export REPO_ROOT
# shellcheck source=scripts/lib.sh
. "$SCRIPT_DIR/lib.sh"

tmp=$(mktemp -d 2>/dev/null) || tmp=$(mktemp -d -t skills-install-test)
trap 'rm -rf "$tmp"' EXIT INT TERM HUP

CLAUDE_SKILLS="$tmp/.claude/skills"
CODEX_SKILLS="$tmp/.codex/skills"
export CLAUDE_SKILLS CODEX_SKILLS

echo "== install-test: sandbox HOME at $tmp =="
sh "$SCRIPT_DIR/install.sh"

rc=0
n=0
for name in $(list_skills); do
	for base in "$CLAUDE_SKILLS" "$CODEX_SKILLS"; do
		link="$base/$name"
		n=$((n + 1))
		if [ ! -L "$link" ]; then
			echo "FAIL: $link is not a symlink"
			rc=1
			continue
		fi
		if [ ! -f "$link/SKILL.md" ]; then
			echo "FAIL: $link/SKILL.md is not reachable through the symlink"
			rc=1
			continue
		fi
		echo "ok   $link -> $(readlink "$link")"
	done
done

if [ "$n" -eq 0 ]; then
	echo "FAIL: no skills found to install-test"
	rc=1
fi

if [ "$rc" -eq 0 ]; then
	echo "== install-test PASSED ($n links verified) =="
else
	echo "== install-test FAILED =="
fi

exit "$rc"
