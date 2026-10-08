#!/usr/bin/env bash
# Build effort files in a temp dir, run effort-approach-graph.sh on them, and check its
# output and exit codes. Prints one line per test and a final count; exits 1
# on any failure.
#
# Usage: test-effort-approach-graph.sh
set -uo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
graph=$here/effort-approach-graph.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pass=0 fail=0

# run CMD...: keep stdout in $out, stderr in $err and the exit code in $code.
run() {
  out=$("$@" 2>"$tmp/stderr")
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

# lacks NAME TEXT: the last run's output does not hold TEXT.
lacks() {
  local msg=
  [[ $out$'\n'$err != *"$2"* ]] || msg="unexpected: $2"
  result "$1" "$msg"
}

# --- Fixtures -------------------------------------------------------------

tree=$tmp/tree
mkdir -p "$tree/a" "$tree/b" "$tree/c"

cat > "$tree/a/ship-widgets-effort.md" <<'EOF'
---
name: ship-widgets
kind: achieve
intent: Have widgets shipping to paying customers, so that the shop earns revenue.
---

## Approaches

- [chosen] ship-from-stock (logbook: 1.2)
- [candidate] ship-to-order (logbook: 1.3)
- [dropped] ship-by-courier (logbook: 1.4) # guessed
EOF

# The three approaches of ship-widgets. ship-from-stock names the child that
# covers one of its steps.
cat > "$tree/a/ship-from-stock-approach.md" <<'EOF'
---
name: ship-from-stock
contributes-to:
  - ship-widgets
---

Ship each order from stock on hand.

## Steps

1. Keep a day of orders in stock.
2. Pack each order within a day. (grow-widgets)

## Assumptions

- stock-covers-a-day : Stock covers a day of orders.
EOF
approach() {  # approach DIR SLUG LEAD EFFORT...: a minimal approach file
  local dir=$1 slug=$2 lead=$3 e
  shift 3
  { printf -- '---\nname: %s\ncontributes-to:\n' "$slug"
    for e in "$@"; do printf '  - %s\n' "$e"; done
    printf -- '---\n\n%s\n' "$lead"; } > "$dir/$slug-approach.md"
}
approach "$tree/a" ship-to-order "Make each widget once it is ordered." ship-widgets
approach "$tree/a" ship-by-courier "Hand every order to a courier." ship-widgets

cat > "$tree/b/keep-users-safe-effort.md" <<'EOF'
---
name: keep-users-safe
kind: maintain
intent: >-
  Keep user data out of reach of outsiders, so that users trust the shop.
---
EOF

# A child serving two of one parent's approaches and any approach of another,
# with a guessed limit, and an End state whose effort-shaped line is not a node.
cat > "$tree/c/grow-widgets-effort.md" <<'EOF'
---
name: grow-widgets
kind: optimize
intent: >-
  Increase the share of widget orders shipped within a day, so that
  customers keep ordering from the shop.
contributes-to:
  ship-widgets: [ship-from-stock, ship-to-order]
  keep-users-safe: []  # guessed
---

# More widget orders shipped within a day

## Limits

- [maintain] order-data-private : Keep order data private, so that customers trust the shop (guessed). # guessed

## End state

- [achieve] not-a-node : Have this line ignored, so that End state stays prose.
EOF

# case NAME: a copy of the tree to edit. Sets $t to its path and $c to its child.
case_tree() {
  t=$tmp/cases/$1
  mkdir -p "$t"
  cp -r "$tree/." "$t"
  c=$t/c/grow-widgets-effort.md
}

# --- Graph ----------------------------------------------------------------

child=$tree/c/grow-widgets-effort.md
run "$graph" --root "$tree"
want="nodes:
grow-widgets [optimize]: Increase the share of widget orders shipped within a day, so that customers keep ordering from the shop.
  file: $child
keep-users-safe [maintain]: Keep user data out of reach of outsiders, so that users trust the shop.
  file: $tree/b/keep-users-safe-effort.md
order-data-private [maintain]: Keep order data private, so that customers trust the shop (guessed).
  limit in: $child:16
ship-by-courier [approach]: Hand every order to a courier.
  file: $tree/a/ship-by-courier-approach.md
  children: none
ship-from-stock [approach]: Ship each order from stock on hand.
  file: $tree/a/ship-from-stock-approach.md
  children: grow-widgets
ship-to-order [approach]: Make each widget once it is ordered.
  file: $tree/a/ship-to-order-approach.md
  children: grow-widgets
ship-widgets [achieve]: Have widgets shipping to paying customers, so that the shop earns revenue.
  file: $tree/a/ship-widgets-effort.md
  chosen approaches: ship-from-stock

edges:
grow-widgets -> keep-users-safe  (contributes-to, $child:9)
grow-widgets -> ship-widgets [ship-from-stock, ship-to-order]  (contributes-to, $child:8)
grow-widgets respects order-data-private  (limit, $child:16)
ship-by-courier reaches ship-widgets [dropped]  (approach, $tree/a/ship-by-courier-approach.md:4)
ship-from-stock reaches ship-widgets [chosen]  (approach, $tree/a/ship-from-stock-approach.md:4)
ship-to-order reaches ship-widgets [candidate]  (approach, $tree/a/ship-to-order-approach.md:4)

coverage:
keep-users-safe
  names no criterion: grow-widgets
ship-widgets
  names no criterion: grow-widgets

problems:
none"
msg=
[[ $code == 0 ]] || msg="exit $code, want 0"
[[ $out == "$want" ]] || msg+="${msg:+; }stdout differs"
[[ -z $err ]] || msg+="${msg:+; }stderr not empty"
result "graph: nodes, edges and no problem" "$msg"
lacks "graph: an effort line in End state is not a node" "not-a-node"
has "graph: an edge shows the parent's approaches it serves" 0 \
  "grow-widgets -> ship-widgets [ship-from-stock, ship-to-order]  (contributes-to"
lacks "graph: an edge serving any approach shows none" "-> keep-users-safe ["
has "graph: an effort shows its chosen approaches" 0 "  file: $tree/a/ship-widgets-effort.md
  chosen approaches: ship-from-stock"

run bash -c 'cd "$1" && "$2"' _ "$tree" "$graph"
has "graph: default root is the working dir" 0 "  file: ./a/ship-widgets-effort.md"

empty=$tmp/empty
mkdir -p "$empty"
run "$graph" --root "$empty"
has "graph: no effort prints none" 0 "nodes:
none"

# An extracted limit: its file and its line name the same node.
case_tree extracted
cat > "$t/c/order-data-private-effort.md" <<'EOF'
---
name: order-data-private
kind: maintain
intent: Keep order data private, so that customers trust the shop (guessed).
---
EOF
run "$graph" --root "$t"
has "graph: a file and a line share one node" 0 "order-data-private [maintain]: Keep order data private, so that customers trust the shop (guessed).
  file: $t/c/order-data-private-effort.md
  limit in: $c:16"

# A Key tasks section left in a file draws nothing.
case_tree key-tasks
sed -i 's/^## Limits/## Key tasks\n\n- [maintain] packing-stock-on-hand : Keep packing stock on hand, so that no order waits.\n\n## Limits/' "$c"
run "$graph" --root "$t"
lacks "graph: a Key tasks line is no node and draws no edge" "packing-stock-on-hand"

# A spaced approach list with a guess reads like the plain one.
case_tree spaced
sed -i 's/^  ship-widgets: .*/  ship-widgets: [ ship-from-stock ,ship-to-order ]  # guessed/' "$c"
run "$graph" --root "$t"
has "graph: a spaced approach list reads the same" 0 \
  "grow-widgets -> ship-widgets [ship-from-stock, ship-to-order]  (contributes-to, $c:8)"

# --- Coverage -------------------------------------------------------------

# ship-widgets gets criteria; grow-widgets serves one of them, a second child
# serves another and names a third, and a third child names none.
case_tree coverage
awk '/^## Approaches/ {
    print "## Definition of done\n"
    print "- paid-order-arrives  Done when: a customer receives the widget they paid for."
    print "- refunds-settled  Held when: every refund is paid within a week."
    print "- margin-per-widget  Metric: margin on each widget sold, target 30%.\n"
  } 1' "$t/a/ship-widgets-effort.md" > "$t/ship" && mv "$t/ship" "$t/a/ship-widgets-effort.md"
