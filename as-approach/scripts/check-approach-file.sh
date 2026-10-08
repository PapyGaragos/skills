#!/usr/bin/env bash
# Check the shape of a finished approach file against the layout
# write-approach-file.sh writes: frontmatter, lead line, Steps, Assumptions,
# Covers and Risks. It judges shape only, never meaning. Prints one problem
# per line as FILE:LINE: <problem> (FILE: <problem> when no line applies),
# then warnings the same way, after "warning: ".
#
# The efforts under ### headings in Covers and Risks are read from
# <slug>-effort.md under --root, by default the git toplevel of FILE's folder,
# else that folder: a covered name is one of their criteria, a risk one of the
# covered criteria or one of their limits. State verbs come from the
# as-effort skill deployed next to this one.
#
# Usage: check-approach-file.sh [--root DIR] FILE
# Exit: 0 no problem, 1 problems found, 2 bad usage.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
  echo "usage: check-approach-file.sh [--root DIR] FILE" >&2
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
  echo "check-approach-file.sh: cannot read $file" >&2
  exit 2
fi
if [[ -z $root ]]; then
  root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null) || root=$(dirname "$file")
fi
[[ -d $root ]] || { echo "check-approach-file.sh: no folder $root" >&2; exit 2; }

slug_re='^[a-z0-9]+(-[a-z0-9]+)*$'
problems=0
out=() warnings=()
report() {  # report LINE MESSAGE; line 0 means none
  if [[ $1 == 0 ]]; then echo "$file: $2"; else echo "$file:$1: $2"; fi
}
problem() { out+=("$(report "$1" "$2")"); problems=$((problems + 1)); }
warn() { warnings+=("$(report "$1" "warning: $2")"); }

# The verbs of the as-effort table name states, so a lead line opening with
# one likely names a state instead of a way.
as_effort=${here%/*/*}/as-effort/SKILL.md
state_verbs=''
if [[ -f $as_effort ]]; then
  state_verbs=" $(awk -F'|' '$2 ~ /^[ ]*`(achieve|maintain|optimize)`[ ]*$/ { gsub(/[ ,]+/, " ", $3); printf "%s ", $3 }' "$as_effort") "
  [[ -n ${state_verbs// /} ]] || warn 0 "no verb table in $as_effort: state verbs not checked"
else
  warn 0 "$as_effort not found: state verbs not checked"
fi

# effort_file SLUG: set `found` to the path of <slug>-effort.md under the
# root, or to nothing. When several files carry the slug, warn and take the
# first.
effort_file() {
  local paths
  paths=$(find "$root" -name "$1-effort.md" -not -path '*/.git/*' 2>/dev/null | LC_ALL=C sort)
  [[ $paths != *$'\n'* ]] || warn 0 "slug $1 is carried by several files, only the first is read: $(paste -sd ' ' <<< "$paths")"
  found=${paths%%$'\n'*}
}

# names_of FILE: the criterion names of an effort file as "c <name>" lines,
# its limit slugs as "l <slug>" lines.
names_of() {
  awk '/^## / { s = $0; sub(/^## +/, "", s); sub(/[ \t]+$/, "", s); next }
    s == "Definition of done" && /^- [a-z0-9]+(-[a-z0-9]+)*[ \t]+(Done when|Held when|Metric):/ {
      l = $0; sub(/^- /, "", l); sub(/[ \t].*/, "", l); print "c " l }
    s == "Limits" && /^- \[[a-z]+\] [a-z0-9]+(-[a-z0-9]+)* : / {
      l = $0; sub(/^- \[[a-z]+\] /, "", l); sub(/ .*/, "", l); print "l " l }' "$1"
}

