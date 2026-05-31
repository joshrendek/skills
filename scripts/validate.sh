#!/usr/bin/env sh
# validate.sh — structurally validate every published skill.
# Exit 0 if all skills are well-formed, 1 otherwise.
set -eu

# Resolve paths independent of any inherited CDPATH.
unset CDPATH
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd -P)
export REPO_ROOT
# shellcheck source=scripts/lib.sh
. "$SCRIPT_DIR/lib.sh"

skills=$(list_skills)
if [ -z "$skills" ]; then
	echo "WARN: no skills found in $REPO_ROOT" >&2
fi

overall=0
for name in $skills; do
	ok=1
	md="$REPO_ROOT/$name/SKILL.md"

	if [ ! -s "$md" ]; then
		echo "FAIL $name: SKILL.md is missing or empty"
		ok=0
	fi

	if [ "$ok" = 1 ]; then
		if ! head -n1 "$md" | grep -qx -- '---'; then
			echo "FAIL $name: line 1 is not a '---' frontmatter delimiter"
			ok=0
		fi
	fi

	if [ "$ok" = 1 ]; then
		fm_name=$(frontmatter_field "$md" name 2>/dev/null || true)
		fm_desc=$(frontmatter_field "$md" description 2>/dev/null || true)

		[ -n "$fm_name" ] || { echo "FAIL $name: missing 'name:' in frontmatter"; ok=0; }
		[ -n "$fm_desc" ] || { echo "FAIL $name: missing 'description:' in frontmatter"; ok=0; }

		if [ -n "$fm_name" ] && [ "$fm_name" != "$name" ]; then
			echo "FAIL $name: frontmatter name '$fm_name' != directory name '$name'"
			ok=0
		fi
	fi

	if [ "$ok" = 1 ]; then
		echo "ok   $name"
	else
		overall=1
	fi
done

exit "$overall"
