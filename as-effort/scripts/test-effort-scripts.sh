#!/usr/bin/env bash
# Build effort files in a temp dir, run check-effort-file.sh on them, and
# check its output and exit codes.
# Prints one line per test and a final count; exits 1 on any failure.
#
# Usage: test-effort-scripts.sh
set -uo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
check=$here/check-effort-file.sh
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

# same NAME CODE STDOUT [STDERR]: the last run printed exactly this.
same() {
  local msg=
  [[ $code == "$2" ]] || msg="exit $code, want $2"
  [[ $out == "$3" ]] || msg+="${msg:+; }stdout differs"
  [[ $err == "${4:-}" ]] || msg+="${msg:+; }stderr differs"
  result "$1" "$msg"
}

# --- Fixtures -------------------------------------------------------------

tree=$tmp/tree
mkdir -p "$tree/a" "$tree/b" "$tree/c"

# A root with an inline intent.
root=$tree/a/ship-widgets-effort.md
cat > "$root" <<'EOF'
---
name: ship-widgets
kind: achieve
intent: Have widgets shipping to paying customers, so that the shop earns revenue.
---

# Widgets shipping

## End state

Paying customers receive their widgets.

## Definition of done

- paid-order-arrives  Done when: a customer receives the widget they paid for.
  - [manual] Done when: a test order arrives at the owner's address.

## Serves

Root effort: it serves no other effort.
EOF

cat > "$tree/b/keep-users-safe-effort.md" <<'EOF'
---
name: keep-users-safe
kind: maintain
intent: >-
  Keep user data out of reach of outsiders, so that users trust the shop.
---
EOF

# A child with a folded intent, a guessed parent and limits.
child=$tree/c/grow-widgets-effort.md
cat > "$child" <<'EOF'
---
name: grow-widgets
kind: optimize
intent: >-
  Increase the share of widget orders shipped within a day, so that
  customers keep ordering from the shop.
contributes-to:
  ship-widgets: [pack-at-dawn,ship-by-courier]
  keep-users-safe: [] # guessed
---

# More widget orders shipped within a day

## End state

The share of widget orders shipped within a day of payment rises.

## Definition of done

Most important first. When two criteria conflict, the earlier one wins.

- orders-ship-within-a-day  Metric: share of orders shipped within 24 hours, target 95%.
  - [automated] Metric: share of orders shipped within 24 hours, from the order log, target 95%. Proves the speed.

## Serves

### ship-widgets

- paid-order-arrives  Done when: orders shipped within a day reach their customers.
  - [manual] Done when: the owner confirms each week's orders arrived.

### keep-users-safe

- Faster shipping exposes no user data.
  - [manual] Held when: the owner reviews the shipping labels monthly.

## Limits

- [maintain] order-data-private : Keep order data private, so that customers trust the shop (guessed).
  - [automated] Held when: an access audit finds no outside reader.

## Approaches

- [chosen] pack-at-dawn (logbook: 1.2)
- [candidate] pack-on-payment (logbook: 1.3.1)
EOF

