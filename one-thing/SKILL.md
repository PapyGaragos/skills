---
name: one-thing
description: Derive the one action to do next from a stated objective, and sort everything else into Must, Should, Could and Won't. Use when asked what to do next, and as the first step of a workflow that picks its own target.
---

# One thing

One action, derived, plus a classification of everything else on the table.

Run at a session's start to choose a target, mid-session when the work has stopped moving, or as a workflow's first step.

Derive first. Classify what was already on the table afterwards.

## Not now

Deferring something says it is not first. It does not say it is worthless. Most of what gets deferred here is real work that matters later, so state the deferral as a scheduling fact and give the condition that makes it relevant again.

## What this derives

The ladder records how a rung was reached. A rung advances the one above it without completing it, so the bottom rung is the only one that is an action.

Axes divide progress toward the root. They say nothing about which files the work touches, so two axes routinely land in the same file. The winner is one action for one worker.

A requirement that pulls against the project's direction is a project management question. This skill flags it in one line and derives anyway.

## Procedure

### 1. Read the root and the axes

The root is the objective the derivation starts from, and only the invocation supplies it. With none supplied, the root is the project's own goal, whatever the session has been discussing: find where the project states it and quote it verbatim. Projects keep it in a readme, design pillars, a vision document, a tracker's milestones.

Read the project's direction, wherever the project records it. Treat it as a rung already derived to produce the root. Whoever supplied the root holds the rungs between the two; they stay unwritten and unreported. When the project records no direction beyond the root, the root is the top rung.

In the same pass, find how the root divides progress: pillars, epics, milestones, named workstreams. That division is the axis list. One axis is a legitimate answer.

Infer whatever is unstated, show the inference to the user, and wait for confirmation or correction before continuing. Where no reply is possible, run on the inference and label it inline, `Root (inferred, unconfirmed):` and `Axes (inferred, unconfirmed):`. A wrong root or a wrong axis makes the winner wrong, and the label is what makes that reviewable.

A requirement arriving from outside the project's written context enters here. When it names something to achieve, it is the root. Otherwise it shapes every ladder as a constraint. It contradicts the project's direction when doing it undoes or blocks something that direction requires. Cost, absence from any plan, and having no written owner are not contradictions. On a contradiction, name in one line what it undoes and derive anyway.

### 2. Derive one ladder per axis

At each rung ask: "Based on `<the rung above, verbatim>`, what is the one thing that would make everything else easier or unnecessary?"

Two rungs minimum, four maximum, per axis. Stop when a rung is an action that can be started immediately rather than a category of work.

Write each rung before asking the next question. A rung, once written, stands.

Then test each bottom rung: does doing it make the rest of that axis easier or unnecessary? A first domino topples the next one. Work that produces only its own value is not one, so derive that axis again.

### 3. Pick the winner

Across axes, ask which bottom rung makes the most of the *other* axes' remaining work easier or unnecessary.

Judge that against the project's direction read in step 1, not against the root, whenever the two differ. Two rungs can serve the root equally and the project's direction unequally, and that is the tiebreak.

One winner. The losing bottom rungs are already concrete actions with real preconditions, and they become the Should bucket.

### 4. Classify

| Bucket | Meaning | Requires |
|---|---|---|
| Must | do now | the winning bottom rung, and only it |
| Should | backlog, not now | the condition that makes it relevant |
| Could | discarded | nothing |
| Won't | rejected | a justification |

Sort the losing bottom rungs, everything proposed this session, and whatever an attached tracker or backlog holds.

When the winner appears nowhere on that list, say so.

### 5. Stop

Emit and end. Disagreement afterwards is ordinary conversation.

## Output

To the conversation, under twenty lines. The first line quotes the root. Axis name in the left column, every axis showing its full ladder.

```
Root: anything I read gets into the vault as a usable note without me formatting it.

Capture    1. one command fetches, extracts and writes a note
           Now: wire the extractor's output into the note writer
Quality    1. notes land with correct frontmatter and links
           Now: map extracted metadata onto the vault's frontmatter schema
Adoption   1. someone else can install and run it
           Now: write the install step in the readme

Capture wins. The other two act on notes that are never written: Quality has
nothing to map, and Adoption documents a command that does not complete.
Not previously on the table. The session had been discussing error messages.

Must:   wire the extractor's output into the note writer
Should: map metadata onto frontmatter, once notes are being written
Should: readme install step, once the command runs end to end
Could:  rework error messages
```

The project's direction never appears. It selects the winner and it stays out of the report.

A contradiction adds one line, `Contradicts: <what doing this undoes>`, directly under the root.

One line per rung. A rung needing two lines is two rungs. The verdict carries the reasoning, in two or three lines.

More axes means shallower ladders. The line budget is what trades them off.
