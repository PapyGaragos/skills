#!/usr/bin/env bash
# Build effort files in a temp dir, run effort-intents.sh and
# check-effort-file.sh on them, and check their output and exit codes.
# Prints one line per test and a final count; exits 1 on any failure.
#
# Usage: test-effort-scripts.sh
set -uo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
intents=$here/effort-intents.sh
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

- A paid order arrives.
  - [manual] Done when: a test order arrives at the owner's address.

## Serves

Root effort: it serves no other effort.

## Work
EOF

cat > "$tree/b/keep-users-safe-effort.md" <<'EOF'
---
name: keep-users-safe
kind: maintain
intent: >-
  Keep user data out of reach of outsiders, so that users trust the shop.
---
EOF

# A child with a folded intent, a guessed parent, key tasks and limits. Its
# Work section holds text that would be a problem anywhere else.
child=$tree/c/grow-widgets-effort.md
cat > "$child" <<'EOF'
---
name: grow-widgets
kind: optimize
intent: >-
  Increase the share of widget orders shipped within a day, so that
  customers keep ordering from the shop.
contributes-to:
  - ship-widgets
  - keep-users-safe # guessed
---

# More widget orders shipped within a day

## End state

The share of widget orders shipped within a day of payment rises.

## Definition of done

Most important first. When two criteria conflict, the earlier one wins.

- Orders ship within a day of payment.
  - [automated] Metric: share of orders shipped within 24 hours, from the order log, target 95%. Proves the speed.

## Serves

### ship-widgets

- Faster shipping keeps widgets reaching customers.
  - [manual] Done when: the owner confirms each week's orders arrived.

### keep-users-safe

- Faster shipping exposes no user data.
  - [manual] Held when: the owner reviews the shipping labels monthly.

## Key tasks

- [achieve] packing-stock-on-hand : Have packing stock on hand every morning, so that no order waits for boxes.
  - [manual] Held when: the packer checks the shelf daily.

## Limits

- [maintain] order-data-private : Keep order data private, so that customers trust the shop (guessed).
  - [automated] Held when: an access audit finds no outside reader.

## Work

- [manual] (to write) Done when: nothing, Metric: speed, now 80%.

## Notes
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

# --- effort-intents.sh ----------------------------------------------------

run "$intents" --root "$tree" grow-widgets nope
same "intents: SLUG output unchanged" 0 "grow-widgets: Increase the share of widget orders shipped within a day, so that customers keep ordering from the shop.
  ship-widgets: Have widgets shipping to paying customers, so that the shop earns revenue.
  keep-users-safe: Keep user data out of reach of outsiders, so that users trust the shop.
nope: (no nope-effort.md under $tree)"

run "$intents" --root "$tree" --all
same "intents: --all" 0 "grow-widgets [optimize]: Increase the share of widget orders shipped within a day, so that customers keep ordering from the shop.
keep-users-safe [maintain]: Keep user data out of reach of outsiders, so that users trust the shop.
ship-widgets [achieve]: Have widgets shipping to paying customers, so that the shop earns revenue."

(cd "$tree" && run "$intents" --all)
has "intents: --all without --root reads the working dir" 0 "ship-widgets [achieve]: Have widgets"

dup=$tmp/dup
mkdir -p "$dup/x" "$dup/y"
cp "$root" "$dup/x/"
sed 's/^intent: Have widgets/intent: Have gadgets/' "$root" > "$dup/y/ship-widgets-effort.md"
warning="warning: slug ship-widgets is carried by several files: $dup/x/ship-widgets-effort.md $dup/y/ship-widgets-effort.md"
run "$intents" --root "$dup" ship-widgets
same "intents: duplicate slug warns on stderr in SLUG mode" 0 \
  "ship-widgets: Have widgets shipping to paying customers, so that the shop earns revenue." "$warning"
run "$intents" --root "$dup" --all
same "intents: duplicate slug gets a line per file in --all" 0 \
  "ship-widgets [achieve]: Have widgets shipping to paying customers, so that the shop earns revenue.
ship-widgets [achieve]: Have gadgets shipping to paying customers, so that the shop earns revenue." "$warning"

run "$intents"
has "intents: no slug is bad usage" 2 "usage:"
run "$intents" --all ship-widgets
has "intents: --all with a slug is bad usage" 2 "usage:"

# --- check-effort-file.sh: valid files -----------------------------------

lint "$child"
same "check: valid child with parents, key tasks and limits" 0 "guesses:
  9: - keep-users-safe # guessed
  44: - [maintain] order-data-private : Keep order data private, so that customers trust the shop (guessed)."

lint "$root"
same "check: valid root with an inline intent" 0 "guesses: none"

variant no-optional '/^## Key tasks/,/^## Work/{/^## Work/!d}'
lint "$v"
same "check: Key tasks and Limits are optional" 0 "guesses:
  9: - keep-users-safe # guessed"

variant intent-guessed 's/from the shop\.$/from the shop (guessed)./'
lint "$v"
has "check: (guessed) right before the intent's period" 0 "  6: customers keep ordering from the shop (guessed)."

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

variant parent-words 's/^  - ship-widgets$/  - Ship Widgets/'
lint "$v"
has "check: parent entry that is not a slug" 1 "$v:8: contributes-to entry is not a slug"

variant parent-comment 's/# guessed$/# maybe/'
lint "$v"
has "check: parent comment other than # guessed" 1 "$v:9: contributes-to entry is not a slug"