cat >> "$c" <<'EOF'

## Serves

### ship-widgets

- paid-order-arrives  Done when: orders shipped within a day reach their customers.

### keep-users-safe

- Faster shipping exposes no user data.
EOF
cat > "$t/c/price-widgets-effort.md" <<'EOF'
---
name: price-widgets
kind: achieve
intent: Have widget prices that cover costs, so that the shop earns revenue.
contributes-to:
  ship-widgets: []
---

## Serves

### ship-widgets

- margin-per-widget  Metric: margin on each widget sold, target 30%.
- paid-order-arrives  Done when: the price shown is the price charged.
EOF
cat > "$t/c/label-widgets-effort.md" <<'EOF'
---
name: label-widgets
kind: achieve
intent: Have every widget labelled, so that the shop earns revenue.
contributes-to:
  ship-widgets: []
---
EOF
run "$graph" --root "$t"
has "graph: a chosen approach without Covers leaves every criterion uncovered" 0 \
  "  not covered by a chosen approach: paid-order-arrives, refunds-settled, margin-per-widget"
has "coverage: children per criterion, in the file's order" 0 "coverage:
keep-users-safe
  names no criterion: grow-widgets
ship-widgets
  paid-order-arrives: grow-widgets, price-widgets
  refunds-settled: none
  margin-per-widget: price-widgets
  names no criterion: label-widgets

