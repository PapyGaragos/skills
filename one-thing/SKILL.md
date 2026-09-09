---
name: one-thing
description: Re-derive the next action from the project's goal across every axis of progress, and classify everything else.
disable-model-invocation: true
---

# One thing

Run at a session's start to choose a target, or mid-session when the work has stopped moving.

Derive first. Classify what was already on the table afterwards.

## Not now

Deferring something says it is not first. It does not say it is worthless. Most of what gets deferred here is real work that matters later, so state the deferral as a scheduling fact and give the condition that makes it relevant again.

## Procedure

### 1. Read the goal and the axes

Find where the project states its goal, and quote it verbatim. Projects keep it in different places: a readme, design pillars, a vision document, a tracker's milestones.

In the same pass, find how the project divides progress toward that goal: pillars, epics, milestones, named workstreams. That division is the axis list. One axis is a legitimate answer.

Infer whatever the project leaves unstated, show the inference to the user, and wait for confirmation or correction before continuing. Where no reply is possible, run on the inference and label it inline, `Goal (inferred, unconfirmed):` and `Axes (inferred, unconfirmed):`. A wrong goal or a wrong axis makes the winner wrong, and the label is what makes that reviewable.

Root at the project's goal, never the session's. The session goal is what drifted.

### 2. Derive one ladder per axis

At each rung ask: "Based on `<the rung above, verbatim>`, what is the one thing that would make everything else easier or unnecessary?"

Two rungs minimum, four maximum, per axis. Stop when a rung is an action that can be started immediately rather than a category of work.

Write each rung before asking the next question. A rung, once written, stands.

Then test each bottom rung: does doing it make the rest of that axis easier or unnecessary? A first domino topples the next one. Work that produces only its own value is not one, so derive that axis again.

### 3. Pick the winner

Across axes, ask the same question one level up: which bottom rung makes the most of the *other* axes' remaining work easier or unnecessary?

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

To the conversation, under twenty lines. Axis name in the left column, every axis showing its full ladder.

```
Goal: anything I read gets into the vault as a usable note without me formatting it.

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

One line per rung. A rung needing two lines is two rungs. The verdict carries the reasoning, in two or three lines.

More axes means shallower ladders. The line budget is what trades them off.
