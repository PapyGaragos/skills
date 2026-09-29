---
name: one-thing
description: Ask the focusing question once, at one horizon, and answer it with a single effort. Use whenever someone asks what to do next, what the one thing is, what to focus on or prioritize (right now, this session, this week, this milestone, someday), when work has stalled or there are too many options to pick from, and as the first step of a workflow that picks its own target.
---

# One thing

Ask the focusing question once and give it one good answer. This skill does not plan, rank a backlog or break the answer into steps.

## The question

"Based on *anchor*, what's the ONE Thing I can do *horizon* such that by doing it everything else will be easier or unnecessary?"

The question drives the reasoning. The output doesn't repeat it. Each part carries weight:

- The horizon sets how big the answer may be.
- The anchor is the effort one horizon wider, the one the answer serves. Without it, the answer drifts toward whatever feels most urgent.
- "Such that by doing it" asks for leverage, not importance. Many things are important. The question wants the one that makes the others move.
- "Easier or unnecessary" is the test every candidate has to pass, and it is only checkable against a concrete "everything else".

## Pick the horizon

When the invocation names a horizon, use it. Otherwise pick the horizon just below the anchor's, the next one narrower than the parent objective. Do not drop to the narrowest horizon the request allows, because the answer would then serve the next step instead of the anchor. Two lists of horizons, widest first, serve as examples:

- someday, five years, this year, this month, this week, today, right now
- the project's final goal, the release or milestone in progress, the piece of work in progress (its branch, issue or PR), this session, the next action

Pick a horizon from either list, or name one that fits the situation better.

## Frame the anchor

When the invocation doesn't name the anchor, infer it from the project and mark it `(inferred)`, because a wrong anchor makes a good-looking answer serve the wrong goal.

Call the Skill tool with "as-effort" and reframe the anchor as an effort: its wanted state, its kind and its intent. The reframing is what the rest of the reasoning works from:

- The wanted state says what "done" looks like, so what is missing from it can be listed.
- The kind says what "missing" means. An `achieve` anchor lacks whatever isn't true yet. A `maintain` anchor lacks nothing until something threatens it. An `optimize` anchor always has a next step past where it stands now.
- The `so that` says what the anchor is for, which sizes the answer and breaks ties.

Do not derive the anchor by asking the focusing question one horizon wider. That is a second question built on a guess, and this skill asks one. At the widest horizon there is no anchor. The question then starts at "What's the ONE Thing", and the output line naming the anchor is left out.

## Answer it well

1. Name "everything else": the work within the horizon that serves the anchor. It comes from what the user raised this session, open tasks or tracker items, and what the anchor's kind says is missing. Without this list, "easier or unnecessary" can't be checked.

2. For each candidate, ask what it makes easier and what it makes unnecessary, by name. The winner topples the most of the list. A candidate that produces only its own value is not the answer, however urgent it looks.

3. Size the answer to the horizon, big and specific. Big means it fills the horizon rather than a slice of it. Specific means someone could tell whether it happened. An answer can be doable (what you'd pick anyway), a stretch (at the edge of what you know how to do) or a possibility (past what has been done). To reach beyond doable, find what the best have done at this, then ask what the next step past it is. For a narrow horizon like the next action, the answer is small and the check is mostly about leverage.

4. Commit to one answer. When two candidates topple the same amount, the anchor's `so that` breaks the tie.

5. Reframe the answer as an effort with as-effort, for its intent.

## Output

Plain text, not in a code block. The fences below only mark the template. Nothing comes after the last line: the reasoning stays out of the output, and disagreement with the answer is ordinary conversation, not a reason to ask again.

```
In order to [<anchor horizon>] <anchor intent>:

[<horizon>] <intent>

Easier: <items>. Unnecessary: <items>.
```

- A horizon label is the horizon's short name, a few words with no punctuation. Details belong in the intent.
- The intent's verb shows the kind, so the kind itself stays out.
- `Easier:` and `Unnecessary:` list names from the "everything else" list, separated by commas, without reasons. Leave out a label with no items.

For example:

```
In order to [this month] keep every invoice I receive in the ledger within a day, so that I never type one in (inferred):

[this week] Establish a typed schema for invoice line items, so that the parser and the ledger agree on what an invoice holds.

Easier: the mail watcher, bank reconciliation. Unnecessary: the manual cleanup script.
```