problems:
none"

# With an approach chosen, a child counts only through [] or the chosen one.
# One naming a candidate and one naming a dropped approach are listed apart,
# with what they serve, and are no problem.
case_tree other-approach
cp "$t/../coverage/a/ship-widgets-effort.md" "$t/a/"
cp "$t/../coverage/c/"*-effort.md "$t/c/"
sed -i 's/^  ship-widgets: \[\]/  ship-widgets: [ship-to-order]/' "$t/c/price-widgets-effort.md"
sed -i 's/^  ship-widgets: \[\]/  ship-widgets: [ship-by-courier]/' "$t/c/label-widgets-effort.md"
run "$graph" --root "$t"
has "coverage: a child serving another approach counts for no criterion" 0 "ship-widgets
  paid-order-arrives: grow-widgets
  refunds-settled: none
  margin-per-widget: none
  serves another approach: label-widgets (ship-by-courier), price-widgets (ship-to-order)

problems:
none"

# With none chosen, a child naming a candidate counts, one naming only a
# dropped approach does not.
case_tree none-chosen
cp -r "$t/../other-approach/." "$t"
sed -i 's/^- \[chosen\] ship-from-stock/- [candidate] ship-from-stock/' "$t/a/ship-widgets-effort.md"
run "$graph" --root "$t"
has "coverage: with none chosen, a candidate counts and a dropped one does not" 0 "ship-widgets
  paid-order-arrives: grow-widgets, price-widgets
  refunds-settled: none
  margin-per-widget: price-widgets
  serves another approach: label-widgets (ship-by-courier)

problems:
none"
lacks "graph: an effort with none chosen shows no chosen approach" "chosen approaches:"
lacks "graph: an effort with none chosen reports no uncovered criterion" "not covered by a chosen approach"

