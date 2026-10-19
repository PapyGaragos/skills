---
name: refined-approach-efforts
description: Break an effort's chosen approaches down into child efforts, then judge whether they meet the effort's definition of done and which it needs. Use when the user asks to refine or break down an effort or its approach, what efforts or sub-efforts an approach needs, whether an effort's children are enough or redundant, or what is missing to finish it, and whenever another skill needs a chosen way turned into efforts.
---

# Refined approach efforts

Filed as a child effort, a step's lasting result gets its own definition of done, and work can name it as a reason. The children refine the effort, which fails in two ways (Darimont and van Lamsweerde, 1996): incomplete when, all reached, they leave a criterion unmet; not minimal when one could go and the rest would do as well.

## Steps

1. **Find the chosen approaches.** Read the effort file and the `[chosen]` lines of its `## Approaches` section. An effort may take several, each covering some of its criteria. When there is none, say `No chosen approach: run propose-effort-approach first.` and stop.

2. **Open the logbook.** Call the Skill tool with "logbook". Use the effort's own, `<effort-slug>.logbook` next to the effort file, created when none exists. Add a goal `Refine <effort-slug> along <approach-slug>, ...` and log under it what you read, try, find and decide as you go, steps left as steps included.

3. **Walk the steps** of each chosen approach. Read each `<approach-slug>-approach.md` and the effort's `[candidate]` approach files, and run `../effort-approach-graph/scripts/effort-approach-graph.sh` from this skill's directory (`--root DIR` when the efforts live outside the working directory). A step's result is worth tracking when someone could later find it true or false, other steps or the end state rely on it, and it could fail or be reached more than one way. A single action is not, nor is the effort's own end state. A step already ending with `(<slug>, ...)` is settled once those efforts exist. Place each state worth tracking with `../effort-approach-graph/references/place.md`, since as-effort writes only the parents it is given:
   - **Reuse** the duplicate it finds, the node that already names the state under any wording. When its `contributes-to:` does not cover this effort through that approach or `[]`, add the approach through as-effort's file reference.
   - **Otherwise file it.** Load the as-effort skill with the Skill tool, leaving its arguments empty, and apply its steps yourself to the state, for an effort file in the effort file's folder unless the caller names another, with `contributes-to: <effort>: [<approach>, ...]`, naming each chosen approach whose steps need that state, or `[]` when every live approach (chosen or candidate) needs that state, plus each other parent the placement found, as its edit names it, marked `# guessed` when the placement marked it so. A skill called with a request answers it and ends the run there.

   Apply the placement's other edits to files you wrote in this run. Beyond the reuse above, an edit to a file you did not write stays a proposal, since another owner may hold that effort: list it under `edits:` in what you produce.

4. **Name the efforts on the steps.** Each covered step ends with ` (<child-slug>)`, or ` (<child-slug>, <child-slug>)` when it yields several states worth tracking. Never split or reword a step to fit them. The references change no step's meaning, so decide it yourself: under the goal, for each approach whose steps gain one, record a question `Name the efforts covering <approach-slug>'s steps?` and `decide` it with the references added. Then follow as-approach's `references/approach-file.md`, with that node as the decision and the refine request as the agreement to replace: `../as-approach/scripts/write-approach-file.sh --replace <its folder>`, every other line passed back unchanged.

5. **Read the coverage.** Rerun the graph script. Its `coverage:` block for the effort lists the children serving each criterion, counting those serving `[]` or any chosen approach, and the effort's node line `not covered by a chosen approach:` names the criteria no chosen approach's Covers lists. With no block, the judgment is `No children: the effort is reached by its own work.`

6. **Judge each criterion.** Take as given that every child serving it reaches its end state and moves the criterion as its Serves entry says. Then ask whether someone looking would find the criterion's condition true. If so, it is `complete`. If not, it is `open`; name what would still be missing, in the criterion's own terms. The kind sets the bar:

   | condition | complete when the children together |
   |---|---|
   | `Done when` | make every condition true |
   | `Held when` | make it true and keep it true; a child that reaches it once leaves open what keeps it held |
   | `Metric` | move the value the better way; it has no target, so this is all it asks |

   A criterion no child serves is open on all it asks. Open is no fault when a step left as a step closes it; when none would, a step is missing, a ground for propose-effort-approach. A criterion no chosen approach covers is open too, a gap of the effort rather than of any approach, and a ground for propose-effort-approach as well. Leave the approaches' steps alone: changing a way is that workflow's to propose.

7. **Judge each child.** For each criterion a child serves, take the child away:
   - On a complete criterion, it is `needed` when the criterion would then be open, and `helps` when it would stay complete.
   - On an open criterion, it is `needed` when no other child moves what it moves, so a first step counts, and `helps` when another child already moves the same.

   A child listed under `names no criterion` is judged under the criterion it moves, and when it moves none, it goes under `outside the definition of done`. A child listed under `serves another approach` is left out. Log each verdict and its reason.

## Output

Once each child is judged, decide whether anything goes back and in what form. When another skill's steps called this one, the mode is `carried`, whatever the call asks for, since its wording is the caller's and the result is theirs to use. Otherwise match the request against each mode below, read the reference of the one it fits, and follow it. Pick by what the request is for, not by what is quickest to give. The shape of the reply is in the reference and nowhere else, so read it before writing any reply, even a short answer to a person.

| mode | when | reference |
|---|---|---|
| block | a person asks to refine or break down the effort, what children it needs, or whether they are enough | `references/block.md` |
| fields | the request names fields or a format (YAML, JSON, CSV, a table) | `references/fields.md` |
| carried | another skill's steps called this one | `references/carried.md` |

## Example

In `poll-on-three-dates`, "Collect answers for three days." yields a state the date relies on and that can stall: `answers-collected`, serving `meeting-date-agreed: [poll-on-three-dates]` since the candidate way collects none. "Propose three dates to every member." stays a step.

## When it doesn't fit

If the effort has no file, or its definition of done names no criteria (entries opening with a slug, as `- <slug>  Done when: ...`), say so in one line and stop.