mapfile -t lines < "$file"
n=${#lines[@]}

# --- Frontmatter ------------------------------------------------------------

fm_end=0  # the line of the closing ---, 0 without one
if [[ ${lines[0]:-} == --- ]]; then
  for (( i = 1; i < n; i++ )); do
    if [[ ${lines[i]} == --- ]]; then fm_end=$((i + 1)); break; fi
  done
fi
(( fm_end )) || problem 1 "no frontmatter between --- lines"

stem=${file##*/}
if [[ $stem == *-approach.md ]]; then
  stem=${stem%-approach.md}
else
  problem 0 "file name does not end in -approach.md"
  stem=
fi

name='' name_line=0 ct_line=0 key=''
efforts=()
declare -A effort_at=()
for (( i = 1; i < fm_end - 1; i++ )); do
  l=${lines[i]} ln=$((i + 1))
  if [[ $l =~ ^([a-z-]+):[[:space:]]*(.*[^[:space:]])?[[:space:]]*$ ]]; then
    key=${BASH_REMATCH[1]} val=${BASH_REMATCH[2]}
    case $key in
      name) name=$val name_line=$ln ;;
      contributes-to)
        ct_line=$ln
        [[ -z $val ]] || problem "$ln" "contributes-to must be a list, one '  - <effort>' per line" ;;
      *) problem "$ln" "frontmatter key $key: an approach holds only name and contributes-to" ;;
    esac
  elif [[ $key == contributes-to && $l =~ ^[[:space:]]+-[[:space:]]+(.*[^[:space:]])[[:space:]]*$ ]]; then
    e=${BASH_REMATCH[1]}
    if [[ ! $e =~ $slug_re ]]; then
      problem "$ln" "contributes-to entry $e is not a kebab-case effort slug"
    elif [[ -n ${effort_at[$e]:-} ]]; then
      problem "$ln" "effort $e appears twice in contributes-to"
    else
      effort_at[$e]=$ln
      efforts+=("$e")
    fi
  elif [[ -n ${l//[[:space:]]/} ]]; then
    problem "$ln" "frontmatter line is not 'name: <slug>' or a contributes-to entry"
  fi
done

if (( fm_end )); then
  if [[ -z $name ]]; then
    problem "$name_line" "frontmatter has no name"
  elif [[ ! $name =~ $slug_re ]]; then
    problem "$name_line" "name $name is not kebab-case"
  else
    [[ -z $stem || $name == "$stem" ]] ||
      problem "$name_line" "name $name does not match the file name $stem-approach.md"
    [[ -z ${effort_at[$name]:-} ]] ||
      problem "$name_line" "name $name is also in contributes-to: an approach is not an effort"
    effort_file "$name"
    [[ -z $found ]] || problem "$name_line" "name $name is already an effort's slug: $found"
  fi
  if (( ct_line == 0 )); then
    problem 0 "frontmatter has no contributes-to"
  elif (( ${#efforts[@]} == 0 )); then
    problem "$ct_line" "contributes-to lists no effort: an approach reaches at least one"
  fi
fi

# --- Body -------------------------------------------------------------------

order=(Steps Assumptions Covers Risks)
declare -A rank=() at=() filled=()
for i in "${!order[@]}"; do rank[${order[i]}]=$i; done
section='' last=-1 lead=() lead_line=0

# Steps: a stack of open lists, one entry per nesting level.
ind=() typ=() num=()
# Assumptions, Covers and Risks. Covers and Risks maps are keyed by
# "<section> <effort>" or "<section> <effort> <name>".
declare -A assumption_at=() head_at=() entry_at=()
assumptions=0 risks=0 head='' head_filled=''

# The criteria and limits of each effort under a heading, read once.
declare -A looked=() crit_of=() lim_of=() path_of=()
look_up() {  # look_up EFFORT LINE
  [[ -z ${looked[$1]:-} ]] || return 0
  looked[$1]=1
  effort_file "$1"
  if [[ -z $found ]]; then
    warn "$2" "no $1-effort.md under $root: its covered criteria and risks are not checked"
    return 0
  fi
  path_of[$1]=$found
  local names
  names=$(names_of "$found")
  crit_of[$1]=" $(sed -n 's/^c //p' <<< "$names" | paste -sd ' ') "
  lim_of[$1]=" $(sed -n 's/^l //p' <<< "$names" | paste -sd ' ') "
}

# close_head: a Covers or Risks heading with no entry under it.
close_head() {
  if [[ -n $head && -z $head_filled ]]; then
    if [[ $head_section == Covers ]]; then
      problem "${head_at["Covers $head"]}" "### $head lists no covered criterion: name what the way covers there"
    else
      problem "${head_at["Risks $head"]}" "### $head lists no risk: leave it out"
    fi
  fi
  head='' head_filled=''
}
hedge_re='[^a-z0-9-](should|may|might|could|probably)[^a-z0-9-]'
reason_re='[^a-z0-9-](because|so that|since|in order to)[^a-z0-9-]'

for (( i = fm_end; i < n; i++ )); do
  l=${lines[i]} ln=$((i + 1))

  if [[ $l =~ ^##\ +(.*[^[:space:]])[[:space:]]*$ ]]; then
    close_head
    section=${BASH_REMATCH[1]}
    if [[ -z ${rank[$section]:-} ]]; then
      problem "$ln" "unknown section ## $section: an approach has ## Steps, ## Assumptions, ## Covers and ## Risks"
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

  if [[ -z $section ]]; then
    lead+=("$l")
    (( lead_line )) || lead_line=$ln
    continue
  fi
  [[ -z ${rank[$section]:-} ]] && continue  # an unknown section, already reported
  filled[$section]=1

  case $section in
    Steps)
      if [[ $l =~ ^(\ *)([0-9]+)\.\ +(.*)$ ]]; then
        indent=${#BASH_REMATCH[1]} t=num k=${BASH_REMATCH[2]} text=${BASH_REMATCH[3]}
      elif [[ $l =~ ^(\ *)-\ +(.*)$ ]]; then
        indent=${#BASH_REMATCH[1]} t=bullet k=0 text=${BASH_REMATCH[2]}
      else
        problem "$ln" "Steps holds only list items: '1. <step>' in sequence, '- <step>' in any order, nested by indenting"
        continue
      fi
      popped=''
      while (( ${#ind[@]} )) && (( ${ind[-1]} > indent )); do
        unset 'ind[-1]' 'typ[-1]' 'num[-1]'
        popped=1
      done
      if (( ${#ind[@]} )) && (( ${ind[-1]} == indent )); then
        if [[ ${typ[-1]} != "$t" ]]; then
          problem "$ln" "step mixes numbered and bullet items in one list: nest the other kind under a step"
        elif [[ $t == num ]] && (( k != ${num[-1]} + 1 )); then
          problem "$ln" "step $k. follows step ${num[-1]}.: number the steps of a list from 1, in order"
        fi
        num[-1]=$k typ[-1]=$t
      else
        if (( ${#ind[@]} == 0 && indent > 0 )); then
          problem "$ln" "first step is indented: a nested list goes under a step"
        elif [[ -n $popped ]]; then
          problem "$ln" "step is indented between two levels of the list above it"
        fi
        [[ $t != num || $k == 1 ]] ||
          problem "$ln" "numbered list starts at $k.: number the steps of a list from 1, in order"
        ind+=("$indent") typ+=("$t") num+=("$k")
      fi
      if [[ $text =~ \(([^()]*)\)[[:space:]]*$ ]]; then
        c=${BASH_REMATCH[1]}
        if [[ ! $c =~ ^[a-z0-9]+(-[a-z0-9]+)*(,\ [a-z0-9]+(-[a-z0-9]+)*)*$ ]]; then
          problem "$ln" "step ends with ($c): only (<effort-slug>, ...) goes there, the efforts that cover it"
        else
          IFS=, read -ra cs <<< "${c//, /,}"
          for s in "${cs[@]}"; do
            [[ -z ${effort_at[$s]:-} ]] ||
              problem "$ln" "step ends with ($c): $s is an effort in contributes-to; (<effort-slug>, ...) names child efforts covering the step"
          done
          [[ $text =~ [^[:space:]][[:space:]]+\($c\)[[:space:]]*$ ]] ||
            problem "$ln" "step is only ($c): give the step, then (<effort-slug>, ...)"
        fi
      fi
      ;;
    Assumptions)
      if [[ ! $l =~ ^-\ ([^[:space:]]+)\ :\ (.+)$ ]]; then
        problem "$ln" "assumption is not - <slug> : <what will or will not be true>. [Breaks when: <signal>.]"
        continue
      fi
      a=${BASH_REMATCH[1]} text=${BASH_REMATCH[2]}
      assumptions=$((assumptions + 1))
      if [[ ! $a =~ $slug_re ]]; then
        problem "$ln" "assumption slug $a is not kebab-case"
      elif [[ -n ${assumption_at[$a]:-} ]]; then
        problem "$ln" "assumption $a appears twice: first at line ${assumption_at[$a]}"
      fi
      assumption_at[$a]=${assumption_at[$a]:-$ln}
      rest=${text//Breaks when:/}
      breaks=$(( (${#text} - ${#rest}) / 12 ))
      if (( breaks > 1 )); then
        problem "$ln" "assumption $a has more than one 'Breaks when:'"
      elif (( breaks == 1 )) && [[ ! $text =~ ^[^[:space:]].*\.\ Breaks\ when:\ [^[:space:]].*\.$ ]]; then
        problem "$ln" "assumption $a is not '<statement>. Breaks when: <signal>.'"
      elif (( breaks == 0 )) && [[ $text != *. ]]; then
        problem "$ln" "assumption $a does not end with a period"
      fi
      if [[ " $text " =~ $hedge_re ]]; then
        problem "$ln" "assumption $a holds '${BASH_REMATCH[1]}': write what will or will not be true"
      fi
      ;;
    Covers|Risks)
      if [[ $l =~ ^###\ +(.*[^[:space:]])[[:space:]]*$ ]]; then
        close_head
        head=${BASH_REMATCH[1]} head_section=$section head_ok=''
        if [[ -n ${head_at["$section $head"]:-} ]]; then
          problem "$ln" "### $head appears twice in $section"
        elif [[ -z ${effort_at[$head]:-} ]]; then
          problem "$ln" "### $head in $section is not in contributes-to"
        else
          head_ok=1
          look_up "$head" "$ln"
        fi
        head_at["$section $head"]=${head_at["$section $head"]:-$ln}
        continue
      fi
      if [[ -z $head ]]; then
        if [[ $section == Covers ]]; then
          problem "$ln" "covered criterion before any ### <effort> heading"
        else
          problem "$ln" "risk before any ### <effort> heading"
        fi
        continue
      fi
      head_filled=1
      if [[ ! $l =~ ^-\ ([^[:space:]]+)([[:space:]]*|\ :\ [^[:space:]].*\.)$ ]]; then
        if [[ $section == Covers ]]; then
          problem "$ln" "covered criterion is not - <criterion name> [: <how the way covers it>.]"
        else
          problem "$ln" "risk is not - <criterion name or limit slug> [: <how the way risks it>.]"
        fi
        continue
      fi
      r=${BASH_REMATCH[1]}
      known=''
      [[ -z $head_ok || -z ${path_of[$head]:-} ]] || known=1
      if [[ $section == Covers ]]; then
        if [[ -n ${entry_at["Covers $head $r"]:-} ]]; then
          problem "$ln" "criterion $r appears twice under ### $head in Covers"
        elif [[ -n $known && ${crit_of[$head]} != *" $r "* ]]; then
          problem "$ln" "covered $r is not a Definition of done entry name of ${path_of[$head]}"
        fi
      else
        risks=$((risks + 1))
        if [[ -n ${entry_at["Risks $head $r"]:-} ]]; then
          problem "$ln" "risk $r appears twice under ### $head"
        elif [[ -n $known && ${crit_of[$head]} == *" $r "* ]]; then
          [[ -n ${entry_at["Covers $head $r"]:-} ]] ||
            problem "$ln" "risk $r is a criterion not under ### $head in Covers: risk only criteria the way covers, or limits"
        elif [[ -n $known && ${lim_of[$head]} != *" $r "* ]]; then
          problem "$ln" "risk $r is not a criterion name or limit slug of ${path_of[$head]}"
        fi
      fi
      entry_at["$section $head $r"]=${entry_at["$section $head $r"]:-$ln}
      ;;
  esac
done
close_head

# Every effort the approach serves names what it covers there.
for e in "${efforts[@]}"; do
  [[ -n ${head_at["Covers $e"]:-} ]] ||
    problem "${effort_at[$e]}" "effort $e has no ### $e in Covers: name the criteria the way covers there"
done

# An empty Covers is reported per effort above.
for s in Steps Assumptions Risks; do
  if [[ -n ${at[$s]:-} && -z ${filled[$s]:-} ]]; then
    problem "${at[$s]}" "section ## $s is empty: leave it out"
  fi
done

# The lead line: the way, one sentence, before any section.
if (( ${#lead[@]} == 0 )); then
  (( fm_end == 0 )) || problem 0 "no lead line between the frontmatter and the first section"
else
  way=${lead[0]}
  if [[ $way == '#'* ]]; then
    problem "$lead_line" "lead line is a heading: give the way as one sentence"
  else
    (( ${#lead[@]} == 1 )) ||
      problem "$lead_line" "lead line runs over several lines: give the way as one sentence on one line"
    [[ $way == *. ]] || problem "$lead_line" "lead line does not end with a period"
    if [[ " ${way,,} " =~ $reason_re ]]; then
      problem "$lead_line" "lead line holds '${BASH_REMATCH[1]}': the reason goes in the logbook"
    fi
    if [[ -n ${state_verbs// /} && $state_verbs == *" ${way%% *} "* ]]; then
      warn "$lead_line" "lead line opens with ${way%% *}, a state verb of as-effort: name a way, not a state"
    fi
  fi
fi

if (( assumptions == 0 && risks == 0 && fm_end )); then
  warn 0 "approach has neither assumptions nor risks"
fi

(( ${#out[@]} == 0 )) || printf '%s\n' "${out[@]}"
(( ${#warnings[@]} == 0 )) || printf '%s\n' "${warnings[@]}"
(( problems == 0 )) || exit 1
