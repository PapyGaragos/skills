# Descend

The effort is too big to act on directly, so advancing it means advancing an effort below it, perhaps several levels down. Picking which is the judgment call of the run: the efforts form a graph, not a tree, so a descendant can serve several parents, and work on it can touch efforts outside the chain you came down.

## Read the graph

Run `scripts/effort-approach-graph.sh --root <the efforts' root>` from effort-approach-graph's folder, next to this skill's. For this effort it prints its chosen approaches, the criteria none of them covers, and under `coverage:` the children serving each criterion. Follow the children down, and their children, through the edges that serve a chosen approach or `[]`. A child listed under `serves another approach` is out of play until a decision brings that approach back.

## Pick the descendant

Take the one whose progress moves the most, weighing:

- **Unmet criteria moved.** How many unmet criteria it serves, here and on the way up. A child of a criterion already met moves nothing.
- **Shared.** A descendant serving several parents is work done once that counts in several places.
- **Unblocking.** Other efforts, or steps of a chosen approach, waiting on its result.
- **Ready.** No guess its next action depends on, and no question in its logbook waiting for a person.

A logbook showing work in progress is no signal: parallel contributors, runs stopped on a surprise and runs cut by a session limit all leave work in progress behind.

Before settling, read the limits of every effort between this one and the descendant, and of the descendant's other parents. Work that serves this chain while breaking a limit elsewhere is no progress.

Record the pick in this effort's logbook: a `question` asking which descendant to advance, an `option` per candidate weighed, and the `decide`. Then go back to step 1 of SKILL.md with the descendant. Its own logbook takes the work, and a `note` here points to it.

## Refine when nothing fits

When no descendant serves an unmet criterion and no concrete action can be named, the effort needs a child. Name the state that would make the next action plain. It is worth an effort file when someone could later find it true or false, other work relies on it, and it could fail or be reached more than one way. A plain action is not, so do it instead.

- **One plain way to reach it.** Place it with effort-approach-graph's `references/place.md`, so an existing node naming the same state gets reused. File it with as-effort, with `contributes-to: <this effort>: []`, plus each parent the placement found. An effort can serve another directly: an approach is only worth recording when there are real alternatives to choose from.
- **Several ways to reach it, really different ones.** That is a choice of approach: call the Skill tool with "propose-effort-approach".
- **The effort has chosen approaches whose steps hold the unmet criteria.** Call the Skill tool with "refined-approach-efforts", which turns those steps into children.

A check that a criterion needs and nobody has built is a child effort too: the state is that the check exists and runs.

Log the new children under the goal, then stop the run: the next run picks among them with fresh eyes.
