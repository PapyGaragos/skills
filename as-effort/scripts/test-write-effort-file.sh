#!/usr/bin/env bash
# Write effort files with write-effort-file.sh in a temp dir, and check the
# files it leaves, its output and its exit codes.
# Prints one line per test and a final count; exits 1 on any failure.
#
# Usage: test-write-effort-file.sh
set -uo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
write=$here/write-effort-file.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pass=0 fail=0

# run INPUT CMD...: feed INPUT on stdin; keep stdout in $out, stderr in $err
# and the exit code in $code.
run() {
  local input=$1
  shift
  out=$("$@" <<< "$input" 2>"$tmp/stderr")
  code=$?
  err=$(<"$tmp/stderr")
}

result() {  # result NAME FAILURE; an empty FAILURE passes
  if [[ -z $2 ]]; then
    echo "pass  $1"
    pass=$((pass + 1))
  else
    echo "FAIL  $1: $2"
    { echo "$out"; echo "$err"; } | sed 's/^/      | /'
    fail=$((fail + 1))
  fi
}

# has NAME CODE TEXT...: the last run exited CODE and its output holds each TEXT.
has() {
  local name=$1 want=$2 t msg=
  shift 2
  [[ $code == "$want" ]] || msg="exit $code, want $want"
  for t in "$@"; do
    [[ $out$'\n'$err == *"$t"* ]] || msg+="${msg:+; }missing: $t"
  done
  result "$name" "$msg"
}

# file_is NAME FILE TEXT: FILE holds exactly TEXT.
file_is() {
  local msg=
  if [[ ! -f $2 ]]; then
    msg="no $2"
  elif [[ $(<"$2") != "$3" ]]; then
    msg="content differs: $(diff <(echo "$3") "$2" | head -5 | tr '\n' ' ')"
  fi
  result "$1" "$msg"
}

# --- Fixtures -------------------------------------------------------------

tree=$tmp/tree
mkdir -p "$tree/a" "$tree/b" "$tree/c"

root_input="name: ship-widgets
kind: achieve
intent: Have widgets shipping to paying customers, so that the shop earns revenue.
title: Widgets shipping
end-state: Paying customers receive their widgets, and the owner's \"orders\" page: lists each one.
criterion: paid-order-arrives  Done when: a customer receives the widget they paid for.
criterion: refund-on-loss Done when: a lost parcel is refunded, or resent; within a week."

cat > "$tree/b/keep-users-safe-effort.md" <<'EOF'
---
name: keep-users-safe
kind: maintain
intent: >-
  Keep user data out of reach of outsiders, so that users trust the shop.
---

# User data safe

## Definition of done

- data-unread  Held when: no outsider reads user data.
EOF

child_input="name: grow-widgets
kind: optimize
intent: Increase the share of widget orders shipped within a day, so that customers keep ordering from the shop.

parent: ship-widgets pack-at-dawn ship-by-courier
parent: keep-users-safe # guessed
title: More widget orders shipped within a day
end-state: The share of widget orders shipped within a day of payment rises.
end-state: Orders that wait longer are the ones a customer asked to hold.
criterion: orders-ship-within-a-day Metric: share of orders shipped within 24 hours, target 95% (guessed).
serves: ship-widgets paid-order-arrives Done when: orders shipped within a day reach their customers.
serves: keep-users-safe data-unread Held when: shipping labels show no more than name and address.
serves: ship-widgets refund-on-loss Done when: a lost fast order is resent the same day.
limit: [maintain] order-data-private : Keep order data private, so that customers trust the shop.
limit: [maintain] packers-rested : Keep packers' shifts under eight hours, so that speed holds (guessed). # guessed"

# --- Root effort ----------------------------------------------------------

run "$root_input" "$write" "$tree/a"
has "root: passes the check and is written" 0 "guesses: none" "wrote $tree/a/ship-widgets-effort.md"
file_is "root: exact text" "$tree/a/ship-widgets-effort.md" '---
name: ship-widgets
kind: achieve
intent: >-
  Have widgets shipping to paying customers, so that the shop earns revenue.
---

# Widgets shipping

## End state

Paying customers receive their widgets, and the owner'"'"'s "orders" page: lists each one.

## Definition of done

