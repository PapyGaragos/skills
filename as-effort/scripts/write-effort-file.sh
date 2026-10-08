#!/usr/bin/env bash
# Write an effort file from content read on stdin, then run
# check-effort-file.sh on it. The caller supplies the content; this script
# lays it out as references/effort-file.md describes and leaves every judgment
# of shape to the checker.
#
# Input, one "key: value" per line, blank lines ignored:
#   name: <slug>               required, names the file <slug>-effort.md
#   kind: <kind>
#   intent: <intent line>
#   parent: <slug> [<approach>...]
#                              one per parent, then the parent's approaches
#                              this effort serves (none: it serves any); may
#                              end with # guessed; none for a root effort
#   title: <the wanted state>  required
#   end-state: <paragraph>     one per paragraph
#   criterion: <slug> <Done when|Held when|Metric>: <condition>
#   serves: <parent> <criterion> <Done when|Held when|Metric>: <condition>
#   limit: <as-effort line>    may end with # guessed
#   approach: [<status>] <approach-slug> (logbook: <path>)
#                              one Approaches line, without its leading "- "
# Feed it a quoted heredoc (<<'EOF'), so that nothing in the content needs
# escaping.
#
# The file is checked in a temporary folder and lands in DIR (by default the
# working directory) only when the check passes. After a failure nothing is
# written, so the same command runs again once the input is fixed. An
# existing file is replaced only with --replace, which keeps its Approaches
# section when the input has no approach: line. --root goes to the checker,
# by default the git toplevel of DIR, else DIR.
#
# --approaches rewrites only the Approaches section of the existing effort
# FILE from the approach: lines on stdin, which may hold no other key, and
# leaves the rest of the file as it is. It is checked the same way first.
#
# Usage: write-effort-file.sh [--root DIR] [--replace] [DIR] < INPUT
#        write-effort-file.sh --approaches [--root DIR] FILE < INPUT
# Exit: 0 written, 1 problems found and nothing written, 2 bad usage or
# input, 3 the file exists and --replace was not given.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
  echo "usage: write-effort-file.sh [--root DIR] [--replace] [DIR] < INPUT" >&2
  echo "       write-effort-file.sh --approaches [--root DIR] FILE < INPUT" >&2
  exit 2
}
die() { echo "write-effort-file.sh: $1" >&2; exit 2; }

root='' replace='' dir='' only_approaches=''
while [[ $# -gt 0 ]]; do
  case $1 in
    --root) [[ $# -ge 2 ]] || usage; root=$2; shift 2 ;;
    --replace) replace=1; shift ;;
    --approaches) only_approaches=1; shift ;;
    -*) usage ;;
    *) [[ -z $dir ]] || usage; dir=$1; shift ;;
  esac
done
if [[ -n $only_approaches ]]; then
  [[ -n $dir && -z $replace ]] || usage
  [[ -f $dir ]] || die "no file $dir"
  file=$dir dir=$(dirname "$dir")
fi
dir=${dir:-.}
[[ -d $dir ]] || die "no folder $dir"
[[ ! -t 0 ]] || die "reads its input on stdin"

# approaches_in FILE: the lines of its Approaches section, blank lines left out.
approaches_in() {
  awk '/^## / { s = $0; sub(/^## +/, "", s); sub(/[ \t]+$/, "", s); in_s = (s == "Approaches"); next }
    in_s && NF' "$1"
}

# entry TEXT: "- <first word>  <rest>", the two spaces a criterion wants.
entry() {
  local t=${1#"${1%%[![:space:]]*}"} word rest
  word=${t%%[[:space:]]*} rest=${t#"$word"}
  rest=${rest#"${rest%%[![:space:]]*}"}
  echo "- $word${rest:+  $rest}"
}

declare -A one=() serves=()
parents=() paragraphs=() criteria=() limits=() heads=() approaches=()
while IFS= read -r l || [[ -n $l ]]; do
  [[ -n ${l//[[:space:]]/} ]] || continue
  [[ $l =~ ^([a-z-]+):[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]] ||
    die "not a 'key: value' line: $l"
  key=${BASH_REMATCH[1]} val=${BASH_REMATCH[2]}
  [[ -z $only_approaches || $key == approach ]] ||
    die "--approaches takes only approach: lines: $l"
  case $key in
    name|kind|intent|title)
      [[ -z ${one[$key]+set} ]] || die "$key given twice"
      one[$key]=$val ;;
    parent) parents+=("$val") ;;
    end-state) paragraphs+=("$val") ;;
    criterion) criteria+=("$(entry "$val")") ;;
    serves)
      [[ $val == *[[:space:]]* ]] || die "serves needs a parent, then its entry: $l"
      p=${val%%[[:space:]]*}
      [[ -n ${serves[$p]+set} ]] || heads+=("$p")
      serves[$p]+=$(entry "${val#"$p"}")$'\n' ;;
    limit) limits+=("- $val") ;;
    approach) approaches+=("- $val") ;;
    *) die "unknown key $key: $l" ;;
  esac
