#!/usr/bin/env bash
# Keep a .logbook: an append-only tree of the work, what came up and what was decided.
# Commands say what happened; the script writes the notation (references/notation.md).
#
# PATH names a node by position: 2.1 is the first child of the second goal. Commands that
# add nodes accept 0 for the top level. Every write prints the nodes it touched with their
# paths. Paths never change, so keep them instead of re-reading the tree.
#
#   plan     FILE PATH STEP... [--parallel]  todos to do in order (or in any order)
#   doing    FILE PATH TEXT                  a todo already under way
#   did      FILE PATH TEXT...               todos already finished
#   start    FILE PATH                       begin a planned todo
#   done     FILE PATH                       finish a todo whose children are all closed
#   drop     FILE PATH REASON                abandon a todo and its open todos, or rule out an option
#   note     FILE PATH TEXT...               context, source, justification: one fact each
#   surprise FILE PATH TEXT                  something unexpected; steps to fix or bypass it go under it
#   blocker  FILE PATH TEXT                  something in the way
#   question FILE PATH TEXT                  something to find out
#   option   FILE PATH TEXT...               candidate answers to a question or blocker
#   decide   FILE PATH [CHOICE] [--over OPTION REASON]... [--why REASON]
#            on a question or blocker: records CHOICE, and each OPTION as ruled out;
#            on an option: confirms it. Options not ruled out stay open for later
#   status   FILE                            work in progress with its goals, open questions
#                                            and blockers, todos not started; with their notes
#   show     FILE [PATH]                     the whole tree, or the subtree at PATH
#
#   add FILE PATH "MARKER text"...   set FILE PATH MARKER   write markers directly
set -euo pipefail

die() { echo "logbook: $*" >&2; exit 1; }

usage() { awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0" >&2; exit 2; }

depth() { local s="${1%%[! ]*}"; echo $(( ${#s} / 2 )); }
marker() { local t="${1#"${1%%[! ]*}"}"; echo "${t%% *}"; }

is_marker() { case "$1" in -|=|'>'|.|x|'#'|!|!!|'??'|'?'|'=>') return 0 ;; esac; return 1; }
is_open_todo() { case "$1" in -|=|'>') return 0 ;; esac; return 1; }
is_closed() { case "$1" in .|x) return 0 ;; esac; return 1; }

# Child markers each parent marker accepts (references/notation.md, "What goes where").
allowed_children() {
  case "$1" in
    ROOT|-|=|'>'|.|x) echo '- = > . x # ! !! ??' ;;
    '??'|!!)          echo '- = > . x # ! ? =>' ;;
    '?'|'=>'|!)       echo '- = > . x # !' ;;
    *)                echo '' ;;
  esac
}

# Fills LINES and PATHS (the node path of each line, empty for blank lines).
load() {
  [[ -f "$1" ]] || die "no such file: $1"
  mapfile -t LINES < "$1"
  number
}

