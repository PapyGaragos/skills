---
name: advance-effort
description: Make progress on an effort by doing the work it needs, one run at a time. Reads where the effort stands from its file, its logbook and the project, picks the one action that moves it most (clarify, investigate, verify, act, descend into a child effort, refine, or propose another way), does it, checks the criteria it targeted, records the result, and stops once the next action is no longer already decided, so the next run judges afresh. Use when the user asks to work on, advance, push forward, continue or make progress on an effort or goal, asks what to do next for it, resumes an effort after a break, or hands over an effort to contribute to, and whenever another skill or agent is started to contribute to an effort.
---

# Advance effort

An effort is a state someone wants, with criteria that say when it is reached. Advancing it means doing work that meets more of its criteria, not adding to its graph. So this skill spends as little on the graph as the next action allows: a small effort with a clear next action goes straight to work, and the graph is read only when the effort is too big to act on directly.

A run makes one choice and carries it out. It goes on while the next todo was already decided and nothing gave a reason to expect it to fail, and stops when a new choice is needed, so that choice gets a fresh look instead of drifting from the last one.

## Steps

1. **Open the effort.** Find `<slug>-effort.md` with `find . -name '<slug>-effort.md'`. When there is none, call the Skill tool with "as-effort", its arguments left empty, and apply its steps yourself for the effort file, then go on to step 2 once it is written: the criteria are what the work gets judged against, and criteria made up after the work would judge it by what it happened to do. Then call the Skill tool with "logbook" and open `<slug>.logbook` next to the effort file, creating it when none exists.

2. **Read where it stands.** From the effort file: the criteria, the limits, and every `(guessed)` or `# guessed` mark. From the logbook: `status`, and the criteria checks, the notes reading `checked <date>: <criterion> ...`. A criterion is met when a check says so and nothing since gives a reason to doubt it. Nothing else counts as progress: a busy logbook, files written or steps done say what happened, not what holds.

   When every criterion is met, the effort is reached: an `achieve` is done, a `maintain` is held as of the latest checks, an `optimize` has moved as far as the checks show. Go to step 7.

3. **Pick the next action** in two passes. First, setting aside what is unknown, pick among act, descend and propose: act only when one action within this run meets an unmet criterion or moves a metric by itself, so a step of an approach that meets no criterion alone means descend, however plain it looks. Then take the first item below that applies: clarify and investigate serve only the action the first pass picked, and what a child will need to know is the child's to find out.

   1. **Clarify.** A guess or an ambiguity the next action depends on. A guess on something the action does not touch can wait, so a guessed purpose blocks nothing until two ways of working differ on it. Load the find-out skill with the Skill tool, leaving its arguments empty, and apply its steps yourself to it. A skill called with a request answers it and ends the run there.
   2. **Investigate.** Something the next action depends on is unknown. Apply find-out to it the same way. Refining does not wait on how the work will be done: children name states, and how to reach them is theirs to find out.
   3. **Verify.** A criterion's state is unknown, or its last check is old enough to doubt. Run the check its condition implies. When no check exists and building one is real work, that check is a child effort: read `references/descend.md`.
   4. **Act.** You can name a concrete action that meets an unmet criterion, or moves a metric, within this run. Do it.
   5. **Descend.** No such action can be named, because the effort is too big or its unmet criteria fall to child efforts, or to steps of a chosen approach not yet filed as children. Read `references/descend.md`: it picks the descendant to advance, or refines the effort when none fits.
   6. **Propose.** The work shows a ground to reconsider how the effort is reached, from propose-effort-approach's list: an assumption found false, a criterion seen failing, a missing step. Call the Skill tool with "propose-effort-approach".

   Earlier decisions stand. Reopen one only on a ground you saw and logged, and refine only when no concrete action can be named: second-guessing a choice costs a run, and refining for its own sake grows the graph instead of the work.

   Add a goal to the logbook naming the action: a logbook goal is one run, never the effort itself.

4. **Do it.** Work in the project. When the action splits into plain parts with no reason to expect any of them to fail, write them as todos under the goal with the logbook's `plan`; anything less certain stays unwritten until you get there. Mark a todo done only once it is: a todo marked done that nobody did tells the next run the work happened. Stay within the effort's limits and those of its parents: an action that could break one is a question for a person, not a try. Commit as the project's conventions say, and note the commit's hash. Log as you go, as the logbook skill says.

5. **Check what it did.** After acting, check each criterion the action targeted and note `checked <date>: <criterion> met|unmet|unknown: <what you found>` under the goal, or for a `Metric`, `checked <date>: <criterion> <value>: <how it was measured>`. Judge against the criterion's condition, written before the work, not against whether the work looks finished. A `Held when` criterion met now is met as of today, and it says nothing about next month.

6. **Go on or stop.** Go on to the next open todo while nothing gives a reason to expect it to fail. A surprise you resolved, with its fix logged under it, changes nothing. Stop when:
   - a surprise gives a reason to expect the remaining todos won't complete
   - a question needs a person or a stronger model, as find-out returns it: log it as a `question` under the goal
   - the next todo belongs to another effort
   - the todos are done, since the next action is a new choice

7. **Reply.** Once the run stops for any of these reasons or because the effort is reached, read the reference of the Output section's mode that fits the request, and write the reply in its shape and nothing else.

## Output

Once the run stops, decide what goes back and in what form. Match the request against each mode below, read the reference of the one it fits, and follow it. Pick by what the request is for, not by what is quickest to give. The shape of the reply is in the reference and nowhere else, so read it before writing any reply, even a short answer to a person.

| mode | when | reference |
|---|---|---|
| report | a person or an agent asks to work on, advance or continue the effort, or what to do next for it | `references/report.md` |
| fields | the request names fields or a format (YAML, JSON, CSV, a table) | `references/fields.md` |