variant parent-missing 's/ship-widgets/ship-gizmos/'
lint "$v"
has "check: missing parent file is a warning only" 0 "$v:8: warning: no ship-gizmos-effort.md under $tree"

run "$check" "$v"
has "check: default root is the file's folder outside git" 0 \
  "$v:9: warning: no keep-users-safe-effort.md under $tmp/cases/parent-missing"

# --- check-effort-file.sh: sections ---------------------------------------

variant order 's/^## Definition of done/## X/; s/^## Serves/## Definition of done/; s/^## X/## Serves/'
lint "$v"
has "check: sections out of order" 1 "section ## Definition of done is out of order: the template puts it before ## Serves"

# shellcheck disable=SC2016  # a sed address, not an expansion
variant no-work '/^## Work/,$d'
lint "$v"
has "check: missing Work" 1 "$v: missing section ## Work"

variant no-end-state '/^## End state/d'
lint "$v"
has "check: missing End state" 1 "$v: missing section ## End state"

variant unknown 's/^## End state/## Wanted state/'
lint "$v"
has "check: unknown section" 1 "$v:14: unknown section ## Wanted state"

variant key-tasks-empty '/^- \[achieve\]/,/the shelf daily/d'
lint "$v"
has "check: empty Key tasks" 1 "$v:37: section ## Key tasks is empty"

variant limits-empty '/^- \[maintain\]/,/access audit/d'
lint "$v"
has "check: empty Limits" 1 "$v:42: section ## Limits is empty"

# --- check-effort-file.sh: Serves -----------------------------------------

variant serves-missing '/^### keep-users-safe/,/monthly/d'
lint "$v"
has "check: Serves missing a parent" 1 "$v:25: Serves has no ### keep-users-safe"

variant serves-extra 's/^### keep-users-safe/### other-effort/'
lint "$v"
has "check: Serves with a heading outside contributes-to" 1 "$v:32: ### other-effort in Serves is not in contributes-to"

variant root-serves 's/^Root effort: .*/Serves nothing./' "$root"
lint "$v"
has "check: root Serves without the root line" 1 \
  "$v:18: a root effort's Serves holds only the line: Root effort: it serves no other effort."

# --- check-effort-file.sh: present state ----------------------------------

variant to-write 's/\[manual\] Done when: the owner/[manual] (to write) Done when: the owner/'
lint "$v"
has "check: (to write) outside Work" 1 "$v:30: present-state marker (to write) outside Work"

variant metric-now 's/order log, target/order log, now 80%, target/'
lint "$v"
has "check: ', now ' in a Metric line" 1 "$v:23: present-state ', now ' in a Metric line outside Work"

# --- check-effort-file.sh: key tasks and limits ---------------------------

variant task-shape 's/^- \[achieve\] packing-stock-on-hand : /- packing-stock-on-hand: /'
lint "$v"
has "check: key task not an as-effort line" 1 "$v:39: key task is not an as-effort line"

variant task-verb 's/: Have packing stock/: Keep packing stock/'
lint "$v"
has "check: key task verb outside its kind's row" 1 "$v:39: key task verb Keep is not in the achieve row"

variant task-period 's/waits for boxes\./waits for boxes/'
lint "$v"
has "check: key task without a final period" 1 "$v:39: key task does not end with a period"

variant limit-kind 's/^- \[maintain\] order-data-private : Keep/- [achieve] order-data-private : Have/'
lint "$v"
has "check: limit not [maintain]" 1 "$v:44: limit is [achieve], a limit is always [maintain]"

variant limit-guessed 's/trust the shop (guessed)\./trust the shop./; s/Keep order data private,/Keep order data private (guessed),/'
lint "$v"
has "check: limit with (guessed) before the purpose" 1 \
  "$v:44: limit has (guessed) elsewhere than right before the final period"

variant limit-invented 's/^\(- \[maintain\] order-data-private : .*\)$/\1 # guessed/'
lint "$v"
has "check: invented limit ending with # guessed" 0 "44: - [maintain] order-data-private"

# --- check-effort-file.sh: verb table and usage ---------------------------

# Skills deploy as sibling links under their bare names. Without an as-effort
# sibling the verb check is skipped; with one it runs.
deployed=$tmp/deployed
mkdir -p "$deployed"
ln -s "${here%/*}" "$deployed/to-effort-file"
run "$deployed/to-effort-file/scripts/check-effort-file.sh" --root "$tree" "$tmp/cases/intent-verb/grow-widgets-effort.md"
has "check: no as-effort sibling skips the verb check" 0 "warning: $deployed/as-effort/SKILL.md not found: verbs not checked"
lacks "check: no as-effort sibling reports no verb problem" "intent verb Build"
ln -s "${here%/*/*}/as-effort" "$deployed/as-effort"
run "$deployed/to-effort-file/scripts/check-effort-file.sh" --root "$tree" "$tmp/cases/intent-verb/grow-widgets-effort.md"
has "check: as-effort sibling found through the deployed link" 1 "intent verb Build is not in the optimize row"

run "$check"
has "check: no file is bad usage" 2 "usage:"
run "$check" "$tmp/nowhere-effort.md"
has "check: unreadable file is bad usage" 2 "cannot read"
run "$check" "$child" "$root"
has "check: two files is bad usage" 2 "usage:"

echo "$pass passed, $fail failed"
(( fail == 0 ))
