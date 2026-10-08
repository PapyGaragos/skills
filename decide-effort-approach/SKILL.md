---
name: decide-effort-approach
description: Decide an open approach question on an effort with fresh context: choose, keep or switch the approaches it takes, a set that together covers its criteria, only when the effort's criteria and purpose settle it, else leave it to a person; reports the criteria no chosen approach covers. Records it in the effort's logbook and file, settles the children a switch affects, and hands back a two-line brief. Use when you were started to decide an effort's approach, whenever propose-effort-approach hands over a question, and when someone asks which proposed way an effort should take.
---

# Decide effort approach

A proposer judging its own ways shares their blind spots, so you decide with fresh context. Your choice steers all work toward the effort, so make it only when the effort itself settles it; any other weighing is a person's.

An approach covers some of the effort's criteria, listed under its `## Covers` heading for the effort, so the effort may take several: you choose a set that together covers the criteria, picking among the ones that cover the same criterion. A criterion no chosen approach covers is a gap of the effort, not a reason to reject an approach.

## Input

The effort file, the effort's logbook, and the path of the question, `How do we reach <effort-slug>?` or `Reconsider <slug>: <ground>`. Its branch holds what the proposers found while looking for ways and one option per approach, `<slug>: <lead line>`, its notes giving its approach file and any change to it waiting for a decision.

## Brief

Your last message is the brief, read by the proposer mid-task: two lines, all else in the logbook. The first is one of:

- `chosen: <slug>, ...`
- `kept: <slug>, ...`
- `switched: <old-slug>, ... to <new-slug>, ...`
- `needs a person: <why, in a few words>`

When a criterion stays uncovered, the first line ends with `; uncovered: <criterion>, ...`, a ground for propose-effort-approach. The second is `logbook: <path> <node>`, the subtree where the decision was worked out, the same one the `decided by:` note names.

## Steps

1. **Read and investigate.** The whole effort file, its intent's purpose included, and each option's approach file. `show` the question's branch and the earlier options the section's lines cite: they show who chose the current approach and why the others lost. Proposers look for ways and leave judging them to you: check whether each option's assumptions hold and what it takes and costs, reading what the project holds and trying what is cheap. Call the Skill tool with "logbook" and log what you read, try and find as you go, dead ends included, under the option concerned, or under the question when it bears on several.

2. **Weigh.** For each option: the criteria it covers under its Covers heading for the effort, the covered criteria and limits it risks under its Risks heading, every covered one not risked claimed met, and whether its assumptions hold on the evidence. Then what it does for the other efforts its file reaches: what it risks under their headings counts against it as this effort's does, since the work done that way touches them too. Reaching them too settles nothing: no file says what that weighs. An option passing only with a smaller end state or fewer Definition of done entries does not pass: a reconsideration never shrinks the effort to fit a way. Changing the effort is its owner's call, through as-effort.

3. **Decide, or leave it open.** Options covering different criteria do not compete: each one that passes may be chosen. Among options covering the same criterion, the criteria and purpose settle the choice when one meets what each other one risks or fails, and none has the reverse edge elsewhere. Options trading criteria against each other need a weight the files do not give, and the order of the Definition of done gives none. A criterion no passing option covers stays a gap: note it under the question and report it in the brief. Switching away from a choice a person made needs a person too; the `decided by:` note under the chosen approach's option shows who made it, and with none, take it as a person's. In either case, note why under the question, leave the files alone and brief `needs a person`. A person may give you the choice; record it as theirs.

4. **Record.**
   - For each chosen option, `decide FILE <option> --why "<the criteria or purpose that settled it>"`, then `note FILE <option> "decided by: <agent | the person's name>, <logbook path> <node>"`. It points to where the decision was worked out: the question's node when you decided here, the subtree recording a person's decision otherwise. When the option carries a change to its approach file, the `--why` names the change.
   - `drop FILE <option> "<reason>"` for each option ruled out, the reason written as a condition that could turn false, so a reader sees when it stops: `while members keep no shared calendar`, not `too unreliable`.
   - Options neither chosen nor dropped stay candidates.

5. **Apply the change the decision names.** When the chosen option carries a change to its approach file, follow `references/approach-file.md` in as-approach's folder with it, giving that decision's logbook path and node. An approach file changes only this way; a status lives in the effort's section alone.

6. **Update the section.** Each line on the question takes its option's status, `[chosen]`, `[candidate]` or `[dropped]`, and its option's path. Dropped lines stay. Lines not on the question, and other efforts' sections, keep theirs. The script rewrites the whole section, so pass every line:

   ```
   <as-effort>/scripts/write-effort-file.sh --approaches <effort file> <<'EOF'
   approach: [chosen] <slug> (logbook: <option path>)
   approach: [chosen] <other-slug> (logbook: <option path>)
   approach: [dropped] <slug> (logbook: <option path>)
   EOF
   ```

   `<as-effort>` is that skill's folder, next to this one. On failure nothing is written.

7. **Settle the children, on a switch.** Call the Skill tool with "effort-approach-graph" and read the `children:` of each approach leaving `[chosen]`, the efforts whose `contributes-to:` names it. For each one naming it under this effort:
   - **Kept** when its work also serves a newly chosen approach: add that approach to the list, then run `<as-effort>/scripts/check-effort-file.sh` on it.
   - Otherwise leave it as it is, even when its list names only the old approach. Remove nothing: efforts, approaches and logbooks stay, above all once work was done, so a switch back finds what was already done and decided, and a postmortem can read it.

   Note each child's outcome under the question.

8. **Brief.**

## Example

For `meeting-date-agreed`, both options cover every criterion and risk none, and only `organizer-fixes-then-hears-objections` lists the limit `members-free-to-decline` under its `### meeting-date-agreed` heading. The limit settles it: decide `poll-on-three-dates`, `--why "keeps members-free-to-decline, which the other risks"`, and drop the other `"while it presses members to accept the fixed date"`. Had the poll risked `date-fixed-before-deadline`, the options would trade one for the other: `needs a person`. Had neither covered `date-fixed-before-deadline`, the brief would read `chosen: poll-on-three-dates; uncovered: date-fixed-before-deadline`.
