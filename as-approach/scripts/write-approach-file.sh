#!/usr/bin/env bash
# Write an approach file from content read on stdin, then run
# check-approach-file.sh on it. The caller supplies the content; this script
# lays it out as references/approach-file.md shows and leaves every judgment
# of shape to the checker.
#
# Input, one "key: value" per line, blank lines ignored:
#   name: <slug>             required, names the file <slug>-approach.md
#   effort: <slug>           one per effort in contributes-to
#   way: <lead line>         required
#   step: <list line>        one per Steps line, as it reads in the file:
#                            "1. ...", "- ...", nested by spaces after the
#                            one that follows "step:"
#   assumption: <slug> : <what will or will not be true>. [Breaks when: <signal>.]
#   cover: <effort> <name> [: <how the way covers it>.]
#                            one per criterion name covered, at least one
#                            per effort
#   risk: <effort> <name> [: <how the way risks it>.]
#                            one per criterion name or limit slug risked
# Feed it a quoted heredoc (<<'EOF'), so that nothing in the content needs
# escaping.
#
# The file is checked in a temporary folder and lands in DIR (by default the
# working directory) only when the check passes. After a failure nothing is
# written, so the same command runs again once the input is fixed. An
# existing file is replaced only with --replace. --root goes to the checker,
# by default the git toplevel of DIR, else DIR.
#
# Usage: write-approach-file.sh [--root DIR] [--replace] [DIR] < INPUT
# Exit: 0 written, 1 problems found and nothing written, 2 bad usage or
# input, 3 the file exists and --replace was not given.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
  echo "usage: write-approach-file.sh [--root DIR] [--replace] [DIR] < INPUT" >&2
  exit 2
}
die() { echo "write-approach-file.sh: $1" >&2; exit 2; }

root='' replace='' dir=''
while [[ $# -gt 0 ]]; do
  case $1 in
    --root) [[ $# -ge 2 ]] || usage; root=$2; shift 2 ;;
    --replace) replace=1; shift ;;
    -*) usage ;;
    *) [[ -z $dir ]] || usage; dir=$1; shift ;;
  esac
done
dir=${dir:-.}
[[ -d $dir ]] || die "no folder $dir"
[[ ! -t 0 ]] || die "reads its input on stdin"

declare -A one=() covers=() risks=()
efforts=() steps=() assumptions=() cheads=() heads=()
while IFS= read -r l || [[ -n $l ]]; do
  [[ -n ${l//[[:space:]]/} ]] || continue
  if [[ $l == "step: "* ]]; then
    # A step keeps its indentation: everything after "step: ".
    v=${l#step: }
    steps+=("${v%"${v##*[![:space:]]}"}")
    continue
  fi
  [[ $l =~ ^([a-z-]+):[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]] ||
    die "not a 'key: value' line: $l"
  key=${BASH_REMATCH[1]} val=${BASH_REMATCH[2]}
  case $key in
    name|way)
      [[ -z ${one[$key]+set} ]] || die "$key given twice"
      one[$key]=$val ;;
    effort) efforts+=("$val") ;;
    assumption) assumptions+=("- $val") ;;
    cover)
      [[ $val =~ ^([^[:space:]]+)[[:space:]]+([^[:space:]].*)$ ]] ||
        die "cover needs an effort, then the criterion it covers: $l"
      e=${BASH_REMATCH[1]}
      [[ -n ${covers[$e]+set} ]] || cheads+=("$e")
      covers[$e]+="- ${BASH_REMATCH[2]}"$'\n' ;;
    risk)
      [[ $val =~ ^([^[:space:]]+)[[:space:]]+([^[:space:]].*)$ ]] ||
        die "risk needs an effort, then the name it risks: $l"
      e=${BASH_REMATCH[1]}
      [[ -n ${risks[$e]+set} ]] || heads+=("$e")
      risks[$e]+="- ${BASH_REMATCH[2]}"$'\n' ;;
    *) die "unknown key $key: $l" ;;
  esac
done

name=${one[name]:-}
[[ -n $name && $name != */* ]] || die "needs a name: line holding the slug"
[[ -n ${one[way]:-} ]] || die "needs a way: line holding the lead line"
file=${dir%/}/$name-approach.md
[[ $dir != . ]] || file=$name-approach.md
if [[ -e $file && -z $replace ]]; then
  echo "write-approach-file.sh: $file exists; --replace replaces it" >&2
  exit 3
fi
if [[ -z $root ]]; then
  root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root=$dir
fi

# Covers and Risks headings: the efforts in order, then any effort of the
# section not among them.
headings() {  # headings MAP HEADS...: print the heading order
  local -n map=$1
  shift
  local e out=()
  for e in "${efforts[@]}"; do [[ -z ${map[$e]+set} ]] || out+=("$e"); done
  for e in "$@"; do [[ " ${out[*]} " == *" $e "* ]] || out+=("$e"); done
  (( ${#out[@]} == 0 )) || printf '%s\n' "${out[@]}"
}
mapfile -t corder < <(headings covers "${cheads[@]}")
mapfile -t order < <(headings risks "${heads[@]}")

render() {
  echo ---
  echo "name: $name"
  if (( ${#efforts[@]} )); then
    echo contributes-to:
    printf '  - %s\n' "${efforts[@]}"
  fi
  echo ---
  printf '\n%s\n' "${one[way]}"
  if (( ${#steps[@]} )); then
    printf '\n## Steps\n\n'
    printf '%s\n' "${steps[@]}"
  fi
  if (( ${#assumptions[@]} )); then
    printf '\n## Assumptions\n\n'
    printf '%s\n' "${assumptions[@]}"
  fi
  if (( ${#corder[@]} )); then
    printf '\n## Covers\n'
    for e in "${corder[@]}"; do
      printf '\n### %s\n\n%s' "$e" "${covers[$e]}"
    done
  fi
  if (( ${#order[@]} )); then
    printf '\n## Risks\n'
    for e in "${order[@]}"; do
      printf '\n### %s\n\n%s' "$e" "${risks[$e]}"
    done
  fi
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
draft=$tmp/$name-approach.md
render > "$draft"

# Report under the final path, each numbered line followed by its text,
# since after a failure there is no file to look the line up in.
code=0
"$here/check-approach-file.sh" --root "$root" "$draft" > "$tmp/out" 2>&1 || code=$?
awk -v t="$draft" -v f="$file" '
  NR == FNR { text[FNR] = $0; next }
  index($0, t) == 1 {
    rest = substr($0, length(t) + 1)
    print f rest
    if (match(rest, /^:[0-9]+:/)) print "    | " text[substr(rest, 2, RLENGTH - 2) + 0]
    next
  }
  { print }' "$draft" "$tmp/out"

if (( code == 0 )); then
  mv -f "$draft" "$file"
  echo "wrote $file"
else
  echo "nothing written: fix the input and run the same command again"
fi
exit "$code"
