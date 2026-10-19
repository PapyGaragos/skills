#!/usr/bin/env bash
# Check the shape of a finished effort file against the format
# write-effort-file.sh writes: frontmatter, intent line, sections and their order, Serves,
# Limits and Approaches lines. It judges shape only, never meaning. Prints one
# problem per line as FILE:LINE: <problem> (FILE: <problem> when no line
# applies), warnings the same way, then every (guessed) and # guessed marker,
# which is what the skill's Reply lists.
#
# Parents are looked up under --root, by default the git toplevel of FILE's
# folder, else that folder. Verbs come from the verb table in this skill's
# SKILL.md.
#
# Usage: check-effort-file.sh [--root DIR] FILE
# Exit: 0 no problem, 1 problems found, 2 bad usage.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# Helpers copied from effort-approach-graph/scripts/effort-lib.sh, so that
# this skill runs without that one deployed next to it. Keep them in step.

frontmatter() {
  awk 'NR == 1 && $0 == "---" { f = 1; next } f && $0 == "---" { exit } f' "$1"
}

# A one-line field such as name or kind, trimmed.
field_of() {
  frontmatter "$1" | awk -v key="$2" '
    index($0, key ":") == 1 { sub(/^[^:]*:[ ]*/, ""); sub(/[ ]+$/, ""); print; exit }'
}

# The intent field, either inline or as a folded/literal block (>-, |).
intent_of() {
  frontmatter "$1" | awk '
    !block && /^intent:/ {
      sub(/^intent:[ ]*/, "")
      if ($0 ~ /^[>|]/) { block = 1; next }
      print; done = 1; exit
    }
    block && /^[ ]+/ { sub(/^[ ]+/, ""); text = text (text == "" ? "" : " ") $0; next }
    block { exit }
    END { if (!done && text != "") print text }'
}

