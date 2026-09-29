#!/usr/bin/env bash
# Check the shape of a finished effort file against the to-effort-file
# template: frontmatter, intent line, sections and their order, Serves, Key
# tasks and Limits lines, and leftover present-state text. It judges shape
# only, never meaning. Prints one problem per line as FILE:LINE: <problem>
# (FILE: <problem> when no line applies), warnings the same way, then every
# (guessed) and # guessed marker, which is what the skill's Reply lists.
#
# Parents are looked up under --root, by default the git toplevel of FILE's
# folder, else that folder. Verbs come from the as-effort skill deployed next
# to this one.
#
# Usage: check-effort-file.sh [--root DIR] FILE
# Exit: 0 no problem, 1 problems found, 2 bad usage.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$here/effort-lib.sh"

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

# The verb rows of the as-effort table, so the list has a single source.
as_effort=${here%/*/*}/as-effort/SKILL.md
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
# shape shared by the intent, key tasks and limits.
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

# contributes-to: one slug per entry, optionally followed by # guessed.
parents=()
cl=$(fm_line contributes-to)
if (( cl )); then
  index_efforts "$root"
  entry_re='^[[:space:]]+- ([a-z0-9]+(-[a-z0-9]+)*)( # guessed)?[[:space:]]*$'
  [[ ${lines[cl - 1]} =~ ^contributes-to:[[:space:]]*$ ]] ||
    problem "$cl" "contributes-to must be a list, one slug per line"
  for (( i = cl; i < fm_end - 1; i++ )); do
    [[ ${lines[i]} =~ ^[[:space:]]+-  ]] || break
    if [[ ${lines[i]} =~ $entry_re ]]; then
      parents+=("${BASH_REMATCH[1]}")
      find_file "${BASH_REMATCH[1]}"
      [[ -n $found ]] || warn $((i + 1)) "no ${BASH_REMATCH[1]}-effort.md under $root"
    else
      problem $((i + 1)) "contributes-to entry is not a slug, optionally followed by ' # guessed'"
    fi
  done
  (( i > cl )) || problem "$cl" "contributes-to is empty: a root effort leaves it out"
fi

# Sections, in template order. Work is free form and last, so whatever
# follows its heading is left alone.
order=("End state" "Definition of done" "Serves" "Key tasks" "Limits" "Work")
declare -A rank=() at=() bullets=() serves_heads=()
for i in "${!order[@]}"; do rank[${order[i]}]=$i; done
line_re='^- \[([a-z]+)\] ([a-z0-9]+(-[a-z0-9]+)*) : (.+)$'
root_line="Root effort: it serves no other effort."
section='' last=-1 serves_text=()

for (( i = 0; i < n; i++ )); do
  l=${lines[i]} ln=$((i + 1))
  [[ $section == Work ]] && break

  if [[ $l == *'(to write)'* ]]; then
    problem "$ln" "present-state marker (to write) outside Work"
  fi
  if [[ $l == *Metric:* && $l == *', now '* ]]; then
    problem "$ln" "present-state ', now ' in a Metric line outside Work"
  fi
  (( i >= fm_end )) || continue

  if [[ $l =~ ^##\ +(.*[^[:space:]])[[:space:]]*$ ]]; then
    section=${BASH_REMATCH[1]}
    if [[ -z ${rank[$section]:-} ]]; then
      problem "$ln" "unknown section ## $section"
    elif [[ -n ${at[$section]:-} ]]; then
      problem "$ln" "section ## $section appears twice"
    elif (( ${rank[$section]} < last )); then
      problem "$ln" "section ## $section is out of order: the template puts it before ## ${order[last]}"
    else
      last=${rank[$section]}
    fi
    at[$section]=${at[$section]:-$ln}
    continue
  fi
  [[ -n ${l//[[:space:]]/} ]] || continue

  case $section in
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
      elif (( ${#parents[@]} )) && [[ $l == "$root_line" ]]; then
        problem "$ln" "Serves has the root line but the effort has parents"
      fi
      ;;
    "Key tasks"|Limits)
      [[ $l == [[:space:]]* ]] && continue  # nested lines hold the checks
      bullets[$section]=1
      what="key task"
      # A limit the request did not state ends with # guessed, like a parent.
      if [[ $section == Limits ]]; then what=limit; l=${l% # guessed}; fi
      if [[ ! $l =~ $line_re ]]; then
        problem "$ln" "$what is not an as-effort line: - [<kind>] <slug> : <Verb> <end state>, so that <purpose>."
        continue
      fi
      k=${BASH_REMATCH[1]} text=${BASH_REMATCH[4]}
      if [[ ! $k =~ ^(achieve|maintain|optimize)$ ]]; then
        problem "$ln" "$what kind $k is not achieve, maintain or optimize"
      elif [[ $what == limit && $k != maintain ]]; then
        problem "$ln" "limit is [$k], a limit is always [maintain]"
      fi
      check_intent "$text" "$k" "$ln" "$what"
      ;;
  esac
done

for s in "End state" "Definition of done" "Serves" "Work"; do
  [[ -n ${at[$s]:-} ]] || problem 0 "missing section ## $s"
done
for s in "Key tasks" "Limits"; do
  if [[ -n ${at[$s]:-} && -z ${bullets[$s]:-} ]]; then
    problem "${at[$s]}" "section ## $s is empty: leave it out when there are none"
  fi
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

# The guesses the file carries, for the Reply.
guesses=$(grep -n -e '(guessed)' -e '# guessed' "$file" || true)
if [[ -z $guesses ]]; then
  echo "guesses: none"
else
  echo "guesses:"
  while IFS=: read -r gn gtext; do
    echo "  $gn: ${gtext#"${gtext%%[![:space:]]*}"}"
  done <<< "$guesses"
fi

(( problems == 0 )) || exit 1
