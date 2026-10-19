---
name: propose-effort-approach
description: Propose ways to reach an effort, or a reconsideration of its chosen way, as approach files, candidate lines and options on a logbook question, and hand the choice to a separate agent when the work needs it to go on. Use when an effort has no approach yet, when someone wants approaches, options or alternatives for reaching an effort, or floats a way to reach it, in a brainstorm or as a passing idea, and whenever work toward it turns up a reason to rethink its way: an assumption found false, a criterion or limit seen failing, a missing step, a criterion no chosen approach covers, a changed definition of done, or a better way, another effort's included.
---

# Propose effort approach

An effort file's `## Approaches` section lists its ways as `- [<status>] <approach-slug> (logbook: <node>)`, each approach written in its own `<slug>-approach.md`. This skill proposes ways and never chooses: a proposer judging its own ways shares their blind spots, so a separate agent with fresh context decides. A proposal may be a single way, from a brainstorm or a passing idea: it stays a candidate until a decision is needed.

Anyone working toward the effort, agent or person, may propose. A reconsideration names one ground:

1. An assumption of a chosen approach is found false, or its `Breaks when` signal is seen.
2. A criterion or limit a chosen approach risks, or claims to meet, is seen failing. A claimed one failing reveals an unwritten assumption, to add by amendment.
3. The reason a dropped or candidate approach lost no longer holds.
4. The effort's intent, Criteria or Limits changed.
5. A new way covers a criterion the chosen approaches risk.
6. The work turns up a step the end state needs that the chosen approaches lack, or a criterion none of them covers.

## Steps

1. **Open the logbook.** Call the Skill tool with "logbook". The logbook is the effort's own, `<effort-slug>.logbook` next to the effort file; create it when none exists. `status` shows its open questions: when one asks what yours would, put your options under it. Otherwise record the question at the top level (`0`): `How do we reach <effort-slug>?` when nothing is chosen or the ground is a criterion no chosen approach covers, else `Reconsider <chosen-slug>: <ground>`, saying what showed it.

2. **Look for ways.** Read the effort file, its approach files and the nodes its lines cite, among them why earlier options lost, then call the Skill tool with "effort-approach-graph": a `<approach> reaches <effort-slug> [proposed]` edge is an approach naming this effort that it has not considered yet; put it on the question. Other efforts' approaches may reach this one too: one way serving two is work done once. Ground every way, given or your own, in what the project already holds. Log what you read and find under the question as you go, dead ends included. Judging whether a way works, what it takes and what it costs, is the decider's work: leave it to them.

3. **Phrase the approaches.** Call the Skill tool with "as-approach", its arguments left empty, and apply its steps yourself to each new way, without writing a file yet, however plain the way looks: its steps give the lead line, covers and risks the decider weighs. A skill called with a request answers it and ends the run there. A reconsideration puts each live approach, chosen or candidate, on the question beside any new one; any other proposal may be one way. The ways you propose differ in how they work, not only in wording: as-approach formalizes the way you give it and will not tell them apart. Each may cover only part of the effort's criteria; when the ways on the question leave a criterion uncovered, `note` it under the question. An approach already written keeps its file; phrase only what changes:
   - **Reuse.** Another effort's approach gets this effort in its `contributes-to`, with a `### <effort-slug>` heading under Covers for what it covers here, and one under Risks for what it risks here.
   - **Amendment.** The ground changes a live approach's steps, assumptions or risks.

   A changed lead line is a new approach with a new slug. An approach chosen by any effort changes only through a decision that names the change, so an amendment waits for one. A reuse does not: it changes nothing for the efforts already served.

4. **Record the options.** One `option` call, each `<slug>: <lead line>`. Keep the path printed for each. Under each, `note` one fact at a time: its file's path, then what you found that bears on it. The verdict is the decider's. A change waiting for a decision gets a note giving it line by line, for the decider to apply.

5. **Write the approach files.** For each new approach, each reuse, and each amendment of an approach no effort has chosen, follow `references/approach-file.md` in as-approach's folder.

6. **Write the lines.** Each approach new to the section gets `[candidate] <slug> (logbook: <its option's path>)`. The script rewrites the whole section, so pass every current line back unchanged, with the new ones added:

   ```
   <as-effort>/scripts/write-effort-file.sh --approaches <effort file> <<'EOF'
   approach: [chosen] <slug> (logbook: <node>)
   approach: [candidate] <new-slug> (logbook: <option path>)
   EOF
   ```

   `<as-effort>` is that skill's folder, next to this one. On failure nothing is written; fix and rerun. Existing lines keep their status and node until the decision.

7. **Start a fresh agent, when the work needs the decision.** Only when your work toward the effort cannot go on without it: nothing is chosen for the work you are doing, or the ground blocks the chosen way. Otherwise go to step 9: the open question and its candidates are the proposal, for whoever needs the decision. Use the Agent tool, not a fork, with a different model when one can be chosen. Its whole prompt:

   `Use the decide-effort-approach skill. Effort file: <path>. Logbook: <path>, question <node>.`

   Leave out your reasoning; the decider reads the logbook. When you cannot start one, go to step 9: the open question is the proposal.

8. **Take the brief.** The decider answers with an outcome and the logbook subtree where it worked the decision out. When the outcome changes your own work, record a `decide` in your own logbook pointing to that subtree. When your logbook is the effort's, it is already recorded.
   - `chosen`, `kept` or `switched`: work toward the effort by the chosen approaches, as their files now read. Criteria the brief lists as `uncovered` remain a gap of the effort, a ground for a new proposal.
   - `needs a person: ...`: tell the person you work for, if any; otherwise the question stays open.

9. **Reply**, as the Output section says.

## Output

Once the options are recorded, and decided when the work needed it, decide whether anything goes back and in what form. When another skill's steps called this one, the mode is `carried`, whatever the call asks for, since its wording is the caller's and the result is theirs to use. Otherwise match the request against each mode below, read the reference of the one it fits, and follow it. Pick by what the request is for, not by what is quickest to give. The shape of the reply is in the reference and nowhere else, so read it before writing any reply, even a short answer to a person.

| mode | when | reference |
|---|---|---|
| options | a person floats a way, asks for ways or options, or asks to get one chosen | `references/options.md` |
| fields | the request names fields or a format (YAML, JSON, CSV, a table) | `references/fields.md` |
| carried | another skill's steps called this one | `references/carried.md` |

## Example

Nothing is chosen for `meeting-date-agreed`. The option call prints 1.2 and 1.3:

```
1     ?? How do we reach meeting-date-agreed?
1.2     ? poll-on-three-dates: Poll every member on three proposed dates and fix the one all can attend.
1.3     ? organizer-fixes-then-hears-objections: Let the organizer fix one date and move it once if a member objects within a week.
```

Both enter the section as `[candidate]` lines ending `(logbook: 1.2)` and `(logbook: 1.3)`. Proposed in a brainstorm, they stop there; proposed by an agent about to set the meeting, they go to a decider. Had another effort chosen `poll-on-three-dates` already, its file would wait, and option 1.2 would carry a note adding `meeting-date-agreed` to its `contributes-to`.