- paid-order-arrives  Done when: a customer receives the widget they paid for.
- refund-on-loss  Done when: a lost parcel is refunded, or resent; within a week.

## Serves

Root effort: it serves no other effort.'

# --- Child serving two parents, with limits -------------------------------

run "$child_input" "$write" --root "$tree" "$tree/c"
child=$tree/c/grow-widgets-effort.md
has "child: passes the check and is written" 0 "wrote $child" "guesses:
  8: keep-users-safe: []  # guessed
  21: - orders-ship-within-a-day  Metric: share of orders shipped within 24 hours, target 95% (guessed).
  37: - [maintain] packers-rested"
file_is "child: exact text" "$child" '---
name: grow-widgets
kind: optimize
intent: >-
  Increase the share of widget orders shipped within a day, so that customers keep ordering from the shop.
contributes-to:
  ship-widgets: [pack-at-dawn, ship-by-courier]
  keep-users-safe: []  # guessed
---

# More widget orders shipped within a day

## End state

The share of widget orders shipped within a day of payment rises.

Orders that wait longer are the ones a customer asked to hold.

## Definition of done

- orders-ship-within-a-day  Metric: share of orders shipped within 24 hours, target 95% (guessed).

## Serves

### ship-widgets

- paid-order-arrives  Done when: orders shipped within a day reach their customers.
- refund-on-loss  Done when: a lost fast order is resent the same day.

### keep-users-safe

- data-unread  Held when: shipping labels show no more than name and address.

## Limits

- [maintain] order-data-private : Keep order data private, so that customers trust the shop.
- [maintain] packers-rested : Keep packers'"'"' shifts under eight hours, so that speed holds (guessed). # guessed'

# --- A failing check writes nothing ---------------------------------------

bad=${child_input/Increase the share/Build the share}
bad=${bad/serves: ship-widgets paid-order-arrives/serves: ship-widgets faster-arrival}
run "$bad" "$write" --root "$tree" "$tmp"
has "failing: the checker's problems, under the final path, with each line's text" 1 \
  "$tmp/grow-widgets-effort.md:4: intent verb Build is not in the optimize row" \
  "    |   Build the share of widget orders shipped within a day, so that customers keep ordering from the shop." \
  "$tmp/grow-widgets-effort.md:27: Serves entry under ### ship-widgets is not named after one of its criteria" \
  "    | - faster-arrival  Done when: orders shipped within a day reach their customers." \
  "nothing written"
result "failing: no file left" "$([[ ! -e $tmp/grow-widgets-effort.md ]] || echo "file written")"

run "$child_input" "$write" --root "$tree" "$tmp"
has "failing: the same command, input fixed, writes the file" 0 "wrote $tmp/grow-widgets-effort.md"

# --- Existing file --------------------------------------------------------

before=$(<"$child")
run "${child_input/rises/climbs}" "$write" --root "$tree" "$tree/c"
has "existing: refused without --replace" 3 "exists; --replace replaces it"
file_is "existing: left as it was" "$child" "$before"

run "$bad" "$write" --replace --root "$tree" "$tree/c"
has "existing: a failing --replace" 1 "nothing written"
file_is "existing: a failing --replace leaves it as it was" "$child" "$before"

run "${child_input/rises/climbs}" "$write" --replace --root "$tree" "$tree/c"
has "existing: --replace replaces it" 0 "wrote $child"
result "existing: replaced content" "$(grep -q 'payment climbs\.' "$child" || echo "not replaced")"

# --- Parents and approaches -----------------------------------------------

# section_is NAME FILE TEXT: FILE's Approaches section, heading to end, is TEXT.
section_is() {
  local got
  got=$(sed -n '/^## Approaches/,$p' "$2")
  result "$1" "$([[ $got == "$3" ]] || echo "section differs: $(diff <(echo "$3") <(echo "$got") | head -5 | tr '\n' ' ')")"
}
# rest_of FILE: the file without its Approaches section.
rest_of() { awk '/^## / { skip = ($0 == "## Approaches") } !skip' "$1"; }

mkdir -p "$tmp/pg"
run "${child_input/parent: keep-users-safe # guessed/parent: keep-users-safe guard-labels  # guessed}" "$write" --root "$tree" "$tmp/pg"
has "parent: approaches and # guessed" 0 "8: keep-users-safe: [guard-labels]  # guessed"