# Every <slug>-effort.md under a root, keyed by slug. A slug can be carried by
# several files, so each value holds all their paths, one per line.
declare -A effort_paths=() effort_warned=()
index_efforts() {
  local path slug
  effort_paths=()
  while IFS= read -r path; do
    slug=${path##*/}
    slug=${slug%-effort.md}
    effort_paths[$slug]+=$path$'\n'
  done < <(find "$1" -name '*-effort.md' -not -path '*/.git/*' 2>/dev/null | LC_ALL=C sort)
}

# Set `found` to the first file carrying the slug, or to nothing. When several
# files carry it, warn once on stderr and name them all, since only the first
# is read.
find_file() {
  local paths=${effort_paths[$1]:-}
  found=${paths%%$'\n'*}
  if [[ $paths == *$'\n'*$'\n'* && -z ${effort_warned[$1]:-} ]]; then
    effort_warned[$1]=1
    echo "warning: slug $1 is carried by several files: $(echo "${paths%$'\n'}" | paste -sd ' ')" >&2
  fi
}

# The criteria a file's Criteria names, in the file's order: the slug
# that opens each "- <slug>  Done when|Held when|Metric:" entry.
criteria_of() {
  awk '/^## / { s = $0; sub(/^## +/, "", s); sub(/[ \t]+$/, "", s); in_s = (s == "Criteria"); next }
    in_s && /^- [a-z0-9]+(-[a-z0-9]+)*[ \t]+(Done when|Held when|Metric):/ { l = $0; sub(/^- /, "", l); sub(/[ \t].*/, "", l); print l }' "$1"
}

usage() {
  echo "usage: check-effort-file.sh [--root DIR] FILE" >&2
  exit 2
}

root='' file=''
while [[ $# -gt 0 ]]; do
  case $1 in
    --root) [[ $# -ge 2 ]] || usage; root=$2; shift 2 ;;
    -*) usage ;;
    *) [[ -z $file ]] || usage; file=$1; shift ;;
  esac
done
[[ -n $file ]] || usage
if [[ ! -f $file || ! -r $file ]]; then
  echo "check-effort-file.sh: cannot read $file" >&2
  exit 2
fi
if [[ -z $root ]]; then
  root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null) || root=$(dirname "$file")
fi

slug_re='^[a-z0-9]+(-[a-z0-9]+)*$'
problems=0
report() {  # report LINE MESSAGE; line 0 means none
  if [[ $1 == 0 ]]; then echo "$file: $2"; else echo "$file:$1: $2"; fi
}
problem() { report "$1" "$2"; problems=$((problems + 1)); }
warn() { report "$1" "warning: $2"; }

# The verb rows of this skill's table, so the list has a single source.
as_effort=${here%/*}/SKILL.md
declare -A verbs=()
if [[ -f $as_effort ]]; then
  for kind in achieve maintain optimize; do
    verbs[$kind]=$(awk -F'|' -v k="$kind" '
      $2 ~ "^[ ]*`" k "`[ ]*$" { gsub(/[ ,]+/, " ", $3); sub(/^ /, "", $3); sub(/ $/, "", $3); print $3; exit }
    ' "$as_effort")
    [[ -n ${verbs[$kind]} ]] || warn 0 "no $kind row in the verb table of $as_effort"
  done
else
  warn 0 "$as_effort not found: verbs not checked"
fi

# check_intent TEXT KIND LINE WHAT: the <Verb> <end state>, so that <purpose>.
# shape shared by the intent and limits.
check_intent() {
  local text=$1 kind=$2 line=$3 what=$4 verb rest
  verb=${text%% *}
  if [[ -n $kind && -n ${verbs[$kind]:-} && " ${verbs[$kind]} " != *" $verb "* ]]; then
    problem "$line" "$what verb $verb is not in the $kind row: ${verbs[$kind]}"
  fi
  rest=${text//, so that /}
  if (( (${#text} - ${#rest}) / 10 != 1 )); then
    problem "$line" "$what needs exactly one ', so that '"
  fi
  if [[ $text != *. ]]; then
    problem "$line" "$what does not end with a period"
  fi
  if [[ ${text% (guessed).} == *'(guessed)'* ]]; then
    problem "$line" "$what has (guessed) elsewhere than right before the final period"
  fi
}

mapfile -t lines < "$file"
n=${#lines[@]}

# Frontmatter. fm_end is the line of its closing ---, 0 without one.
fm_end=0
if [[ ${lines[0]:-} == --- ]]; then
  for (( i = 1; i < n; i++ )); do
    if [[ ${lines[i]} == --- ]]; then fm_end=$((i + 1)); break; fi
  done
fi
(( fm_end )) || problem 1 "no frontmatter between --- lines"

fm_line() {  # line of a frontmatter key, 0 when absent
  local i
  for (( i = 1; i < fm_end - 1; i++ )); do
    if [[ ${lines[i]} == "$1:"* ]]; then echo $((i + 1)); return; fi
  done
  echo 0
}

stem=${file##*/}
if [[ $stem == *-effort.md ]]; then
  stem=${stem%-effort.md}
else
  problem 0 "file name does not end in -effort.md"
  stem=
fi

name=$(field_of "$file" name)
if [[ -z $name ]]; then
  problem "$(fm_line name)" "frontmatter has no name"
elif [[ ! $name =~ $slug_re ]]; then
  problem "$(fm_line name)" "name $name is not kebab-case"
elif [[ -n $stem && $name != "$stem" ]]; then
  problem "$(fm_line name)" "name $name does not match the file name $stem-effort.md"
fi

kind=$(field_of "$file" kind)
case $kind in
  achieve|maintain|optimize) ;;
  '') problem "$(fm_line kind)" "frontmatter has no kind" ;;
  *) problem "$(fm_line kind)" "kind $kind is not achieve, maintain or optimize" ;;
esac

intent=$(intent_of "$file")
if [[ -z $intent ]]; then
  problem "$(fm_line intent)" "frontmatter has no intent"
else
  check_intent "$intent" "$kind" "$(fm_line intent)" intent
fi

# contributes-to: a map from each parent's slug to the list of the parent's
# approaches this effort serves, [] for any approach, optionally followed by
# # guessed.
parents=()
declare -A criteria=()
cl=$(fm_line contributes-to)
if (( cl )); then
  index_efforts "$root"
  slug_part='[a-z0-9]+(-[a-z0-9]+)*'
  entry_re="^[[:space:]]+($slug_part):[[:space:]]*\[[[:space:]]*($slug_part([[:space:]]*,[[:space:]]*$slug_part)*)?[[:space:]]*\]([[:space:]]+# guessed)?[[:space:]]*$"
  [[ ${lines[cl - 1]} =~ ^contributes-to:[[:space:]]*$ ]] ||
    problem "$cl" "contributes-to must be a map, one parent per line"
  for (( i = cl; i < fm_end - 1; i++ )); do
    [[ ${lines[i]} == [[:space:]]* ]] || break
    if [[ ${lines[i]} =~ $entry_re ]]; then
      parents+=("${BASH_REMATCH[1]}")
      find_file "${BASH_REMATCH[1]}"
      [[ -z $found ]] || criteria[${BASH_REMATCH[1]}]=$(criteria_of "$found" | paste -sd ' ')
      [[ -n $found ]] || warn $((i + 1)) "no ${BASH_REMATCH[1]}-effort.md under $root"
    else
      problem $((i + 1)) "contributes-to entry is not '<parent>: [<approach>, ...]' ([] for any approach), optionally followed by ' # guessed'"
    fi
  done
  (( i > cl )) || problem "$cl" "contributes-to is empty: a root effort leaves it out"
