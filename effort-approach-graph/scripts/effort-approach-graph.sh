#!/usr/bin/env bash
# Print the graph the efforts under a root form, rebuilt from the files on
# every run. A node is a slug, whether it has its own <slug>-effort.md or only
# appears as a Limits line in another effort's file; a node with a file shows
# its chosen approaches, and the criteria of its definition of done that no
# chosen approach lists under the effort in its Covers section. An approach
# is a node too, from its <slug>-approach.md, with the efforts whose
# contributes-to names it as its children. Edges come
# from contributes-to entries (the child contributes to the parent, through
# the parent's approaches its list names), from Limits lines (the effort
# respects the limit) and from an approach's contributes-to list (the approach
# reaches the effort, with the status the effort's Approaches section gives
# it, or proposed when the section does not list it yet). Coverage lists, for
# each effort with children, which children serve each criterion of its
# definition of done, and apart, the children serving only approaches the
# effort does not take. Then come the problems a script can find: a slug
# carried by several files, or by an approach and an effort, a slug worded
# differently in two places, a contributes-to slug no effort names, an
# approach its parent does not list, an Approaches line with no approach file
# or whose file does not name the effort, a step naming an effort that does
# not serve the approach, a Serves entry naming a criterion its parent lacks,
# and cycles.
# Whether two slugs name the same state is judgment, left to the reader.
#
# Usage: effort-approach-graph.sh [--root DIR]
# Exit: 0 no problem, 1 problems found, 2 bad usage.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$here/effort-lib.sh"

usage() {
  echo "usage: effort-approach-graph.sh [--root DIR]" >&2
  exit 2
}