# Several approaches chosen: a child counts through any of them, and a
# criterion counts as covered when any chosen approach's Covers lists it.
case_tree two-chosen
cp -r "$t/../other-approach/." "$t"
sed -i 's/^- \[candidate\] ship-to-order/- [chosen] ship-to-order/' "$t/a/ship-widgets-effort.md"
printf '\n## Covers\n\n### ship-widgets\n\n- paid-order-arrives\n' >> "$t/a/ship-from-stock-approach.md"
printf '\n## Covers\n\n### other-effort\n\n- refunds-settled\n\n### ship-widgets\n\n- margin-per-widget : Each widget is priced once ordered.\n' >> "$t/a/ship-to-order-approach.md"
run "$graph" --root "$t"
has "graph: several chosen approaches and the criteria none covers" 0 "  chosen approaches: ship-from-stock, ship-to-order
  not covered by a chosen approach: refunds-settled
"
has "coverage: a child serving any chosen approach counts" 0 "ship-widgets
  paid-order-arrives: grow-widgets, price-widgets
  refunds-settled: none
  margin-per-widget: price-widgets
  serves another approach: label-widgets (ship-by-courier)"
printf -- '- refunds-settled\n' >> "$t/a/ship-to-order-approach.md"
run "$graph" --root "$t"
lacks "graph: every criterion covered reports none uncovered" "not covered by a chosen approach"

case_tree unknown
sed -i 's/^  ship-widgets: .*/  ship-widgets: [ship-from-stock, ship-by-drone]/' "$c"
run "$graph" --root "$t"
has "graph: an approach the parent does not list" 1 \
  "unknown approach: $c:8: grow-widgets serves ship-by-drone, which the Approaches of ship-widgets do not list"
lacks "coverage: an unknown approach beside the chosen one still counts" "serves another approach"

case_tree unknown-only
sed -i 's/^  ship-widgets: .*/  ship-widgets: [ship-by-drone]/' "$c"
run "$graph" --root "$t"
has "coverage: a child naming only an unknown approach does not count" 1 \
  "ship-widgets
  serves another approach: grow-widgets (ship-by-drone)" \
  "unknown approach: $c:8:"

case_tree no-file-parent
sed -i 's/^  keep-users-safe: .*/  order-data-private: [any-way]/' "$c"
run "$graph" --root "$t"
lacks "graph: a parent without a file has no approaches to check" "unknown approach"

case_tree stale
cp "$t/../coverage/a/ship-widgets-effort.md" "$t/a/"
cp "$t/../coverage/c/price-widgets-effort.md" "$t/c/"
sed -i -e 's/^- margin-per-widget  Metric/- margin  Metric/' -e '/^- paid-order-arrives/d' "$t/c/price-widgets-effort.md"
run "$graph" --root "$t"
has "coverage: an entry naming a criterion the parent lacks" 1 \
  "  margin-per-widget: none
  names no criterion: grow-widgets, price-widgets" \
  "stale: $t/c/price-widgets-effort.md:13: price-widgets serves margin, which the definition of done of ship-widgets does not name"

# An entry under a heading the child does not contribute to draws no edge.
case_tree heading-only
cp "$t/../coverage/a/ship-widgets-effort.md" "$t/a/"
sed '/^contributes-to:/,/^---$/{/^contributes-to:/d;/^  [a-z]/d}' "$t/../coverage/c/price-widgets-effort.md" > "$t/c/price-widgets-effort.md"
run "$graph" --root "$t"
has "coverage: a Serves heading without the edge counts nothing" 0 "  margin-per-widget: none"

# --- Approaches -----------------------------------------------------------

run "$graph" --root "$tree"
has "approach: a node with its lead line, file and children" 0 \
  "ship-from-stock [approach]: Ship each order from stock on hand.
  file: $tree/a/ship-from-stock-approach.md
  children: grow-widgets"
has "approach: an edge to each effort, with the status its section gives" 0 \
  "ship-from-stock reaches ship-widgets [chosen]  (approach, $tree/a/ship-from-stock-approach.md:4)" \
  "ship-to-order reaches ship-widgets [candidate]" "ship-by-courier reaches ship-widgets [dropped]"
