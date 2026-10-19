# Keel

Agents drift on long tasks, and fixed plans break at the first surprise.

Keel keeps long-running work, by agents or people, aimed at what someone wants, across plan changes, sessions and handoffs. It breaks a high-level goal down until each piece is small enough for one agent to take on alone. That agent gets a well-defined state to reach, a way to reach it, the larger goal both serve, and a way to reopen the plan when the work shows it is wrong. A logbook records every choice for later audit.

Keel is a set of agent skills. They work in any agent that loads `SKILL.md` skills, such as Claude Code.

## The idea

Keel tracks two kinds of things, each in a plain Markdown file, and links them into a graph:

- **Efforts** are states someone wants, never the work to reach them: "every attic print is scanned", not "scan the prints". An effort names what counts as done, the limits the work must respect, and the efforts it serves. It keeps its name when the plan changes.
- **Approaches** are ways to reach one or more efforts: steps, the assumptions they rest on, the criteria they cover and the ones they put at risk. An effort may take several, each covering part of it.

Each link says why a piece of work exists: a child effort serves a parent through one of the parent's approaches, or whatever approach it takes. Next to each effort, a **logbook** records the reasoning: what was tried, what was found, the options weighed and the choice made.

The files hold the current state, and the logbook holds the history. Keel deletes nothing, so switching back to an old way finds the earlier work intact.

A few design choices shape the rest:

- **Progress is criteria met, and nothing else.** A busy logbook or a pile of commits says what happened, not what holds. Progress is a dated check that finds a criterion met, and the criterion was written before the work started.
- **Proposing and deciding are split.** Whoever proposes a way shares its blind spots, so a separate agent with fresh context decides. It decides only when the effort's own criteria and purpose settle it, and hands any other trade-off to a person.
- **Contributors pick their own work.** Nobody assigns tasks top-down. An agent given an effort picks the action that moves it most, does it, checks it and stops when the next move needs a fresh choice.
- **Small pieces for small models.** A cheap model should be able to handle a leaf effort. Agents hand judgment calls to a stronger model first, then to a person.

## What the files look like

`attic-prints-scanned-effort.md`:

```markdown
---
name: attic-prints-scanned
kind: achieve
intent: >-
  Have every printed photo from the attic scanned, so that each print has a digital copy.
contributes-to:
  family-memories-kept: [scan-prints-to-two-clouds]
---

# Every attic print is scanned

## End state

Every printed photo stored in the attic exists as a digital image.

## Criteria

- every-attic-print-scanned  Done when: every print from the attic has a matching scan file.

## Serves

### family-memories-kept

- copies-survive-one-loss  Done when: every attic print has a digital copy besides the paper.
```

An effort's `kind` is `achieve` (reached once), `maintain` (held over time) or `optimize` (pushed in a direction). Once approaches are proposed, an `## Approaches` section lists each one as `[chosen]`, `[candidate]` or `[dropped]`, with the logbook node that records the decision. Each approach lives in its own `<slug>-approach.md`, and the logbook in `<slug>.logbook` next to the effort file.

You rarely write these by hand. The skills write them through scripts that check the format and refuse a broken file.

## How it runs

### Doing the work

Ask an agent to work on an effort, and **advance-effort** makes one run on it. It reads where the effort stands from its file, its logbook and the project, then picks one action: clarify a guess, investigate an unknown, verify a criterion, act, descend into a child effort, or propose another way. It does it, checks the criteria it targeted, logs the result and stops once the next action is a new choice. Each run ends with a short report: what it did, which criteria are met, and any question for a person.

When a question comes up mid-run, **find-out** looks for the answer from the cheapest source up: the conversation, the records, the project, trying it, outside sources. It stops before asking a stronger model or a person, and returns the question instead.

### From a goal to a plan

When an effort is too big to act on in one run, advance-effort descends into it. Each step below adds files only when the work needs them:

