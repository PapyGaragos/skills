---
name: to-effort-file
description: Write an effort down as a Markdown file, `<slug>-effort.md`, holding its frontmatter, its end state, how to check the state is reached, and how to check it serves its parent efforts, with room at the end to track the work. Use when the user asks for an effort file, wants to write down, file or record an effort, or turns a goal, task or ticket into an effort to track work against.
---

# To effort file

An effort is a state someone wants to be true. Its file is what work records point at when they name the effort as their reason, so it says what the state is and how anyone would tell it holds. It leaves out how things stand today. That goes stale within days, while the wanted state and its checks last as long as the effort does.

## Steps

1. **Find the parents.** The parents are the efforts this one serves, and they go in `contributes-to:`. Use the ones the user names. When they name none, look for `*-effort.md` files anywhere under the working directory, read each one's frontmatter, and keep those whose state this effort would help bring about. A parent found this way is a guess, so put `# guessed` after its slug. With no parent given or found, the effort is a root and the file has no `contributes-to:`.

2. **Frame the effort.** Call the Skill tool with "as-effort" for the slug, kind and intent, with the parents' intents in view so the `so that` says how this effort serves them. If as-effort finds no wanted state in the input, say so and stop.

3. **Describe the end state.** A few sentences on what is true once the state holds, concrete enough that two people would agree on whether it does: what someone would look at, and what they would find there. For `maintain`, say what stays true. For `optimize`, name the value and the direction it moves. Describe the state alone, since the approach to reach it may change and belongs in the work section.

4. **Check the state.** Call the Skill tool with "how-to-check" on the end state from step 3.

5. **Check the contribution.** For each parent, call how-to-check on the property that reaching this effort's state moves the parent's state. When the parent has a file, read its checks first, so the contribution is checked against what the parent counts as progress.

6. **Strip the present.** From both check outputs, remove what describes how things stand now rather than the check: the `now <value>` clause of a metric, the `(to write)` marker, and any clause about what exists or is true today. Keep the rest of each entry as how-to-check wrote it.

7. **Write the file** as `<slug>-effort.md` in the working directory, or where the user says. If that file exists, show it and ask before replacing it.

## The file

```
---
name: <slug>
kind: <kind>
intent: >-
  <intent>
contributes-to:
  - <parent slug>
---

# <The wanted state, in sentence case>

## End state

<Step 3.>

## Checking

- <Each how-to-check entry from step 4, one per bullet.>
  - <Its `ground with:` or `proxy:` line, when it has one.>

## Contribution

### <parent slug>

- <Each how-to-check entry from step 5 for this parent, same shape.>

## Work

<Free form: the work done for this effort and the artifacts it produced. It starts with whatever work or artifacts the request mentioned, or empty.>
```

A root effort's Contribution section holds one line: `Root effort: it serves no other effort.`

## Reply

The file's path, then one line per guess the file carries: a guessed parent, or a purpose as-effort marked `(guessed)`. Nothing else, since the file holds the rest.