done

if [[ -n $only_approaches ]]; then
  (( ${#approaches[@]} )) || die "no approach: line; the section would be emptied"
  name=${file##*/} name=${name%-effort.md}
else
  name=${one[name]:-}
  [[ -n $name && $name != */* ]] || die "needs a name: line holding the slug"
  [[ -n ${one[title]:-} ]] || die "needs a title: line"
  file=${dir%/}/$name-effort.md
  [[ $dir != . ]] || file=$name-effort.md
  if [[ -e $file && -z $replace ]]; then
    echo "write-effort-file.sh: $file exists; --replace replaces it" >&2
    exit 3
  fi
  # Approaches are written by their own skills: a replaced file keeps them.
  if [[ -f $file ]] && (( ${#approaches[@]} == 0 )); then
    mapfile -t approaches < <(approaches_in "$file")
  fi
fi
if [[ -z $root ]]; then
  root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root=$dir
fi

# Serves headings: the parents in order, then any serves parent not among them.
order=()
for v in "${parents[@]}"; do order+=("${v%%[[:space:]]*}"); done
for p in "${heads[@]}"; do [[ " ${order[*]} " == *" $p "* ]] || order+=("$p"); done

# contributes_entry "<slug> [<approach>...] [# guessed]": "  <slug>: [<a>, <b>]".
contributes_entry() {
  local v=$1 guessed='' list words
  if [[ $v =~ ^(.*[^[:space:]])[[:space:]]+#[[:space:]]*guessed$ ]]; then
    v=${BASH_REMATCH[1]} guessed='  # guessed'
  fi
  read -ra words <<< "$v"
  printf -v list '%s, ' "${words[@]:1}"
  list=${list%, }
  echo "  ${words[0]}: [$list]$guessed"
}

render() {
  if [[ -n $only_approaches ]]; then
    # The file without its Approaches section; the new one, last, follows.
    printf '%s\n' "$(awk '/^## / { s = $0; sub(/^## +/, "", s); sub(/[ \t]+$/, "", s); skip = (s == "Approaches") } !skip' "$file")"
  else
    echo ---
    echo "name: $name"
    [[ -z ${one[kind]:-} ]] || echo "kind: ${one[kind]}"
    [[ -z ${one[intent]:-} ]] || printf 'intent: >-\n  %s\n' "${one[intent]}"
    if (( ${#parents[@]} )); then
      echo contributes-to:
      for v in "${parents[@]}"; do contributes_entry "$v"; done
    fi
    echo ---
    printf '\n# %s\n' "${one[title]}"
    if (( ${#paragraphs[@]} )); then
      printf '\n## End state\n'
      printf '\n%s\n' "${paragraphs[@]}"
    fi
    if (( ${#criteria[@]} )); then
      printf '\n## Definition of done\n\n'
      printf '%s\n' "${criteria[@]}"
    fi
    printf '\n## Serves\n'
    if (( ${#order[@]} == 0 )); then
      printf '\nRoot effort: it serves no other effort.\n'
    fi
    for p in "${order[@]}"; do
      [[ -n ${serves[$p]+set} ]] || continue  # the checker reports it missing
      printf '\n### %s\n\n%s' "$p" "${serves[$p]}"
    done
    if (( ${#limits[@]} )); then
      printf '\n## Limits\n\n'
      printf '%s\n' "${limits[@]}"
    fi
  fi
  if (( ${#approaches[@]} )); then
    printf '\n## Approaches\n\n'
    printf '%s\n' "${approaches[@]}"
  fi
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
draft=$tmp/$name-effort.md
render > "$draft"

# Report under the final path, each numbered line followed by its text,
# since after a failure there is no file to look the line up in.
code=0
"$here/check-effort-file.sh" --root "$root" "$draft" > "$tmp/out" 2>&1 || code=$?
awk -v t="$draft" -v f="$file" '
  NR == FNR { text[FNR] = $0; next }
  index($0, t) == 1 {
    rest = substr($0, length(t) + 1)
    print f rest
    if (match(rest, /^:[0-9]+:/)) {
      n = substr(rest, 2, RLENGTH - 2) + 0
      print "    | " text[n + (text[n] == "intent: >-")]  # the folded intent itself
    }
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