has "approach: no child names it" 0 "ship-by-courier [approach]: Hand every order to a courier.
  file: $tree/a/ship-by-courier-approach.md
  children: none"

case_tree ap-children
cp "$t/../other-approach/a/ship-widgets-effort.md" "$t/a/"
cp "$t/../other-approach/c/"*-effort.md "$t/c/"
run "$graph" --root "$t"
has "approach: children are the efforts whose list names it, [] left out" 0 \
  "ship-by-courier [approach]: Hand every order to a courier.
  file: $t/a/ship-by-courier-approach.md
  children: label-widgets" \
  "ship-from-stock [approach]: Ship each order from stock on hand.
  file: $t/a/ship-from-stock-approach.md
  children: grow-widgets"

case_tree ap-proposed
approach "$t/a" ship-to-order "Make each widget once it is ordered." ship-widgets keep-users-safe
run "$graph" --root "$t"
has "approach: an effort whose section does not list it yet is proposed, no problem" 0 \
  "ship-to-order reaches keep-users-safe [proposed]  (approach, $t/a/ship-to-order-approach.md:5)" \
  "problems:
none"

case_tree ap-no-file
rm "$t/a/ship-to-order-approach.md"
run "$graph" --root "$t"
has "approach: a section line with no approach file" 1 \
  "no approach file: $t/a/ship-widgets-effort.md:10: ship-widgets lists ship-to-order, which has no ship-to-order-approach.md"
lacks "approach: no file, no node" "ship-to-order [approach]"

case_tree ap-not-reached
approach "$t/a" ship-to-order "Make each widget once it is ordered." keep-users-safe
run "$graph" --root "$t"
has "approach: a section line whose approach does not name the effort" 1 \
  "not reached: $t/a/ship-widgets-effort.md:10: ship-widgets lists ship-to-order, whose contributes-to does not name ship-widgets"

case_tree ap-file-unlisted
sed -i 's/^  ship-widgets: .*/  ship-widgets: [ship-by-drone]/' "$c"
approach "$t/a" ship-by-drone "Fly each order to its customer." ship-widgets
run "$graph" --root "$t"
has "approach: a file alone does not list an approach in its effort's section" 1 \
  "ship-by-drone reaches ship-widgets [proposed]" \
  "unknown approach: $c:8: grow-widgets serves ship-by-drone, which the Approaches of ship-widgets do not list"

case_tree ap-several
cp "$t/a/ship-to-order-approach.md" "$t/c/"
run "$graph" --root "$t"
has "approach: a slug carried by two approach files" 1 \
  "several files: ship-to-order: $t/a/ship-to-order-approach.md $t/c/ship-to-order-approach.md"

case_tree ap-effort-slug
approach "$t/c" grow-widgets "Pack faster." ship-widgets
approach "$t/c" order-data-private "Encrypt every order." keep-users-safe
run "$graph" --root "$t"
has "approach: a slug carried by an approach and an effort" 1 \
  "approach and effort: grow-widgets: $t/c/grow-widgets-approach.md and $c carry one slug" \
  "approach and effort: order-data-private: $t/c/order-data-private-approach.md and $c:16 carry one slug"

case_tree ap-dangling
approach "$t/a" ship-by-courier "Hand every order to a courier." ship-widgets ship-gizmos
run "$graph" --root "$t"
has "approach: an effort no file or line names" 1 \
  "dangling: $t/a/ship-by-courier-approach.md:5: approach ship-by-courier reaches ship-gizmos, which no effort names"

case_tree ap-step-unknown
sed -i 's/(grow-widgets)$/(ship-faster)/' "$t/a/ship-from-stock-approach.md"
run "$graph" --root "$t"
has "approach: a step naming no effort" 1 \
  "step: $t/a/ship-from-stock-approach.md:12: (ship-faster) names no effort"

case_tree ap-step-unrelated
sed -i 's/(grow-widgets)$/(keep-users-safe)/' "$t/a/ship-from-stock-approach.md"
run "$graph" --root "$t"
has "approach: a step naming an effort that serves none of its efforts" 1 \
  "step: $t/a/ship-from-stock-approach.md:12: (keep-users-safe) contributes to none of ship-widgets with [ship-from-stock] or []"

