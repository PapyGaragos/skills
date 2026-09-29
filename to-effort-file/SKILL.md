---
name: to-effort-file
description: Write an effort down as a Markdown file, `<slug>-effort.md`, holding its frontmatter, its end state, its definition of done with the checks for each criterion, how to check it serves its parent efforts, its key tasks and its limits, with room at the end to track the work. Use when the user asks for an effort file, wants to write down, file or record an effort, or turns a goal, task or ticket into an effort to track work against.
---

# To effort file

An effort is a state someone wants to be true. Its file is what work records point at when they name the effort as their reason, so it says what the state is, how anyone would tell it holds, and what bounds the work toward it. It leaves out how things stand today. That goes stale within days, while the wanted state and its checks last as long as the effort does. It also leaves out how to reach the state, which is for whoever does the work to decide.

## Steps

1. **Find the parents.** The parents are the efforts this one serves, and they go in `contributes-to:`. Use the ones the user names. When they name none, run `scripts/effort-intents.sh --all` from this skill's directory to list every effort under the working directory with its kind and intent, and keep those whose state this effort would help bring about. A parent found this way is a guess, so put `# guessed` after its slug. With no parent given or found, the effort is a root and the file has no `contributes-to:`. Run `scripts/effort-intents.sh` from this skill's directory with the parents' slugs to read their intents and their own parents' intents. The file never copies these, since the script shows them from the source.

2. **Frame the effort.** Call the Skill tool with "as-effort" for the slug, kind and intent, with the intents from step 1 in view so the `so that` says how this effort serves its parents. If as-effort finds no wanted state in the input, say so and stop.

3. **Describe the end state.** A few sentences on what is true once the state holds, concrete enough that two people would agree on whether it does: what someone would look at, and what they would find there. For `maintain`, say what stays true. For `optimize`, name the value and the direction it moves. Describe the state alone, since the approach to reach it may change. Say what is found, not how anyone looks: no test, drill, sample size or schedule.

4. **Define done.** Call the Skill tool with "definition-of-done" on the end state from step 3. Order its criteria by how much the purpose depends on each, most first, since the order is what settles a conflict between two of them. Then call "reliable-checks" on the ordered criteria.

5. **Check the contribution.** For each parent, call definition-of-done and then reliable-checks on the property that reaching this effort's state moves the parent's state. When the parent has a file, read its definition of done first, so the contribution is checked against what the parent counts as progress.

6. **Pick the key tasks.** Call the Skill tool with "key-tasks" on the end state.

7. **Name the limits.** Collect the outcomes to avoid and the constraints the work must respect, from the request and the parents' files. A criterion from step 4 that only protects something already true, rather than marking the state reached, is a limit too, so move it here, and take it out of the end state too. Frame each one with as-effort as a `maintain` effort, then call reliable-checks on it. A constraint that dictates an action becomes the state it protects. Don't invent limits. A limit the request did not state, including one moved from step 4, ends its line with ` # guessed`, as a guessed parent does. A `(guessed)` before the final period still marks only a guessed purpose.

8. **Strip the present.** From every check, remove what describes how things stand now rather than the check: the `now <value>` clause of a metric, the `(to write)` marker, and any clause about what exists or is true today. Keep the rest of each entry as reliable-checks wrote it, except the conditions: a check sits under its criterion, so it drops the conditions the criterion already states and keeps its label, what does the checking and when, and what a pass proves.

9. **Write the file** as `<slug>-effort.md` in the working directory, or where the user says. If that file exists, show it and ask before replacing it.

10. **Check the file.** Run `scripts/check-effort-file.sh <file>`. Fix every problem it reports and run it again until it exits 0.

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

## Definition of done

Most important first. When two criteria conflict, the earlier one wins.

- <Each definition-of-done entry from step 4, one per bullet.>
  - <Its reliable-checks entry.>
  - <Its `ground with:` or `proxy:` line, when it has one.>

## Serves

### <parent slug>

- <Each definition-of-done entry from step 5 for this parent, same shape.>
  - <Its reliable-checks entry, and any `ground with:` or `proxy:` line.>

## Key tasks

- <Each key-tasks line from step 6.>

## Limits

- <Each limit's as-effort line from step 7, then ` # guessed` when the request did not state it.>
  - <Its reliable-checks entry.>

## Work

<Free form: the work done for this effort and the artifacts it produced. It opens with one line `baseline: <what is measured>: unknown` for each check that compares with a value from the effort's start, so the value gets recorded before the work changes it. Then comes whatever work or artifacts the request mentioned, or nothing.>
```

A root effort's Serves section holds one line: `Root effort: it serves no other effort.` Leave out the Key tasks section when key-tasks finds none, and the Limits section when there are none.

## Reply

The file's path, then the lines under `guesses:` from the last `check-effort-file.sh` run, copied as the lint printed them. Nothing else, since the file holds the rest: start with the path, put no sentence around it, and don't explain the guesses.