fi

# Sections, in the order write-effort-file.sh writes them.
order=("End state" "Criteria" "Serves" "Limits" "Approaches")
declare -A rank=() at=() bullets=() serves_heads=()
for i in "${!order[@]}"; do rank[${order[i]}]=$i; done
line_re='^- \[([a-z]+)\] ([a-z0-9]+(-[a-z0-9]+)*) : (.+)$'
criterion_re='^- [a-z0-9]+(-[a-z0-9]+)*[[:space:]]+(Done when|Held when|Metric): '
root_line="Root effort: it serves no other effort."
section='' last=-1 serves_text=() head= limit_slugs=() approach_lines=()

for (( i = 0; i < n; i++ )); do
  l=${lines[i]} ln=$((i + 1))

  (( i >= fm_end )) || continue

  if [[ $l =~ ^##\ +(.*[^[:space:]])[[:space:]]*$ ]]; then
    section=${BASH_REMATCH[1]}
    if [[ -z ${rank[$section]:-} ]]; then
      problem "$ln" "unknown section ## $section"
    elif [[ -n ${at[$section]:-} ]]; then
      problem "$ln" "section ## $section appears twice"
    elif (( ${rank[$section]} < last )); then
      problem "$ln" "section ## $section is out of order: it goes before ## ${order[last]}"
    else
      last=${rank[$section]}
    fi
    at[$section]=${at[$section]:-$ln}
    continue
  fi
  [[ -n ${l//[[:space:]]/} ]] || continue

  case $section in
    "Criteria")
      [[ $l == "- "* ]] || continue  # prose and nested lines
      bullets[$section]=1
      # The slug is what children name in Serves, and what effort-approach-graph reads.
      [[ $l =~ $criterion_re ]] ||
        problem "$ln" "criterion is not - <slug>  Done when|Held when|Metric: <condition>"
      ;;
    Serves)
      serves_text+=("$l")
      if [[ $l =~ ^###\ +([^[:space:]]+)[[:space:]]*$ ]]; then
        h=${BASH_REMATCH[1]}
        if [[ -n ${serves_heads[$h]:-} ]]; then
          problem "$ln" "### $h appears twice in Serves"
        elif [[ " ${parents[*]} " != *" $h "* ]]; then
          problem "$ln" "### $h in Serves is not in contributes-to"
        fi
        serves_heads[$h]=$ln
        head=$h
      elif [[ -n $head && $l =~ ^-\ +([^[:space:]]+) && -n ${criteria[$head]:-} ]]; then
        # A parent with criteria: each entry is named after the one it moves,
        # in a criterion's shape, or effort-approach-graph cannot read it.
        if [[ " ${criteria[$head]} " != *" ${BASH_REMATCH[1]} "* ]]; then
          problem "$ln" "Serves entry under ### $head is not named after one of its criteria: ${criteria[$head]}"
        elif [[ ! $l =~ $criterion_re ]]; then
          problem "$ln" "Serves entry under ### $head is not - <criterion>  Done when|Held when|Metric: <condition>"
        fi
      elif (( ${#parents[@]} )) && [[ $l == "$root_line" ]]; then
        problem "$ln" "Serves has the root line but the effort has parents"
      fi
      ;;
    Limits)
      [[ $l == [[:space:]]* ]] && continue  # nested lines hold the checks
      bullets[$section]=1
      # A limit the request did not state ends with # guessed, like a parent.
      l=${l% # guessed}
      if [[ ! $l =~ $line_re ]]; then
        problem "$ln" "limit is not an as-effort line: - [<kind>] <slug> : <Verb> <end state>, so that <purpose>."
        continue
      fi
      k=${BASH_REMATCH[1]} text=${BASH_REMATCH[4]}
      limit_slugs+=("${BASH_REMATCH[2]}")
      if [[ ! $k =~ ^(achieve|maintain|optimize)$ ]]; then
        problem "$ln" "limit kind $k is not achieve, maintain or optimize"
      elif [[ $k != maintain ]]; then
        problem "$ln" "limit is [$k], a limit is always [maintain]"
      fi
      check_intent "$text" "$k" "$ln" limit
      ;;
    Approaches)
      bullets[$section]=1
      approach_lines+=("$ln")  # checked below, once the criteria and limits are known
      ;;
  esac
done

for s in "End state" "Criteria" "Serves"; do
  [[ -n ${at[$s]:-} ]] || problem 0 "missing section ## $s"
done
if [[ -n ${at["Criteria"]:-} && -z ${bullets["Criteria"]:-} ]]; then
  problem "${at["Criteria"]}" "section ## Criteria names no criterion"
fi
if [[ -n ${at[Limits]:-} && -z ${bullets[Limits]:-} ]]; then
  problem "${at[Limits]}" "section ## Limits is empty: leave it out when there are none"
fi
if [[ -n ${at[Approaches]:-} && -z ${bullets[Approaches]:-} ]]; then
  problem "${at[Approaches]}" "section ## Approaches is empty: leave it out when there are none"
fi

# Approaches: - [<status>] <approach-slug> (logbook: <path>). The approach
# itself lives in <approach-slug>-approach.md; effort-approach-graph checks
# that the file exists and names this effort.
approach_re='^- \[([a-z]+)\] ([a-z0-9]+(-[a-z0-9]+)*) \(logbook: [0-9]+(\.[0-9]+)*\)$'
own_criteria=" $(criteria_of "$file" | paste -sd ' ') "
taken=" $name ${parents[*]} $own_criteria ${limit_slugs[*]} "
declare -A approach_at=()
for ln in "${approach_lines[@]}"; do
  l=${lines[ln - 1]% # guessed}
  if [[ ! $l =~ $approach_re ]]; then
    problem "$ln" "approach is not - [<status>] <approach-slug> (logbook: <path>)"
    continue
  fi
  status=${BASH_REMATCH[1]} slug=${BASH_REMATCH[2]}
  case $status in
    chosen|candidate|dropped) ;;
    *) problem "$ln" "approach status $status is not chosen, candidate or dropped" ;;
  esac
  if [[ -n ${approach_at[$slug]:-} ]]; then
    problem "$ln" "approach $slug appears twice in Approaches"
  elif [[ $taken == *" $slug "* ]]; then
    problem "$ln" "approach $slug already names the effort, a parent, a criterion or a limit"
  fi
  approach_at[$slug]=$ln
done
if [[ -n ${at[Serves]:-} ]]; then
  if (( ${#parents[@]} )); then
    for p in "${parents[@]}"; do
      [[ -n ${serves_heads[$p]:-} ]] || problem "${at[Serves]}" "Serves has no ### $p"
    done
  elif [[ ${#serves_text[@]} -ne 1 || ${serves_text[0]} != "$root_line" ]]; then
    problem "${at[Serves]}" "a root effort's Serves holds only the line: $root_line"
  fi
fi

# The guesses the file carries, for the Reply. A guess inside a folded intent
# prints the whole intent once, at its key's line, since one of its lines
# alone is a fragment.
il=$(fm_line intent) iend=0
if (( il )) && [[ ${lines[il - 1]} =~ ^intent:[[:space:]]*[\>\|] ]]; then
  for (( iend = il; iend < fm_end - 1; iend++ )); do
    [[ ${lines[iend]} == [[:space:]]* ]] || break
  done
fi
guesses=$(grep -n -e '(guessed)' -e '# guessed' "$file" || true)
if [[ -z $guesses ]]; then
  echo "guesses: none"
else
  echo "guesses:"
  shown=0
  while IFS=: read -r gn gtext; do
    if (( gn > il && gn <= iend )); then
      (( shown )) || echo "  $il: intent: $intent"
      shown=1
      continue
    fi
    echo "  $gn: ${gtext#"${gtext%%[![:space:]]*}"}"
  done <<< "$guesses"
fi

(( problems == 0 )) || exit 1