number() {
  PATHS=()
  local line lead d k p counts=()
  for line in "${LINES[@]}"; do
    if [[ -z "${line// }" ]]; then PATHS+=(''); continue; fi
    lead="${line%%[! ]*}"; d=$(( ${#lead} / 2 ))
    counts[d]=$(( ${counts[d]:-0} + 1 ))
    for (( k = ${#counts[@]} - 1; k > d; k-- )); do unset 'counts[k]'; done
    p=${counts[0]:-0}
    for (( k = 1; k <= d; k++ )); do p+=".${counts[k]:-0}"; done
    PATHS+=("$p")
  done
}

# 1-based line number of the node at PATH $1.
find_line() {
  [[ "$1" =~ ^[1-9][0-9]*(\.[1-9][0-9]*)*$ ]] || die "not a node path: $1"
  local i
  for (( i = 0; i < ${#PATHS[@]}; i++ )); do
    [[ "${PATHS[$i]}" == "$1" ]] && { echo $(( i + 1 )); return; }
  done
  die "no node at path $1"
}

# Index (0-based) one past the last descendant of line $1 (1-based).
subtree_end() {
  local i=$1 d; d=$(depth "${LINES[$1-1]}")
  while (( i < ${#LINES[@]} )) && [[ -n "${LINES[$i]// }" ]] && (( $(depth "${LINES[$i]}") > d )); do
    i=$((i + 1))
  done
  echo "$i"
}

# Print lines $@ (1-based) with their paths in an aligned column.
print_lines() {
  local n w=0
  for n in "$@"; do (( ${#PATHS[$n-1]} > w )) && w=${#PATHS[$n-1]}; done
  for n in "$@"; do printf '%-*s  %s\n' "$w" "${PATHS[$n-1]}" "${LINES[$n-1]}"; done
}

# Lines (1-based) written by the current command, printed once it has saved the file.
TOUCHED=()

save() {
  printf '%s\n' "${LINES[@]}" > "$1"
  number
  (( ${#TOUCHED[@]} )) || return 0
  print_lines $(printf '%s\n' "${TOUCHED[@]}" | sort -nu)
}

remark() {
  local text=${LINES[$1-1]} lead from
  lead="${text%%[! ]*}"; from=$(marker "$text")
  LINES[$1-1]="$lead$2${text#"$lead$from"}"
  TOUCHED+=("$1")
}

# A todo that has started work under it is in progress.
activate_ancestors() {
  local i d; d=$(depth "${LINES[$1-1]}")
  for (( i = $1 - 1; i >= 1 && d > 0; i-- )); do
    (( $(depth "${LINES[$i-1]}") < d )) || continue
    d=$(depth "${LINES[$i-1]}")
    case "$(marker "${LINES[$i-1]}")" in -|=) remark "$i" '>' ;; esac
  done
}

# Append items ("MARKER text") as the last children of node PATH $1, or of the top level for 0.
insert() {
  local parent=$1; shift
  (( $# > 0 )) || die "nothing to add"
  local pmark indent at pline
  if [[ "$parent" == 0 ]]; then
    pmark=ROOT; indent=''; at=${#LINES[@]}
  else
    pline=$(find_line "$parent")
    pmark=$(marker "${LINES[$pline-1]}")
    indent=$(printf '%*s' $(( ($(depth "${LINES[$pline-1]}") + 1) * 2 )) '')
    at=$(subtree_end "$pline")
  fi

  local allowed new=() item m
  allowed=" $(allowed_children "$pmark") "
  for item in "$@"; do
    item="${item#"${item%%[![:space:]]*}"}"; item="${item%"${item##*[![:space:]]}"}"
    [[ "$item" != *$'\n'* ]] || die "one line per item: $item"
    m="${item%% *}"
    [[ "$item" == *' '* && -n "${item#* }" ]] && is_marker "$m" \
      || die "item must be MARKER TEXT with MARKER one of - = > . x # ! !! ?? ? => : $item"
    [[ "$allowed" == *" $m "* ]] \
      || die "'$m' cannot go under '$pmark' (allowed: $(allowed_children "$pmark"))"
    if is_closed "$pmark" && is_open_todo "$m"; then
      die "$parent is closed; add new work under an open node, or 0 for a new goal"
    fi
    new+=("$indent$item")
  done

  local k count=${#new[@]}
  for k in "${!TOUCHED[@]}"; do
    (( TOUCHED[k] > at )) && TOUCHED[k]=$(( TOUCHED[k] + count ))
  done
  LINES=("${LINES[@]:0:$at}" "${new[@]}" "${LINES[@]:$at}")
  number
  for (( k = 1; k <= count; k++ )); do
    TOUCHED+=($(( at + k )))
    case "$(marker "${LINES[$at+k-1]}")" in '>'|.) activate_ancestors $(( at + k )) ;; esac
  done
  LAST=$(( at + count ))
}

# Change the marker of the node at line $1 to $2.
mutate() {
  local line=$1 to=$2 from ok=''
  from=$(marker "${LINES[$line-1]}")
  case "$from" in
    -|=) [[ "$to" == '>' || "$to" == . || "$to" == x ]] && ok=1 ;;
    '>') [[ "$to" == . || "$to" == x ]] && ok=1 ;;
    '?') [[ "$to" == '=>' || "$to" == x ]] && ok=1 ;;
  esac
  [[ -n "$ok" ]] || die "${PATHS[$line-1]} cannot change from '$from' to '$to' (allowed: - = to > . x, > to . x, ? to => x)"

  if [[ "$to" == . ]]; then
    local i end d; end=$(subtree_end "$line"); d=$(depth "${LINES[$line-1]}")
    for (( i = line; i < end; i++ )); do
      if (( $(depth "${LINES[$i]}") == d + 1 )) && is_open_todo "$(marker "${LINES[$i]}")"; then
        die "${PATHS[$i]} is still open; finish or drop it first"
      fi
    done
  fi
  remark "$line" "$to"
  case "$to" in '>'|.) activate_ancestors "$line" ;; esac
}

cmd_show() {
  local file=$1 from=1 to
  load "$file"
  to=${#LINES[@]}
  if [[ -n "${2:-}" ]]; then from=$(find_line "$2"); to=$(subtree_end "$from"); fi
  (( to >= from )) || return 0
  print_lines $(seq "$from" "$to")
}

# Add one node per TEXT, all with marker $1.
cmd_append() {
  local m=$1 file=$2 path=$3; shift 3
  (( $# > 0 )) || usage
  local items=() t
  for t in "$@"; do items+=("$m $t"); done
  cmd_add "$file" "$path" "${items[@]}"
}

cmd_add() {
  local file=$1 path=$2; shift 2
  if [[ -f "$file" ]]; then load "$file"; else
    [[ "$path" == 0 ]] || die "no such file: $file"
    LINES=(); PATHS=()
  fi
  insert "$path" "$@"
  save "$file"
}

cmd_plan() {
  local m=- args=() a
  for a in "$@"; do [[ "$a" == --parallel ]] && m='=' || args+=("$a"); done
  cmd_append "$m" "${args[@]}"
}

cmd_set() {
  load "$1"
  mutate "$(find_line "$2")" "$3"
  save "$1"
}

cmd_drop() {
  local file=$1 reason=$3 line m i end
  [[ -n "${reason// }" ]] || die "say why it was dropped"
  load "$file"; line=$(find_line "$2"); m=$(marker "${LINES[$line-1]}")
  is_open_todo "$m" || [[ "$m" == '?' ]] || die "$2 is '$m'; only open todos and options can be dropped"
  mutate "$line" x
  end=$(subtree_end "$line")
  for (( i = line; i < end; i++ )); do
    is_open_todo "$(marker "${LINES[$i]}")" && remark $(( i + 1 )) x
  done
  insert "$2" "# $reason"
  save "$file"
}

cmd_decide() {
  local file=$1 path=$2; shift 2
  local choice='' why='' over=()
  while (( $# )); do
    case "$1" in
      --over) (( $# >= 3 )) && [[ -n "${3// }" ]] || die "--over takes an option and why it lost"; over+=("$2" "$3"); shift 3 ;;
      --why)  (( $# >= 2 )) || usage; why=$2; shift 2 ;;
      *) [[ -z "$choice" ]] || usage; choice=$1; shift ;;
    esac
  done
  load "$file"
  local line m; line=$(find_line "$path"); m=$(marker "${LINES[$line-1]}")
  case "$m" in
    '?')
      [[ -z "$choice" && ${#over[@]} == 0 ]] \
        || die "$path is an option: deciding confirms it as is, so give no CHOICE or --over"
      mutate "$line" '=>'
      [[ -z "$why" ]] || insert "$path" "# $why"
      ;;
    '??'|!!)
      [[ -n "$choice" ]] || die "say what was decided"
      local i end d; end=$(subtree_end "$line"); d=$(depth "${LINES[$line-1]}")
      for (( i = line; i < end; i++ )); do
        if (( $(depth "${LINES[$i]}") == d + 1 )) && [[ "${LINES[$i]#"${LINES[$i]%%[! ]*}"}" == "? $choice" ]]; then
          die "'$choice' is already option ${PATHS[$i]}: run decide on ${PATHS[$i]} to confirm it"
        fi
      done
      local k; for (( k = 0; k < ${#over[@]}; k += 2 )); do
        insert "$path" "x ${over[k]}"; insert "${PATHS[$LAST-1]}" "# ${over[k+1]}"
      done
      insert "$path" "=> $choice"
      [[ -z "$why" ]] || insert "${PATHS[$LAST-1]}" "# $why"
      ;;
    *) die "$path is '$m'; decide answers a question, a blocker or an option. Record the question or blocker first." ;;
  esac
  save "$file"
}

cmd_status() {
  load "$1"
  local n=${#LINES[@]} i d p m stack=()
  local -a par mk closed dropped pending decided keep shown
  for (( i = 0; i < n; i++ )); do
    keep[i]=0; decided[i]=0
    if [[ -z "${PATHS[i]}" ]]; then par[i]=-1; mk[i]=''; closed[i]=1; dropped[i]=1; pending[i]=0; continue; fi
    d=$(depth "${LINES[i]}"); m=$(marker "${LINES[i]}")
    (( d > 0 )) && p=${stack[d-1]} || p=-1
    stack[d]=$i; par[i]=$p; mk[i]=$m
    if (( p < 0 )); then closed[i]=0; dropped[i]=0; pending[i]=0; else
      closed[i]=${closed[p]}; is_closed "${mk[p]}" && closed[i]=1
      dropped[i]=${dropped[p]}; [[ "${mk[p]}" == x ]] && dropped[i]=1
      pending[i]=${pending[p]}; [[ "${mk[p]}" == - || "${mk[p]}" == = ]] && pending[i]=1
      [[ "$m" == '=>' ]] && decided[p]=1
    fi
  done

  for (( i = 0; i < n; i++ )); do
    # An open question or blocker outlives the step it came up in, unless that step was dropped.
    case "${mk[i]}" in
      '>')     (( closed[i] )) || keep[i]=1 ;;
      '??'|!!) (( dropped[i] || decided[i] )) || keep[i]=1 ;;
      -|=)     (( closed[i] || pending[i] )) || keep[i]=1 ;;
      '?')     (( dropped[i] || pending[i] || decided[par[i]] )) || keep[i]=1 ;;
    esac
    if (( keep[i] )); then
      for (( p = par[i]; p >= 0; p = par[p] )); do keep[p]=1; done
    fi
  done
  for (( i = 0; i < n; i++ )); do shown[i]=${keep[i]}; done
  # Notes and surprises on the nodes shown carry their context, such as a pointer to the full plan.
  for (( i = 0; i < n; i++ )); do
    case "${mk[i]}" in '#'|!) (( par[i] >= 0 && shown[par[i]] )) && keep[i]=1 ;; esac
  done

  local show=()
  for (( i = 0; i < n; i++ )); do (( keep[i] )) && show+=($(( i + 1 ))); done
  (( ${#show[@]} )) || { echo "nothing open in $1"; return 0; }
  print_lines "${show[@]}"
}

(( $# >= 2 )) || usage
cmd=$1; shift
case "$cmd" in
  show)     (( $# <= 2 )) || usage; cmd_show "$@" ;;
  status)   (( $# == 1 )) || usage; cmd_status "$@" ;;
  plan)     (( $# >= 3 )) || usage; cmd_plan "$@" ;;
  doing)    (( $# == 3 )) || usage; cmd_append '>' "$@" ;;
  did)      (( $# >= 3 )) || usage; cmd_append . "$@" ;;
  note)     (( $# >= 3 )) || usage; cmd_append '#' "$@" ;;
  surprise) (( $# == 3 )) || usage; cmd_append ! "$@" ;;
  blocker)  (( $# == 3 )) || usage; cmd_append !! "$@" ;;
  question) (( $# == 3 )) || usage; cmd_append '??' "$@" ;;
  option)   (( $# >= 3 )) || usage; cmd_append '?' "$@" ;;
  start)    (( $# == 2 )) || usage; cmd_set "$@" '>' ;;
  done)     (( $# == 2 )) || usage; cmd_set "$@" . ;;
  drop)     (( $# == 3 )) || usage; cmd_drop "$@" ;;
  decide)   (( $# >= 2 )) || usage; cmd_decide "$@" ;;
  add)      (( $# >= 3 )) || usage; cmd_add "$@" ;;
  set)      (( $# == 3 )) || usage; cmd_set "$@" ;;
  *) usage ;;
esac