# variant CASE SED [SRC]: a copy of SRC (the child by default) edited by SED,
# alone in its own folder. Sets $v to its path.
variant() {
  local src=${3:-$child}
  mkdir -p "$tmp/cases/$1"
  v=$tmp/cases/$1/${src##*/}
  sed -e "$2" "$src" > "$v"
}
lint() { run "$check" --root "$tree" "$@"; }

# --- check-effort-file.sh: valid files -----------------------------------

lint "$child"
same "check: valid child with parents and limits" 0 "guesses:
  9: keep-users-safe: [] # guessed
  39: - [maintain] order-data-private : Keep order data private, so that customers trust the shop (guessed)."

lint "$root"
same "check: valid root with an inline intent" 0 "guesses: none"

variant no-optional '/^## Limits/,$d'
lint "$v"
same "check: Limits is optional" 0 "guesses:
  9: keep-users-safe: [] # guessed"

variant intent-guessed 's/from the shop\.$/from the shop (guessed)./'
lint "$v"
has "check: (guessed) right before the intent's period" 0 "  4: intent: Increase the share of widget orders shipped within a day, so that customers keep ordering from the shop (guessed)."
lacks "check: a folded intent's guess prints no fragment" "  6: customers"

# --- check-effort-file.sh: frontmatter ------------------------------------

variant no-frontmatter '1d'
lint "$v"
has "check: no frontmatter" 1 "$v:1: no frontmatter"

variant name-missing '/^name:/d'
lint "$v"
has "check: missing name" 1 "$v: frontmatter has no name"

variant kind-missing '/^kind:/d'
lint "$v"
has "check: missing kind" 1 "$v: frontmatter has no kind"

variant intent-missing '/^intent:/,/ordering from the shop/d'
lint "$v"
has "check: missing intent" 1 "$v: frontmatter has no intent"

variant kind-bad 's/^kind: optimize/kind: improve/'
lint "$v"
has "check: kind outside the three" 1 "$v:3: kind improve is not achieve, maintain or optimize"

variant name-case 's/^name: .*/name: Grow_Widgets/'
lint "$v"
has "check: name not kebab-case" 1 "$v:2: name Grow_Widgets is not kebab-case"

variant name-other 's/^name: .*/name: grow-gadgets/'
lint "$v"
has "check: name not matching the file name" 1 "$v:2: name grow-gadgets does not match the file name grow-widgets-effort.md"

mkdir -p "$tmp/cases/stem"
cp "$child" "$tmp/cases/stem/grow-widgets.md"
lint "$tmp/cases/stem/grow-widgets.md"
has "check: file name without -effort.md" 1 "grow-widgets.md: file name does not end in -effort.md"

# --- check-effort-file.sh: intent -----------------------------------------

variant intent-verb 's/^  Increase the share/  Build the share/'
lint "$v"
has "check: intent verb outside its kind's row" 1 "$v:4: intent verb Build is not in the optimize row: Maximize Minimize Increase Reduce"

variant intent-no-so-that 's/, so that$/ and/'
lint "$v"
has "check: intent without ', so that '" 1 "$v:4: intent needs exactly one ', so that '"

variant intent-two-so-that 's/from the shop\.$/from the shop, so that it grows./'
lint "$v"
has "check: intent with two ', so that '" 1 "$v:4: intent needs exactly one ', so that '"

variant intent-period 's/from the shop\.$/from the shop/'
lint "$v"
has "check: intent without a final period" 1 "$v:4: intent does not end with a period"

variant intent-guessed-early 's/, so that$/ (guessed), so that/'
lint "$v"
has "check: intent with (guessed) before the purpose" 1 "$v:4: intent has (guessed) elsewhere than right before the final period"

# --- check-effort-file.sh: contributes-to ---------------------------------

variant parent-words 's/^  ship-widgets:/  Ship Widgets:/'
lint "$v"
has "check: parent entry that is not a slug" 1 "$v:8: contributes-to entry is not"

variant parent-comment 's/# guessed$/# maybe/'
lint "$v"
has "check: parent comment other than # guessed" 1 "$v:9: contributes-to entry is not"

variant parent-list-form 's/^  ship-widgets: .*/  - ship-widgets/'
lint "$v"
has "check: the old list form is a problem" 1 "$v:8: contributes-to entry is not '<parent>: [<approach>, ...]'"

variant parent-no-list 's/^  ship-widgets: .*/  ship-widgets:/'
lint "$v"
has "check: a parent without its approach list" 1 "$v:8: contributes-to entry is not"

variant parent-approach-words 's/^  ship-widgets: .*/  ship-widgets: [Pack At Dawn]/'
lint "$v"
has "check: a parent approach that is not a slug" 1 "$v:8: contributes-to entry is not"

variant parent-spaced 's/^  ship-widgets: .*/  ship-widgets: [ pack-at-dawn ,  ship-by-courier ]/; s/^  keep-users-safe: \[\] # guessed/  keep-users-safe: []    # guessed/'
lint "$v"
has "check: spaces inside the list and before # guessed" 0 "9: keep-users-safe: []    # guessed"

variant parent-missing 's/ship-widgets/ship-gizmos/'
lint "$v"
has "check: missing parent file is a warning only" 0 "$v:8: warning: no ship-gizmos-effort.md under $tree"

run "$check" "$v"
has "check: default root is the file's folder outside git" 0 \
  "$v:9: warning: no keep-users-safe-effort.md under $tmp/cases/parent-missing"

# --- check-effort-file.sh: sections ---------------------------------------

variant order 's/^## Definition of done/## X/; s/^## Serves/## Definition of done/; s/^## X/## Serves/'
lint "$v"
has "check: sections out of order" 1 "section ## Definition of done is out of order: it goes before ## Serves"

variant criterion-unnamed 's/^- orders-ship-within-a-day  Metric: share/- Share/'
lint "$v"
has "check: a criterion without a slug" 1 "$v:22: criterion is not - <slug>  Done when|Held when|Metric: <condition>"

variant criterion-period 's/^- orders-ship-within-a-day  Metric:/- orders-ship-within-a-day. Metric:/'
lint "$v"
has "check: a criterion slug followed by a period" 1 "$v:22: criterion is not"

variant criterion-none '/^- orders-ship-within-a-day/d'
lint "$v"
has "check: a Definition of done with no criterion" 1 "$v:18: section ## Definition of done names no criterion"

variant no-end-state '/^## End state/d'
lint "$v"
has "check: missing End state" 1 "$v: missing section ## End state"

variant unknown 's/^## End state/## Wanted state/'
lint "$v"
has "check: unknown section" 1 "$v:14: unknown section ## Wanted state"

variant key-tasks 's/^## Limits/## Key tasks/'
lint "$v"
has "check: leftover Key tasks section" 1 "$v:37: unknown section ## Key tasks"

variant limits-empty '/^- \[maintain\] order-data-private/,/access audit/d'
lint "$v"
has "check: empty Limits" 1 "$v:37: section ## Limits is empty"

# --- check-effort-file.sh: Serves -----------------------------------------

variant serves-missing '/^### keep-users-safe/,/monthly/d'
lint "$v"
has "check: Serves missing a parent" 1 "$v:25: Serves has no ### keep-users-safe"

variant serves-extra 's/^### keep-users-safe/### other-effort/'
lint "$v"
has "check: Serves with a heading outside contributes-to" 1 "$v:32: ### other-effort in Serves is not in contributes-to"

variant serves-condition 's/^- paid-order-arrives  Done when: orders/- paid-order-arrives  Reached when: orders/'
lint "$v"
has "check: Serves entry with a condition other than Done when, Held when or Metric" 1 \
  "$v:29: Serves entry under ### ship-widgets is not - <criterion>  Done when|Held when|Metric: <condition>"

variant serves-own-name 's/^- paid-order-arrives  Done when: orders/- faster-arrival  Done when: orders/'
lint "$v"
has "check: Serves entry not named after a parent criterion" 1 \
  "$v:29: Serves entry under ### ship-widgets is not named after one of its criteria: paid-order-arrives"

variant serves-prose 's/^- paid-order-arrives  Done when: orders.*/- Faster shipping keeps widgets reaching customers./'
lint "$v"
has "check: Serves prose under a parent with criteria" 1 \
  "$v:29: Serves entry under ### ship-widgets is not named after one of its criteria"

lint "$child"
lacks "check: a parent without named criteria takes any Serves entry" "not named after"

variant root-serves 's/^Root effort: .*/Serves nothing./' "$root"
lint "$v"
has "check: root Serves without the root line" 1 \
  "$v:18: a root effort's Serves holds only the line: Root effort: it serves no other effort."

# --- check-effort-file.sh: limits -----------------------------------------

variant limit-shape 's/^- \[maintain\] order-data-private : /- order-data-private: /'
lint "$v"
has "check: limit not an as-effort line" 1 "$v:39: limit is not an as-effort line"

variant limit-verb 's/: Keep order data/: Have order data/'
lint "$v"
has "check: limit verb outside its kind's row" 1 "$v:39: limit verb Have is not in the maintain row"

variant limit-period 's/trust the shop (guessed)\./trust the shop (guessed)/'
lint "$v"
has "check: limit without a final period" 1 "$v:39: limit does not end with a period"

variant limit-kind 's/^- \[maintain\] order-data-private : Keep/- [achieve] order-data-private : Have/'
lint "$v"
has "check: limit not [maintain]" 1 "$v:39: limit is [achieve], a limit is always [maintain]"

variant limit-guessed 's/trust the shop (guessed)\./trust the shop./; s/Keep order data private,/Keep order data private (guessed),/'
lint "$v"
has "check: limit with (guessed) before the purpose" 1 \
  "$v:39: limit has (guessed) elsewhere than right before the final period"

variant limit-invented 's/^\(- \[maintain\] order-data-private : .*\)$/\1 # guessed/'
lint "$v"
has "check: invented limit ending with # guessed" 0 "39: - [maintain] order-data-private"

# --- check-effort-file.sh: approaches -------------------------------------

# Lines 44 (pack-at-dawn, chosen) and 45 (pack-on-payment, candidate).
dawn='/^- \[chosen\] pack-at-dawn/'
pay='/^- \[candidate\] pack-on-payment/'

variant ap-v1 "${dawn}s/pack-at-dawn /pack-at-dawn : Pack every paid order at dawn. /"
lint "$v"
has "approach: a version 1 line with its way" 1 "$v:44: approach is not - [<status>] <approach-slug> (logbook: <path>)"

variant ap-no-logbook "${dawn}s/ (logbook: 1.2)\$//"
lint "$v"
has "approach: no logbook path" 1 "$v:44: approach is not"

variant ap-logbook-path "${dawn}s/(logbook: 1.2)/(logbook: one)/"
lint "$v"
has "approach: logbook path not a node path" 1 "$v:44: approach is not"

variant ap-slug-case "${pay}s/pack-on-payment /Pack_On_Payment /"
lint "$v"
has "approach: slug not kebab-case" 1 "$v:45: approach is not"

variant ap-guessed "${pay}s/\$/ # guessed/"
lint "$v"
has "approach: trailing # guessed is listed" 0 "45: - [candidate] pack-on-payment"

variant ap-nested "${dawn}a\\  - a note"
lint "$v"
has "approach: a nested line" 1 "$v:45: approach is not"

variant ap-status "${pay}s/\[candidate\]/[maybe]/"
lint "$v"
has "approach: status outside the list" 1 "$v:45: approach status maybe is not chosen, candidate or dropped"

variant ap-dropped "${pay}s/\[candidate\]/[dropped]/"
lint "$v"
has "approach: dropped is a status" 0 "guesses:"

variant ap-two-chosen "${pay}s/\[candidate\]/[chosen]/"
lint "$v"
has "approach: several chosen" 0 "guesses:"
lacks "approach: several chosen is no problem" "[chosen] approach"

variant ap-none-chosen "${dawn}s/\[chosen\]/[candidate]/"
lint "$v"
has "approach: none chosen" 0 "guesses:"

variant ap-dup "${pay}s/pack-on-payment /pack-at-dawn /"
lint "$v"
has "approach: slug twice" 1 "$v:45: approach pack-at-dawn appears twice"

for taken in grow-widgets ship-widgets orders-ship-within-a-day order-data-private; do
  variant "ap-taken-$taken" "${pay}s/pack-on-payment /$taken /"
  lint "$v"
  has "approach: slug $taken already taken" 1 "$v:45: approach $taken already names the effort, a parent, a criterion or a limit"
done

variant ap-empty "${dawn}d;${pay}d"
lint "$v"
has "approach: empty section" 1 "$v:42: section ## Approaches is empty"

variant ap-before-limits '/^## Limits/,/access audit/d'
printf '\n## Limits\n\n- [maintain] order-data-private : Keep order data private, so that customers trust the shop.\n' >> "$v"
lint "$v"
has "approach: section before Limits" 1 "section ## Limits is out of order: it goes before ## Approaches"

lint "$child"
lacks "approach: a valid section warns nothing" "warning:"

# --- check-effort-file.sh: verb table and usage ---------------------------

# Skills deploy as sibling links under their bare names. The verb table is
# found through the deployed link, in the skill's own SKILL.md, and the
# checker needs no other skill deployed next to it.
deployed=$tmp/deployed
mkdir -p "$deployed"
ln -s "${here%/*}" "$deployed/as-effort"
run "$deployed/as-effort/scripts/check-effort-file.sh" --root "$tree" "$tmp/cases/intent-verb/grow-widgets-effort.md"
has "check: verb table found through the deployed link" 1 "intent verb Build is not in the optimize row"
lacks "check: runs without an effort-approach-graph sibling" "No such file"
run "$deployed/as-effort/scripts/check-effort-file.sh" --root "$tree" "$tmp/cases/serves-own-name/grow-widgets-effort.md"
has "check: parent criteria read without an effort-approach-graph sibling" 1 "is not named after one of its criteria: paid-order-arrives"

run "$check"
has "check: no file is bad usage" 2 "usage:"
run "$check" "$tmp/nowhere-effort.md"
has "check: unreadable file is bad usage" 2 "cannot read"
run "$check" "$child" "$root"
has "check: two files is bad usage" 2 "usage:"

echo "$pass passed, $fail failed"
(( fail == 0 ))