root=.
while (( $# )); do
  case $1 in
    --root) [[ $# -ge 2 ]] || usage; root=$2; shift 2 ;;
    *) usage ;;
  esac
done
[[ -d $root ]] || { echo "effort-approach-graph.sh: no directory $root" >&2; exit 2; }

index_efforts "$root"
index_approaches "$root"
declare -A kind=() intent=() first=() places=() adj=() color=() appr=()
edges=() problems=() parent_refs=()

# place SLUG LABEL LOC KIND INTENT: record one place a slug appears. The
# first place sets the node's kind and intent; a later one worded differently
# shows its own wording and is a problem.
place() {
  local slug=$1 label=$2 loc=$3 k=$4 text=$5
  if [[ -z ${kind[$slug]+set} ]]; then
    kind[$slug]=$k intent[$slug]=$text first[$slug]=$loc
    places[$slug]+="  $label: $loc"$'\n'
  elif [[ ${kind[$slug]} == "$k" && ${intent[$slug]} == "$text" ]]; then
    places[$slug]+="  $label: $loc"$'\n'
  else
    places[$slug]+="  $label: $loc: [$k] $text"$'\n'
    problems+=("differs: $slug: $loc words it differently from ${first[$slug]}")
  fi
}

slugs=$(printf '%s\n' "${!effort_paths[@]}" | LC_ALL=C sort)

# Files first, so a file's own frontmatter sets its node's wording. The
# first file carrying a slug also gives its approaches, as "<status> <slug>"
# lines, and its chosen ones, space separated; listed keeps where each is
# listed.
declare -A approaches=() chosen=() listed=()
for slug in $slugs; do
  paths=${effort_paths[$slug]%$'\n'}
  [[ $paths == *$'\n'* ]] && problems+=("several files: $slug: $(paste -sd ' ' <<< "$paths")")
  while IFS= read -r file; do
    place "$slug" file "$file" "$(field_of "$file" kind)" "$(intent_of "$file")"
  done <<< "$paths"
  approaches[$slug]=
  while read -r ln st a; do
    approaches[$slug]+="$st $a"$'\n'
    [[ -n ${listed[$slug|$a]+set} ]] || listed[$slug|$a]="${paths%%$'\n'*}:$ln $st"
  done < <(approaches_of "${paths%%$'\n'*}")
  approaches[$slug]=${approaches[$slug]%$'\n'}
  chosen[$slug]=$(awk '$1 == "chosen" { printf "%s%s", sep, $2; sep = " " }' <<< "${approaches[$slug]}")
  [[ -n ${chosen[$slug]} ]] || continue
  places[$slug]+="  chosen approaches: ${chosen[$slug]// /, }"$'\n'
  # A criterion no chosen approach covers is a gap of the effort, no problem.
  covered=' '
  for a in ${chosen[$slug]}; do
    apath=${approach_paths[$a]:-}
    [[ -z $apath ]] || covered+="$(covers_of "${apath%%$'\n'*}" "$slug" | paste -sd ' ') "
  done
  gaps=$(criteria_of "${paths%%$'\n'*}" | while read -r c; do [[ $covered == *" $c "* ]] || echo "$c"; done | paste -sd ' ')
  [[ -z $gaps ]] || places[$slug]+="  not covered by a chosen approach: ${gaps// /, }"$'\n'
done

for slug in $slugs; do
  while IFS= read -r file; do
    while read -r ln parent names; do
      edges+=("$slug -> $parent${names:+ [${names// /, }]}  (contributes-to, $file:$ln)")
      [[ " ${adj[$slug]:-} " == *" $parent "* ]] || adj[$slug]+=" $parent"
      [[ -n ${appr[$slug|$parent]+set} ]] || appr[$slug|$parent]=$names
      parent_refs+=("$file:$ln $slug $parent $names")
    done < <(parents_of "$file")
    while IFS=$'\t' read -r ln k s text; do
      place "$s" "limit in" "$file:$ln" "$k" "$text"
      edges+=("$slug respects $s  (limit, $file:$ln)")
    done < <(section_efforts "$file" Limits)
  done <<< "${effort_paths[$slug]%$'\n'}"
done

for ref in "${parent_refs[@]}"; do
  read -r where child parent names <<< "$ref"
  if [[ -z ${kind[$parent]+set} ]]; then
    problems+=("dangling: $where: $child contributes to $parent, which no effort names")
    continue
  fi
  # Approaches are checked only against a parent with a file to list them.
  [[ -n ${effort_paths[$parent]:-} ]] || continue
  for a in $names; do
    grep -qx "[a-z]* $a" <<< "${approaches[$parent]}" ||
      problems+=("unknown approach: $where: $child serves $a, which the Approaches of $parent do not list")
  done
done

# Approaches. Each approach reaches the efforts of its contributes-to list,
# with the status the effort's Approaches section gives it there, or
# proposed: an approach may name an effort before the effort considers it.
# Its children are the efforts whose contributes-to lists name it.
declare -A reaches=() lead=() children=()
aslugs=$(printf '%s\n' "${!approach_paths[@]}" | LC_ALL=C sort)
for ref in "${parent_refs[@]}"; do
  read -r where child parent names <<< "$ref"
  for a in $names; do
    [[ " ${children[$a]:-} " == *" $child "* ]] || children[$a]+=" $child"
  done
done
for a in $aslugs; do
  paths=${approach_paths[$a]%$'\n'}
  afile=${paths%%$'\n'*}
  [[ $paths == *$'\n'* ]] && problems+=("several files: $a: $(paste -sd ' ' <<< "$paths")")
  [[ -z ${kind[$a]+set} ]] ||
    problems+=("approach and effort: $a: $afile and ${first[$a]} carry one slug")
  lead[$a]=$(lead_of "$afile")
  while read -r ln e; do
    reaches[$a]+=" $e"
    st=${listed[$e|$a]:-proposed}
    edges+=("$a reaches $e [${st##* }]  (approach, $afile:$ln)")
    [[ -n ${kind[$e]+set} ]] ||
      problems+=("dangling: $afile:$ln: approach $a reaches $e, which no effort names")
  done < <(reaches_of "$afile")
done
for key in $(printf '%s\n' "${!listed[@]}" | LC_ALL=C sort); do
  e=${key%%|*} a=${key#*|} where=${listed[$key]% *}
  if [[ -z ${approach_paths[$a]:-} ]]; then
    problems+=("no approach file: $where: $e lists $a, which has no $a-approach.md")
  elif [[ " ${reaches[$a]:-} " != *" $e "* ]]; then
    problems+=("not reached: $where: $e lists $a, whose contributes-to does not name $e")
  fi
done
# A step's (<effort>) names the effort that covers it: one serving one of the
# approach's efforts through this approach or whatever the approach.
for a in $aslugs; do
  afile=${approach_paths[$a]%%$'\n'*}
  while read -r ln e; do
    if [[ -z ${kind[$e]+set} ]]; then
      problems+=("step: $afile:$ln: ($e) names no effort")
      continue
    fi
    ok=
    for p in ${reaches[$a]:-}; do
      [[ -n ${appr[$e|$p]+set} ]] || continue
      [[ -z ${appr[$e|$p]} || " ${appr[$e|$p]} " == *" $a "* ]] && ok=1
    done
    [[ -n $ok ]] ||
      problems+=("step: $afile:$ln: ($e) contributes to none of$(printf ' %s' ${reaches[$a]:-}) with [$a] or []")
  done < <(step_efforts_of "$afile")
done

# Depth-first search over contributes edges; an edge back into the current
# path closes a cycle, printed from where it starts.
path=()
visit() {
  local u=$1 v i
  color[$u]=1
  path+=("$u")
  for v in ${adj[$u]:-}; do
    if [[ ${color[$v]:-0} == 1 ]]; then
      for (( i = 0; i < ${#path[@]}; i++ )); do [[ ${path[i]} == "$v" ]] && break; done
      problems+=("cycle: $(printf '%s -> ' "${path[@]:i}")$v")
    elif [[ ${color[$v]:-0} == 0 ]]; then
      visit "$v"
    fi
  done
  unset 'path[-1]'
  color[$u]=2
}
for slug in $(printf '%s\n' "${!kind[@]}" | LC_ALL=C sort); do
  [[ ${color[$slug]:-0} == 0 ]] && visit "$slug"
done

# Coverage: for each effort with a file and children, the children serving
# each criterion of its definition of done, in the file's order. A child names
# the criteria it moves in its Serves entries under the parent's heading. A
# child counts when its list for the parent is [], or names one of the
# parent's chosen approaches, or, with none chosen, names one not dropped. A child that
# does not count is listed apart with the approaches it serves, and is no
# problem: a switch back to its approach finds it there. A counted child that
# names no criterion is listed apart too, and an entry naming a criterion the
# parent lacks is a problem.
declare -A served=() named=() kids=() other=()
counts() {  # counts CHILD PARENT: whether the child serves an approach the parent takes
  local a names=${appr[$1|$2]:-}
  [[ -n $names ]] || return 0
  for a in $names; do
    if [[ -n ${chosen[$2]:-} ]]; then
      [[ " ${chosen[$2]} " == *" $a "* ]] && return 0
    else
      grep -qx "candidate $a" <<< "${approaches[$2]:-}" && return 0
    fi
  done
  return 1
}
for u in "${!adj[@]}"; do
  for p in ${adj[$u]}; do
    if counts "$u" "$p"; then kids[$p]+=" $u"; else other[$p]+=" $u"; fi
  done
done
for slug in $slugs; do
  file=${effort_paths[$slug]%%$'\n'*}
  while IFS=$'\t' read -r ln p c; do
    [[ -n $c && " ${adj[$slug]:-} " == *" $p "* ]] || continue
    pfile=${effort_paths[$p]:-}
    pfile=${pfile%%$'\n'*}
    if [[ -n $pfile ]] && ! grep -qxF -- "$c" <(criteria_of "$pfile"); then
      problems+=("stale: $file:$ln: $slug serves $c, which the definition of done of $p does not name")
      continue
    fi
    [[ " ${kids[$p]:-} " == *" $slug "* ]] || continue
    named[$p|$slug]=1
    served[$p|$c]+=" $slug"
  done < <(serves_of "$file")
done
# list_slugs PARENT [approaches]: read slugs, print them sorted, comma separated,
# each followed by the approaches of PARENT it serves when asked.
list_slugs() {
  local u out=() names
  for u in $(tr ' ' '\n' | sed '/^$/d' | LC_ALL=C sort -u); do
    names=${appr[$u|$1]:-}
    out+=("$u${2:+ (${names// /, })}")
  done
  local IFS=$'\x1f'
  local joined="${out[*]:-}"
  printf '%s' "${joined//$'\x1f'/, }"
}
coverage=()
for p in $slugs; do
  [[ -n ${kids[$p]:-}${other[$p]:-} ]] || continue
  coverage+=("$p")
  while IFS= read -r c; do
    list=$(list_slugs "$p" <<< "${served[$p|$c]:-}")
    coverage+=("  $c: ${list:-none}")
  done < <(criteria_of "${effort_paths[$p]%%$'\n'*}")
  loose=
  for u in ${kids[$p]:-}; do
    [[ -n ${named[$p|$u]:-} ]] || loose+=" $u"
  done
  loose=$(list_slugs "$p" <<< "$loose")
  [[ -z $loose ]] || coverage+=("  names no criterion: $loose")
  loose=$(list_slugs "$p" approaches <<< "${other[$p]:-}")
  [[ -z $loose ]] || coverage+=("  serves another approach: $loose")
done

echo "nodes:"
(( ${#kind[@]} + ${#approach_paths[@]} )) || echo "none"
for slug in $(printf '%s\n' "${!kind[@]}" "${!approach_paths[@]}" | LC_ALL=C sort -u); do
  if [[ -n ${kind[$slug]+set} ]]; then
    echo "$slug [${kind[$slug]}]: ${intent[$slug]}"
    printf '%s' "${places[$slug]}"
  fi
  if [[ -n ${approach_paths[$slug]:-} ]]; then
    echo "$slug [approach]: ${lead[$slug]}"
    while IFS= read -r path; do echo "  file: $path"; done <<< "${approach_paths[$slug]%$'\n'}"
    list=$(list_slugs "" <<< "${children[$slug]:-}")
    echo "  children: ${list:-none}"
  fi
done
echo
echo "edges:"
if (( ${#edges[@]} )); then printf '%s\n' "${edges[@]}" | LC_ALL=C sort; else echo "none"; fi
echo
echo "coverage:"
if (( ${#coverage[@]} )); then printf '%s\n' "${coverage[@]}"; else echo "none"; fi
echo
echo "problems:"
if (( ${#problems[@]} )); then
  printf '%s\n' "${problems[@]}"
  exit 1
fi
echo "none"