1. **as-effort** turns the goal into an effort file, with criteria from **definition-of-done**.
2. **propose-effort-approach** writes candidate approaches, reusing ones that already serve other efforts, and opens a question in the logbook.
3. **decide-effort-approach** runs in a fresh agent. It chooses a set of approaches that together cover the criteria, or hands the choice to a person, and reports any criterion no chosen approach covers.
4. **refined-approach-efforts** turns the chosen approaches' steps into child efforts and reports the criteria they leave open.
5. Each child goes through the same cycle, until it is small enough for one agent to take on alone.

Each skill also works on its own: ask for an effort file, a definition of done, or approaches for an effort, and stop there.

### When the work shows a problem

An assumption turns out false, a criterion starts failing, or a step is missing. The working agent calls **propose-effort-approach** to reopen the choice, naming what it saw, and **decide-effort-approach** keeps, switches or adds approaches. Child efforts of a dropped approach stay on file.

### Brainstorming

An idea floated mid-discussion goes through **propose-effort-approach** as one more candidate on the effort's open question. The question stays open until someone needs the choice.

### Handing off and resuming

Agents write to the logbook as they go. The next session runs `status` to see what is open, and a sub-agent given a node writes its findings under it.

## The skills

| Skill | Does |
|---|---|
| **advance-effort** | Does the work an effort needs, one run at a time, and records what it met. |
| **as-effort** | Reframes a goal or task as the state wanted, and writes the effort file. |
| **definition-of-done** | States the conditions that mark an effort reached or held, or the metric to push. |
| **reliable-checks** | Names the most trustworthy check for a criterion and what a pass would miss. |
| **as-approach** | Writes down a way to reach an effort: its steps, assumptions, the criteria it covers and the ones it risks. |
| **propose-effort-approach** | Proposes approaches, or reopens a choice when the work shows a problem. Never chooses. |
| **decide-effort-approach** | Chooses with fresh context when the effort's criteria settle it, else leaves it to a person. |
| **refined-approach-efforts** | Turns the chosen approaches into child efforts and judges whether they cover the criteria. |
| **effort-approach-graph** | Shows what an effort serves and what serves it, catches duplicates, and audits for broken links and cycles. |
| **find-out** | Answers what the work depends on from the cheapest source that can settle it, or says who to ask. |
| **logbook** | Keeps an append-only record of multi-step work. See below. |

The skills call each other by name: advance-effort needs all the others but reliable-checks. Install them together, under these names.

Each skill answers in the form the request asks for: a one-line statement for a person, a file, or fields in YAML, JSON or a table for a script. Called from another skill's steps, it hands its result to the caller instead of answering.

## The logbook

The logbook is a plain-text tree of goals, steps, notes, blockers, questions and decisions, written by a script. It is append-only and paths never change, so effort files cite the node behind each decision. It also works on its own, outside any effort.

Use it to:

- resume after a session ends, with `status` showing what is open
- hand work to sub-agents, each writing under its own node
- keep dead ends on record so nobody retries them
- store each decision with the options it beat and when a dropped one would come back
- keep blockers visible until someone resolves them
- give someone arriving cold a compact summary with `status` and `show`

## Which model for which step

From the evals so far, on Claude Haiku and Sonnet:

| Step | Small model (Haiku) |
|---|---|
| as-effort with definition-of-done | Fine for criteria taken from the request. It misses limits that only the project's own docs state; Sonnet finds them. |
| propose-effort-approach with as-approach | Not yet. A judge found 12 of its 30 proposals sound, against 19 of 30 for Sonnet. |
| decide-effort-approach | Fine on hand-written approach files. On proposals written by agents, its choice can change from one run to the next. |

## Status

Every skill is built and passes its tests. The decider weighs options against the effort's criteria and purpose only. It has no formal way yet to weigh trade-offs, so it hands those to a person.

## Install

Copy or symlink every skill folder into your agent's skills folder, such as `.claude/skills/`. There is no setup script to run.

The scripts the skills use need bash 4 or newer, plus `awk`, `find` and `sort`. `git` is optional: when present, the approach scripts use the repository root to find effort files.