ap1="approach: [chosen] batch-at-dawn (logbook: 1.2)"
ap2="approach: [candidate] pack-on-payment (logbook: 1.3) # guessed"
ap3="approach: [candidate] pack-in-two-waves (logbook: 2.1)"
sec12="## Approaches

- [chosen] batch-at-dawn (logbook: 1.2)
- [candidate] pack-on-payment (logbook: 1.3) # guessed"
sec3="## Approaches

- [candidate] pack-in-two-waves (logbook: 2.1)"

mkdir -p "$tmp/ap"
apf=$tmp/ap/grow-widgets-effort.md
run "$child_input
$ap1
$ap2" "$write" --root "$tree" "$tmp/ap"
has "approach: lines pass the check and are written" 0 "wrote $apf" "42: - [candidate] pack-on-payment"
section_is "approach: the last section, one line per approach: key" "$apf" "$sec12"

run "${child_input/rises/climbs}" "$write" --replace --root "$tree" "$tmp/ap"
has "replace: without approach: lines" 0 "wrote $apf"
section_is "replace: keeps the Approaches section" "$apf" "$sec12"
result "replace: still replaces the rest" "$(grep -q 'payment climbs\.' "$apf" || echo "not replaced")"

run "$child_input
$ap3" "$write" --replace --root "$tree" "$tmp/ap"
has "replace: with approach: lines" 0 "wrote $apf"
section_is "replace: approach: lines replace the section" "$apf" "$sec3"

rest=$(rest_of "$apf")
run "$ap1
$ap2" "$write" --approaches --root "$tree" "$apf"
has "--approaches: passes the check and is written" 0 "wrote $apf"
section_is "--approaches: rewrites the section" "$apf" "$sec12"
result "--approaches: leaves the rest as it was" "$([[ $(rest_of "$apf") == "$rest" ]] || echo "rest changed")"

mkdir -p "$tmp/noap"
cp "$tree/c/grow-widgets-effort.md" "$tmp/noap/"
run "$ap3" "$write" --approaches --root "$tree" "$tmp/noap/grow-widgets-effort.md"
has "--approaches: a file without the section" 0 "wrote $tmp/noap/grow-widgets-effort.md"
result "--approaches: appends the section to the file" \
  "$([[ $(<"$tmp/noap/grow-widgets-effort.md") == "$(<"$tree/c/grow-widgets-effort.md")"$'\n\n'"$sec3" ]] || echo "not the file plus the section")"

before=$(<"$apf")
run "${ap3/\[candidate\]/[maybe]}" "$write" --approaches --root "$tree" "$apf"
has "--approaches: a failing check" 1 "$apf:41: approach status maybe is not chosen, candidate or dropped" \
  "    | - [maybe] pack-in-two-waves (logbook: 2.1)" "nothing written"
file_is "--approaches: a failing check leaves the file as it was" "$apf" "$before"

run "$ap3
limit: [maintain] x : Keep x, so that y." "$write" --approaches "$apf"
has "--approaches: another key" 2 "--approaches takes only approach: lines"

run "" "$write" --approaches "$apf"
has "--approaches: no approach: line" 2 "no approach: line"

run "$ap3" "$write" --approaches "$tmp/ap/nowhere-effort.md"
has "--approaches: no such file" 2 "no file"

run "$ap3" "$write" --approaches --replace "$apf"
has "--approaches: with --replace" 2 "usage:"
file_is "--approaches: refused runs leave the file as it was" "$apf" "$before"

# --- Input and usage ------------------------------------------------------

run "${root_input}
key-task: something" "$write" "$tmp"
has "input: unknown key" 2 "unknown key key-task"

run "${root_input/title: Widgets shipping/}" "$write" "$tmp"
has "input: no title" 2 "needs a title"

run "${root_input/name: ship-widgets/}" "$write" "$tmp"
has "input: no name" 2 "needs a name"

run "$root_input" "$write" "$tmp/nowhere"
has "usage: missing folder" 2 "no folder"

run "$root_input" "$write" "$tmp" "$tree"
has "usage: two folders" 2 "usage:"

echo "$pass passed, $fail failed"
(( fail == 0 ))
