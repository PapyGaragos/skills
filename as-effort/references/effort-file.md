# Effort file

This writes an effort down as a Markdown file, `<slug>-effort.md`, holding its frontmatter, its end state, its definition of done, what counts as serving its parent efforts and its limits.

The file is what work records point at when they name the effort as their reason, so it says what the state is, how anyone would tell it holds, and what bounds the work toward it. It leaves out how things stand today. That goes stale within days, while the wanted state and its criteria last as long as the effort does. It also leaves out how to reach the state. The ways to reach it may be listed in their own `## Approaches` section, as references to approach files and to the effort's logbook (`- [<status>] <approach-slug> (logbook: <node>)`), which only the approach workflows (propose-effort-approach, decide-effort-approach) write, since the way can change while the state lasts. This reference never writes that section, and carrying out the work stays with whoever does it.

## Steps

1. **Take the parents.** The parents are the efforts this one serves, and they go in `contributes-to:`. They come from whoever asks: the user names them, or a calling skill passes `<parent>: [<approach>, ...]`, listing the parent's approaches this effort serves, so that a change of approach up there shows which children it affects. A parent given with no approach takes `[]`: this effort serves it whatever the approach. A parent the caller marks as guessed keeps ` # guessed`. With no parent given, the effort is a root and the file has no `contributes-to:`. Read each parent's file, found with `find . -name '<parent>-effort.md'`, for its intent and definition of done, and never copy them into this file. Placing the effort in the graph, finding its duplicate, other parents and children, is effort-approach-graph's job, for the user who wants it.

2. **Frame the effort.** Work out the slug, kind and intent with the steps in SKILL.md, with the parents' intents in view so the `so that` says how this effort serves its parents. If the input holds no wanted state, say so and stop.

3. **Describe the end state.** A few sentences on what is true once the state holds, concrete enough that two people would agree on whether it does: what someone would look at, and what they would find there. For `maintain`, say what stays true. For `optimize`, name the value and the direction it moves. Describe the state alone, since the approach to reach it may change. Say what is found, not how anyone looks: no test, drill, sample size or schedule.

4. **Define done.** Call the Skill tool with "definition-of-done" on the end state from step 3.

5. **Define the contribution.** For each parent, call definition-of-done on the property that reaching this effort's state moves the parent's state. When the parent has a file, read its definition of done first, so the contribution matches what the parent counts as progress. Then name each entry after the parent criterion it moves, in place of the name definition-of-done gave it, and split an entry that moves two. The shared name is what shows which of the parent's criteria its children serve.

6. **Name the limits.** Collect the outcomes to avoid and the constraints the work must respect, from the request and the parents' files. A criterion from step 4 that only protects something already true, rather than marking the state reached, is a limit too, so move it here, and take it out of the end state too. Frame each one with the steps in SKILL.md as a `maintain` effort, in its one-line form. A limit taken from a parent's file keeps its slug there. A constraint that dictates an action becomes the state it protects. Don't invent limits. A limit the request did not state, including one moved from step 4, ends its line with ` # guessed`, as a guessed parent does. A `(guessed)` before the final period still marks only a guessed purpose.

7. **Write the file.** Pipe the content into `scripts/write-effort-file.sh`, in this skill's folder. It writes in the working directory, or in the folder the user names, passed as its argument:

   ```
   scripts/write-effort-file.sh <<'EOF'
   name: <slug>
   kind: <kind>
   intent: <intent>
   parent: <one line per parent: its slug, then the parent's approaches this effort serves, space-separated, if any, then ` # guessed` for a guessed one; no parent: line at all for a root>
   title: <the wanted state, in sentence case>
   end-state: <step 3, one line per paragraph>
   criterion: <one line per definition-of-done entry from step 4, as it came>
   serves: <parent slug> <one line per entry from step 5 for that parent>
   limit: <one line per limit from step 6, then ` # guessed` when the request did not state it>
   EOF
   ```

   It writes `<slug>-effort.md` only when `scripts/check-effort-file.sh` passes on it. Otherwise it prints the problems and writes nothing: fix the input and run the same command again until it exits 0. When it says the file exists, show that file and ask before rerunning with `--replace`, and write nothing, there or anywhere else, until the user answers. `--replace` keeps the file's Approaches section.

## Reply

The file's path, then the lines under `guesses:` from the last `write-effort-file.sh` run, copied as it printed them. Nothing else, since the file holds the rest: start with the path, put no sentence around it, and don't explain the guesses.
