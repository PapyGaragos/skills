# Keel

Agents drift on long tasks, and fixed plans break at the first surprise.

Keel breaks a high-level goal down until each piece is small enough for one agent to take on alone. That agent gets a well-defined state to reach, an approach to follow, the bigger picture both serve, and a way to signal when the course needs correcting. Every choice is logged for audit.

It keeps a graph of efforts (states someone wants, with a definition of done) and approaches (ways to reach them), where every link says why a piece of work exists. The skills below build and maintain that graph as the work turns up surprises.

## How it runs

### From a goal to a plan

1. **as-effort** turns the goal into an effort file, with criteria from **definition-of-done**.
2. **propose-effort-approach** writes candidate approaches, reusing ones that already serve other efforts, and opens a question in the logbook.
3. **decide-effort-approach** picks in a fresh agent, or hands the choice to a person.
4. **refined-approach-efforts** turns the chosen approach's steps into child efforts and reports the criteria they leave open.
5. Each child goes through the same cycle, until it is small enough for one agent to take on alone.

### When the work meets reality

An assumption turns out false, a criterion starts failing, or a step is missing. The working agent calls **propose-effort-approach** to reopen the choice, and **decide-effort-approach** keeps, switches or adds approaches. Nothing is deleted, so switching back finds the earlier work intact.

### Brainstorming

An idea floated mid-discussion goes through **propose-effort-approach** as one more candidate on the effort's open question. The question stays open until someone needs the choice.

### Handing off and resuming

Agents write to the logbook as they go. The next session runs `status` to see what is open, and a sub-agent given a node writes its findings under it.

## The skills

| Skill | Does |
|---|---|
| **as-effort** | Reframes a goal or task as the state wanted, and writes the effort file. |
| **definition-of-done** | States the conditions that mark an effort reached, held or good enough. |
| **reliable-checks** | Names the most trustworthy check for a criterion and what a pass would miss. |
| **as-approach** | Writes a way to reach an effort: its steps, assumptions, the criteria it covers and the ones it risks. |
| **propose-effort-approach** | Lists candidate approaches, or reopens a choice when the work shows a problem. Never chooses. |
| **decide-effort-approach** | Chooses with fresh context when the effort's criteria settle it, else leaves it to a person. |
| **refined-approach-efforts** | Turns a chosen approach into child efforts and judges whether they cover the criteria. |
| **effort-approach-graph** | Shows what an effort serves and what serves it, prevents duplicates, and audits for broken links and cycles. |
| **logbook** | Keeps an append-only record of multi-step work. See below. |

## The logbook

The logbook is a plain-text tree of goals, steps, notes, blockers, questions and decisions, written by a script. It is append-only and paths never change, so effort files cite the node behind each decision. It also works on its own, outside any effort.

Use it to:

- resume after a session ends, with `status` showing what is open
- hand work to sub-agents, each writing under its own node
- keep dead ends on record so nobody retries them
- store each decision with the options it beat and when a dropped one would come back
- keep blockers visible until someone resolves them
- give someone arriving cold a compact summary with `status` and `show`

## Install

Copy or symlink to your relevant `skills/` folder. No setup script to run.
The scripts used by the skills need bash 4 or newer.