case_tree ap-step-other
sed -i 's/^  ship-widgets: .*/  ship-widgets: [ship-to-order]/' "$c"
run "$graph" --root "$t"
has "approach: a step naming an effort that serves another approach" 1 \
  "step: $t/a/ship-from-stock-approach.md:12: (grow-widgets) contributes to none of ship-widgets with [ship-from-stock] or []"

case_tree ap-step-any
sed -i 's/^  ship-widgets: .*/  ship-widgets: []/' "$c"
run "$graph" --root "$t"
has "approach: a step naming an effort serving whatever the approach" 0 "problems:
none"

case_tree ap-step-two
sed -i 's/(grow-widgets)$/(grow-widgets, ship-faster)/' "$t/a/ship-from-stock-approach.md"
run "$graph" --root "$t"
has "approach: each effort a step names is checked" 1 \
  "step: $t/a/ship-from-stock-approach.md:12: (ship-faster) names no effort"
lacks "approach: the first of two efforts on a step passes" "(grow-widgets) contributes to none"

# --- Problems -------------------------------------------------------------

case_tree differs
cat > "$t/c/order-data-private-effort.md" <<'EOF'
---
name: order-data-private
kind: maintain
intent: Keep order records private, so that customers trust the shop.
---
EOF
run "$graph" --root "$t"
has "graph: a line worded unlike its file" 1 \
  "  limit in: $c:16: [maintain] Keep order data private, so that customers trust the shop (guessed)." \
  "differs: order-data-private: $c:16 words it differently from $t/c/order-data-private-effort.md"

case_tree several
mkdir -p "$t/d"
sed 's/^intent: Have widgets/intent: Have gadgets/' "$t/a/ship-widgets-effort.md" > "$t/d/ship-widgets-effort.md"
run "$graph" --root "$t"
has "graph: a slug carried by several files" 1 \
  "several files: ship-widgets: $t/a/ship-widgets-effort.md $t/d/ship-widgets-effort.md" \
  "differs: ship-widgets: $t/d/ship-widgets-effort.md words it differently from $t/a/ship-widgets-effort.md"

case_tree dangling
sed -i 's/^  ship-widgets:/  ship-gizmos:/' "$c"
run "$graph" --root "$t"
has "graph: a parent no effort names" 1 \
  "dangling: $c:8: grow-widgets contributes to ship-gizmos, which no effort names"

case_tree cycle
printf -- '---\nname: ship-widgets\nkind: achieve\nintent: Have widgets shipping, so that the shop earns revenue.\ncontributes-to:\n  grow-widgets: []\n---\n' > "$t/a/ship-widgets-effort.md"
run "$graph" --root "$t"
has "graph: a contributes-to cycle" 1 "cycle: grow-widgets -> ship-widgets -> grow-widgets"

case_tree self
sed -i 's/^  ship-widgets:/  grow-widgets:/' "$c"
run "$graph" --root "$t"
has "graph: an effort contributing to itself" 1 "cycle: grow-widgets -> grow-widgets"

case_tree limit-loop
sed -i 's/^- \[maintain\] order-data-private : /- [maintain] keep-users-safe : /' "$c"
printf -- '\n## Limits\n\n- [maintain] grow-widgets : Keep widgets growing, so that the shop lives.\n' >> "$t/b/keep-users-safe-effort.md"
run "$graph" --root "$t"
lacks "graph: limits close no cycle" "cycle:"

# --- Usage ----------------------------------------------------------------

run "$graph" --nope
has "usage: unknown option" 2 "usage:"
run "$graph" --root
has "usage: --root without a directory" 2 "usage:"
run "$graph" --root "$tmp/nowhere"
has "usage: missing root" 2 "no directory"

echo "$pass passed, $fail failed"
(( fail == 0 ))
