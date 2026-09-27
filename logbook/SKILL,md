---
name: logbook
description: Keep a running record of multi-step work - what was done, what came up, what was decided and why - so anyone can pick the work up later, and so choices can be audited with the context they were made in. Use for any effort that spans several steps or decisions (coding, debugging, research, migrations, planning, design, analysis), when resuming work that may have a .logbook, when a session may run out before the work is done, and when handing off to another agent or session. Start it without being asked; skip only trivial single-action tasks.
---

# Logbook

A logbook is a `.logbook` file recording an effort as it unfolds: the goals, the steps taken, what got in the way, the options weighed and the choice made, and why. It serves two readers:

- **Whoever picks the work up next.** A session hits its limit, the work changes hands, or context gets compacted. The logbook tells the next one what's done, what's in progress, what failed and what's left, so they continue instead of starting over.
- **Whoever audits the work later.** A commit history shows what changed. The logbook shows what was known and considered when each choice was made, including the paths that were dropped.

## When to write

Write right after something worth recording happens, while the reasons are still fresh:

- you take on a goal, or settle on the steps to reach it
- something turns out differently than expected
- something blocks you
- you pick between options, including the ones you didn't pick and why
- you finish a step, or give one up and know why

The logbook doesn't need to come before the work. It needs to exist before the reasons are forgotten. Entries written at the end of a long stretch keep the outcomes and lose the reasons, and the reasons are what the next reader lacks. When a session could end at any moment, ask yourself: if it stopped now, could someone else carry on from the logbook without redoing my work?

Failures and dead ends matter as much as successes. A logbook that only records what worked makes the next reader try the same dead ends again.

Write in fragments. Drop the grammar you don't need, but keep the meaning clear.

## Writing

Write through `scripts/logbook.sh` in this skill's directory, never by editing the file directly. You describe what happened, and the script picks the notation, places the node, and refuses entries that would break the structure. Its error messages say what to do instead.

Nodes are addressed by path: `2.1` is the first child of the second goal, and `0` is the top level for commands that add nodes. Every write prints the nodes it touched with their paths. Paths never change, so keep the ones you get back instead of re-reading the file.

| to record | command |
|---|---|
| a goal, or steps to take | `plan FILE PATH STEP... [--parallel]` |
| a step already under way | `doing FILE PATH TEXT` |
| steps already finished | `did FILE PATH TEXT...` |
| starting or finishing a planned step | `start FILE PATH`, `done FILE PATH` |
| giving up a step, or ruling out an option | `drop FILE PATH REASON` |
| context, a source, a justification | `note FILE PATH TEXT...` |
| something unexpected, problems included; steps to fix or bypass it go under it | `surprise FILE PATH TEXT` |
| something in the way | `blocker FILE PATH TEXT` |
| something to find out | `question FILE PATH TEXT` |
| candidate answers; steps taken to explore one go under it | `option FILE PATH TEXT...` |
| the choice made | `decide FILE PATH [CHOICE] [--over OPTION REASON]... [--why REASON]` |

`decide` goes on a question or blocker, recording CHOICE along with each option ruled out by `--over` and why it lost. On an option recorded earlier, it confirms that option. Other options stay open, as candidates that could come back later, until you `drop` the ones that are truly ruled out. A choice made while doing a step is a question or blocker first, then a decision on it.

Run the script without arguments for the full usage.

## Reading

- `status FILE` shows the work in progress with the goals above it, the open questions and blockers, and the steps not started yet, each with its notes and surprises. Start from it when resuming, then `show` the branch you pick up: steps planned under a step not started yet only appear there.
- `show FILE [PATH]` shows the whole tree, or one branch in full.

To read a `.logbook` without the script, see `references/notation.md`.

## The file

Use one `<effort-name>.logbook` per effort, stored wherever the project keeps its work artifacts. When resuming, look for an existing logbook for the effort before starting a new one. Add new goals to that file as the effort grows. A different effort gets its own file, and a `note` can point to it.

When delegating part of the work to a sub-agent, give it the logbook path and the path of the node to write under, and tell it to use the logbook skill. Skills don't carry over to sub-agents on their own.
