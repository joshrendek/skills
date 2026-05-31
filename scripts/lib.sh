# shellcheck shell=sh
# lib.sh — shared helpers for the skills repo tooling.
# POSIX sh only. Must run on macOS (BSD userland) and Linux (CI) alike.
# Callers MUST export REPO_ROOT before sourcing this file.

: "${REPO_ROOT:?lib.sh requires REPO_ROOT to be set}"

# list_skills — print the name of every published skill, one per line.
# A directory is a skill IFF it contains a SKILL.md. This auto-excludes
# infrastructure dirs (scripts/, .github/, etc.) with no allowlist to maintain.
list_skills() {
	for _d in "$REPO_ROOT"/*/; do
		[ -f "${_d}SKILL.md" ] || continue
		_name=${_d%/}
		printf '%s\n' "${_name##*/}"
	done
}

# frontmatter_field <SKILL.md> <key> — print the value of a top-level
# frontmatter key (e.g. name, description). Returns non-zero if the file does
# not start with a `---` frontmatter block. Strips one layer of surrounding
# single or double quotes. Indented keys (e.g. under metadata:) are ignored.
frontmatter_field() {
	_raw=$(awk -v key="$2" '
		NR == 1 { if ($0 != "---") exit 1; infm = 1; next }
		infm && $0 == "---" { exit }
		infm && index($0, key ":") == 1 {
			val = substr($0, length(key) + 2)
			sub(/^[ \t]+/, "", val)
			print val
			exit
		}
	' "$1") || return 1

	_sq="'"
	case "$_raw" in
		\"*\") _raw=${_raw#\"}; _raw=${_raw%\"} ;;
		"$_sq"*"$_sq") _raw=${_raw#"$_sq"}; _raw=${_raw%"$_sq"} ;;
	esac
	printf '%s\n' "$_raw"
}

# link_skill <name> <target_base> — symlink REPO_ROOT/<name> into
# <target_base>/<name>. Idempotent and safe:
#   - already the correct symlink            -> skip
#   - a different symlink or a real directory -> refuse, unless FORCE=1
#   - FORCE=1 backs up any real dir to <dest>.bak.<pid> before linking
# Returns non-zero on a refused conflict so the caller can surface it.
link_skill() {
	_name=$1
	_base=$2
	_src="$REPO_ROOT/$_name"
	_dest="$_base/$_name"

	mkdir -p "$_base"

	if [ -L "$_dest" ]; then
		_cur=$(readlink "$_dest")
		if [ "$_cur" = "$_src" ]; then
			printf 'skip   %s (already linked)\n' "$_dest"
			return 0
		fi
		if [ "${FORCE:-0}" = "1" ]; then
			rm -f "$_dest"
			ln -s "$_src" "$_dest"
			printf 'relink %s -> %s\n' "$_dest" "$_src"
			return 0
		fi
		printf 'WARN   %s is a symlink to %s (not this repo); rerun with FORCE=1 to relink\n' "$_dest" "$_cur" >&2
		return 1
	fi

	if [ -e "$_dest" ]; then
		if [ "${FORCE:-0}" = "1" ]; then
			_bak="$_dest.bak.$$"
			mv "$_dest" "$_bak"
			ln -s "$_src" "$_dest"
			printf 'backup %s -> %s; linked\n' "$_dest" "$_bak"
			return 0
		fi
		printf 'WARN   %s exists as a real path; run: make move SKILL=%s (or rerun with FORCE=1)\n' "$_dest" "$_name" >&2
		return 1
	fi

	ln -s "$_src" "$_dest"
	printf 'link   %s -> %s\n' "$_dest" "$_src"
}
