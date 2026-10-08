#!/usr/bin/env bash
# Build approach files in a temp dir and run check-approach-file.sh on them,
# then write approach files with write-approach-file.sh, and check the files,
# output and exit codes.
# Prints one line per test and a final count; exits 1 on any failure.
#
# Usage: test-approach-scripts.sh
set -uo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
check=$here/check-approach-file.sh
write=$here/write-approach-file.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pass=0 fail=0

# run CMD...: keep stdout in $out, stderr in $err and the exit code in $code.
run() {
  out=$("$@" 2>"$tmp/stderr" </dev/null)
  code=$?
  err=$(<"$tmp/stderr")
}

# feed INPUT CMD...: run with INPUT on stdin.
feed() {
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

# lacks NAME TEXT: the last run's output does not hold TEXT.
lacks() {
  local msg=
  [[ $out$'\n'$err != *"$2"* ]] || msg="unexpected: $2"
  result "$1" "$msg"
}

# same NAME CODE STDOUT: the last run exited CODE and printed exactly STDOUT
# and nothing on stderr.
same() {
  local msg=
  [[ $code == "$2" ]] || msg="exit $code, want $2"
  [[ $out == "$3" ]] || msg+="${msg:+; }stdout differs"
  [[ -z $err ]] || msg+="${msg:+; }stderr not empty"
  result "$1" "$msg"
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
mkdir -p "$tree/efforts" "$tree/approaches"

cat > "$tree/efforts/meeting-date-agreed-effort.md" <<'EOF'
---
name: meeting-date-agreed
kind: achieve
intent: Have a meeting date every member accepts, so that the group meets.
---

# Meeting date agreed

## End state

A date is fixed and every member knows it.

## Definition of done

- date-accepted-by-all  Done when: every member accepted the date.
- date-fixed-before-deadline  Done when: the date is fixed before the deadline.

## Serves

Root effort: it serves no other effort.

## Limits

- [maintain] members-free-to-decline : Keep members free to decline, so that nobody attends under pressure. # guessed
EOF

cat > "$tree/efforts/group-keeps-meeting-effort.md" <<'EOF'
---
name: group-keeps-meeting
kind: maintain
intent: Keep the group meeting every month, so that members stay in touch.
---

# Group keeps meeting

## End state

The group meets every month.

## Definition of done

- members-attend  Held when: every member attends each meeting.

## Serves

Root effort: it serves no other effort.

## Limits

- [maintain] same-weekday-each-time : Keep meetings on the same weekday, so that members can plan around them. # guessed
EOF

cat > "$tree/efforts/room-booked-effort.md" <<'EOF'
---
name: room-booked
kind: achieve
intent: Have a room held for the meeting, so that the group has a place to meet.
---

# Room booked

## End state

A room is held for the date.

## Definition of done

- room-held  Done when: a room is held for the date.

## Serves

Root effort: it serves no other effort.
EOF

valid_text=$(cat <<'EOF'
---
name: poll-on-three-dates
contributes-to:
  - meeting-date-agreed
  - group-keeps-meeting
---

Poll every member on three proposed dates and fix the one all can attend.

## Steps

1. Propose three dates to every member.
2. In any order:
   - Collect answers for three days. (answers-collected)
   - Hold a room for each date.
3. Fix the date all can attend and announce it.

## Assumptions

- every-member-answers : Every member will answer within three days. Breaks when: fewer than half have answered after two days.
- one-date-suits-all : One of the three dates will suit everyone.

## Covers

### meeting-date-agreed

- date-accepted-by-all
- date-fixed-before-deadline

### group-keeps-meeting

- members-attend : Only a date all can attend is fixed.

## Risks

### meeting-date-agreed

- members-free-to-decline
- date-fixed-before-deadline
EOF
)
valid=$tree/approaches/poll-on-three-dates-approach.md
echo "$valid_text" > "$valid"

# variant CASE SED [NAME]: a copy of the valid file edited by SED, alone in
# its own folder, named NAME (the valid file's name by default). Sets $v.
variant() {
  mkdir -p "$tmp/cases/$1"
  v=$tmp/cases/$1/${3:-${valid##*/}}
  sed -e "$2" "$valid" > "$v"
}
lint() { run "$check" --root "$tree" "$@"; }

# --- check-approach-file.sh: valid files ---------------------------------

lint "$valid"
same "check: valid file with steps, assumptions and risks" 0 ""

variant minimal '/^## Steps/,/^3\./d; /^## Risks/,$d'
lint "$v"
same "check: steps and risks are optional" 0 ""

variant bullets-only 's/^[0-9]\. /- /'
lint "$v"
same "check: a bullet list of steps in any order" 0 ""

variant capital-may 's/^- one-date-suits-all : .*/- one-date-suits-all : May is one of the three dates./'
lint "$v"
same "check: a capitalised May is not a hedge" 0 ""

variant risk-explained 's/^- members-free-to-decline$/- members-free-to-decline : Members are pressed to answer a poll they did not ask for./'
lint "$v"
same "check: a risk with how the way risks it" 0 ""

variant risks-only '/^## Assumptions/,/^- one-date/d'
lint "$v"
same "check: risks without assumptions" 0 ""

variant risk-limit-other '$a\\n### group-keeps-meeting\n\n- same-weekday-each-time : Polling picks whichever date suits all, so meetings drift across weekdays.'
lint "$v"
same "check: a limit risked under a second effort" 0 ""

# --- frontmatter ----------------------------------------------------------

variant no-frontmatter '1d'
lint "$v"
has "check: no frontmatter" 1 "$v:1: no frontmatter between --- lines"

variant bad-file-name '' poll-on-three-dates.md
lint "$v"
has "check: file name without -approach.md" 1 "$v: file name does not end in -approach.md"

variant name-missing '/^name:/d'
lint "$v"
has "check: missing name" 1 "$v: frontmatter has no name"

variant name-case 's/^name: .*/name: Poll_On_Dates/'
lint "$v"
has "check: name not kebab-case" 1 "$v:2: name Poll_On_Dates is not kebab-case"

variant name-stem 's/^name: .*/name: poll-on-two-dates/'
lint "$v"
has "check: name differs from the file name" 1 "$v:2: name poll-on-two-dates does not match the file name poll-on-three-dates-approach.md"

variant name-in-efforts 's/^  - group-keeps-meeting/  - poll-on-three-dates/'
lint "$v"
has "check: name listed in contributes-to" 1 "$v:2: name poll-on-three-dates is also in contributes-to"

variant name-is-effort 's/^name: .*/name: room-booked/' room-booked-approach.md
lint "$v"
has "check: name already an effort's slug" 1 "$v:2: name room-booked is already an effort's slug: $tree/efforts/room-booked-effort.md"

variant status-key 's/^name: \(.*\)/name: \1\nstatus: chosen/'
lint "$v"
has "check: a status key" 1 "$v:3: frontmatter key status: an approach holds only name and contributes-to"

variant inline-list 's/^contributes-to:$/contributes-to: [meeting-date-agreed]/'
lint "$v"
has "check: contributes-to inline" 1 "$v:3: contributes-to must be a list"

variant entry-case 's/^  - group-keeps-meeting/  - Group_Meeting/'
lint "$v"
has "check: contributes-to entry not kebab-case" 1 "$v:5: contributes-to entry Group_Meeting is not a kebab-case effort slug"

variant entry-twice 's/^  - group-keeps-meeting/  - meeting-date-agreed/'
lint "$v"
has "check: contributes-to entry twice" 1 "$v:5: effort meeting-date-agreed appears twice in contributes-to"

variant ct-empty '/^  - /d'
lint "$v"
has "check: contributes-to empty" 1 "$v:3: contributes-to lists no effort"

variant ct-missing '/^contributes-to:/,/^  - group/d'
lint "$v"
has "check: no contributes-to" 1 "$v: frontmatter has no contributes-to"

variant stray-line 's/^name: \(.*\)/name: \1\njust words/'
lint "$v"
has "check: stray frontmatter line" 1 "$v:3: frontmatter line is not"

# --- lead line ------------------------------------------------------------

variant no-lead '/^Poll every member/d'
lint "$v"
has "check: no lead line" 1 "$v: no lead line between the frontmatter and the first section"

variant lead-two-lines 's/^Poll every member.*/Poll every member on three dates\nand fix one./'
lint "$v"
has "check: lead line over two lines" 1 "$v:8: lead line runs over several lines"

variant lead-period 's/all can attend\.$/all can attend/'
lint "$v"
has "check: lead line without a period" 1 "$v:8: lead line does not end with a period"

for w in because "so that" since "in order to"; do
  variant "reason-${w// /-}" "s/ and fix the one all can attend\./ $w the group wants it./"
  lint "$v"
  has "check: lead line holding '$w'" 1 "$v:8: lead line holds '$w': the reason goes in the logbook"
done

variant lead-heading 's/^Poll every member.*/# Poll on three dates/'
lint "$v"
has "check: lead line is a heading" 1 "$v:8: lead line is a heading"

variant state-verb 's/^Poll every member on/Reach every member with/'
lint "$v"
has "check: state verb is a warning" 0 "$v:8: warning: lead line opens with Reach, a state verb of as-effort"

# --- sections -------------------------------------------------------------

variant unknown-section 's/^## Risks/## Costs/'
lint "$v"
has "check: unknown section" 1 "unknown section ## Costs"

variant twice-section 's/^## Risks/## Steps/'
lint "$v"
has "check: section twice" 1 "section ## Steps appears twice"

variant order-section 's/^## Steps/## Placeholder/; s/^## Assumptions/## Steps/; s/^## Placeholder/## Assumptions/'
lint "$v"
has "check: sections out of order" 1 "section ## Steps is out of order: it goes before ## Assumptions"

variant empty-section '/^1\. Propose/,/^3\. Fix/d'
lint "$v"
has "check: empty section" 1 "$v:10: section ## Steps is empty: leave it out"

# --- steps ----------------------------------------------------------------

variant step-prose 's/^1\. Propose three dates to every member\./First, propose three dates./'
lint "$v"
has "check: prose in Steps" 1 "$v:12: Steps holds only list items"

variant step-mixed 's/^2\. In any order:/- In any order:/'
lint "$v"
has "check: numbered and bullet items in one list" 1 "$v:13: step mixes numbered and bullet items in one list"

variant step-skip 's/^3\. Fix/4. Fix/'
lint "$v"
has "check: numbering skips" 1 "$v:16: step 4. follows step 2."

variant step-start 's/^   - Collect/   2. Collect/; s/^   - Hold/   3. Hold/'
lint "$v"
has "check: nested numbered list not from 1" 1 "$v:14: numbered list starts at 2."

variant step-indented 's/^1\. Propose/  1. Propose/'
lint "$v"
has "check: first step indented" 1 "$v:12: first step is indented"

variant step-between 's/^3\. Fix/      - Deeper.\n  - Fix/'
lint "$v"
has "check: step indented between levels" 1 "$v:17: step is indented between two levels"

variant step-marker 's/(answers-collected)/(three days at most)/'
lint "$v"
has "check: step ending with a parenthetical" 1 "$v:14: step ends with (three days at most): only (<effort-slug>, ...) goes there"

variant step-only-marker 's/^   - Collect answers for three days\. (answers-collected)/   - (answers-collected)/'
lint "$v"
has "check: step that is only a marker" 1 "$v:14: step is only (answers-collected)"

variant step-own-effort 's/(answers-collected)/(group-keeps-meeting)/'
lint "$v"
has "check: step marker naming an effort in contributes-to" 1 "$v:14: step ends with (group-keeps-meeting): group-keeps-meeting is an effort in contributes-to"

variant step-two-markers 's/(answers-collected)/(answers-collected, room-held)/'
lint "$v"
has "check: step naming two child efforts passes" 0 ""

variant step-two-markers-own 's/(answers-collected)/(answers-collected, group-keeps-meeting)/'
lint "$v"
has "check: second step marker naming an effort in contributes-to" 1 "$v:14: step ends with (answers-collected, group-keeps-meeting): group-keeps-meeting is an effort"

variant step-bad-list 's/(answers-collected)/(answers-collected,room-held)/'
lint "$v"
has "check: step marker list without a space" 1 "$v:14: step ends with (answers-collected,room-held): only"

# --- assumptions ----------------------------------------------------------

variant assumption-shape 's/^- one-date-suits-all : /- one-date-suits-all: /'
lint "$v"
has "check: assumption line shape" 1 "$v:21: assumption is not - <slug> : <what will or will not be true>."

variant assumption-slug 's/^- one-date-suits-all : /- One_Date : /'
lint "$v"
has "check: assumption slug not kebab-case" 1 "$v:21: assumption slug One_Date is not kebab-case"

variant assumption-twice 's/^- one-date-suits-all : /- every-member-answers : /'
lint "$v"
has "check: assumption slug twice" 1 "$v:21: assumption every-member-answers appears twice: first at line 20"

variant breaks-twice 's/after two days\.$/after two days. Breaks when: nobody answers./'
lint "$v"
has "check: Breaks when twice" 1 "$v:20: assumption every-member-answers has more than one 'Breaks when:'"

variant breaks-shape 's/three days\. Breaks when:/three days, Breaks when:/'
lint "$v"
has "check: Breaks when not after a sentence" 1 "$v:20: assumption every-member-answers is not '<statement>. Breaks when: <signal>.'"

variant breaks-empty 's/ Breaks when: .*/ Breaks when: ./'
lint "$v"
has "check: Breaks when without a signal" 1 "$v:20: assumption every-member-answers is not '<statement>. Breaks when: <signal>.'"

variant assumption-period 's/will suit everyone\./will suit everyone/'
lint "$v"
has "check: assumption without a period" 1 "$v:21: assumption one-date-suits-all does not end with a period"

for w in should may might could probably; do
  variant "hedge-$w" "s/One of the three dates will suit/One of the three dates $w suit/"
  lint "$v"
  has "check: assumption holding '$w'" 1 "$v:21: assumption one-date-suits-all holds '$w'"
done

# --- covers ---------------------------------------------------------------

variant covers-none '/^## Covers/,/^- members-attend/d'
lint "$v"
has "check: no Covers section" 1 "$v:4: effort meeting-date-agreed has no ### meeting-date-agreed in Covers" \
  "$v:5: effort group-keeps-meeting has no ### group-keeps-meeting in Covers: name the criteria the way covers there"

variant covers-missing-head '29,32d'
lint "$v"
has "check: effort without its Covers heading" 1 "$v:5: effort group-keeps-meeting has no ### group-keeps-meeting in Covers"

variant covers-empty-head '32d'
lint "$v"
has "check: Covers heading with no entry" 1 "$v:30: ### group-keeps-meeting lists no covered criterion"

variant covers-head-unknown '30s/group-keeps-meeting/room-booked/'
lint "$v"
has "check: Covers heading not in contributes-to" 1 "$v:30: ### room-booked in Covers is not in contributes-to"

variant covers-head-twice '30s/group-keeps-meeting/meeting-date-agreed/'
lint "$v"
has "check: Covers heading twice" 1 "$v:30: ### meeting-date-agreed appears twice in Covers"

variant covers-before-head '25d'
lint "$v"
has "check: covered criterion before any heading" 1 "$v:26: covered criterion before any ### <effort> heading"

variant covers-shape '27s/^- date-accepted-by-all/- date accepted by all/'
lint "$v"
has "check: covered line shape" 1 "$v:27: covered criterion is not - <criterion name> [: <how the way covers it>.]"

variant covers-explain-period '27s/$/ : Every member answers/'
lint "$v"
has "check: covered explanation without a period" 1 "$v:27: covered criterion is not"

variant covers-limit '27s/date-accepted-by-all/members-free-to-decline/'
lint "$v"
has "check: a limit is not covered" 1 "$v:27: covered members-free-to-decline is not a Definition of done entry name of $tree/efforts/meeting-date-agreed-effort.md"

variant covers-unknown '32s/members-attend/members-travel/'
lint "$v"
has "check: covered name not a criterion" 1 "$v:32: covered members-travel is not a Definition of done entry name of $tree/efforts/group-keeps-meeting-effort.md"

variant covers-twice '28s/date-fixed-before-deadline/date-accepted-by-all/'
lint "$v"
has "check: covered criterion twice" 1 "$v:28: criterion date-accepted-by-all appears twice under ### meeting-date-agreed in Covers"

variant covers-after-risks '/^## Covers/,/^- members-attend/d; $a\\n## Covers\n\n### meeting-date-agreed\n\n- date-fixed-before-deadline\n\n### group-keeps-meeting\n\n- members-attend'
lint "$v"
has "check: Covers after Risks" 1 "section ## Covers is out of order: it goes before ## Risks"

# --- risks ----------------------------------------------------------------

variant risk-head '36s/meeting-date-agreed/room-booked/'
lint "$v"
has "check: risk heading not in contributes-to" 1 "$v:36: ### room-booked in Risks is not in contributes-to"

variant risk-head-twice '39s/^- date-fixed-before-deadline/\n### meeting-date-agreed\n\n- date-fixed-before-deadline/'
lint "$v"
has "check: risk heading twice" 1 "### meeting-date-agreed appears twice in Risks"

variant risk-before-head '36d'
lint "$v"
has "check: risk before any heading" 1 "$v:37: risk before any ### <effort> heading"

variant risk-shape 's/^- members-free-to-decline/- members free to decline/'
lint "$v"
has "check: risk line shape" 1 "$v:38: risk is not - <criterion name or limit slug>"

variant risk-explain-period 's/^- members-free-to-decline$/- members-free-to-decline : Members are pressed to answer/'
lint "$v"
has "check: risk explanation without a period" 1 "$v:38: risk is not - <criterion name or limit slug> [: <how the way risks it>.]"

variant risk-explain-empty 's/^- members-free-to-decline$/- members-free-to-decline : ./'
lint "$v"
has "check: risk explanation empty" 1 "$v:38: risk is not"

variant risk-explain-unknown '39s/^- date-fixed-before-deadline$/- date-in-spring : The poll takes a week./'
lint "$v"
has "check: explained risk still checked against the effort" 1 "$v:39: risk date-in-spring is not a criterion name or limit slug"

variant risk-twice '39s/^- date-fixed-before-deadline/- members-free-to-decline/'
lint "$v"
has "check: risk twice" 1 "$v:39: risk members-free-to-decline appears twice under ### meeting-date-agreed"

variant risk-empty-head '38,39d'
lint "$v"
has "check: risk heading with no entry" 1 "$v:36: ### meeting-date-agreed lists no risk: leave it out"

variant risk-empty-mid '36s/^### meeting-date-agreed/### group-keeps-meeting\n\n### meeting-date-agreed/'
lint "$v"
has "check: risk heading with no entry before another" 1 "$v:36: ### group-keeps-meeting lists no risk"

variant risk-unknown '39s/^- date-fixed-before-deadline/- date-in-spring/'
lint "$v"
has "check: risk not a criterion or limit" 1 "$v:39: risk date-in-spring is not a criterion name or limit slug of $tree/efforts/meeting-date-agreed-effort.md"

variant risk-uncovered '28d'
lint "$v"
has "check: risk on a criterion the way does not cover" 1 "$v:38: risk date-fixed-before-deadline is a criterion not under ### meeting-date-agreed in Covers: risk only criteria the way covers, or limits"

variant risk-no-file 's/group-keeps-meeting/group-grows/g'
lint "$v"
has "check: effort without a file is a warning" 0 "$v:30: warning: no group-grows-effort.md under $tree: its covered criteria and risks are not checked"

mkdir -p "$tree/copy"
cp "$tree/efforts/meeting-date-agreed-effort.md" "$tree/copy/"
lint "$valid"
has "check: effort carried by several files is a warning" 0 "warning: slug meeting-date-agreed is carried by several files"
rm -r "$tree/copy"

# --- warnings -------------------------------------------------------------

variant bare '/^## Assumptions/,/^- one-date/d; /^## Risks/,$d'
lint "$v"
has "check: neither assumptions nor risks is a warning" 0 "$v: warning: approach has neither assumptions nor risks"

# Deployed without an as-effort sibling, the state verbs go unchecked.
deployed=$tmp/deployed
mkdir -p "$deployed"
ln -s "${here%/*}" "$deployed/as-approach"
variant state-verb-deployed 's/^Poll every member on/Reach every member with/'
run "$deployed/as-approach/scripts/check-approach-file.sh" --root "$tree" "$v"
has "check: no as-effort sibling skips the state verbs" 0 "warning: $deployed/as-effort/SKILL.md not found: state verbs not checked"
lacks "check: no as-effort sibling gives no state verb warning" "a state verb of as-effort"
ln -s "${here%/*/*}/as-effort" "$deployed/as-effort"
run "$deployed/as-approach/scripts/check-approach-file.sh" --root "$tree" "$v"
has "check: as-effort sibling found through the deployed link" 0 "lead line opens with Reach"

# --- root -----------------------------------------------------------------

# Outside a git repository, the root defaults to the file's folder.
mkdir -p "$tmp/alone"
cp "$tree/efforts/meeting-date-agreed-effort.md" "$tmp/alone/"
sed 's/^- date-fixed-before-deadline/- date-in-spring/' "$valid" > "$tmp/alone/${valid##*/}"
run "$check" "$tmp/alone/${valid##*/}"
has "check: root defaults to the file's folder" 1 "risk date-in-spring is not a criterion name or limit slug of $tmp/alone/meeting-date-agreed-effort.md"

run "$check" --root "$tmp/nowhere" "$valid"
has "check: missing root is bad usage" 2 "no folder"

# --- usage ----------------------------------------------------------------

run "$check"
has "check: no file is bad usage" 2 "usage:"
run "$check" "$tmp/nowhere-approach.md"
has "check: unreadable file is bad usage" 2 "cannot read"
run "$check" "$valid" "$valid"
has "check: two files is bad usage" 2 "usage:"
run "$check" --strict "$valid"
has "check: unknown flag is bad usage" 2 "usage:"

# --- write-approach-file.sh -----------------------------------------------

input=$(cat <<'EOF'
name: poll-on-three-dates
effort: meeting-date-agreed
effort: group-keeps-meeting
way: Poll every member on three proposed dates and fix the one all can attend.
step: 1. Propose three dates to every member.
step: 2. In any order:
step:    - Collect answers for three days. (answers-collected)
step:    - Hold a room for each date.

step: 3. Fix the date all can attend and announce it.
assumption: every-member-answers : Every member will answer within three days. Breaks when: fewer than half have answered after two days.
assumption: one-date-suits-all : One of the three dates will suit everyone.
cover: meeting-date-agreed date-accepted-by-all
cover: group-keeps-meeting members-attend : Only a date all can attend is fixed.
cover: meeting-date-agreed date-fixed-before-deadline
risk: meeting-date-agreed members-free-to-decline
risk: meeting-date-agreed date-fixed-before-deadline
EOF
)
out_dir=$tree/written
mkdir -p "$out_dir"
target=$out_dir/poll-on-three-dates-approach.md

feed "$input" "$write" --root "$tree" "$out_dir"
has "write: valid input" 0 "wrote $target"
file_is "write: lays the file out as the checker expects" "$target" "$valid_text"

feed "$input" "$write" --root "$tree" "$out_dir"
has "write: an existing file is not replaced" 3 "$target exists; --replace replaces it"
file_is "write: the existing file is left as it was" "$target" "$valid_text"

feed "${input/three proposed dates/two proposed dates}" "$write" --replace --root "$tree" "$out_dir"
has "write: --replace replaces it" 0 "wrote $target"
file_is "write: the replaced file holds the new content" "$target" "${valid_text/three proposed dates/two proposed dates}"

feed "${input/risk: meeting-date-agreed date-fixed-before-deadline/risk: meeting-date-agreed date-in-spring}" "$write" --replace --root "$tree" "$out_dir"
has "write: problems block the write" 1 "$target:39: risk date-in-spring is not a criterion name or limit slug" \
  "    | - date-in-spring" "nothing written: fix the input and run the same command again"
file_is "write: a failed write leaves the file" "$target" "${valid_text/three proposed dates/two proposed dates}"

mkdir -p "$out_dir/other"
feed "${input/risk: meeting-date-agreed members/risk: room-booked members}" "$write" --root "$tree" "$out_dir/other"
has "write: a risk for an effort not in contributes-to is reported" 1 "### room-booked in Risks is not in contributes-to"

minimal=$'name: ask-each-member\neffort: meeting-date-agreed\nway: Ask each member for a date in turn and fix the first that all accept.\nassumption: members-reply : Every member will reply within a day.\ncover: meeting-date-agreed date-accepted-by-all'
mkdir -p "$tmp/cwd"
out=$(cd "$tmp/cwd" && "$write" --root "$tree" <<< "$minimal" 2>"$tmp/stderr")
code=$? err=$(<"$tmp/stderr")
has "write: writes in the working directory by default" 0 "wrote ask-each-member-approach.md"
file_is "write: minimal file" "$tmp/cwd/ask-each-member-approach.md" "---
name: ask-each-member
contributes-to:
  - meeting-date-agreed
---

Ask each member for a date in turn and fix the first that all accept.

## Assumptions

- members-reply : Every member will reply within a day.

## Covers

### meeting-date-agreed

- date-accepted-by-all"

# Outside a git repository, the root defaults to DIR.
mkdir -p "$out_dir/explained"
feed "${input/risk: meeting-date-agreed members-free-to-decline/risk: meeting-date-agreed members-free-to-decline : Members are pressed to answer a poll.}" "$write" --root "$tree" "$out_dir/explained"
has "write: a risk with how the way risks it" 0 "wrote $out_dir/explained/poll-on-three-dates-approach.md"
file_is "write: the explanation follows the risk name" "$out_dir/explained/poll-on-three-dates-approach.md" \
  "${valid_text/- members-free-to-decline/- members-free-to-decline : Members are pressed to answer a poll.}"

mkdir -p "$tmp/alone-write"
cp "$tree/efforts/meeting-date-agreed-effort.md" "$tmp/alone-write/"
feed "${input/risk: meeting-date-agreed date-fixed-before-deadline/risk: meeting-date-agreed date-in-spring}" "$write" "$tmp/alone-write"
has "write: root defaults to DIR" 1 "risk date-in-spring is not a criterion name or limit slug of $tmp/alone-write/meeting-date-agreed-effort.md"

feed "$input"$'\nstatus: chosen' "$write" "$tmp/cwd"
has "write: unknown key" 2 "unknown key status"
feed "$input"$'\njust words' "$write" "$tmp/cwd"
has "write: line without a key" 2 "not a 'key: value' line: just words"
feed "${input/name: poll-on-three-dates/}" "$write" "$tmp/cwd"
has "write: no name" 2 "needs a name: line"
feed "${input/way: /step: - }" "$write" "$tmp/cwd"
has "write: no way" 2 "needs a way: line"
feed "$input"$'\nname: other' "$write" "$tmp/cwd"
has "write: name twice" 2 "name given twice"
feed "$input"$'\nrisk: meeting-date-agreed' "$write" "$tmp/cwd"
has "write: risk without a name" 2 "risk needs an effort, then the name it risks"
feed "$input"$'\ncover: meeting-date-agreed' "$write" "$tmp/cwd"
has "write: cover without a name" 2 "cover needs an effort, then the criterion it covers"
feed "$input" "$write" "$tmp/nowhere"
has "write: missing folder" 2 "no folder"
feed "$input" "$write" "$tmp/cwd" "$tmp/cwd"
has "write: two folders is bad usage" 2 "usage:"
feed "$input" "$write" --force "$tmp/cwd"
has "write: unknown flag is bad usage" 2 "usage:"
result "write: bad input writes nothing" "$( [[ -e $tmp/cwd/poll-on-three-dates-approach.md ]] && echo 'file written' )"

echo "$pass passed, $fail failed"
(( fail == 0 ))
